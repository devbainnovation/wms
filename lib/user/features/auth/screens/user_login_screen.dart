import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/auth/screens/user_forgot_password_screen.dart';
import 'package:wms/user/features/auth/providers/providers.dart';
import 'package:wms/user/features/dashboard/screens/user_dashboard_screen.dart';

class UserLoginScreen extends ConsumerStatefulWidget {
  const UserLoginScreen({super.key});

  @override
  ConsumerState<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends ConsumerState<UserLoginScreen> {
  static const _tempEmail = 'user@gmail.com';
  static const _tempPassword = '123456';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = _tempEmail;
    _passwordController.text = _tempPassword;
  }

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

    final enteredEmail = _emailController.text.trim().toLowerCase();
    final enteredPassword = _passwordController.text.trim();
    final validTempLogin =
        enteredEmail == _tempEmail && enteredPassword == _tempPassword;

    if (!validTempLogin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use temp login: user@gmail.com / 123456'),
        ),
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
      (route) => false,
    );
  }

  Future<void> _onForgotPasswordTap() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const UserForgotPasswordScreen()),
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
    final obscurePassword = ref.watch(userObscurePasswordProvider);
    final rememberMe = ref.watch(userRememberMeProvider);
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width > 900 ? 430.0 : 380.0;

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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppAssets.logo,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.water_drop_rounded,
                        size: 72,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'User Login',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Access your water management dashboard',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.greyText),
                    ),
                    const SizedBox(height: 20),
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
                              .read(userObscurePasswordProvider.notifier)
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
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              ref
                                  .read(userRememberMeProvider.notifier)
                                  .set(!rememberMe);
                            },
                            child: Row(
                              children: [
                                Checkbox(
                                  value: rememberMe,
                                  onChanged: (value) {
                                    ref
                                        .read(userRememberMeProvider.notifier)
                                        .set(value ?? false);
                                  },
                                  activeColor: AppColors.primaryTeal,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                const Flexible(
                                  child: Text(
                                    'Remember me',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: _onForgotPasswordTap,
                          child: const Text('Forgot password?'),
                        ),
                      ],
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
