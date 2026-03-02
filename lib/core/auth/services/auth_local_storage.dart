import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms/core/auth/models/auth_models.dart';

class AuthLocalStorage {
  const AuthLocalStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(),
          );

  final FlutterSecureStorage _secureStorage;

  static const _rememberMeKey = 'auth.remember_me';
  static const _usernameKey = 'auth.username';
  static const _passwordKey = 'auth.password';
  static const _tokenKey = 'auth.token';
  static const _roleKey = 'auth.role';
  static const _userIdKey = 'auth.user_id';
  static const _sessionIdKey = 'auth.session_id';

  Future<void> saveLoginData({
    required bool rememberMe,
    required String username,
    required String password,
    required AuthSession session,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (!rememberMe) {
      await clear();
      await prefs.setBool(_rememberMeKey, false);
      return;
    }

    await prefs.setBool(_rememberMeKey, true);
    if (kIsWeb) {
      await prefs.setString(_usernameKey, username);
      await prefs.setString(_passwordKey, password);
      await prefs.setString(_tokenKey, session.token);
      await prefs.setString(_roleKey, session.role);
      await prefs.setString(_userIdKey, session.userId);
      await prefs.setString(_sessionIdKey, session.sessionId);
      return;
    }

    await Future.wait([
      _secureStorage.write(key: _usernameKey, value: username),
      _secureStorage.write(key: _passwordKey, value: password),
      _secureStorage.write(key: _tokenKey, value: session.token),
      _secureStorage.write(key: _roleKey, value: session.role),
      _secureStorage.write(key: _userIdKey, value: session.userId),
      _secureStorage.write(key: _sessionIdKey, value: session.sessionId),
    ]);
  }

  Future<RememberedAuthData?> loadLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_rememberMeKey) ?? false;
    if (!remember) {
      return null;
    }

    if (kIsWeb) {
      return RememberedAuthData(
        username: prefs.getString(_usernameKey) ?? '',
        password: prefs.getString(_passwordKey) ?? '',
        token: prefs.getString(_tokenKey) ?? '',
        role: prefs.getString(_roleKey) ?? '',
        userId: prefs.getString(_userIdKey) ?? '',
        sessionId: prefs.getString(_sessionIdKey) ?? '',
        rememberMe: true,
      );
    }

    final values = await Future.wait<String?>([
      _secureStorage.read(key: _usernameKey),
      _secureStorage.read(key: _passwordKey),
      _secureStorage.read(key: _tokenKey),
      _secureStorage.read(key: _roleKey),
      _secureStorage.read(key: _userIdKey),
      _secureStorage.read(key: _sessionIdKey),
    ]);

    return RememberedAuthData(
      username: values[0] ?? '',
      password: values[1] ?? '',
      token: values[2] ?? '',
      role: values[3] ?? '',
      userId: values[4] ?? '',
      sessionId: values[5] ?? '',
      rememberMe: true,
    );
  }

  Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  Future<void> clearSessionDataOnly() async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = <Future<void>>[
      prefs.remove(_tokenKey),
      prefs.remove(_roleKey),
      prefs.remove(_userIdKey),
      prefs.remove(_sessionIdKey),
    ];

    if (!kIsWeb) {
      tasks.addAll([
        _secureStorage.delete(key: _tokenKey),
        _secureStorage.delete(key: _roleKey),
        _secureStorage.delete(key: _userIdKey),
        _secureStorage.delete(key: _sessionIdKey),
      ]);
    }

    await Future.wait(tasks);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = <Future<void>>[
      prefs.remove(_rememberMeKey),
      prefs.remove(_usernameKey),
      prefs.remove(_passwordKey),
      prefs.remove(_tokenKey),
      prefs.remove(_roleKey),
      prefs.remove(_userIdKey),
      prefs.remove(_sessionIdKey),
    ];
    if (!kIsWeb) {
      tasks.addAll([
        _secureStorage.delete(key: _usernameKey),
        _secureStorage.delete(key: _passwordKey),
        _secureStorage.delete(key: _tokenKey),
        _secureStorage.delete(key: _roleKey),
        _secureStorage.delete(key: _userIdKey),
        _secureStorage.delete(key: _sessionIdKey),
      ]);
    }
    await Future.wait(tasks);
  }
}
