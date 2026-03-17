// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

class AuthWebStorage {
  const AuthWebStorage();

  Future<void> write(String key, String value) async {
    html.window.sessionStorage[key] = value;
  }

  Future<String?> read(String key) async {
    return html.window.sessionStorage[key];
  }

  Future<void> delete(String key) async {
    html.window.sessionStorage.remove(key);
  }
}
