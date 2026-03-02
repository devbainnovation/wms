import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/auth/models/auth_models.dart';
import 'package:wms/core/auth/services/auth_api_service.dart';
import 'package:wms/core/auth/services/auth_local_storage.dart';

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService();
});

final authLocalStorageProvider = Provider<AuthLocalStorage>((ref) {
  return const AuthLocalStorage();
});

final currentAuthSessionProvider =
    NotifierProvider<CurrentAuthSessionNotifier, AuthSession?>(
      CurrentAuthSessionNotifier.new,
    );

class CurrentAuthSessionNotifier extends Notifier<AuthSession?> {
  @override
  AuthSession? build() => null;

  void setSession(AuthSession session) {
    state = session;
  }

  void clear() {
    state = null;
  }
}

final authLoginControllerProvider =
    NotifierProvider.autoDispose<AuthLoginController, AsyncValue<void>>(
      AuthLoginController.new,
    );

class AuthLoginController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<AuthSession> login({
    required String username,
    required String password,
    required bool rememberMe,
    String? deviceInfo,
    String? fcmToken,
  }) async {
    state = const AsyncLoading<void>();
    try {
      final authApi = ref.read(authApiServiceProvider);
      final storage = ref.read(authLocalStorageProvider);

      final session = await authApi.login(
        username: username,
        password: password,
        deviceInfo: deviceInfo,
        fcmToken: fcmToken,
      );

      await storage.saveLoginData(
        rememberMe: rememberMe,
        username: username,
        password: password,
        session: session,
      );
      ref.read(currentAuthSessionProvider.notifier).setSession(session);

      state = const AsyncData<void>(null);
      return session;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}

final authLogoutControllerProvider =
    NotifierProvider.autoDispose<AuthLogoutController, AsyncValue<void>>(
      AuthLogoutController.new,
    );

class AuthLogoutController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> logout({String? sessionId}) async {
    state = const AsyncLoading<void>();
    try {
      final authApi = ref.read(authApiServiceProvider);
      final storage = ref.read(authLocalStorageProvider);
      final remembered = await storage.loadLoginData();
      final rememberMe = await storage.isRememberMeEnabled();
      final activeSessionId = (sessionId ?? remembered?.sessionId ?? '').trim();

      if (activeSessionId.isNotEmpty) {
        try {
          await authApi.logout(activeSessionId);
        } catch (_) {
          // Continue local cleanup even if server-side session invalidation fails.
        }
      }

      if (rememberMe) {
        await storage.clearSessionDataOnly();
      } else {
        await storage.clear();
      }
      ref.read(currentAuthSessionProvider.notifier).clear();
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}

final rememberedLoginProvider = FutureProvider.autoDispose<RememberedAuthData?>(
  (ref) {
    return ref.read(authLocalStorageProvider).loadLoginData();
  },
);
