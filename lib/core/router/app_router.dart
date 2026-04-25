// Tum navigasyonu yoneten go_router konfigurasyonu. AuthProvider'i
// dinleyerek:
//   - Login yapilmadiysa sadece /login'e izin verir.
//   - Login yapildiysa /login'e gidilse bile /home'a redirect eder.
// Boylece subject'in "back navigation" ve auth kurallarini ayni anda saglar.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/login/login_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const profile = '/profile';
}

GoRouter buildAppRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    // AuthProvider'i dinle; auth status degistiginde router re-evaluate eder.
    refreshListenable: authProvider,
    redirect: (context, state) {
      final status = authProvider.status;
      final loc = state.matchedLocation;

      // Splash ekranindaysak ve auth bootstrap devam ediyorsa oldugumuz yerde kal.
      if (status == AuthStatus.initial || status == AuthStatus.loading) {
        // Login ekraninda loading durumu (kullanici login butonuna bastiginda)
        // routing'e engel olmamali - zaten ekranda loading gosteriliyor.
        if (loc == AppRoutes.login) return null;
        return AppRoutes.splash;
      }

      final isAuthed = status == AuthStatus.authenticated;

      if (!isAuthed) {
        // Login olunmamis ve login DISINDA bir yere gitmeye calisiyorsa login'e yolla.
        if (loc != AppRoutes.login) return AppRoutes.login;
        return null;
      }

      // Login olmus ama splash veya login ekranindaysa home'a al.
      if (loc == AppRoutes.splash || loc == AppRoutes.login) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
        routes: [
          GoRoute(
            // /home/profile?login=xxx  -- daha temiz URL yapisi icin
            // ama biz extra ile UserModel de gonderiyoruz (onceden yukluyse).
            path: 'profile',
            name: 'profile',
            pageBuilder: (context, state) {
              final login = state.uri.queryParameters['login'] ?? '';
              return _slidePage(
                key: state.pageKey,
                child: ProfileScreen(login: login),
              );
            },
          ),
        ],
      ),
    ],
  );
}

/// Fade geciis.
CustomTransitionPage _fadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (_, animation, __, w) =>
        FadeTransition(opacity: animation, child: w),
  );
}

/// Sagdan sola slide gecis (profile aciliisi icin).
CustomTransitionPage _slidePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (_, animation, __, w) {
      final tween = Tween(begin: const Offset(1, 0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
        position: animation.drive(tween),
        child: w,
      );
    },
  );
}
