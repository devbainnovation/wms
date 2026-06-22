import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';

enum AppLaunchTarget { webAdmin, userLogin, userPhoneLogin, userDashboard, adminDashboard }

class AppLaunchState {
  const AppLaunchState._({required this.target, this.session});

  const AppLaunchState.web() : this._(target: AppLaunchTarget.webAdmin);

  const AppLaunchState.userLogin()
    : this._(target: AppLaunchTarget.userLogin);

  const AppLaunchState.userPhoneLogin()
    : this._(target: AppLaunchTarget.userPhoneLogin);

  const AppLaunchState.userDashboard(AuthSession session)
    : this._(target: AppLaunchTarget.userDashboard, session: session);

  const AppLaunchState.adminDashboard(AuthSession session)
    : this._(target: AppLaunchTarget.adminDashboard, session: session);

  final AppLaunchTarget target;
  final AuthSession? session;
}

final appLaunchProvider = FutureProvider<AppLaunchState>((ref) async {
  final remembered = await ref.read(authLocalStorageProvider).loadLoginData();
  if (remembered == null) {
    return kIsWeb
        ? const AppLaunchState.web()
        : const AppLaunchState.userPhoneLogin();
  }

  final hasValidSession =
      remembered.token.isNotEmpty &&
      remembered.role.isNotEmpty &&
      remembered.userId.isNotEmpty &&
      remembered.sessionId.isNotEmpty;

  if (!hasValidSession) {
    return kIsWeb
        ? const AppLaunchState.web()
        : const AppLaunchState.userPhoneLogin();
  }

  final session = AuthSession(
    token: remembered.token,
    role: remembered.role,
    userId: remembered.userId,
    sessionId: remembered.sessionId,
  );

  if (kIsWeb) {
    final hasActiveWebSession = await validateStoredWebSession(
      session: session,
      storage: ref.read(authLocalStorageProvider),
    );
    if (!hasActiveWebSession) {
      return const AppLaunchState.web();
    }
    return AppLaunchState.adminDashboard(session);
  }

  return AppLaunchState.userDashboard(session);
});

Future<bool> validateStoredWebSession({
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
