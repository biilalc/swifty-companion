// Uygulamanin authentication durumunu tutan provider. Tum ekranlar bu
// provider'i dinleyerek otomatik olarak login <-> home arasinda redirect
// olur (bkz. app_router.dart).

import 'package:flutter/foundation.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/utils/logger.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus {
  /// Uygulama acildi, henuz auth durumu bilinmiyor.
  initial,

  /// Login veya storage islemi devam ediyor.
  loading,

  /// Token var, authenticated.
  authenticated,

  /// Token yok, login ekranina gitmeli.
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;

  AuthStatus _status = AuthStatus.initial;

  /// Son hata mesaji. UI snackbar/dialog gostermek icin okuyabilir.
  String? _lastErrorKey;
  Map<String, String>? _lastErrorArgs;

  AuthProvider(this._repo);

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  String? get lastErrorKey => _lastErrorKey;
  Map<String, String>? get lastErrorArgs => _lastErrorArgs;

  /// Uygulama start'inda cagrilir. Kayitli token var mi bakip auth status
  /// belirler.
  Future<void> bootstrap() async {
    _setStatus(AuthStatus.loading);
    try {
      final authed = await _repo.isAuthenticated();
      _setStatus(authed ? AuthStatus.authenticated : AuthStatus.unauthenticated);
    } catch (e, st) {
      appLogger.e('Auth bootstrap hatasi', error: e, stackTrace: st);
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// Kullanicinin 42 ile login olma akisini baslatir.
  Future<bool> login() async {
    _clearError();
    _setStatus(AuthStatus.loading);
    try {
      await _repo.login();
      _setStatus(AuthStatus.authenticated);
      return true;
    } on AuthException catch (e) {
      appLogger.w('Login basarisiz: ${e.message}');
      _setError(
        e.message.toLowerCase().contains('cancel')
            ? 'errors.login_cancelled'
            : 'errors.login_failed',
      );
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } on AppException catch (e) {
      appLogger.w('Login sirasinda beklenmedik hata: ${e.message}');
      _setError('errors.login_failed');
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } catch (e, st) {
      appLogger.e('Login generic hata', error: e, stackTrace: st);
      _setError('errors.login_failed');
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  /// Tum oturumu temizler ve login ekranina yollar.
  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (e, st) {
      // Logout hata verse bile status'u unauthenticated yapiyoruz - kullaniciyi
      // kendi hesabinda sikistirmak yerine token'i local de temizlenmis
      // varsayip login'e yolluyoruz.
      appLogger.w('Logout sirasinda hata (yok sayiliyor)',
          error: e, stackTrace: st);
    }
    _setStatus(AuthStatus.unauthenticated);
  }

  /// Interceptor token refresh'i tamamen beceremezse (kullanici cok uzun
  /// sure logout etmedi, refresh_token revoke edildi vs.) bu cagrilir.
  /// Router bunu dinleyerek login ekranina yonlendirir.
  void onSessionExpired() {
    appLogger.w('Oturum sonlandi (interceptor bildirdi)');
    _setError('errors.unauthorized');
    _setStatus(AuthStatus.unauthenticated);
  }

  void _setStatus(AuthStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    notifyListeners();
  }

  void _setError(String key, [Map<String, String>? args]) {
    _lastErrorKey = key;
    _lastErrorArgs = args;
    notifyListeners();
  }

  void _clearError() {
    _lastErrorKey = null;
    _lastErrorArgs = null;
  }

  /// UI error banner'ini manuel kapatmak icin.
  void clearError() {
    _clearError();
    notifyListeners();
  }
}
