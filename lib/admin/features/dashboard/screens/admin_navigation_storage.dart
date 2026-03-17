import 'dart:async';

// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

class AdminNavigationStorage {
  const AdminNavigationStorage();

  static const _defaultPath = '/dashboard';

  Uri readRoute() {
    final pathname = (html.window.location.pathname ?? '').trim();
    final search = (html.window.location.search ?? '').trim();
    final hasPathRoute = pathname.isNotEmpty && pathname != '/';
    if (hasPathRoute) {
      return Uri.parse('$pathname$search');
    }

    final rawHash = html.window.location.hash.trim();
    if (rawHash.isEmpty) {
      return Uri(path: _defaultPath);
    }

    final normalized = rawHash.startsWith('#') ? rawHash.substring(1) : rawHash;
    if (normalized.isEmpty) {
      return Uri(path: _defaultPath);
    }

    return Uri.parse(normalized.startsWith('/') ? normalized : '/$normalized');
  }

  String readPath() {
    return readRoute().path;
  }

  void writePath(String path) {
    writeRoute(Uri(path: path.startsWith('/') ? path : '/$path'));
  }

  void writeRoute(Uri route) {
    final normalizedPath = route.path.startsWith('/')
        ? route.path
        : '/${route.path}';
    final normalizedRoute = Uri(
      path: normalizedPath,
      queryParameters: route.queryParameters.isEmpty
          ? null
          : route.queryParameters,
    );
    final nextUrl = normalizedRoute.toString();
    final currentUrl =
        '${html.window.location.pathname}${html.window.location.search}';
    if (currentUrl == nextUrl || html.window.location.hash == '#$nextUrl') {
      return;
    }
    html.window.history.pushState(null, '', nextUrl);
  }

  void resetPath() {
    writePath(_defaultPath);
  }

  Stream<void> get changes => html.window.onPopState.map((_) {});
}
