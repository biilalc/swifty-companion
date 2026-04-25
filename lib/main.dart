// Uygulamanin giris noktasi. Ayrıca:
//  - .env dosyasini yukler (konfigurasyonu erken validate et).
//  - DI icin Provider.multi ile tum bagimliliklari kurar.
//  - easy_localization ile coklu dil (TR + EN) baslatir.
//  - Hata yakalamasi icin FlutterError handler kurar.

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config/env_config.dart';
import 'core/errors/app_exceptions.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'data/datasources/local/token_storage.dart';
import 'data/datasources/remote/api_client.dart';
import 'data/datasources/remote/auth_interceptor.dart';
import 'data/datasources/remote/auth_service.dart';
import 'data/datasources/remote/user_api.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/user_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/home_provider.dart';
import 'presentation/providers/profile_provider.dart';

Future<void> main() async {
  // runZonedGuarded ile tum async hatalarini yakaliyoruz ki uygulama
  // sessizce crash etmesin, log'a dusurebilelim.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Uygulama sadece portrait modunda calissin - mobil arama app'i icin
    // landscape UX hem gereksiz hem de bizim iconlarimizi bozuyor.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // .env dosyasini pubspec'teki asset olarak yukle.
    await dotenv.load(fileName: '.env');

    // Konfigurasyonu validate et - eksikse uygulamayi baslatmiyoruz.
    try {
      EnvConfig.validate();
    } on ConfigException catch (e) {
      appLogger.e('Konfigurasyon eksik: ${e.message}');
      runApp(_ConfigErrorApp(message: e.message));
      return;
    }

    // easy_localization init.
    await EasyLocalization.ensureInitialized();

    // Global Flutter hata handler'i - runtime framework hatalarini log'a duser.
    FlutterError.onError = (details) {
      appLogger.e(
        'Flutter framework hatasi: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
      );
      FlutterError.presentError(details);
    };

    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('tr')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        useOnlyLangCode: true,
        child: const SwiftyCompanionApp(),
      ),
    );
  }, (error, stack) {
    appLogger.e('Unhandled async error', error: error, stackTrace: stack);
  });
}

class SwiftyCompanionApp extends StatefulWidget {
  const SwiftyCompanionApp({super.key});

  @override
  State<SwiftyCompanionApp> createState() => _SwiftyCompanionAppState();
}

class _SwiftyCompanionAppState extends State<SwiftyCompanionApp> {
  late final TokenStorage _storage;
  late final AuthService _authService;
  late final AuthRepository _authRepo;
  late final AuthProvider _authProvider;
  late final AuthInterceptor _authInterceptor;
  late final ApiClient _apiClient;
  late final UserApi _userApi;
  late final UserRepository _userRepo;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    // DI graph'i manuel kuruyoruz - Hilt/GetIt gibi kutuphaneler bu scope
    // icin overkill; provider.multi ile widget tree'de saglaniyorlar.
    _storage = TokenStorage();
    _authService = AuthService();
    _authRepo = AuthRepository(
      authService: _authService,
      storage: _storage,
    );
    _authProvider = AuthProvider(_authRepo);

    // AuthInterceptor olusturuyoruz ve callback uzerinden provider'a baglıyoruz
    // ki session expire oldugunda router dinlesin.
    _authInterceptor = AuthInterceptor(
      storage: _storage,
      authService: _authService,
      onSessionExpired: _authProvider.onSessionExpired,
    );
    _apiClient = ApiClient.create(authInterceptor: _authInterceptor);
    _userApi = UserApi(_apiClient.dio);
    _userRepo = UserRepository(_userApi);

    _router = buildAppRouter(_authProvider);

    // Uygulama acilisinda auth durumunu kontrol et.
    // addPostFrameCallback ile provider notify'lari build sirasinda degil,
    // ilk frame sonrasinda tetiklenir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider.bootstrap();
    });
  }

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<HomeProvider>(
          create: (_) => HomeProvider(_userRepo),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(_userRepo),
        ),
      ],
      child: MaterialApp.router(
        title: 'Swifty Companion',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        routerConfig: _router,
      ),
    );
  }
}

/// .env eksikse gosterilen failure ekrani. Uygulama fail fast, ama
/// kullaniciya "neden acilmiyor" aciklamasi veriyoruz.
class _ConfigErrorApp extends StatelessWidget {
  final String message;
  const _ConfigErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Configuration error',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please make sure .env file exists in the project root '
                    'with all required keys (see .env.example).',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
