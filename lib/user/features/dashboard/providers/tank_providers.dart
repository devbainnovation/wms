import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/user/features/dashboard/services/tank_service.dart';

enum TankFilter { all, low, normal, high }

final tankServiceProvider = Provider<TankService>((ref) {
  return MockTankService();
});

final tankListProvider = FutureProvider.autoDispose<List<TankData>>((ref) {
  final service = ref.watch(tankServiceProvider);
  return service.getTanks();
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
