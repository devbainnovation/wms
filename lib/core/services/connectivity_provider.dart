import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

enum NetworkStatus { online, offline }

final internetConnectionProvider = Provider<InternetConnection>((ref) {
  return InternetConnection();
});

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  final checker = ref.watch(internetConnectionProvider);

  final hasInternet = await checker.hasInternetAccess;
  yield hasInternet ? NetworkStatus.online : NetworkStatus.offline;

  yield* checker.onStatusChange
      .map((status) => status == InternetStatus.connected
          ? NetworkStatus.online
          : NetworkStatus.offline)
      .distinct();
});
