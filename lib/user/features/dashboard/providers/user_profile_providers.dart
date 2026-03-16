import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/user/features/dashboard/services/user_profile_service.dart';

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  ref.watch(currentAuthSessionProvider);
  final token = await _resolveToken(ref);
  if (token.isEmpty) {
    throw const ApiException('Session expired. Please login again.');
  }
  final service = ref.read(userProfileServiceProvider);
  return service.getProfile(bearerToken: token);
});

final userProfileUpdateControllerProvider =
    NotifierProvider.autoDispose<UserProfileUpdateController, AsyncValue<void>>(
      UserProfileUpdateController.new,
    );

class UserProfileUpdateController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> update(UserProfileUpdateRequest request) async {
    state = const AsyncLoading<void>();
    try {
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      final service = ref.read(userProfileServiceProvider);
      await service.updateProfile(bearerToken: token, request: request);
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}

final userPasswordUpdateControllerProvider =
    NotifierProvider.autoDispose<
      UserPasswordUpdateController,
      AsyncValue<void>
    >(UserPasswordUpdateController.new);

class UserPasswordUpdateController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> update(UserProfilePasswordUpdateRequest request) async {
    state = const AsyncLoading<void>();
    try {
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      final service = ref.read(userProfileServiceProvider);
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
  return (session?.token ?? '').trim();
}
