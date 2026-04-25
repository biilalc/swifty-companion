// Bir kullanicinin bir projeyle olan iliskisini temsil eder (projects_users
// endpoint'inin response modeli). Subject: "You must display the projects
// that the user has completed, including failed ones."

import 'package:equatable/equatable.dart';

/// Projenin durumu. 42 API'sinde bu alan string olarak gelir (ornek:
/// "in_progress", "finished", "waiting_for_correction") ama UI'da
/// renklendirme yapabilmek icin enum'a donusturuyoruz.
enum ProjectStatus {
  inProgress,
  waitingForCorrection,
  finishedPassed,
  finishedFailed,
  unknown,
}

class ProjectUserModel extends Equatable {
  final int id;
  final int projectId;

  /// Proje adi (ornek: "libft", "get_next_line").
  final String name;

  /// Proje slug'i.
  final String slug;

  /// Projenin final notu (null olabilir; proje henuz degerlendirilmediyse).
  final int? finalMark;

  /// Projeyi gecmis mi? 42 API'sinde "validated?" alani bool donerken
  /// JSON'da "validated?" seklindedir - ? karakterine dikkat.
  final bool? validated;

  /// 42 API'sindeki ham status string'i.
  final String status;

  /// Projeyi baslatma tarihi.
  final DateTime? createdAt;

  /// Projeyi bitirme tarihi.
  final DateTime? markedAt;

  /// Projenin hangi cursus'a ait oldugu (filtrelemede kullanilir).
  final List<int> cursusIds;

  const ProjectUserModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.slug,
    required this.status,
    required this.cursusIds,
    this.finalMark,
    this.validated,
    this.createdAt,
    this.markedAt,
  });

  /// UI icin kullanisli, islenmis status.
  ProjectStatus get projectStatus {
    if (validated == true) return ProjectStatus.finishedPassed;
    if (validated == false && (status == 'finished' || finalMark != null)) {
      return ProjectStatus.finishedFailed;
    }
    switch (status) {
      case 'in_progress':
      case 'creating_group':
      case 'searching_a_group':
        return ProjectStatus.inProgress;
      case 'waiting_for_correction':
        return ProjectStatus.waitingForCorrection;
      case 'finished':
        return validated == true
            ? ProjectStatus.finishedPassed
            : ProjectStatus.finishedFailed;
      default:
        return ProjectStatus.unknown;
    }
  }

  /// Subject'e gore "completed (including failed)" olanlari gosterecegiz.
  /// Devam edenleri de gostermek UX acisindan guzel ama zorunlu degil.
  bool get isCompleted =>
      projectStatus == ProjectStatus.finishedPassed ||
      projectStatus == ProjectStatus.finishedFailed;

  factory ProjectUserModel.fromJson(Map<String, dynamic> json) {
    final project = json['project'] as Map<String, dynamic>? ?? {};
    final cursusIdsRaw = json['cursus_ids'] as List<dynamic>? ?? const [];
    return ProjectUserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      projectId: (project['id'] as num?)?.toInt() ?? 0,
      name: (project['name'] as String?) ?? '',
      slug: (project['slug'] as String?) ?? '',
      finalMark: (json['final_mark'] as num?)?.toInt(),
      validated: json['validated?'] as bool?,
      status: (json['status'] as String?) ?? 'unknown',
      createdAt: _parseDate(json['created_at']),
      markedAt: _parseDate(json['marked_at']),
      cursusIds: cursusIdsRaw.map((e) => (e as num).toInt()).toList(),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        name,
        slug,
        finalMark,
        validated,
        status,
        createdAt,
        markedAt,
        cursusIds,
      ];
}
