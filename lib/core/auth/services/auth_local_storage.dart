import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms/core/auth/models/auth_models.dart';
import 'auth_web_storage_stub.dart'
    if (dart.library.html) 'auth_web_storage.dart';

class AuthLocalStorage {
  const AuthLocalStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(),
          ),
      _webStorage = const AuthWebStorage();

  final FlutterSecureStorage _secureStorage;
  final AuthWebStorage _webStorage;

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
      if (kIsWeb) {
        await Future.wait([
          _webStorage.write(_tokenKey, session.token),
          _webStorage.write(_roleKey, session.role),
          _webStorage.write(_userIdKey, session.userId),
          _webStorage.write(_sessionIdKey, session.sessionId),
        ]);
        return;
      }
      return;
    }

    await prefs.setBool(_rememberMeKey, true);
    if (kIsWeb) {
      await Future.wait([
        prefs.setString(_usernameKey, username),
        prefs.setString(_passwordKey, password),
        prefs.setString(_tokenKey, session.token),
        prefs.setString(_roleKey, session.role),
        prefs.setString(_userIdKey, session.userId),
        prefs.setString(_sessionIdKey, session.sessionId),
        _webStorage.write(_tokenKey, session.token),
        _webStorage.write(_roleKey, session.role),
        _webStorage.write(_userIdKey, session.userId),
        _webStorage.write(_sessionIdKey, session.sessionId),
      ]);
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

    if (kIsWeb) {
      final webToken =
          await _webStorage.read(_tokenKey) ?? prefs.getString(_tokenKey) ?? '';
      final webRole =
          await _webStorage.read(_roleKey) ?? prefs.getString(_roleKey) ?? '';
      final webUserId =
          await _webStorage.read(_userIdKey) ??
          prefs.getString(_userIdKey) ??
          '';
      final webSessionId =
          await _webStorage.read(_sessionIdKey) ??
          prefs.getString(_sessionIdKey) ??
          '';

      final hasSession =
          webToken.isNotEmpty &&
          webRole.isNotEmpty &&
          webUserId.isNotEmpty &&
          webSessionId.isNotEmpty;
      if (!remember && !hasSession) {
        return null;
      }

      return RememberedAuthData(
        username: remember ? (prefs.getString(_usernameKey) ?? '') : '',
        password: remember ? (prefs.getString(_passwordKey) ?? '') : '',
        token: webToken,
        role: webRole,
        userId: webUserId,
        sessionId: webSessionId,
        rememberMe: remember,
      );
    }

    if (!remember) {
      return null;
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
    } else {
      tasks.addAll([
        _webStorage.delete(_tokenKey),
        _webStorage.delete(_roleKey),
        _webStorage.delete(_userIdKey),
        _webStorage.delete(_sessionIdKey),
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
    } else {
      tasks.addAll([
        _webStorage.delete(_tokenKey),
        _webStorage.delete(_roleKey),
        _webStorage.delete(_userIdKey),
        _webStorage.delete(_sessionIdKey),
      ]);
    }
    await Future.wait(tasks);
  }
}
