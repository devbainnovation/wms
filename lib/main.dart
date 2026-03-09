import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/admin/admin.dart';
import 'package:wms/core/core.dart';
import 'package:wms/firebase_options.dart';
import 'package:wms/shared/shared.dart';
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
        scaffoldBackgroundColor: AppColors.lightBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryTeal,
          primary: AppColors.primaryTeal,
          secondary: AppColors.accentGreen,
          surface: AppColors.white,
          onPrimary: AppColors.white,
          onSurface: AppColors.darkText,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        primaryTextTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.darkText,
          surfaceTintColor: AppColors.white,
          elevation: 2,
          scrolledUnderElevation: 2,
          shadowColor: Color(0x26000000),
          titleTextStyle: TextStyle(
            color: AppColors.darkText,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.lightGreyText),
          ),
        ),
        dividerColor: AppColors.lightGreyText,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColors.primaryTeal,
          selectionHandleColor: AppColors.primaryTeal,
          selectionColor: AppColors.primaryTeal.withValues(alpha: 0.28),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          hintStyle: const TextStyle(color: AppColors.greyText),
          labelStyle: const TextStyle(color: AppColors.greyText),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.lightGreyText),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.primaryTeal,
              width: 1.4,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.lightGreyText),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.white,
          selectedColor: AppColors.lightTeal,
          disabledColor: AppColors.lightGreyText,
          labelStyle: const TextStyle(
            color: AppColors.darkText,
            fontWeight: FontWeight.w600,
          ),
          secondaryLabelStyle: const TextStyle(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: const BorderSide(color: AppColors.lightGreyText),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.darkText,
            side: const BorderSide(color: AppColors.lightGreyText),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1F2937),
          contentTextStyle: TextStyle(color: AppColors.white),
        ),
      ),
      builder: (context, child) {
        return ValueListenableBuilder<int>(
          valueListenable: ApiClient.inFlightRequestCount,
          builder: (context, count, _) {
            final showLoader = count > 0;
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                if (showLoader)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.2),
                      child: const Center(
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
      home: loginScreen,
    );
  }
}
