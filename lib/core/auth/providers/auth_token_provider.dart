import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/auth/providers/auth_providers.dart';

/// Resolves the auth bearer token from the active session, falling back
/// to remembered credentials in local storage if the session has not yet
/// been loaded into memory.
Future<String> resolveAuthToken(Ref ref) async {
  final session = ref.read(currentAuthSessionProvider);
  var token = (session?.token ?? '').trim();
  if (token.isNotEmpty) {
    return token;
  }

  final remembered = await ref.read(authLocalStorageProvider).loadLoginData();
  token = (remembered?.token ?? '').trim();
  return token;
}

/// Convenience provider for reading or watching the resolved auth token.
final authTokenProvider = FutureProvider<String>((ref) => resolveAuthToken(ref));
