import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms/shared/theme/theme.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.hintText,
    this.labelText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.capitalizeFirstLetter = true,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final AutovalidateMode autovalidateMode;
  final bool capitalizeFirstLetter;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        obscureText: obscureText,
        maxLines: 1,
        validator: validator,
        onChanged: onChanged,
        autovalidateMode: autovalidateMode,
        inputFormatters: capitalizeFirstLetter
            ? const [_CapitalizeFirstLetterFormatter()]
            : null,
        style: const TextStyle(fontSize: 16),
        strutStyle: const StrutStyle(fontSize: 16, height: 1.2),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          filled: true,
          isDense: true,
          fillColor: AppColors.white,
          labelStyle: const TextStyle(color: AppColors.greyText),
          hintStyle: const TextStyle(color: AppColors.lightGreyText),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
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
      ),
    );
  }
}

class _CapitalizeFirstLetterFormatter extends TextInputFormatter {
  const _CapitalizeFirstLetterFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    final firstLetterIndex = text.indexOf(RegExp(r'[a-zA-Z]'));
    if (firstLetterIndex == -1) {
      return newValue;
    }

    final currentCharacter = text[firstLetterIndex];
    final uppercasedCharacter = currentCharacter.toUpperCase();
    if (currentCharacter == uppercasedCharacter) {
      return newValue;
    }

    final updatedText = text.replaceRange(
      firstLetterIndex,
      firstLetterIndex + 1,
      uppercasedCharacter,
    );
    return newValue.copyWith(
      text: updatedText,
      selection: TextSelection.collapsed(
        offset: newValue.selection.extentOffset,
      ),
      composing: TextRange.empty,
    );
  }
}
