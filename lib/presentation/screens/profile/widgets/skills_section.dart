// Skill'leri level + yuzde bar ile gosteren bolum.
// Subject: "You must display the user's skills with level and percentage."

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/skill_model.dart';

class SkillsSection extends StatelessWidget {
  final List<SkillModel> skills;

  const SkillsSection({super.key, required this.skills});

  @override
  Widget build(BuildContext context) {
    // Yuksek level'deki yetenekleri uste koymak UX acisindan daha
    // anlamli - kullanici bilir ki bu kisi en cok nelerde iyi.
    final sorted = [...skills]..sort((a, b) => b.level.compareTo(a.level));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'profile.section_skills'.tr(),
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
        ),
        if (sorted.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              'profile.skills_empty'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < sorted.length; i++) ...[
                  _SkillRow(skill: sorted[i]),
                  if (i < sorted.length - 1) const SizedBox(height: 14),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  final SkillModel skill;
  const _SkillRow({required this.skill});

  @override
  Widget build(BuildContext context) {
    // Ayni cubukta seviye, progress ve yuzde ayni anda gosterilir.
    // Level bar'in dolulugunu ondalik kisma gore ayarliyoruz.
    final ratio = skill.percentageRatio.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                skill.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Lv ${skill.level.toStringAsFixed(2)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${skill.percentage.toStringAsFixed(0)}%',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            children: [
              Container(
                height: 8,
                color: AppColors.surfaceVariant,
              ),
              // TweenAnimationBuilder ile progress subtle bir sekilde animate olur.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ratio),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      gradient: AppColors.skillGradient,
                    ),
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
