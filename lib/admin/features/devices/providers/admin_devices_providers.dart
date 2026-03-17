import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/devices/services/admin_device_service.dart';
import 'package:wms/core/core.dart';
import 'package:wms/routing/routing.dart';

final adminDeviceServiceProvider = Provider<AdminDeviceService>((ref) {
  return AdminDeviceService();
});

final adminDevicesPageProvider =
    NotifierProvider<AdminDevicesPageNotifier, int>(
      AdminDevicesPageNotifier.new,
    );

final adminDevicesShowUnassignedOnlyProvider =
    Provider.autoDispose<bool>((ref) {
      final route = ref.watch(appRouteProvider);
      if (route.section != AppRouteSection.devices) {
        return false;
      }
      return route.queryParameters['filter'] == 'unassigned';
    });

class AdminDevicesPageNotifier extends Notifier<int> {
  @override
  int build() {
    final route = ref.watch(appRouteProvider);
    if (route.section != AppRouteSection.devices) {
      return 0;
    }

    final page = int.tryParse(route.queryParameters['page'] ?? '') ?? 0;
    return page < 0 ? 0 : page;
  }

  void next() {
    state = state + 1;
    _syncRoute();
  }

  void previous() {
    state = state > 0 ? state - 1 : 0;
    _syncRoute();
  }

  void set(int page) {
    state = page < 0 ? 0 : page;
    _syncRoute();
  }

  void _syncRoute() {
    final queryParameters = <String, String>{};
    if (state > 0) {
      queryParameters['page'] = state.toString();
    }

    ref
        .read(appRouteProvider.notifier)
        .goToSection(AppRouteSection.devices, queryParameters: queryParameters);
  }
}

final adminDevicesListProvider =
    FutureProvider.autoDispose<AdminDevicePageResult>((ref) async {
      final service = ref.read(adminDeviceServiceProvider);
      final page = ref.watch(adminDevicesPageProvider);
      final showUnassignedOnly = ref.watch(
        adminDevicesShowUnassignedOnlyProvider,
      );
      final session = ref.read(currentAuthSessionProvider);
      var token = (session?.token ?? '').trim();

      if (token.isEmpty) {
        final remembered = await ref
            .read(authLocalStorageProvider)
            .loadLoginData();
        token = (remembered?.token ?? '').trim();
      }

      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }

      if (showUnassignedOnly) {
        return service.getUnassignedDevices(bearerToken: token);
      }

      return service.getDevices(bearerToken: token, page: page, size: 20);
    });

final adminRegisterDeviceControllerProvider =
    NotifierProvider.autoDispose<
      AdminRegisterDeviceController,
      AsyncValue<void>
    >(AdminRegisterDeviceController.new);

class AdminRegisterDeviceController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> register(AdminDeviceRequest request) async {
    state = const AsyncLoading<void>();
    try {
      final service = ref.read(adminDeviceServiceProvider);
      final token = await _resolveToken(ref);

      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }

      await service.registerDevice(bearerToken: token, request: request);
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}

final adminUpdateDeviceControllerProvider =
    NotifierProvider.autoDispose<AdminUpdateDeviceController, AsyncValue<void>>(
      AdminUpdateDeviceController.new,
    );

class AdminUpdateDeviceController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> update({
    required String id,
    required AdminDeviceRequest request,
  }) async {
    state = const AsyncLoading<void>();
    try {
      final service = ref.read(adminDeviceServiceProvider);
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }

      await service.updateDevice(bearerToken: token, id: id, request: request);
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}

final adminDeleteDeviceControllerProvider =
    NotifierProvider.autoDispose<AdminDeleteDeviceController, AsyncValue<void>>(
      AdminDeleteDeviceController.new,
    );

class AdminDeleteDeviceController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> delete(String id) async {
    state = const AsyncLoading<void>();
    try {
      final service = ref.read(adminDeviceServiceProvider);
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }

      await service.deleteDevice(bearerToken: token, id: id);
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
