// Tum ekranlarda kullanilan standart hata gosterimi. Subject: "You must
// handle all cases of errors" - bu widget hata mesajini ve optional
// retry butonunu ekrana temiz bir sekilde basar.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ErrorView extends StatelessWidget {
  /// easy_localization key'i (ornek: 'errors.network').
  final String messageKey;

  /// Key'e gecilecek degiskenler (ornek: {'login': 'abcd'}).
  final Map<String, String>? messageArgs;

  /// Kullanicinin tekrar denemesine izin vermek icin.
  final VoidCallback? onRetry;

  /// Kucuk gosterim (inline) vs tam ekran.
  final bool compact;

  const ErrorView({
    super.key,
    required this.messageKey,
    this.messageArgs,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final message = messageKey.tr(namedArgs: messageArgs);

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('errors.retry'.tr()),
          ),
        ],
      ],
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: content,
      );
    }
    return Center(child: content);
  }
}
