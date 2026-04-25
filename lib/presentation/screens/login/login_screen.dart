// Login ekrani (View #1). Tek buton - "Sign in with 42". Butona basilinca
// intra.42.fr OAuth sayfasi acilir, kullanici login olur, app'e donus yapar.
//
// Subject:
//   - "Your app must have at least 2 views" -> bu 1. view
//   - "You must use intra oauth2" -> buton buna yonlendirir
//   - "You must handle all cases of errors" -> error snackbar + banner

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      // SafeArea + LayoutBuilder + IntrinsicHeight: farkli ekran boyutlarinda
      // (kucuk telefon, tablet, landscape) dogru ve esnek layout icin.
      // Subject: "use a flexible or modern layout technique".
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: media.size.width > 600 ? 64 : 24,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        const Spacer(),
                        const _BrandHero(),
                        const SizedBox(height: 40),
                        _WelcomeCopy(),
                        const Spacer(),
                        const _LoginButton(),
                        const SizedBox(height: 20),
                        Text(
                          'login.privacy_note'.tr(),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            '42',
            style: TextStyle(
              color: AppColors.onPrimary,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'app.name'.tr(),
          style: AppTextStyles.headlineLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'app.tagline'.tr(),
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}

class _WelcomeCopy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'login.title'.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.displayLarge,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'login.subtitle'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isLoading = auth.isLoading;
        return Column(
          children: [
            // Hata gelmiste inline banner goster (kalici; reload icin retry'a basmasi gerekir).
            if (auth.lastErrorKey != null) ...[
              _InlineErrorBanner(
                messageKey: auth.lastErrorKey!,
                onClose: auth.clearError,
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                        final success = await auth.login();
                        if (!success && context.mounted) {
                          final key = auth.lastErrorKey;
                          if (key != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(key.tr())),
                            );
                          }
                        }
                      },
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.login_rounded, size: 20),
                label: Text(
                  isLoading ? 'login.loading'.tr() : 'login.button'.tr(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  final String messageKey;
  final VoidCallback onClose;

  const _InlineErrorBanner({
    required this.messageKey,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.error.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              messageKey.tr(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          ),
        ],
      ),
    );
  }
}
