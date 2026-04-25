// Yukleme durumlarinda kullanilan minimal ve ferah bir progress gostergesi.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class LoadingView extends StatelessWidget {
  final String? messageKey;

  const LoadingView({super.key, this.messageKey});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
          if (messageKey != null) ...[
            const SizedBox(height: 16),
            Text(
              messageKey!.tr(),
              style: AppTextStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
