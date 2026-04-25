// User ile ilgili business logic. API katmani ham veri donerken,
// repository uygulamanin ihtiyac duydugu isleri yapar (validasyon,
// cache, agregasyon vs.).

import '../../core/errors/app_exceptions.dart';
import '../datasources/remote/user_api.dart';
import '../models/user_model.dart';

class UserRepository {
  final UserApi _userApi;

  UserRepository(this._userApi);

  /// Login'e gore kullanici detayini getirir. Login stringi normalizasyondan
  /// (lowercase, trim) gecer. Bos veya gecersiz ise uygun exception atar.
  Future<UserModel> getUser(String rawLogin) async {
    final login = _sanitizeLogin(rawLogin);
    if (login.isEmpty) {
      throw UserNotFoundException(rawLogin);
    }
    return _userApi.getUserByLogin(login);
  }

  /// Login olmus kullanicinin kendi profili.
  Future<UserModel> getMe() => _userApi.getMe();

  /// Login girdisini temizler:
  /// - bosluklari kaldir
  /// - kucuk harfe cevir (42 login'leri lowercase)
  /// - gecersiz karakterleri filtrele (letter, digit, -, _ disinda hepsi cikar)
  static String _sanitizeLogin(String raw) {
    final trimmed = raw.trim().toLowerCase();
    // 42 login kurali: alfanumerik + - ve _. Boylece enjeksiyon korumasi da saglanir.
    final sanitized = trimmed.replaceAll(RegExp(r'[^a-z0-9_\-]'), '');
    return sanitized;
  }

  /// UI katmani aramadan once input'u validate etmek isterse diye public
  /// olarak da expose ediyoruz.
  static bool isValidLogin(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return false;
    // 42 login'leri genelde 2-20 karakter, tamamen alfanumerik-_-
    return RegExp(r'^[a-zA-Z0-9_-]{1,32}$').hasMatch(s);
  }
}
