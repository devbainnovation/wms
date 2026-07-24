import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  final Country _selectedCountry = Country(
    phoneCode: "91",
    countryCode: "IN",
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: "India",
    example: "9123456789",
    displayName: "India (IN) [+91]",
    displayNameNoCountryCode: "India (IN)",
    e164Key: "91-IN-0",
  );

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
            child: _LoginCard(
              selectedCountry: _selectedCountry,
              phoneController: _phoneController,
              otpController: _otpController,
              onSendOtp: _onSendOtp,
              onVerifyOtp: _onVerifyOtp,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends ConsumerWidget {
  const _LoginCard({
    required this.selectedCountry,
    required this.phoneController,
    required this.otpController,
    required this.onSendOtp,
    required this.onVerifyOtp,
  });

  final Country selectedCountry;
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneState = ref.watch(userPhoneLoginControllerProvider);
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width > 900 ? 430.0 : 380.0;

    return Container(
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
          const _LoginHeader(),
          const SizedBox(height: 24),
          if (!phoneState.isOtpSent)
            _PhoneInputSection(
              selectedCountry: selectedCountry,
              phoneController: phoneController,
              onSendOtp: onSendOtp,
              isLoading: phoneState.isVerifying,
            )
          else
            _OtpInputSection(
              otpController: otpController,
              onVerifyOtp: onVerifyOtp,
              isLoading: phoneState.isVerifying,
            ),
        ],
      ),
    );
  }
}

class _LoginHeader extends ConsumerWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneState = ref.watch(userPhoneLoginControllerProvider);

    return Column(
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
          'Welcome To Di-WMS',
          textAlign: TextAlign.center,
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
      ],
    );
  }
}

class _PhoneInputSection extends ConsumerWidget {
  const _PhoneInputSection({
    required this.selectedCountry,
    required this.phoneController,
    required this.onSendOtp,
    required this.isLoading,
  });

  final Country selectedCountry;
  final TextEditingController phoneController;
  final VoidCallback onSendOtp;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter mobile number',
            fillColor: AppColors.white,
            filled: true,
            prefixIcon: _CountryPrefix(selectedCountry: selectedCountry),
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
          onChanged: (value) {
            ref.read(userPhoneLoginControllerProvider.notifier).updatePhoneNumber(
                  '+${selectedCountry.phoneCode}$value',
                );
          },
        ),
        const SizedBox(height: 16),
        AppButton(
          text: 'Send OTP',
          isLoading: isLoading,
          onPressed: isLoading ? null : onSendOtp,
        ),
      ],
    );
  }
}

class _CountryPrefix extends StatelessWidget {
  const _CountryPrefix({required this.selectedCountry});

  final Country selectedCountry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedCountry.flagEmoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Text(
            '+${selectedCountry.phoneCode}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            height: 24,
            child: VerticalDivider(
              color: AppColors.lightGreyText,
              thickness: 1,
              width: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpInputSection extends ConsumerWidget {
  const _OtpInputSection({
    required this.otpController,
    required this.onVerifyOtp,
    required this.isLoading,
  });

  final TextEditingController otpController;
  final VoidCallback onVerifyOtp;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Pinput(
          length: 6,
          controller: otpController,
          onCompleted: (_) => onVerifyOtp(),
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
          isLoading: isLoading,
          onPressed: isLoading ? null : onVerifyOtp,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: isLoading
              ? null
              : () => ref.read(userPhoneLoginControllerProvider.notifier).reset(),
          child: const Text('Change Phone Number'),
        ),
      ],
    );
  }
}
