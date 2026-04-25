// Uygulama genelinde kullanilan custom exception'lar. Her hata tipinin
// ayri sinif olmasinin sebebi: UI katmaninda `switch` ile dogru mesaji
// gostermek ve loglamada context'i kaybetmemek.
//
// Subject: "You must handle all cases of errors (login not found, network
// error, etc.)" - bu dosya o handling'in omurgasidir.

abstract class AppException implements Exception {
  /// Kullaniciya (veya log'a) gosterilecek aciklama.
  final String message;

  /// Debugging icin orijinal hata (varsa). Production'da gosterilmez.
  final Object? cause;

  const AppException(this.message, {this.cause});

  @override
  String toString() => '$runtimeType: $message'
      '${cause != null ? ' (cause: $cause)' : ''}';
}

/// Ag erisimi yok / baglanti reddedildi / DNS hatasi vs.
class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error', Object? cause])
      : super(cause: cause);
}

/// Istek timeout'a ugradi (connect/send/receive).
class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Request timed out', Object? cause])
      : super(cause: cause);
}

/// 401 - token gecersiz veya suresi dolmus. Normal sartlarda AuthInterceptor
/// bunu otomatik refresh ile cozer; coz(e)mezse bu exception yukselir.
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized', Object? cause])
      : super(cause: cause);
}

/// 404 - aranan kullanici bulunamadi. Subject'in "login not found" case'i.
class UserNotFoundException extends AppException {
  /// Bulunamayan login (UI'da kullanici mesajinda gostermek icin).
  final String login;

  const UserNotFoundException(this.login, {super.cause})
      : super('User not found: $login');
}

/// 429 - 42 API rate limit'i asildi (default: 2 req/sn, 1200 req/saat).
class RateLimitException extends AppException {
  /// Retry-After header'indan gelebilecek saniye cinsinden bekleme.
  final int? retryAfterSeconds;

  const RateLimitException({this.retryAfterSeconds, super.cause})
      : super('Rate limit exceeded');
}

/// 5xx - sunucu tarafi problem.
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({this.statusCode, super.cause}) : super('Server error');
}

/// OAuth2 surecindeki hatalar (login iptal edildi, token endpoint'i basarisiz).
class AuthException extends AppException {
  const AuthException(super.message, {super.cause});
}

/// .env konfigurasyon eksikligi. Uygulama calismaya baslarken yakalanir.
class ConfigException extends AppException {
  const ConfigException(super.message, {super.cause});
}

/// Bilinmeyen / siniflandirilamamis hatalar icin catch-all.
class UnknownException extends AppException {
  const UnknownException([super.message = 'Unknown error', Object? cause])
      : super(cause: cause);
}
