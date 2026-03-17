import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/auth/screens/admin_login_screen.dart';
import 'package:wms/admin/features/dashboard/screens/admin_dashboard_screen.dart';
import 'package:wms/core/auth/models/auth_models.dart';
import 'package:wms/core/auth/providers/auth_providers.dart';
import 'package:wms/shared/shared.dart';

enum AppRouteSection { dashboard, customers, devices, schedules, profile }

class AppRouteState {
  const AppRouteState({
    required this.section,
    this.queryParameters = const <String, String>{},
  });

  final AppRouteSection section;
  final Map<String, String> queryParameters;

  String get path => switch (section) {
    AppRouteSection.dashboard => '/dashboard',
    AppRouteSection.customers => '/customers',
    AppRouteSection.devices => '/devices',
    AppRouteSection.schedules => '/schedules',
    AppRouteSection.profile => '/profile',
  };

  Uri get uri => Uri(
    path: path,
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  );

  AppRouteState copyWith({
    AppRouteSection? section,
    Map<String, String>? queryParameters,
  }) {
    return AppRouteState(
      section: section ?? this.section,
      queryParameters: queryParameters ?? this.queryParameters,
    );
  }

  static const dashboard = AppRouteState(section: AppRouteSection.dashboard);
}

class AppRouteNotifier extends Notifier<AppRouteState> {
  @override
  AppRouteState build() => AppRouteState.dashboard;

  void setRoute(AppRouteState route) {
    state = route;
  }

  void goToSection(
    AppRouteSection section, {
    Map<String, String> queryParameters = const <String, String>{},
  }) {
    state = AppRouteState(
      section: section,
      queryParameters: Map<String, String>.from(queryParameters),
    );
  }
}

final appRouteProvider = NotifierProvider<AppRouteNotifier, AppRouteState>(
  AppRouteNotifier.new,
);

class AppRouteInformationParser extends RouteInformationParser<AppRouteState> {
  @override
  Future<AppRouteState> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final uri = routeInformation.uri;
    final normalizedPath = uri.path.trim().toLowerCase();

    final section = switch (normalizedPath) {
      '/customers' => AppRouteSection.customers,
      '/devices' => AppRouteSection.devices,
      '/schedules' => AppRouteSection.schedules,
      '/profile' => AppRouteSection.profile,
      '/dashboard' || '/' || '' => AppRouteSection.dashboard,
      _ => AppRouteSection.dashboard,
    };

    return AppRouteState(
      section: section,
      queryParameters: Map<String, String>.from(uri.queryParameters),
    );
  }

  @override
  RouteInformation? restoreRouteInformation(AppRouteState configuration) {
    return RouteInformation(uri: configuration.uri);
  }
}

class AppRouterDelegate extends RouterDelegate<AppRouteState>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRouteState> {
  AppRouterDelegate(this.ref);

  final WidgetRef ref;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  AppRouteState get currentConfiguration => ref.read(appRouteProvider);

  @override
  Future<void> setNewRoutePath(AppRouteState configuration) async {
    ref.read(appRouteProvider.notifier).setRoute(configuration);
  }

  void refresh() {
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: const [MaterialPage<void>(child: _WebAppRouterGate())],
      onDidRemovePage: (_) {},
    );
  }
}

class _WebAppRouterGate extends ConsumerStatefulWidget {
  const _WebAppRouterGate();

  @override
  ConsumerState<_WebAppRouterGate> createState() => _WebAppRouterGateState();
}

class _WebAppRouterGateState extends ConsumerState<_WebAppRouterGate> {
  bool _didRestoreLaunchSession = false;

  @override
  Widget build(BuildContext context) {
    final launchAsync = ref.watch(_appLaunchProviderForRouter);
    final currentSession = ref.watch(currentAuthSessionProvider);

    return launchAsync.when(
      loading: () => const _WebSplashScreen(),
      error: (_, _) => const AdminLoginScreen(),
      data: (launchSession) {
        if (!_didRestoreLaunchSession && launchSession != null) {
          _didRestoreLaunchSession = true;
          final sameSession =
              currentSession?.token == launchSession.token &&
              currentSession?.role == launchSession.role &&
              currentSession?.userId == launchSession.userId &&
              currentSession?.sessionId == launchSession.sessionId;
          if (!sameSession) {
            Future<void>(() {
              ref
                  .read(currentAuthSessionProvider.notifier)
                  .setSession(launchSession);
            });
            return const _WebSplashScreen();
          }
        }

        if (currentSession == null) {
          return const AdminLoginScreen();
        }

        return const AdminDashboardScreen();
      },
    );
  }
}

class _WebSplashScreen extends StatelessWidget {
  const _WebSplashScreen();

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
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      ),
    );
  }
}

final _appLaunchProviderForRouter = FutureProvider<AuthSession?>((ref) async {
  final remembered = await ref.read(authLocalStorageProvider).loadLoginData();
  if (remembered == null) {
    return null;
  }

  final hasValidSession =
      remembered.token.isNotEmpty &&
      remembered.role.isNotEmpty &&
      remembered.userId.isNotEmpty &&
      remembered.sessionId.isNotEmpty;
  if (!hasValidSession) {
    return null;
  }

  return AuthSession(
    token: remembered.token,
    role: remembered.role,
    userId: remembered.userId,
    sessionId: remembered.sessionId,
  );
});
