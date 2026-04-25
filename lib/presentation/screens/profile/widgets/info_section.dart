// Profile ekraninin "Details" bolumu. Subject: "display at least four
// details for the user" - biz buraya login, email, phone, location,
// wallet, correction points, pool ay/yili basiyoruz. 7 detay.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/user_model.dart';

class InfoSection extends StatelessWidget {
  final UserModel user;

  const InfoSection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final items = <_InfoItem>[
      _InfoItem(
        icon: Icons.alternate_email_rounded,
        label: 'profile.email'.tr(),
        value: user.email.isEmpty ? '—' : user.email,
        copyable: true,
      ),
      _InfoItem(
        icon: Icons.phone_iphone_rounded,
        label: 'profile.mobile'.tr(),
        value: _formatPhone(user.phone),
        copyable: user.phone != null &&
            user.phone!.isNotEmpty &&
            user.phone != 'hidden',
      ),
      _InfoItem(
        icon: Icons.place_outlined,
        label: 'profile.location'.tr(),
        value: user.location ?? 'profile.location_unavailable'.tr(),
      ),
      _InfoItem(
        icon: Icons.account_balance_wallet_outlined,
        label: 'profile.wallet'.tr(),
        value: '${user.wallet} ₳',
      ),
      _InfoItem(
        icon: Icons.rate_review_outlined,
        label: 'profile.correction_points'.tr(),
        value: '${user.correctionPoint}',
      ),
      if (user.poolMonth != null && user.poolYear != null)
        _InfoItem(
          icon: Icons.pool_outlined,
          label: 'profile.pool'.tr(),
          value: '${_capitalize(user.poolMonth!)} ${user.poolYear}',
        ),
    ];

    return _Section(
      title: 'profile.section_details'.tr(),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _InfoRow(item: items[i]),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 48, endIndent: 12),
            ],
          ],
        ),
      ),
    );
  }

  /// 42 bazen "hidden" string'i dondurur; daha kullanici dostu gosterelim.
  String _formatPhone(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    if (raw == 'hidden') return 'hidden';
    return raw;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
  });
}

class _InfoRow extends StatelessWidget {
  final _InfoItem item;
  const _InfoRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.copyable
          ? () async {
              await Clipboard.setData(ClipboardData(text: item.value));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.label}: ${item.value}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, size: 18, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (item.copyable)
              const Icon(
                Icons.copy_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
