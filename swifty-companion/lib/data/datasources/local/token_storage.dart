// Token'lari cihazin guvenli alanina (Android Keystore) kaydeden servis.
// SharedPreferences gibi seyleri kullanmayiz cunku access_token ve
// refresh_token sifrelenmemis diskte durmamali.
//
// Subject: "Do not create a token for each query" kuralini burada
// sakladigimiz token'i tekrar tekrar kullanarak sagliyoruz.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/utils/logger.dart';
import '../../models/token_model.dart';

class TokenStorage {
  /// Production'da kritik: Android'de EncryptedSharedPreferences kullanir
  /// (M+ tum cihazlarda Keystore tarafindan master key sifreli).
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'swifty_companion.oauth_token';

  /// Yeni token'i diske kaydeder. Mevcut token varsa uzerine yazar.
  Future<void> save(TokenModel token) async {
    try {
      await _storage.write(key: _tokenKey, value: token.encode());
      appLogger.d('Token kaydedildi (expires at: ${token.expiresAt})');
    } catch (e, st) {
      // Storage hatalari kritik degil - bir sonraki istekte yeniden deniyecez.
      // Ama log'u birakiyoruz ki debug edilebilsin.
      appLogger.e('Token kaydedilemedi', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Mevcut token'i okur. Yoksa veya bozuksa null doner.
  Future<TokenModel?> read() async {
    try {
      final raw = await _storage.read(key: _tokenKey);
      if (raw == null || raw.isEmpty) return null;
      return TokenModel.decode(raw);
    } catch (e, st) {
      appLogger.w('Token okunamadi, silinip tekrar login istenecek',
          error: e, stackTrace: st);
      // Bozuk JSON gibi durumlarda storage'i temizle ki yeniden login alinabilsin.
      await clear();
      return null;
    }
  }

  /// Token'i siler - logout'ta veya refresh basarisizliginda cagrilir.
  Future<void> clear() async {
    try {
      await _storage.delete(key: _tokenKey);
      appLogger.d('Token silindi');
    } catch (e, st) {
      appLogger.e('Token silinirken hata', error: e, stackTrace: st);
    }
  }
}
