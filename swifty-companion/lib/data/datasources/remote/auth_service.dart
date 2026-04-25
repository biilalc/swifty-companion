// OAuth2 Authorization Code + PKCE akisini yoneten servis.
// flutter_appauth paketi native tarafta Android Custom Tabs (Chrome) veya
// system browser acarak kullaniciyi intra.42.fr'ye gonderir, PKCE challenge
// uretir, redirect URI'yi intercept eder ve token degisimini yapar.
//
// Bu servis ayni zamanda refresh token akisini da yonetir - bonus'un
// omurgasi. Token expire olunca /oauth/token endpoint'ine refresh_token
// ile POST ederek yeni access_token aliriz.

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

import '../../../core/config/env_config.dart';
import '../../../core/errors/app_exceptions.dart' as app_err;
import '../../../core/utils/logger.dart';
import '../../models/token_model.dart';

class AuthService {
  final FlutterAppAuth _appAuth;

  /// Manuel refresh icin ayri bir Dio client. 42 API refresh icin client
  /// secret de istedigi icin basit bir POST daha guvenli ve ongorulebilir.
  final Dio _tokenDio;

  AuthService({FlutterAppAuth? appAuth, Dio? tokenDio})
      : _appAuth = appAuth ?? const FlutterAppAuth(),
        _tokenDio = tokenDio ?? Dio();

  /// Kullaniciyi intra.42.fr'de login olmaya yonlendiren asil fonksiyon.
  /// Authorization Code + PKCE akisi:
  ///   1. App, random code_verifier uretir (flutter_appauth otomatik yapar).
  ///   2. code_challenge = SHA256(code_verifier) olarak hesaplanir.
  ///   3. Browser acilir, kullanici intra'da login olur.
  ///   4. Intra, bizim redirect_uri'ye ?code=xxx ile doner.
  ///   5. App, code + code_verifier'i /oauth/token'a POST eder.
  ///   6. Sunucu access_token + refresh_token doner.
  /// Subject: "you must use intra oauth2" - birebir uygulaniyor.
  Future<TokenModel> login() async {
    try {
      appLogger.i('OAuth2 login akisi baslatildi');
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          EnvConfig.uid,
          EnvConfig.redirectUri,
          clientSecret: EnvConfig.secret,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: EnvConfig.authUrl,
            tokenEndpoint: EnvConfig.tokenUrl,
          ),
          scopes: EnvConfig.scopesList,
          preferEphemeralSession: true,
          promptValues: const ['login'],
        ),
      );

      if (result == null || result.accessToken == null) {
        // result null ise kullanici iptal etti veya plugin beklenmedik
        // bir durumla karsilasti. Iptal olarak handle ediyoruz.
        throw const app_err.AuthException('Login cancelled');
      }

      final token = _appAuthToTokenModel(result);
      appLogger.i('Login basarili, token alindi (expires: ${token.expiresAt})');
      return token;
    } on PlatformException catch (e, st) {
      // flutter_appauth 6.x tum platform hatalarini PlatformException
      // olarak firlatir. error code AUTHORIZE/AUTHORIZE_AND_EXCHANGE_CODE
      // oldugunda genelde user cancellation veya browser problemi demektir.
      final isCancelled = _isCancellationError(e);
      appLogger.w(
        isCancelled
            ? 'Login kullanici tarafindan iptal edildi'
            : 'Login platform hatasi: ${e.code} - ${e.message}',
        error: e,
        stackTrace: st,
      );
      throw app_err.AuthException(
        isCancelled ? 'Login cancelled' : 'Authentication failed: ${e.message}',
        cause: e,
      );
    } catch (e, st) {
      if (e is app_err.AuthException) rethrow;
      appLogger.e('Login beklenmedik hata', error: e, stackTrace: st);
      throw app_err.AuthException('Login failed', cause: e);
    }
  }

  /// Refresh token kullanarak yeni bir access_token alir.
  /// Bonus: "Recreate token at expiration date. If the token expires, the
  /// application must refresh it."
  Future<TokenModel> refresh(TokenModel current) async {
    final refreshToken = current.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const app_err.UnauthorizedException(
        'No refresh token available - re-login required',
      );
    }

    try {
      appLogger.i('Token refresh isteniyor');
      final response = await _tokenDio.post<Map<String, dynamic>>(
        EnvConfig.tokenUrl,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => status != null && status < 500,
        ),
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': EnvConfig.uid,
          'client_secret': EnvConfig.secret,
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        appLogger.w(
          'Refresh basarisiz: ${response.statusCode} - ${response.data}',
        );
        throw app_err.UnauthorizedException(
          'Refresh failed (${response.statusCode})',
        );
      }

      final newToken = TokenModel.fromApiResponse(response.data!);
      // 42 bazen refresh_token dondurmez; eski token'i koru ki kullanici
      // bir sonraki refresh'te de calissin.
      final merged = newToken.refreshToken == null
          ? newToken.copyWith(refreshToken: refreshToken)
          : newToken;
      appLogger.i('Token refresh basarili (yeni expires: ${merged.expiresAt})');
      return merged;
    } on DioException catch (e, st) {
      appLogger.e('Refresh network hatasi', error: e, stackTrace: st);
      throw app_err.UnauthorizedException(
        'Refresh failed due to network error',
        e,
      );
    }
  }

  /// Logout: yerel token silme TokenStorage'da yapilir. Burada
  /// ileride session revocation'u eklemek istersek diye placeholder birakiyoruz.
  Future<void> endSession() async {
    appLogger.i('Oturum sonlandirildi');
  }

  /// flutter_appauth response'unu TokenModel'e cevirir.
  TokenModel _appAuthToTokenModel(AuthorizationTokenResponse result) {
    final expiresAt = result.accessTokenExpirationDateTime?.toUtc() ??
        DateTime.now().toUtc().add(const Duration(hours: 2));
    return TokenModel(
      accessToken: result.accessToken!,
      refreshToken: result.refreshToken,
      expiresAt: expiresAt,
      tokenType: result.tokenType ?? 'Bearer',
      scopes: (result.scopes ?? EnvConfig.scopesList).toList(),
    );
  }

  /// PlatformException'un cancellation mi yoksa gercek hata mi oldugunu anlar.
  bool _isCancellationError(PlatformException e) {
    final msg = (e.message ?? '').toLowerCase();
    final details = (e.details?.toString() ?? '').toLowerCase();
    if (msg.contains('cancel') || details.contains('cancel')) return true;
    if (msg.contains('user cancelled') || msg.contains('user canceled')) {
      return true;
    }
    // iOS CanceledByUser + Android user_cancelled icerirler.
    if (e.code == 'authorize_and_exchange_code_failed' ||
        e.code == 'authorize_failed') {
      // Native plugin cancel'i da bu code'a dahil ediyor; message'a bakarak
      // ayiriyoruz. Cancel degilse de auth exception olarak yukseltecegiz.
      return msg.contains('access_denied') || msg.contains('cancel');
    }
    return false;
  }
}
