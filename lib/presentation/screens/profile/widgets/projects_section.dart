// Projeler bolumu. Subject: "display the projects that the user has
// completed, including failed ones." - basarili yesil, basarisiz kirmizi.
// Devam edenleri de opsiyonel olarak gosteriyoruz (UX icin daha dolu).

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/project_user_model.dart';

class ProjectsSection extends StatelessWidget {
  final List<ProjectUserModel> projects;

  const ProjectsSection({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    // Subject "completed (including failed)" diyor; biz once tamamlananlari
    // bitme tarihine gore yeniden eskiye siralayip gosteriyoruz.
    final sorted = [...projects]..sort((a, b) {
        final ad = a.markedAt ?? a.createdAt ?? DateTime(1970);
        final bd = b.markedAt ?? b.createdAt ?? DateTime(1970);
        return bd.compareTo(ad);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'profile.section_projects'.tr(),
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                '${sorted.length}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
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
              'profile.projects_empty'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < sorted.length; i++) ...[
                  _ProjectRow(project: sorted[i]),
                  if (i < sorted.length - 1)
                    const Divider(height: 1, indent: 14, endIndent: 14),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final ProjectUserModel project;
  const _ProjectRow({required this.project});

  @override
  Widget build(BuildContext context) {
    final status = project.projectStatus;
    final statusInfo = _statusInfo(status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusInfo.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusInfo.icon, color: statusInfo.fgColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  statusInfo.label.tr(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: statusInfo.fgColor,
                  ),
                ),
              ],
            ),
          ),
          if (project.finalMark != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusInfo.bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${project.finalMark}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: statusInfo.fgColor,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _ProjectStatusInfo _statusInfo(ProjectStatus s) {
    switch (s) {
      case ProjectStatus.finishedPassed:
        return const _ProjectStatusInfo(
          label: 'profile.projects_passed',
          icon: Icons.check_rounded,
          bgColor: Color(0x1A10B981),
          fgColor: AppColors.success,
        );
      case ProjectStatus.finishedFailed:
        return const _ProjectStatusInfo(
          label: 'profile.projects_failed',
          icon: Icons.close_rounded,
          bgColor: Color(0x1AEF4444),
          fgColor: AppColors.error,
        );
      case ProjectStatus.waitingForCorrection:
      case ProjectStatus.inProgress:
        return const _ProjectStatusInfo(
          label: 'profile.projects_in_progress',
          icon: Icons.hourglass_empty_rounded,
          bgColor: Color(0x1A3B82F6),
          fgColor: AppColors.info,
        );
      case ProjectStatus.unknown:
        return const _ProjectStatusInfo(
          label: 'profile.projects_in_progress',
          icon: Icons.help_outline_rounded,
          bgColor: Color(0x1A9CA3AF),
          fgColor: AppColors.textSecondary,
        );
    }
  }
}

class _ProjectStatusInfo {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color fgColor;

  const _ProjectStatusInfo({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.fgColor,
  });
}
