// Home ekraninda, login olan kullanicinin kendi mini profil kartini gosterir.
// Kullaniciya bastiginda kendi profiline git (profile ekranina /login=me).

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/user_model.dart';

class SelfCard extends StatelessWidget {
  final UserModel user;

  const SelfCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final primaryCursus = user.primaryCursus;
    final level = primaryCursus?.level ?? 0.0;
    final location = user.location;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.goNamed(
          'profile',
          queryParameters: {'login': user.login},
        ),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(imageUrl: user.imageUrl, login: user.login),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.onPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${user.login}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.onPrimary.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'profile.level'.tr(),
                      value: level.toStringAsFixed(2),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  Expanded(
                    child: _MetricTile(
                      label: 'profile.wallet'.tr(),
                      value: '${user.wallet}₳',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  Expanded(
                    child: _MetricTile(
                      label: 'profile.location'.tr(),
                      value: location ?? 'profile.location_unavailable'.tr(),
                      small: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => const SizedBox.shrink(),
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
    final initial = login.isNotEmpty ? login[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final bool small;

  const _MetricTile({
    required this.label,
    required this.value,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: (small
                  ? AppTextStyles.titleMedium
                  : AppTextStyles.titleLarge)
              .copyWith(color: AppColors.onPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.onPrimary.withOpacity(0.65),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
