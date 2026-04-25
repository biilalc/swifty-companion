// OAuth2 token bilgilerini temsil eden model. Hem flutter_appauth'un
// AuthorizationTokenResponse'undan, hem de manuel refresh cevabindan
// olusturulabilir. Expiry kontrolu bu sinif uzerinden yapilir - Dio
// interceptor istek atmadan once `isExpired` ile bakar, gerekirse
// refresh eder. Bu sayede subject'in "do not create a token for each
// query" kurali saglanir + bonus olan "recreate token at expiration"
// karsilanir.

import 'dart:convert';

import 'package:equatable/equatable.dart';

class TokenModel extends Equatable {
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final String tokenType;
  final List<String> scopes;

  const TokenModel({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
    this.tokenType = 'Bearer',
    this.scopes = const [],
  });

  /// Token'in suresi DOLMAK UZERE mi? 30 saniyelik guvenlik tamponu
  /// birakiyoruz ki istek sirasinda sure bitmesin. 42 token default
  /// 7200 saniye (2 saat) oldugu icin bu degisken kayiplari sorun olmaz.
  bool get isExpiringSoon {
    final now = DateTime.now().toUtc();
    return expiresAt.isBefore(now.add(const Duration(seconds: 30)));
  }

  /// Token'in tamamen expire olup olmadigi (refresh yapilmadan kullanilamaz).
  bool get isExpired {
    final now = DateTime.now().toUtc();
    return expiresAt.isBefore(now);
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_at': expiresAt.toUtc().toIso8601String(),
        'token_type': tokenType,
        'scopes': scopes,
      };

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String).toUtc(),
      tokenType: (json['token_type'] as String?) ?? 'Bearer',
      scopes: (json['scopes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  /// 42 token endpoint cevabindan model olusturur. Cevap formati:
  /// { "access_token": "...", "token_type": "bearer", "expires_in": 7200,
  ///   "refresh_token": "...", "scope": "public", "created_at": 1443451918 }
  factory TokenModel.fromApiResponse(Map<String, dynamic> json) {
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 7200;
    final createdAt = (json['created_at'] as num?)?.toInt();
    // created_at gelirse expiry hesabinda onu baz al (daha dogru),
    // gelmezse simdiki zamani baz al.
    final baseTime = createdAt != null
        ? DateTime.fromMillisecondsSinceEpoch(createdAt * 1000, isUtc: true)
        : DateTime.now().toUtc();
    final scope = (json['scope'] as String?) ?? '';
    return TokenModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresAt: baseTime.add(Duration(seconds: expiresIn)),
      tokenType: (json['token_type'] as String?) ?? 'Bearer',
      scopes: scope.split(' ').where((s) => s.isNotEmpty).toList(),
    );
  }

  String encode() => jsonEncode(toJson());

  static TokenModel decode(String raw) =>
      TokenModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  TokenModel copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? tokenType,
    List<String>? scopes,
  }) {
    return TokenModel(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      tokenType: tokenType ?? this.tokenType,
      scopes: scopes ?? this.scopes,
    );
  }

  @override
  List<Object?> get props =>
      [accessToken, refreshToken, expiresAt, tokenType, scopes];
}
