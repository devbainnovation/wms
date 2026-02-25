import 'package:flutter_riverpod/flutter_riverpod.dart';

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
