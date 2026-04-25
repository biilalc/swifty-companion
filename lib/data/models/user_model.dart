// 42 "users" endpoint'inin tam detay cevabini temsil eder. Bu model
// tek bir kullanicinin tum verilerini (cursus'lari, projeleri, cuzdan,
// wallet, image vs.) barindirir. Subject'in istedigi TUM alanlar burada.

import 'package:equatable/equatable.dart';

import 'cursus_user_model.dart';
import 'project_user_model.dart';

class UserModel extends Equatable {
  final int id;

  /// Intra login'i (benzersiz).
  final String login;

  /// "Firstname Lastname" formatinda tam isim.
  final String displayName;

  final String? firstName;
  final String? lastName;

  final String email;

  /// Telefon - kullanici gizli tuttuysa "hidden" gelir.
  final String? phone;

  /// Campus lokasyonu (cihaz kimligi, ornek: "e2r13p5"). Null ise
  /// kullanici o an intra'da degil demek.
  final String? location;

  /// Kullanicinin correction puani (evaluations).
  final int correctionPoint;

  /// Cuzdan bakiyesi (42 coin).
  final int wallet;

  /// Pool ayi (ornek: "august").
  final String? poolMonth;

  /// Pool yili (ornek: "2023").
  final String? poolYear;

  /// Profile resmi URL'i. 42 genellikle birden fazla size sunar;
  /// "medium" size'i tercih ediyoruz (hiz + kalite dengesi).
  final String? imageUrl;
  final String? imageUrlLarge;

  /// Personel (staff) mi? Staff kullanicilari farkli renklendirmek UX
  /// acisindan guzel.
  final bool isStaff;

  final List<CursusUserModel> cursusUsers;
  final List<ProjectUserModel> projectsUsers;

  const UserModel({
    required this.id,
    required this.login,
    required this.displayName,
    required this.email,
    required this.correctionPoint,
    required this.wallet,
    required this.isStaff,
    required this.cursusUsers,
    required this.projectsUsers,
    this.firstName,
    this.lastName,
    this.phone,
    this.location,
    this.poolMonth,
    this.poolYear,
    this.imageUrl,
    this.imageUrlLarge,
  });

  /// Kullanicinin aktif (en yeni) cursus'unu dondurur - genellikle
  /// 42cursus. Yoksa piscine veya herhangi biri. Yoksa null.
  /// Home ekraninda ve profile ekraninda varsayilan olarak bu gosterilir.
  CursusUserModel? get primaryCursus {
    if (cursusUsers.isEmpty) return null;
    // Once adi "42cursus" olani ara (en yaygin senaryo).
    final main = cursusUsers.firstWhere(
      (c) => c.cursusSlug == '42cursus',
      orElse: () => cursusUsers.first,
    );
    return main;
  }

  /// Belirli bir cursus'a ait projeleri dondurur. null ise tum projeler.
  List<ProjectUserModel> projectsForCursus(int? cursusId) {
    if (cursusId == null) return projectsUsers;
    return projectsUsers
        .where((p) => p.cursusIds.contains(cursusId))
        .toList();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;
    final versions = image?['versions'] as Map<String, dynamic>?;

    // image.link genelde full-size; image.versions.medium hizli yuklenir.
    final imageMedium = versions?['medium'] as String?;
    final imageLink = image?['link'] as String?;

    final cursusUsersRaw = json['cursus_users'] as List<dynamic>? ?? const [];
    final projectsUsersRaw =
        json['projects_users'] as List<dynamic>? ?? const [];

    return UserModel(
      id: (json['id'] as num).toInt(),
      login: (json['login'] as String?) ?? '',
      displayName: (json['displayname'] as String?) ?? json['login'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: (json['email'] as String?) ?? '',
      phone: json['phone'] as String?,
      location: json['location'] as String?,
      correctionPoint: (json['correction_point'] as num?)?.toInt() ?? 0,
      wallet: (json['wallet'] as num?)?.toInt() ?? 0,
      poolMonth: json['pool_month'] as String?,
      poolYear: json['pool_year'] as String?,
      imageUrl: imageMedium ?? imageLink,
      imageUrlLarge: imageLink,
      isStaff: (json['staff?'] as bool?) ?? false,
      cursusUsers: cursusUsersRaw
          .whereType<Map<String, dynamic>>()
          .map(CursusUserModel.fromJson)
          .toList(),
      projectsUsers: projectsUsersRaw
          .whereType<Map<String, dynamic>>()
          .map(ProjectUserModel.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        login,
        displayName,
        firstName,
        lastName,
        email,
        phone,
        location,
        correctionPoint,
        wallet,
        poolMonth,
        poolYear,
        imageUrl,
        imageUrlLarge,
        isStaff,
        cursusUsers,
        projectsUsers,
      ];
}
