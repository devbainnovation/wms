import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/user/features/dashboard/services/user_admin_users_service.dart';

final userAdminUsersServiceProvider = Provider<UserAdminUsersService>((ref) {
  return UserAdminUsersService();
});

final userAdminUsersListProvider =
    FutureProvider.autoDispose<List<UserAdminUserSummary>>((ref) async {
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      final service = ref.read(userAdminUsersServiceProvider);
      return service.getUsers(bearerToken: token);
    });

final userAdminUserDetailsProvider = FutureProvider.autoDispose
    .family<UserAdminUserSummary, String>((ref, userId) async {
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      final service = ref.read(userAdminUsersServiceProvider);
      return service.getUserById(bearerToken: token, userId: userId);
    });

final userAdminCreateUserControllerProvider =
    NotifierProvider.autoDispose<
      UserAdminCreateUserController,
      AsyncValue<void>
    >(UserAdminCreateUserController.new);

class UserAdminCreateUserController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> create(UserAdminUserCreateRequest request) async {
    state = const AsyncLoading<void>();
    try {
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      final service = ref.read(userAdminUsersServiceProvider);
      await service.createUser(bearerToken: token, request: request);
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}

final userAdminDeleteUserControllerProvider =
    NotifierProvider.autoDispose<
      UserAdminDeleteUserController,
      AsyncValue<void>
    >(UserAdminDeleteUserController.new);

class UserAdminDeleteUserController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> delete(String userId) async {
    state = const AsyncLoading<void>();
    try {
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      final service = ref.read(userAdminUsersServiceProvider);
      await service.deleteUser(bearerToken: token, userId: userId);
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}

final userAdminUpdatePermissionsControllerProvider =
    NotifierProvider.autoDispose<
      UserAdminUpdatePermissionsController,
      AsyncValue<void>
    >(UserAdminUpdatePermissionsController.new);

class UserAdminUpdatePermissionsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> update({
    required String userId,
    required UserAdminUserPermissions permissions,
  }) async {
    state = const AsyncLoading<void>();
    try {
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      final service = ref.read(userAdminUsersServiceProvider);
      await service.updateUserPermissions(
        bearerToken: token,
        userId: userId,
        permissions: permissions,
      );
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
