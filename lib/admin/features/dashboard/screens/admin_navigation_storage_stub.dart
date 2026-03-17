import 'dart:async';

class AdminNavigationStorage {
  const AdminNavigationStorage();

  String readPath() => '/dashboard';

  Uri readRoute() => Uri(path: readPath());

  void writePath(String path) {}

  void writeRoute(Uri route) {}

  void resetPath() {}

  Stream<void> get changes => const Stream<void>.empty();
}
