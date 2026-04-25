// Uygulama renk paleti. Kullanicinin istegi dogrultusunda beyaz, sade,
// modern bir tema icin tasarlandi. Ana vurgu rengi 42'nin markasiyla
// uyumlu olmasi icin koyu gri-siyah + turkuaz aksan.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ----- Temel paletti -----
  /// Ana background - saf beyaz, ferah hissi icin.
  static const Color background = Color(0xFFFFFFFF);

  /// Ikincil yuzey (card, dialog, bottom sheet). Hafif off-white.
  static const Color surface = Color(0xFFFAFAFA);

  /// Kart gibi yukseltilmis elementler icin subtle shadow'a alternatif renk.
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  // ----- Metin renkleri -----
  /// Birincil metin - neredeyse siyah ama saf degil (goz yormaz).
  static const Color textPrimary = Color(0xFF111827);

  /// Ikincil metin (aciklama, subtitle).
  static const Color textSecondary = Color(0xFF6B7280);

  /// Ucuncul metin (timestamp, ipucu).
  static const Color textTertiary = Color(0xFF9CA3AF);

  // ----- Aksan renkleri -----
  /// 42'nin markasina gondermeyle birlikte modern bir teal - butonlar ve
  /// aktif elementler icin kullanilir.
  static const Color primary = Color(0xFF0B1120);

  /// Primary uzerine gelen metin rengi.
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Vurgu rengi (progress bar, skill levels, chip'ler).
  static const Color accent = Color(0xFF00BABC);

  // ----- Semantik renkler -----
  /// Basarili proje ve olumlu durumlar.
  static const Color success = Color(0xFF10B981);

  /// Basarisiz proje ve hata durumlari.
  static const Color error = Color(0xFFEF4444);

  /// Uyari (devam eden proje, beklenen aksiyonlar).
  static const Color warning = Color(0xFFF59E0B);

  /// Bilgi / in-progress.
  static const Color info = Color(0xFF3B82F6);

  // ----- Border ve divider -----
  /// Input border, divider cizgileri icin hafif gri.
  static const Color border = Color(0xFFE5E7EB);

  /// Daha belirgin border (focus, hover durumlari).
  static const Color borderStrong = Color(0xFFD1D5DB);

  // ----- Gradient'lar -----
  /// Profil banner'i ve login ekrani icin sofistike gradient.
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0B1120), Color(0xFF1F2937)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Skill level bar'lari icin gradient.
  static const LinearGradient skillGradient = LinearGradient(
    colors: [Color(0xFF00BABC), Color(0xFF00E5CF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
