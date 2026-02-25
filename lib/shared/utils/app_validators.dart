class AppValidators {
  AppValidators._();

  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(input)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? emailOrMobile(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Email or mobile number is required';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    final isValid = emailRegex.hasMatch(input) || phoneRegex.hasMatch(input);

    if (!isValid) {
      return 'Enter a valid email or mobile number';
    }
    return null;
  }

  static String? password(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Password is required';
    }
    if (input.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}
