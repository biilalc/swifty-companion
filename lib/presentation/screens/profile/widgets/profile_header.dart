// Profile ekraninin en ustteki banner'i. Arka plan gradient, merkezde
// profil fotografi, alt tarafta isim/login ve primary cursus level.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/cursus_user_model.dart';
import '../../../../data/models/user_model.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final CursusUserModel? cursus;

  const ProfileHeader({super.key, required this.user, this.cursus});

  @override
  Widget build(BuildContext context) {
    final level = cursus?.level ?? 0.0;
    final levelInt = level.truncate();
    final levelFraction = level - levelInt;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          _Avatar(imageUrl: user.imageUrlLarge ?? user.imageUrl, login: user.login),
          const SizedBox(height: 14),
          Text(
            user.displayName,
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.onPrimary,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '@${user.login}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onPrimary.withOpacity(0.75),
            ),
          ),
          if (user.isStaff) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.85),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'STAFF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _LevelBar(level: levelInt, fraction: levelFraction),
          if (cursus?.grade != null && cursus!.grade!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${'profile.grade'.tr()} · ${cursus!.grade!}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onPrimary.withOpacity(0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final String login;

  const _Avatar({required this.imageUrl, required this.login});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 200),
              placeholder: (_, __) => _FallbackInitial(login: login),
              errorWidget: (_, __, ___) => _FallbackInitial(login: login),
            )
          : _FallbackInitial(login: login),
    );
  }
}

class _FallbackInitial extends StatelessWidget {
  final String login;
  const _FallbackInitial({required this.login});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        login.isNotEmpty ? login[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.onPrimary,
          fontSize: 42,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LevelBar extends StatelessWidget {
  final int level;
  final double fraction;

  const _LevelBar({required this.level, required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${'profile.level'.tr()} $level',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.onPrimary,
              ),
            ),
            Text(
              '${(fraction * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.onPrimary.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(
                height: 10,
                color: Colors.white.withOpacity(0.12),
              ),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: const BoxDecoration(
                    gradient: AppColors.skillGradient,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
