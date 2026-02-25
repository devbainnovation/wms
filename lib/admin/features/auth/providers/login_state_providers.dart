import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminObscurePasswordProvider =
    NotifierProvider.autoDispose<AdminObscurePasswordNotifier, bool>(
      AdminObscurePasswordNotifier.new,
    );

final adminRememberMeProvider =
    NotifierProvider.autoDispose<AdminRememberMeNotifier, bool>(
      AdminRememberMeNotifier.new,
    );

class AdminObscurePasswordNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() {
    state = !state;
  }
}

class AdminRememberMeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) {
    state = value;
  }
}
