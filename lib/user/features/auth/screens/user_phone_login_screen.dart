import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:pinput/pinput.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/auth/providers/providers.dart';

class UserPhoneLoginScreen extends ConsumerStatefulWidget {
  const UserPhoneLoginScreen({super.key});

  @override
  ConsumerState<UserPhoneLoginScreen> createState() => _UserPhoneLoginScreenState();
}

class _UserPhoneLoginScreenState extends ConsumerState<UserPhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    showAppSnackBar(context, message, status: AppSnackBarStatus.error);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    showAppSnackBar(context, message, status: AppSnackBarStatus.success);
  }

  Future<void> _onSendOtp() async {
    await ref.read(userPhoneLoginControllerProvider.notifier).sendOtp(
      onCodeSent: () => _showSuccess('OTP sent successfully'),
      onError: _showError,
    );
  }

  Future<void> _onVerifyOtp() async {
    await ref.read(userPhoneLoginControllerProvider.notifier).verifyOtp(
      otp: _otpController.text,
      onError: _showError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final phoneState = ref.watch(userPhoneLoginControllerProvider);
    final isBusy = phoneState.isVerifying;

    final width = MediaQuery.of(context).size.width;
    final cardWidth = width > 900 ? 430.0 : 380.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.lightBlue, AppColors.lightGreen],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: cardWidth,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.65),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    AppAssets.logo,
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.water_drop_rounded,
                      size: 64,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Phone Login',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    phoneState.isOtpSent 
                      ? 'Enter the code sent to your mobile'
                      : 'Verify your identity via mobile number',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.greyText),
                  ),
                  const SizedBox(height: 24),
                  
                  if (!phoneState.isOtpSent) ...[
                    IntlPhoneField(
                      controller: _phoneController,
                      initialCountryCode: 'IN',
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter mobile number',
                        fillColor: AppColors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.lightGreyText),
                        ),
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
                      ),
                      languageCode: "en",
                      onChanged: (phone) {
                        ref.read(userPhoneLoginControllerProvider.notifier)
                           .updatePhoneNumber(phone.completeNumber);
                      },
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Send OTP',
                      isLoading: isBusy,
                      onPressed: isBusy ? null : _onSendOtp,
                    ),
                    /*
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR', style: TextStyle(color: AppColors.greyText, fontSize: 12)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isBusy ? null : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const UserLoginScreen()),
                        );
                      },
                      icon: const Icon(Icons.person_outline_rounded),
                      label: const Text('Login with Username'),
                    ),
                    */
                  ] else ...[
                    Pinput(
                      length: 6,
                      controller: _otpController,
                      onCompleted: (_) => _onVerifyOtp(),
                      defaultPinTheme: PinTheme(
                        width: 50,
                        height: 56,
                        textStyle: const TextStyle(
                          fontSize: 22,
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightGreyText),
                        ),
                      ),
                      focusedPinTheme: PinTheme(
                        width: 50,
                        height: 56,
                        textStyle: const TextStyle(
                          fontSize: 22,
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryTeal, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      text: 'Verify & Login',
                      isLoading: isBusy,
                      onPressed: isBusy ? null : _onVerifyOtp,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: isBusy ? null : () => ref.read(userPhoneLoginControllerProvider.notifier).reset(),
                      child: const Text('Change Phone Number'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
