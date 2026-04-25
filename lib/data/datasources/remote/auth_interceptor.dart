// Dio interceptor'u. Iki kritik isi vardir:
//  1. Her istege Authorization header'i ekler (token yoksa login'e gidilir).
//  2. Token expire olmak uzereyse PROAKTIF olarak refresh eder; 401 gelirse
//     REAKTIF olarak refresh deneyip istegi tekrar eder.
//
// Bu sayede:
//  - Subject: "Do not create a token for each query" -> SAGLANDI
//    (token disk'te cached, sadece gerektiginde yenilenir).
//  - Bonus: "Recreate token at expiration date" -> SAGLANDI.

import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/errors/app_exceptions.dart' as app_err;
import '../../../core/utils/logger.dart';
import '../../models/token_model.dart';
import '../local/token_storage.dart';
import 'auth_service.dart';

/// Refresh operasyonunun birden fazla concurrent istek tarafindan tetiklenmesini
/// engellemek icin bir lock. Cok onemli: kullanici profil ekranina girdiginde
/// birden fazla API cagrisi ayni anda atilir (me, user detail, vs.). Eger
/// token expire ise her biri ayri ayri refresh tetiklerse hem gereksiz
/// trafik olur hem de race condition'la refresh_token yanlis tuketilebilir.
class AuthInterceptor extends QueuedInterceptor {
  final TokenStorage _storage;
  final AuthService _authService;

  /// Mevcut refresh islemi varsa, tum bekleyen istekler ayni future'i bekler.
  Future<TokenModel>? _ongoingRefresh;

  /// Callback: token kalici olarak expire oldu (refresh de basarisiz),
  /// uygulamanin kullaniciyi login ekranina atmasi gerekir.
  final void Function()? onSessionExpired;

  AuthInterceptor({
    required TokenStorage storage,
    required AuthService authService,
    this.onSessionExpired,
  })  : _storage = storage,
        _authService = authService;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // OAuth endpoint'lerine atilan isteklere token eklemiyoruz (zaten auth
      // icin kendileri). Sadece /v2/* API cagrilarina ekle.
      if (_isAuthEndpoint(options.uri)) {
        return handler.next(options);
      }

      var token = await _storage.read();

      // Token yoksa -> login olunmamis veya manuel silinmis. 401'e zorla.
      if (token == null) {
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: const app_err.UnauthorizedException('No token stored'),
          ),
          true,
        );
      }

      // PROAKTIF refresh: Token yakin zamanda expire olacaksa simdiden yenile.
      if (token.isExpiringSoon) {
        appLogger.d('Token expire olmak uzere, proaktif refresh yapiliyor');
        try {
          token = await _refreshWithLock(token);
        } on app_err.UnauthorizedException catch (e) {
          appLogger.w('Proaktif refresh basarisiz: ${e.message}');
          await _storage.clear();
          onSessionExpired?.call();
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: e,
            ),
            true,
          );
        }
      }

      options.headers['Authorization'] = '${token.tokenType} ${token.accessToken}';
      handler.next(options);
    } catch (e, st) {
      appLogger.e('AuthInterceptor onRequest hatasi', error: e, stackTrace: st);
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          type: DioExceptionType.unknown,
        ),
        true,
      );
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // REAKTIF refresh: Server 401 dondurduyse token invalid (erken expire
    // olmus olabilir, clock skew, veya revoke edilmis).
    final status = err.response?.statusCode;
    final isAuthEndpoint = _isAuthEndpoint(err.requestOptions.uri);

    // Token refresh endpoint'ine atilan istek 401 verdiyse - retry etmek
    // sonsuz dongu yaratir. Direkt expired gibi davran.
    if (status == 401 && !isAuthEndpoint) {
      // Bu istek daha once retry edildiyse tekrar deneme.
      final alreadyRetried = err.requestOptions.extra['auth_retry'] == true;
      if (alreadyRetried) {
        appLogger.w('401 tekrar geldi, refresh calismadi, oturum bitiyor');
        await _storage.clear();
        onSessionExpired?.call();
        return handler.next(err);
      }

      try {
        final current = await _storage.read();
        if (current == null) {
          onSessionExpired?.call();
          return handler.next(err);
        }

        appLogger.i('401 alindi, refresh deneniyor');
        final newToken = await _refreshWithLock(current);
        // Orijinal istegi yeni token ile tekrarla.
        final opts = err.requestOptions;
        opts.headers['Authorization'] =
            '${newToken.tokenType} ${newToken.accessToken}';
        opts.extra['auth_retry'] = true;

        final cloneDio = Dio(BaseOptions(
          baseUrl: opts.baseUrl,
          connectTimeout: opts.connectTimeout,
          receiveTimeout: opts.receiveTimeout,
          sendTimeout: opts.sendTimeout,
        ));
        final response = await cloneDio.fetch<dynamic>(opts);
        return handler.resolve(response);
      } on app_err.UnauthorizedException catch (e) {
        appLogger.w('Reaktif refresh basarisiz: ${e.message}');
        await _storage.clear();
        onSessionExpired?.call();
        return handler.next(err);
      } catch (e, st) {
        appLogger.e('Reaktif refresh beklenmeyen hata',
            error: e, stackTrace: st);
        return handler.next(err);
      }
    }

    handler.next(err);
  }

  /// Refresh'i lock'lu sekilde calistirir. Ayni anda birden cok istek
  /// 401 alirsa hepsi tek bir refresh operasyonunu bekler.
  Future<TokenModel> _refreshWithLock(TokenModel current) async {
    final ongoing = _ongoingRefresh;
    if (ongoing != null) {
      appLogger.d('Zaten devam eden bir refresh var, onu bekliyoruz');
      return ongoing;
    }

    final future = _performRefresh(current);
    _ongoingRefresh = future;
    try {
      return await future;
    } finally {
      _ongoingRefresh = null;
    }
  }

  Future<TokenModel> _performRefresh(TokenModel current) async {
    final newToken = await _authService.refresh(current);
    await _storage.save(newToken);
    return newToken;
  }

  /// OAuth authorize/token endpoint'lerinde mi sorgusu. Bu endpoint'lere
  /// Authorization header eklememeliyiz cunku kendileri auth istiyor.
  bool _isAuthEndpoint(Uri uri) {
    final path = uri.path;
    return path.contains('/oauth/token') || path.contains('/oauth/authorize');
  }
}
