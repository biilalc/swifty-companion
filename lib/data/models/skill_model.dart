// Bir kullanicinin sahip oldugu beceri (skill). 42 API'sinde her cursus
// (42cursus, piscine vb.) kendi skill listesine sahiptir. CursusUser
// icindeki "skills" dizisinin her bir elemani bu modele map'lenir.
//
// Subject: "You must display the user's skills with level and percentage."

import 'package:equatable/equatable.dart';

class SkillModel extends Equatable {
  final int id;
  final String name;

  /// 42'de skill level'i bir float olarak gelir (ornek: 4.25, 11.80).
  /// Uygulamada iki ondalikli basamak ile gosterilecek.
  final double level;

  const SkillModel({
    required this.id,
    required this.name,
    required this.level,
  });

  /// Subject "level and percentage" istiyor. 42 API yuzde dondurmedigi
  /// icin level'i yuzdeye cevirmemiz gerekiyor. Standart approach:
  /// ondalik kismi yuzde olarak gosterir (ornek: 4.25 -> level 4, %25).
  /// Bu mantigi 42'nin kendi arayuzu de kullanir.
  double get percentage {
    final fractional = level - level.truncate();
    return (fractional * 100).clamp(0.0, 100.0);
  }

  /// Progress bar'larda kullanilacak 0.0 - 1.0 arasi deger.
  double get percentageRatio => percentage / 100.0;

  /// Tam tamsayi seviye (ornek: level 4.25 -> 4).
  int get levelInt => level.truncate();

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
      level: (json['level'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [id, name, level];
}
