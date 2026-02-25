import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/auth/providers/providers.dart';
import 'package:wms/admin/features/auth/screens/admin_forgot_password_screen.dart';
import 'package:wms/shared/shared.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginTap() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login API will be connected later.')),
    );
  }

  Future<void> _onForgotPasswordTap() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AdminForgotPasswordScreen()),
    );

    if (!mounted || result != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset request submitted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final obscurePassword = ref.watch(adminObscurePasswordProvider);
    final rememberMe = ref.watch(adminRememberMeProvider);
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
                      height: 130,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.water_drop_rounded,
                        size: 76,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Admin Login',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sign in to manage users, devices and operations',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.greyText),
                    ),
                    const SizedBox(height: 22),
                    AppTextField(
                      controller: _emailController,
                      hintText: 'Enter email or mobile number',
                      labelText: 'Email / Mobile',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      validator: AppValidators.emailOrMobile,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _passwordController,
                      hintText: 'Enter password',
                      labelText: 'Password',
                      obscureText: obscurePassword,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () {
                          ref
                              .read(adminObscurePasswordProvider.notifier)
                              .toggle();
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                      validator: AppValidators.password,
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 360) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: rememberMe,
                                    onChanged: (value) {
                                      ref
                                          .read(
                                            adminRememberMeProvider.notifier,
                                          )
                                          .set(value ?? false);
                                    },
                                    activeColor: AppColors.primaryTeal,
                                  ),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      ref
                                          .read(
                                            adminRememberMeProvider.notifier,
                                          )
                                          .set(!rememberMe);
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 8,
                                      ),
                                      child: Text('Remember me'),
                                    ),
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _onForgotPasswordTap,
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              onChanged: (value) {
                                ref
                                    .read(adminRememberMeProvider.notifier)
                                    .set(value ?? false);
                              },
                              activeColor: AppColors.primaryTeal,
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                ref
                                    .read(adminRememberMeProvider.notifier)
                                    .set(!rememberMe);
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                                child: Text('Remember me'),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _onForgotPasswordTap,
                              child: const Text('Forgot password?'),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    AppButton(text: 'Login', onPressed: _onLoginTap),
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
