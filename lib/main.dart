import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/admin/admin.dart';
import 'package:wms/core/core.dart';
import 'package:wms/firebase_options.dart';
import 'package:wms/routing/routing.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/user.dart';

final _appLaunchProvider = FutureProvider<_AppLaunchState>((ref) async {
  final remembered = await ref.read(authLocalStorageProvider).loadLoginData();
  if (remembered == null) {
    return kIsWeb
        ? const _AppLaunchState.web()
        : const _AppLaunchState.userLogin();
  }

  final hasValidSession =
      remembered.token.isNotEmpty &&
      remembered.role.isNotEmpty &&
      remembered.userId.isNotEmpty &&
      remembered.sessionId.isNotEmpty;

  if (!hasValidSession) {
    return kIsWeb
        ? const _AppLaunchState.web()
        : const _AppLaunchState.userLogin();
  }

  final session = AuthSession(
    token: remembered.token,
    role: remembered.role,
    userId: remembered.userId,
    sessionId: remembered.sessionId,
  );

  if (kIsWeb) {
    final hasActiveWebSession = await _validateStoredWebSession(
      session: session,
      storage: ref.read(authLocalStorageProvider),
    );
    if (!hasActiveWebSession) {
      return const _AppLaunchState.web();
    }
    return _AppLaunchState.adminDashboard(session);
  }

  return _AppLaunchState.userDashboard(session);
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: WmsApp()));
}

Future<bool> _validateStoredWebSession({
  required AuthSession session,
  required AuthLocalStorage storage,
}) async {
  final client = ApiClient();
  try {
    final response = await client.get(
      ApiEndpoints.adminSystemDashboard,
      bearerToken: session.token,
      showGlobalLoader: false,
      reportUnauthorized: false,
    );

    if (response.isSuccess) {
      return true;
    }
  } catch (_) {
    // Treat startup validation failures as an invalid session so web does not
    // open directly into the dashboard with a broken token.
  } finally {
    client.dispose();
  }

  final rememberMe = await storage.isRememberMeEnabled();
  if (rememberMe) {
    await storage.clearSessionDataOnly();
  } else {
    await storage.clear();
  }
  return false;
}

class WmsApp extends ConsumerStatefulWidget {
  const WmsApp({super.key});

  @override
  ConsumerState<WmsApp> createState() => _WmsAppState();
}

class _WmsAppState extends ConsumerState<WmsApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _isHandlingUnauthorized = false;
  late final AppRouterDelegate _routerDelegate;
  final AppRouteInformationParser _routeInformationParser =
      AppRouteInformationParser();

  @override
  void initState() {
    super.initState();
    ApiClient.unauthorizedEventCount.addListener(_handleUnauthorizedEvent);
    _routerDelegate = AppRouterDelegate(ref);
  }

  @override
  void dispose() {
    ApiClient.unauthorizedEventCount.removeListener(_handleUnauthorizedEvent);
    _routerDelegate.dispose();
    super.dispose();
  }

  Future<void> _handleUnauthorizedEvent() async {
    if (_isHandlingUnauthorized || !mounted) {
      return;
    }

    final currentSession = ref.read(currentAuthSessionProvider);
    if (currentSession == null) {
      return;
    }

    _isHandlingUnauthorized = true;
    try {
      final storage = ref.read(authLocalStorageProvider);
      final rememberMe = await storage.isRememberMeEnabled();
      if (rememberMe) {
        await storage.clearSessionDataOnly();
      } else {
        await storage.clear();
      }

      ref.read(currentAuthSessionProvider.notifier).clear();
      if (!mounted) {
        return;
      }

      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again.')),
      );
    } finally {
      _isHandlingUnauthorized = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(pushNotificationInitProvider);
    ref.listen<AppRouteState>(appRouteProvider, (previous, next) {
      _routerDelegate.refresh();
    });
    ref.listen<AuthSession?>(currentAuthSessionProvider, (previous, next) {
      _routerDelegate.refresh();
    });
    ref.listen(fcmTokenProvider, (_, next) {
      next.whenData((token) {
        if (token != null && token.isNotEmpty) {
          debugPrint('FCM token: $token');
        }
      });
    });

    if (kIsWeb) {
      return MaterialApp.router(
        scaffoldMessengerKey: _scaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        scrollBehavior: const _AppScrollBehavior(),
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.lightBackground,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryTeal,
            primary: AppColors.primaryTeal,
            secondary: AppColors.accentGreen,
            surface: AppColors.white,
            onPrimary: AppColors.white,
            onSurface: AppColors.darkText,
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          primaryTextTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.darkText,
            surfaceTintColor: AppColors.white,
            elevation: 2,
            scrolledUnderElevation: 2,
            shadowColor: Color(0x26000000),
            titleTextStyle: TextStyle(
              color: AppColors.darkText,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          cardTheme: CardThemeData(
            color: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.lightGreyText),
            ),
          ),
          dividerColor: AppColors.lightGreyText,
          iconTheme: const IconThemeData(color: AppColors.darkText),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: AppColors.primaryTeal,
            selectionHandleColor: AppColors.primaryTeal,
            selectionColor: AppColors.primaryTeal.withValues(alpha: 0.28),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.white,
            hintStyle: const TextStyle(color: AppColors.greyText),
            labelStyle: const TextStyle(color: AppColors.greyText),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.lightGreyText),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primaryTeal,
                width: 1.4,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.lightGreyText),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: AppColors.white,
            selectedColor: AppColors.lightTeal,
            disabledColor: AppColors.lightGreyText,
            labelStyle: const TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w600,
            ),
            secondaryLabelStyle: const TextStyle(
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.w600,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: const BorderSide(color: AppColors.lightGreyText),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkText,
              side: const BorderSide(color: AppColors.lightGreyText),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: Color(0xFF1F2937),
            contentTextStyle: TextStyle(color: AppColors.white),
          ),
        ),
        routerDelegate: _routerDelegate,
        routeInformationParser: _routeInformationParser,
        builder: (context, child) {
          return ValueListenableBuilder<int>(
            valueListenable: ApiClient.inFlightRequestCount,
            builder: (context, count, _) {
              final showLoader = count > 0;
              return Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  if (showLoader)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.2),
                        child: const Center(
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      );
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _AppScrollBehavior(),
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.lightBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryTeal,
          primary: AppColors.primaryTeal,
          secondary: AppColors.accentGreen,
          surface: AppColors.white,
          onPrimary: AppColors.white,
          onSurface: AppColors.darkText,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        primaryTextTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.darkText,
          surfaceTintColor: AppColors.white,
          elevation: 2,
          scrolledUnderElevation: 2,
          shadowColor: Color(0x26000000),
          titleTextStyle: TextStyle(
            color: AppColors.darkText,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.lightGreyText),
          ),
        ),
        dividerColor: AppColors.lightGreyText,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColors.primaryTeal,
          selectionHandleColor: AppColors.primaryTeal,
          selectionColor: AppColors.primaryTeal.withValues(alpha: 0.28),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          hintStyle: const TextStyle(color: AppColors.greyText),
          labelStyle: const TextStyle(color: AppColors.greyText),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.lightGreyText),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.primaryTeal,
              width: 1.4,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.lightGreyText),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.white,
          selectedColor: AppColors.lightTeal,
          disabledColor: AppColors.lightGreyText,
          labelStyle: const TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.w600,
          ),
          secondaryLabelStyle: const TextStyle(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: const BorderSide(color: AppColors.lightGreyText),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.darkText,
            side: const BorderSide(color: AppColors.lightGreyText),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1F2937),
          contentTextStyle: TextStyle(color: AppColors.white),
        ),
      ),
      builder: (context, child) {
        return ValueListenableBuilder<int>(
          valueListenable: ApiClient.inFlightRequestCount,
          builder: (context, count, _) {
            final showLoader = count > 0;
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                if (showLoader)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.2),
                      child: const Center(
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
      home: const _AppLaunchGate(),
    );
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

class _AppLaunchGate extends ConsumerStatefulWidget {
  const _AppLaunchGate();

  @override
  ConsumerState<_AppLaunchGate> createState() => _AppLaunchGateState();
}

class _AppLaunchGateState extends ConsumerState<_AppLaunchGate> {
  bool _didRestoreLaunchSession = false;

  @override
  Widget build(BuildContext context) {
    final launchAsync = ref.watch(_appLaunchProvider);
    final currentSession = ref.watch(currentAuthSessionProvider);

    return launchAsync.when(
      loading: () => const _SplashScreen(),
      error: (_, _) =>
          kIsWeb ? const AdminLoginScreen() : const UserLoginScreen(),
      data: (state) {
        if (!_didRestoreLaunchSession && state.session != null) {
          final session = state.session!;
          _didRestoreLaunchSession = true;
          final isSameSession =
              currentSession?.token == session.token &&
              currentSession?.role == session.role &&
              currentSession?.userId == session.userId &&
              currentSession?.sessionId == session.sessionId;

          if (!isSameSession) {
            Future<void>(() {
              ref.read(currentAuthSessionProvider.notifier).setSession(session);
            });
            return const _SplashScreen();
          }
        }

        if (currentSession != null) {
          if (kIsWeb) {
            return const AdminDashboardScreen();
          }
          return const UserDashboardScreen();
        }

        return switch (state.target) {
          _AppLaunchTarget.webAdmin => const AdminLoginScreen(),
          _AppLaunchTarget.userLogin => const UserLoginScreen(),
          _AppLaunchTarget.userDashboard => const UserLoginScreen(),
          _AppLaunchTarget.adminDashboard => const AdminLoginScreen(),
        };
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.lightBlue, AppColors.lightGreen],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppAssets.logo,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.water_drop_rounded,
                  size: 72,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(height: 18),
              const CircularProgressIndicator(color: AppColors.primaryTeal),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AppLaunchTarget { webAdmin, userLogin, userDashboard, adminDashboard }

class _AppLaunchState {
  const _AppLaunchState._({required this.target, this.session});

  const _AppLaunchState.web() : this._(target: _AppLaunchTarget.webAdmin);

  const _AppLaunchState.userLogin()
    : this._(target: _AppLaunchTarget.userLogin);

  const _AppLaunchState.userDashboard(AuthSession session)
    : this._(target: _AppLaunchTarget.userDashboard, session: session);

  const _AppLaunchState.adminDashboard(AuthSession session)
    : this._(target: _AppLaunchTarget.adminDashboard, session: session);

  final _AppLaunchTarget target;
  final AuthSession? session;
}
