import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/admin/admin.dart';
import 'package:wms/core/core.dart';
import 'package:wms/firebase_options.dart';
import 'package:wms/user/user.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: WmsApp()));
}

class WmsApp extends ConsumerWidget {
  const WmsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pushNotificationInitProvider);
    ref.listen(fcmTokenProvider, (_, next) {
      next.whenData((token) {
        if (token != null && token.isNotEmpty) {
          debugPrint('FCM token: $token');
        }
      });
    });

    final loginScreen = kIsWeb
        ? const AdminLoginScreen()
        : const UserLoginScreen();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        primaryTextTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: loginScreen,
    );
  }
}
