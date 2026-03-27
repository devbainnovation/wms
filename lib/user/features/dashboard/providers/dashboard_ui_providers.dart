import 'package:flutter_riverpod/flutter_riverpod.dart';

final userDashboardTabProvider =
    NotifierProvider.autoDispose<UserDashboardTabNotifier, int>(
      UserDashboardTabNotifier.new,
    );

class UserDashboardTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    state = index;
  }
}

final dashboardMotorSubmittingProvider =
    NotifierProvider.autoDispose<
      DashboardMotorSubmittingNotifier,
      Map<String, bool>
    >(DashboardMotorSubmittingNotifier.new);

final dashboardValvesExpandedProvider =
    NotifierProvider.autoDispose<
      DashboardValvesExpandedNotifier,
      Map<String, bool>
    >(DashboardValvesExpandedNotifier.new);

final dashboardSearchQueryProvider =
    NotifierProvider.autoDispose<DashboardSearchQueryNotifier, String>(
      DashboardSearchQueryNotifier.new,
    );

class DashboardMotorSubmittingNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => <String, bool>{};

  void setSubmitting(String key, bool value) {
    state = <String, bool>{...state, key: value};
  }
}

class DashboardValvesExpandedNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => <String, bool>{};

  void toggle(String key) {
    final current = state[key] ?? false;
    state = <String, bool>{...state, key: !current};
  }
}

class DashboardSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}
