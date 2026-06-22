import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';

final userObscurePasswordProvider =
    NotifierProvider.autoDispose<UserObscurePasswordNotifier, bool>(
      UserObscurePasswordNotifier.new,
    );

final userRememberMeProvider =
    NotifierProvider.autoDispose<UserRememberMeNotifier, bool>(
      UserRememberMeNotifier.new,
    );

class UserObscurePasswordNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() {
    state = !state;
  }
}

class UserRememberMeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) {
    state = value;
  }
}

class UserPhoneLoginState {
  final String verificationId;
  final String completePhoneNumber;
  final bool isOtpSent;
  final bool isVerifying;
  final String? error;

  UserPhoneLoginState({
    this.verificationId = '',
    this.completePhoneNumber = '',
    this.isOtpSent = false,
    this.isVerifying = false,
    this.error,
  });

  UserPhoneLoginState copyWith({
    String? verificationId,
    String? completePhoneNumber,
    bool? isOtpSent,
    bool? isVerifying,
    String? error,
    bool clearError = false,
  }) {
    return UserPhoneLoginState(
      verificationId: verificationId ?? this.verificationId,
      completePhoneNumber: completePhoneNumber ?? this.completePhoneNumber,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      isVerifying: isVerifying ?? this.isVerifying,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final userPhoneLoginControllerProvider =
    NotifierProvider<UserPhoneLoginController, UserPhoneLoginState>(
      UserPhoneLoginController.new,
    );

class UserPhoneLoginController extends Notifier<UserPhoneLoginState> {
  @override
  UserPhoneLoginState build() => UserPhoneLoginState();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void updatePhoneNumber(String phone) {
    state = state.copyWith(completePhoneNumber: phone);
  }

  Future<void> sendOtp({
    required VoidCallback onCodeSent,
    required void Function(String) onError,
  }) async {
    if (state.completePhoneNumber.isEmpty) {
      onError('Please enter a valid phone number');
      return;
    }

    state = state.copyWith(isVerifying: true, clearError: true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: state.completePhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential, onError);
        },
        verificationFailed: (FirebaseAuthException e) {
          state = state.copyWith(isVerifying: false, error: e.message);
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          state = state.copyWith(
            verificationId: verificationId,
            isOtpSent: true,
            isVerifying: false,
          );
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          state = state.copyWith(verificationId: verificationId);
        },
      );
    } catch (e) {
      state = state.copyWith(isVerifying: false, error: e.toString());
      onError('Error sending OTP: $e');
    }
  }

  Future<void> verifyOtp({
    required String otp,
    required void Function(String) onError,
  }) async {
    if (otp.length != 6) {
      onError('Please enter the 6-digit OTP');
      return;
    }

    state = state.copyWith(isVerifying: true, clearError: true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId,
        smsCode: otp,
      );
      await _signInWithCredential(credential, onError);
    } catch (e) {
      state = state.copyWith(isVerifying: false, error: 'Invalid OTP');
      onError('Invalid OTP. Please try again.');
    }
  }

  Future<void> _signInWithCredential(
    PhoneAuthCredential credential,
    void Function(String) onError,
  ) async {
    // Prevent duplicate calls if already verifying
    if (state.isVerifying && state.isOtpSent && state.verificationId.isEmpty) {
      // This is a safety check for auto-verification on Android
    }
    
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Clear verifying state so subsequent (manual) attempts are blocked or ignored
        // while we process the token exchange.
        final idToken = await user.getIdToken();
        
        // Ensure we only proceed if we haven't already established a session
        final currentSession = ref.read(currentAuthSessionProvider);
        if (currentSession != null) return;

        if (idToken != null) {
          final appDeviceInfoService = ref.read(appDeviceInfoServiceProvider);
          final deviceInfo = await appDeviceInfoService.buildDeviceInfo();
          final fcmToken = await _readFcmTokenSafely();

          await ref.read(authLoginControllerProvider.notifier).loginWithFirebase(
            firebaseIdToken: idToken,
            phoneNumber: state.completePhoneNumber,
            deviceInfo: deviceInfo,
            fcmToken: fcmToken,
          );
        }
      }
    } catch (e) {
      state = state.copyWith(isVerifying: false, error: e.toString());
      final message = e is AuthApiException ? e.message : 'Login failed: $e';
      onError(message);
    }
  }

  Future<String?> _readFcmTokenSafely() async {
    final appDeviceInfoService = ref.read(appDeviceInfoServiceProvider);
    if (!appDeviceInfoService.shouldAttachFcmToken) return null;
    try {
      return await ref.read(pushNotificationServiceProvider).getToken();
    } catch (error) {
      debugPrint('FCM token unavailable during login: $error');
      return null;
    }
  }

  void reset() {
    state = UserPhoneLoginState();
  }
}
