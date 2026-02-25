import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/admin.dart';
import 'package:wms/user/user.dart';

void main() {
  runApp(const ProviderScope(child: WmsApp()));
}

class WmsApp extends StatelessWidget {
  const WmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final loginScreen = kIsWeb
        ? const AdminLoginScreen()
        : const UserLoginScreen();

    return MaterialApp(debugShowCheckedModeBanner: false, home: loginScreen);
  }
}
