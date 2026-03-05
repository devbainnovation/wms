import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/customers/services/admin_customer_service.dart';
import 'package:wms/core/core.dart';

class AdminCustomersQuery {
  const AdminCustomersQuery({this.page = 0, this.size = 10, this.search = ''});

  final int page;
  final int size;
  final String search;

  AdminCustomersQuery copyWith({int? page, int? size, String? search}) {
    return AdminCustomersQuery(
      page: page ?? this.page,
      size: size ?? this.size,
      search: search ?? this.search,
    );
  }
}

final adminCustomerServiceProvider = Provider<AdminCustomerService>((ref) {
  return AdminCustomerService();
});

final adminCustomersQueryProvider =
    NotifierProvider<AdminCustomersQueryNotifier, AdminCustomersQuery>(
      AdminCustomersQueryNotifier.new,
    );

class AdminCustomersQueryNotifier extends Notifier<AdminCustomersQuery> {
  @override
  AdminCustomersQuery build() => const AdminCustomersQuery();

  void next() => state = state.copyWith(page: state.page + 1);

  void previous() =>
      state = state.copyWith(page: state.page > 0 ? state.page - 1 : 0);

  void resetPage() => state = state.copyWith(page: 0);

  void setSearch(String text) {
    final normalized = text.trim();
    state = state.copyWith(search: normalized, page: 0);
  }
}

final adminCustomersListProvider =
    FutureProvider.autoDispose<AdminCustomerPageResult>((ref) async {
      final service = ref.read(adminCustomerServiceProvider);
      final query = ref.watch(adminCustomersQueryProvider);
      final token = await _resolveToken(ref);

      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }

      return service.getCustomers(
        bearerToken: token,
        page: query.page,
        size: query.size,
        search: query.search,
      );
    });

final adminUnassignedDevicesProvider =
    FutureProvider.autoDispose<List<AdminUnassignedDevice>>((ref) async {
      final service = ref.read(adminCustomerServiceProvider);
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      return service.getUnassignedDevices(bearerToken: token);
    });

final adminCreateCustomerControllerProvider =
    NotifierProvider.autoDispose<
      AdminCreateCustomerController,
      AsyncValue<void>
    >(AdminCreateCustomerController.new);

class AdminCreateCustomerController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> create(AdminCustomerRequest request) async {
    state = const AsyncLoading<void>();
    try {
      final service = ref.read(adminCustomerServiceProvider);
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      await service.createCustomer(bearerToken: token, request: request);
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}

final adminUpdateCustomerControllerProvider =
    NotifierProvider.autoDispose<
      AdminUpdateCustomerController,
      AsyncValue<void>
    >(AdminUpdateCustomerController.new);

class AdminUpdateCustomerController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> update({
    required String customerId,
    required AdminCustomerUpdateRequest request,
  }) async {
    state = const AsyncLoading<void>();
    try {
      final service = ref.read(adminCustomerServiceProvider);
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      await service.updateCustomer(
        bearerToken: token,
        customerId: customerId,
        request: request,
      );
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}

final adminDeleteCustomerControllerProvider =
    NotifierProvider.autoDispose<
      AdminDeleteCustomerController,
      AsyncValue<void>
    >(AdminDeleteCustomerController.new);

class AdminDeleteCustomerController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> delete(String customerId) async {
    state = const AsyncLoading<void>();
    try {
      final service = ref.read(adminCustomerServiceProvider);
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      await service.deleteCustomer(bearerToken: token, customerId: customerId);
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}

final adminAssignDevicesCustomerControllerProvider =
    NotifierProvider.autoDispose<
      AdminAssignDevicesCustomerController,
      AsyncValue<void>
    >(AdminAssignDevicesCustomerController.new);

class AdminAssignDevicesCustomerController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<void> assign({
    required String customerId,
    required List<String> espUnitIds,
  }) async {
    state = const AsyncLoading<void>();
    try {
      final service = ref.read(adminCustomerServiceProvider);
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      await service.assignDevices(
        bearerToken: token,
        customerId: customerId,
        request: AdminCustomerAssignDevicesRequest(
          customerId: customerId,
          espUnitIds: espUnitIds,
        ),
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
