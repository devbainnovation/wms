import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/user/features/dashboard/services/tank_service.dart';

enum TankFilter { all, low, normal, high }

final tankServiceProvider = Provider<TankService>((ref) {
  return TankService(apiClient: ref.watch(apiClientProvider));
});

final tankListProvider = FutureProvider.autoDispose<List<TankData>>((ref) async {
  ref.watch(currentAuthSessionProvider);
  final token = await _resolveToken(ref);
  if (token.isEmpty) {
    throw const ApiException('Session expired. Please login again.');
  }
  final service = ref.watch(tankServiceProvider);
  return service.getTanks(bearerToken: token);
});

final tankFilterProvider =
    NotifierProvider.autoDispose<TankFilterNotifier, TankFilter>(
      TankFilterNotifier.new,
    );

class TankFilterNotifier extends Notifier<TankFilter> {
  @override
  TankFilter build() => TankFilter.all;

  void setFilter(TankFilter filter) {
    state = filter;
  }
}

final tankSearchQueryProvider =
    NotifierProvider.autoDispose<TankSearchQueryNotifier, String>(
      TankSearchQueryNotifier.new,
    );

class TankSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final filteredTankListProvider = Provider.autoDispose<AsyncValue<List<TankData>>>((ref) {
  final tankListAsync = ref.watch(tankListProvider);
  final filter = ref.watch(tankFilterProvider);
  final query = ref.watch(tankSearchQueryProvider).toLowerCase();

  return tankListAsync.whenData((list) {
    return list.where((tank) {
      final searchableName = (tank.espDisplayName.isEmpty
              ? tank.espId
              : tank.espDisplayName)
          .toLowerCase();
      
      final matchName = searchableName.contains(query);
      
      final byFilter = switch (filter) {
        TankFilter.all => true,
        TankFilter.low => tank.levelPercent < 0.2,
        TankFilter.normal =>
          tank.levelPercent >= 0.2 && tank.levelPercent < 0.7,
        TankFilter.high => tank.levelPercent >= 0.7,
      };
      
      return matchName && byFilter;
    }).toList();
  });
});

final tankHistoryDaysProvider =
    NotifierProvider.autoDispose<TankHistoryDaysNotifier, int>(
      TankHistoryDaysNotifier.new,
    );

class TankHistoryDaysNotifier extends Notifier<int> {
  @override
  int build() => 7;

  void setDays(int days) {
    state = days;
  }
}

final tankHistoryProvider = FutureProvider.autoDispose
    .family<List<TankHistoryItem>, String>((ref, componentId) async {
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      final days = ref.watch(tankHistoryDaysProvider);
      final service = ref.watch(tankServiceProvider);
      return service.getTankHistory(
        bearerToken: token,
        componentId: componentId,
        days: days,
      );
    });

Future<String> _resolveToken(Ref ref) async {
  final session = ref.read(currentAuthSessionProvider);
  return (session?.token ?? '').trim();
}
