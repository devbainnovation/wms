import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/devices/services/admin_device_component_service.dart';
import 'package:wms/core/core.dart';

final adminDeviceComponentServiceProvider =
    Provider<AdminDeviceComponentService>(
      (ref) => AdminDeviceComponentService(),
    );

final adminDeviceComponentsProvider = FutureProvider.autoDispose
    .family<List<AdminDeviceComponent>, String>((ref, deviceId) async {
      final service = ref.read(adminDeviceComponentServiceProvider);
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      return service.getComponents(bearerToken: token, deviceId: deviceId);
    });

final adminCreateComponentControllerProvider =
    NotifierProvider.autoDispose<
      AdminCreateComponentController,
      AsyncValue<void>
    >(AdminCreateComponentController.new);

class AdminCreateComponentController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> create({
    required String deviceId,
    required AdminDeviceComponentRequest request,
  }) async {
    state = const AsyncLoading<void>();
    try {
      final service = ref.read(adminDeviceComponentServiceProvider);
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      await service.addComponent(
        bearerToken: token,
        deviceId: deviceId,
        request: request,
      );
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}

final adminUpdateComponentControllerProvider =
    NotifierProvider.autoDispose<
      AdminUpdateComponentController,
      AsyncValue<void>
    >(AdminUpdateComponentController.new);

class AdminUpdateComponentController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> update({
    required String deviceId,
    required String compId,
    required AdminDeviceComponentRequest request,
  }) async {
    state = const AsyncLoading<void>();
    try {
      final service = ref.read(adminDeviceComponentServiceProvider);
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      await service.updateComponent(
        bearerToken: token,
        deviceId: deviceId,
        compId: compId,
        request: request,
      );
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}

final adminDeleteComponentControllerProvider =
    NotifierProvider.autoDispose<
      AdminDeleteComponentController,
      AsyncValue<void>
    >(AdminDeleteComponentController.new);

class AdminDeleteComponentController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> delete({
    required String deviceId,
    required String compId,
  }) async {
    state = const AsyncLoading<void>();
    try {
      final service = ref.read(adminDeviceComponentServiceProvider);
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      await service.deleteComponent(
        bearerToken: token,
        deviceId: deviceId,
        compId: compId,
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
