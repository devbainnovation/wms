import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/user/features/dashboard/services/user_profile_service.dart';

final adminProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

final adminProfileProvider = FutureProvider.autoDispose<UserProfile>((
  ref,
) async {
  ref.watch(currentAuthSessionProvider);
  final token = await _resolveToken(ref);
  if (token.isEmpty) {
    throw const ApiException('Session expired. Please login again.');
  }

  final service = ref.read(adminProfileServiceProvider);
  return service.getProfile(bearerToken: token);
});

final adminProfileUpdateControllerProvider =
    NotifierProvider.autoDispose<
      AdminProfileUpdateController,
      AsyncValue<void>
    >(AdminProfileUpdateController.new);

class AdminProfileUpdateController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> update(UserProfileUpdateRequest request) async {
    state = const AsyncLoading<void>();
    try {
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }

      final service = ref.read(adminProfileServiceProvider);
      await service.updateProfile(bearerToken: token, request: request);
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}

final adminPasswordUpdateControllerProvider =
    NotifierProvider.autoDispose<
      AdminPasswordUpdateController,
      AsyncValue<void>
    >(AdminPasswordUpdateController.new);

class AdminPasswordUpdateController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> update(UserProfilePasswordUpdateRequest request) async {
    state = const AsyncLoading<void>();
    try {
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }

      final service = ref.read(adminProfileServiceProvider);
      await service.updatePassword(bearerToken: token, request: request);
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}

Future<String> _resolveToken(Ref ref) async {
  final session = ref.read(currentAuthSessionProvider);
  var token = (session?.token ?? '').trim();
  if (token.isNotEmpty) {
    return token;
  }

  final remembered = await ref.read(authLocalStorageProvider).loadLoginData();
  token = (remembered?.token ?? '').trim();
  return token;
}
