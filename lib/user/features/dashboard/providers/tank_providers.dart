import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/user/features/dashboard/services/tank_service.dart';

enum TankFilter { all, low, normal, high }

final tankServiceProvider = Provider<TankService>((ref) {
  return TankService();
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

Future<String> _resolveToken(Ref ref) async {
  final session = ref.read(currentAuthSessionProvider);
  return (session?.token ?? '').trim();
}
