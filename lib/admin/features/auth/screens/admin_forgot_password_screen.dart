import 'package:flutter/material.dart';
import 'package:wms/shared/shared.dart';

class AdminForgotPasswordScreen extends StatefulWidget {
  const AdminForgotPasswordScreen({super.key});

  @override
  State<AdminForgotPasswordScreen> createState() =>
      _AdminForgotPasswordScreenState();
}

class _AdminForgotPasswordScreenState extends State<AdminForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width > 900 ? 460.0 : 390.0;

    return Scaffold(
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
            padding: const EdgeInsets.all(24),
            child: Container(
              width: cardWidth,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.93),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.65),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppAssets.logo,
                      height: 115,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.water_drop_rounded,
                        size: 76,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Forgot Password',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your admin email and submit. API binding will be connected later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.greyText),
                    ),
                    const SizedBox(height: 22),
                    AppTextField(
                      controller: _emailController,
                      hintText: 'Enter email address',
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: AppValidators.email,
                    ),
                    const SizedBox(height: 14),
                    AppButton(text: 'Submit', onPressed: _onSubmit),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Back to login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
