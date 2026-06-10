import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  void login(String userId) {
    state = state.copyWith(currentUserId: userId);
  }

  void logout() {
    state = state.copyWith(clearUser: true);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
