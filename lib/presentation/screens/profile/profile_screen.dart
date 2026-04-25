// Profile ekrani (View #3). Aranan kullanicinin tum bilgilerini gosterir.
// Subject gerekliliklerinin buyuk cogunlugu bu ekrandadir:
//   - Login mevcut ise bilgileri goster (aksi halde hata).
//   - En az 4 detay + profil fotografi.
//   - Skills (level + %).
//   - Projeler (basarili + basarisiz).
//   - Geri navigasyon (AppBar back button, go_router otomatik).
//   - Flexible layout (LayoutBuilder + CustomScrollView).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_model.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import 'widgets/cursus_selector.dart';
import 'widgets/info_section.dart';
import 'widgets/profile_header.dart';
import 'widgets/projects_section.dart';
import 'widgets/skills_section.dart';

class ProfileScreen extends StatefulWidget {
  final String login;

  const ProfileScreen({super.key, required this.login});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileProvider>().loadUser(widget.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          // Subject: "Your app must allow for navigating back to the first view."
          // go_router'da geri gidilebiliyorsa go_router'i kullan, yoksa
          // direkt home'a yonlendir (ornek: deep link ile gelindiyse).
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          widget.login,
          style: AppTextStyles.headlineMedium.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, prof, _) {
          switch (prof.status) {
            case ProfileStatus.idle:
            case ProfileStatus.loading:
              return const LoadingView();
            case ProfileStatus.error:
              return ErrorView(
                messageKey: prof.errorKey ?? 'errors.unknown',
                messageArgs: prof.errorArgs,
                onRetry: () => prof.loadUser(widget.login),
              );
            case ProfileStatus.loaded:
              final user = prof.user;
              if (user == null) {
                return ErrorView(
                  messageKey: 'errors.unknown',
                  onRetry: () => prof.loadUser(widget.login),
                );
              }
              return _ProfileBody(user: user);
          }
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final UserModel user;

  const _ProfileBody({required this.user});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, prof, _) {
        final selectedCursus = user.cursusUsers
            .where((c) => c.cursusId == prof.selectedCursusId)
            .fold<dynamic>(null, (a, b) => b) ??
            user.primaryCursus;

        final projects = user.projectsForCursus(selectedCursus?.cursusId);

        return LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth > 600 ? 64.0 : 16.0;

            return RefreshIndicator(
              onRefresh: () => prof.loadUser(user.login),
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: ProfileHeader(
                      user: user,
                      cursus: selectedCursus,
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      20,
                      horizontalPadding,
                      32,
                    ),
                    sliver: SliverList.list(
                      children: [
                        if (user.cursusUsers.length > 1) ...[
                          CursusSelector(
                            cursusList: user.cursusUsers,
                            selectedId: selectedCursus?.cursusId,
                            onSelected: prof.selectCursus,
                          ),
                          const SizedBox(height: 20),
                        ],
                        InfoSection(user: user),
                        const SizedBox(height: 20),
                        SkillsSection(
                          skills: selectedCursus?.skills ?? const [],
                        ),
                        const SizedBox(height: 20),
                        ProjectsSection(projects: projects),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
