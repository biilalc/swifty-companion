// Bir kullanicinin bir cursus'a olan aidiyetini temsil eder.
// Bir ogrenci piscine + 42cursus gibi birden fazla cursus'a dahil
// olabilir; her biri icin ayri level, skills ve grade bilgisi vardir.

import 'package:equatable/equatable.dart';

import 'skill_model.dart';

class CursusUserModel extends Equatable {
  /// Cursus'un id'si (ornek: 42cursus -> id 21).
  final int cursusId;

  /// Cursus'un insanin okuyabilecegi adi.
  final String cursusName;

  /// Cursus'un slug'i (ornek: "42cursus", "c-piscine").
  final String cursusSlug;

  /// Bu cursus'taki genel level (ornek: 11.75).
  final double level;

  /// Kademe (ornek: "Learner", "Cadet", "Member").
  final String? grade;

  /// Bu cursus'taki skills listesi.
  final List<SkillModel> skills;

  /// Cursus'a baslama tarihi.
  final DateTime? beginAt;

  /// Cursus'u bitirme tarihi (null ise hala devam ediyor).
  final DateTime? endAt;

  const CursusUserModel({
    required this.cursusId,
    required this.cursusName,
    required this.cursusSlug,
    required this.level,
    required this.skills,
    this.grade,
    this.beginAt,
    this.endAt,
  });

  factory CursusUserModel.fromJson(Map<String, dynamic> json) {
    final cursus = json['cursus'] as Map<String, dynamic>? ?? {};
    final skillsRaw = json['skills'] as List<dynamic>? ?? const [];
    return CursusUserModel(
      cursusId: (cursus['id'] as num?)?.toInt() ?? 0,
      cursusName: (cursus['name'] as String?) ?? '',
      cursusSlug: (cursus['slug'] as String?) ?? '',
      level: (json['level'] as num?)?.toDouble() ?? 0.0,
      grade: json['grade'] as String?,
      skills: skillsRaw
          .whereType<Map<String, dynamic>>()
          .map(SkillModel.fromJson)
          .toList(),
      beginAt: _parseDate(json['begin_at']),
      endAt: _parseDate(json['end_at']),
    );
  }

  /// 42 API tarih alanlarini parse ederken null ve bosluk durumlarini
  /// guvenle ele alan yardimci. Hatali formatta null dondurur.
  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props =>
      [cursusId, cursusName, cursusSlug, level, grade, skills, beginAt, endAt];
}
