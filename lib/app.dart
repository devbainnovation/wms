import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/admin.dart';
import 'package:wms/core/core.dart';
import 'package:wms/routing/routing.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/user.dart';

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
      ref.read(userPhoneLoginControllerProvider.notifier).reset();
      
      if (!mounted) {
        return;
      }

      final navigator = _navigatorKey.currentState;
      if (!kIsWeb && navigator != null) {
        // Return to the root app gate instead of pushing a standalone login
        // route, so a successful relogin can naturally rebuild into the
        // dashboard from auth state changes.
        navigator.popUntil((route) => route.isFirst);
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
      if (next == null) {
        // Reset phone login state on logout/session expiry so the next login
        // starts from the mobile number input screen.
        ref.read(userPhoneLoginControllerProvider.notifier).reset();
      } else if (!kIsWeb) {
        // When a session is established on mobile, clear the navigation stack
        // (e.g., pop the Phone Login screen) so the AppLaunchGate root
        // can transition to the Dashboard.
        _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
      _routerDelegate.refresh();
    });
    ref.listen(fcmTokenProvider, (_, next) {
      next.whenData((token) {
        if (token != null && token.isNotEmpty) {
          debugPrint('FCM token: $token');
        }
      });
    });

    final theme = AppTheme.lightTheme;

    Widget buildWithLoader(Widget? child) {
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
    }

    if (kIsWeb) {
      return MaterialApp.router(
        scaffoldMessengerKey: _scaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        scrollBehavior: const AppScrollBehavior(),
        theme: theme,
        routerDelegate: _routerDelegate,
        routeInformationParser: _routeInformationParser,
        builder: (context, child) => buildWithLoader(child),
      );
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: theme,
      builder: (context, child) => buildWithLoader(child),
      home: const AppLaunchGate(),
    );
  }
}

class AppLaunchGate extends ConsumerStatefulWidget {
  const AppLaunchGate({super.key});

  @override
  ConsumerState<AppLaunchGate> createState() => _AppLaunchGateState();
}

class _AppLaunchGateState extends ConsumerState<AppLaunchGate> {
  bool _didRestoreLaunchSession = false;
  bool _didRemoveNativeSplash = false;

  void _removeNativeSplashIfNeeded() {
    if (kIsWeb || _didRemoveNativeSplash) {
      return;
    }

    _didRemoveNativeSplash = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final launchAsync = ref.watch(appLaunchProvider);
    final currentSession = ref.watch(currentAuthSessionProvider);

    return launchAsync.when(
      loading: () => kIsWeb ? const AppSplashScreen() : const SizedBox.shrink(),
      error: (_, _) {
        _removeNativeSplashIfNeeded();
        return kIsWeb ? const AdminLoginScreen() : const UserPhoneLoginScreen();
      },
      data: (state) {
        if (!_didRestoreLaunchSession && state.session != null) {
          final session = state.session!;
          _didRestoreLaunchSession = true;
          
          // Use Future.microtask to avoid modifying providers during build
          Future.microtask(() {
            final current = ref.read(currentAuthSessionProvider);
            if (current == null || current.token != session.token) {
              ref.read(currentAuthSessionProvider.notifier).setSession(session);
            }
          });
          
          return kIsWeb ? const AppSplashScreen() : const SizedBox.shrink();
        }

        if (currentSession != null) {
          _removeNativeSplashIfNeeded();
          if (kIsWeb) {
            return const AdminDashboardScreen();
          }
          return const UserDashboardScreen();
        }

        _removeNativeSplashIfNeeded();
        return switch (state.target) {
          AppLaunchTarget.webAdmin => const AdminLoginScreen(),
          AppLaunchTarget.userLogin => const UserPhoneLoginScreen(), // Fallback to Phone Login
          AppLaunchTarget.userPhoneLogin => const UserPhoneLoginScreen(),
          AppLaunchTarget.userDashboard => const UserPhoneLoginScreen(), // Fix for logout redirection
          AppLaunchTarget.adminDashboard => const AdminLoginScreen(),
        };
      },
    );
  }
}
