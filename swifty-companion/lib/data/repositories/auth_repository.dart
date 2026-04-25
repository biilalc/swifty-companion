// Authentication ile ilgili islemlerin tek giris kapisi. UI katmani
// AuthService'e veya TokenStorage'a direkt erisMEZ, hepsi bu repo
// uzerinden akar. Bu sayede:
//  - Test'ler icin kolay mock'lanir.
//  - Business rule degisikligi tek yerden yapilir.

import '../../core/utils/logger.dart';
import '../datasources/local/token_storage.dart';
import '../datasources/remote/auth_service.dart';
import '../models/token_model.dart';

class AuthRepository {
  final AuthService _authService;
  final TokenStorage _storage;

  AuthRepository({
    required AuthService authService,
    required TokenStorage storage,
  })  : _authService = authService,
        _storage = storage;

  /// Uygulama acildiginda daha once login olunmus mu bak.
  /// Token varsa ve refresh edilebilir durumdaysa kullaniciyi
  /// direkt Home'a yolla. Yoksa Login'e.
  Future<bool> isAuthenticated() async {
    final token = await _storage.read();
    if (token == null) return false;

    // Token hala taze ise direkt kullan.
    if (!token.isExpired) return true;

    // Expire ama refresh_token varsa yenilemeyi dene - bonus'un bir parcasi.
    if (token.refreshToken != null) {
      try {
        final refreshed = await _authService.refresh(token);
        await _storage.save(refreshed);
        appLogger.i('Uygulama acilisinda token yenilendi');
        return true;
      } catch (e) {
        appLogger.w('Uygulama acilisinda refresh basarisiz, login gerekli');
        await _storage.clear();
        return false;
      }
    }

    // Expire + refresh yoksa -> login gerekli.
    await _storage.clear();
    return false;
  }

  /// OAuth2 akisi ile login olur ve token'i kaydeder.
  Future<void> login() async {
    final token = await _authService.login();
    await _storage.save(token);
  }

  /// Mevcut token'i siler. Uygulamayi Login ekranina yonlendirmek
  /// cagrildigi yerin sorumlulugunda.
  Future<void> logout() async {
    await _authService.endSession();
    await _storage.clear();
  }

  /// Debug / advanced usage icin token okumak.
  Future<TokenModel?> currentToken() => _storage.read();
}
