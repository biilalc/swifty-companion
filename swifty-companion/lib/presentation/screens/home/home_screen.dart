// Home ekrani (View #2). Login olmus kullanicinin kendi profil kartini
// ve arama kutusunu icerir. Appbar'da logout ve dil secme (isteyene gore)
// butonlari var. Buradan Profile ekranina gecilir.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import 'widgets/search_input.dart';
import 'widgets/self_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Ilk frame'de API cagrisi yap. `addPostFrameCallback` initState icinde
    // dogrudan context kullanimini engeller - iyi uygulamadir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeProvider>().loadMe();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('app.name'.tr()),
        titleTextStyle: AppTextStyles.headlineMedium,
        actions: [
          IconButton(
            tooltip: 'home.logout'.tr(),
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () =>
              context.read<HomeProvider>().loadMe(force: true),
          color: AppColors.primary,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth > 600 ? 64 : 20,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight - 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Greeting(),
                      const SizedBox(height: 18),
                      const _SelfSection(),
                      const SizedBox(height: 32),
                      Text(
                        'home.search_hint'.tr(),
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SearchInput(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('home.logout_confirm_title'.tr()),
        content: Text('home.logout_confirm_body'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('home.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('home.confirm'.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await auth.logout();
    }
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final key = hour < 12
        ? 'home.greeting_morning'
        : hour < 18
            ? 'home.greeting_afternoon'
            : 'home.greeting_evening';
    final me = context.watch<HomeProvider>().me;
    final name = me?.firstName ?? me?.login;

    return Text(
      name != null ? '${key.tr()}, $name' : key.tr(),
      style: AppTextStyles.headlineLarge.copyWith(letterSpacing: -0.5),
    );
  }
}

class _SelfSection extends StatelessWidget {
  const _SelfSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, home, _) {
        switch (home.status) {
          case HomeStatus.loading:
          case HomeStatus.idle:
            return Container(
              height: 160,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const LoadingView(),
            );
          case HomeStatus.error:
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: ErrorView(
                messageKey: home.errorKey ?? 'errors.unknown',
                messageArgs: home.errorArgs,
                onRetry: () => home.loadMe(force: true),
                compact: true,
              ),
            );
          case HomeStatus.loaded:
            final user = home.me;
            if (user == null) return const SizedBox.shrink();
            return SelfCard(user: user);
        }
      },
    );
  }
}
