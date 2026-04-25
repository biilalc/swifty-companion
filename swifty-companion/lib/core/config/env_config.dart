// .env dosyasindan okunan ortam degerlerini tek yerden saglamak icin
// kullanilan konfigurasyon sinifi. Uygulamanin herhangi bir yerinden
// dogrudan `dotenv.env[...]` cagirmak yerine EnvConfig uzerinden erismek
// hem type-safety saglar hem de eksik degerleri erken yakalamamizi saglar.

import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../errors/app_exceptions.dart';

class EnvConfig {
  EnvConfig._();

  /// 42 API uygulamasinin UID'si (Client ID).
  static String get uid => _requireKey('FORTYTWO_UID');

  /// 42 API uygulamasinin SECRET'i. Authorization Code akisinda token
  /// endpoint'ine gonderilir. 42 intra PKCE tek basina kafi sayabilir ama
  /// guvenli tarafta kalmak icin secret de gonderiyoruz.
  static String get secret => _requireKey('FORTYTWO_SECRET');

  /// OAuth2 callback icin mobil app'in dinledigi URI.
  /// AndroidManifest.xml icindeki intent-filter ile BIREBIR esiesmeli.
  static String get redirectUri => _requireKey('FORTYTWO_REDIRECT_URI');

  /// 42 REST API base URL'i (ornek: https://api.intra.42.fr).
  static String get apiBaseUrl => _requireKey('FORTYTWO_API_BASE_URL');

  /// OAuth2 authorize endpoint'i (kullaniciya intra login ekrani gosterilir).
  static String get authUrl => _requireKey('FORTYTWO_AUTH_URL');

  /// OAuth2 token endpoint'i (code -> access_token swap veya refresh icin).
  static String get tokenUrl => _requireKey('FORTYTWO_TOKEN_URL');

  /// OAuth2 scope'lari (bosluk ile ayrilmis string).
  static String get scopes => _requireKey('FORTYTWO_SCOPES');

  /// Scope'lari liste olarak donen yardimci getter.
  static List<String> get scopesList =>
      scopes.split(' ').where((s) => s.isNotEmpty).toList();

  /// Tum konfigurasyonun yuklu olup olmadigini dogrular.
  /// main()'de uygulama acilmadan once cagrilir - boylece eksik config
  /// durumunda kullaniciya uygun bir hata gosterebiliriz (fail fast).
  static void validate() {
    final required = <String>[
      'FORTYTWO_UID',
      'FORTYTWO_SECRET',
      'FORTYTWO_REDIRECT_URI',
      'FORTYTWO_API_BASE_URL',
      'FORTYTWO_AUTH_URL',
      'FORTYTWO_TOKEN_URL',
      'FORTYTWO_SCOPES',
    ];
    final missing = required.where((k) => (dotenv.env[k] ?? '').isEmpty).toList();
    if (missing.isNotEmpty) {
      throw ConfigException(
        'Missing required env keys: ${missing.join(', ')}. '
        'Check your .env file in the project root.',
      );
    }
  }

  /// Belirli bir key'i .env'den okur; yoksa ConfigException firlatir.
  /// Bu sayede ham `env[key]` kullanimindaki null riskini ortadan kaldiririz.
  static String _requireKey(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw ConfigException('Missing .env key: $key');
    }
    return value;
  }
}
