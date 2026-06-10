class AuthState {
  final String? currentUserId;
  final List<String> availableUsers;

  const AuthState({
    this.currentUserId,
    this.availableUsers = const ['user_1', 'user_2', 'user_3', 'user_4', 'user_5'],
  });

  bool get isAuthenticated => currentUserId != null;

  AuthState copyWith({
    String? currentUserId,
    bool clearUser = false,
    List<String>? availableUsers,
  }) {
    return AuthState(
      currentUserId: clearUser ? null : (currentUserId ?? this.currentUserId),
      availableUsers: availableUsers ?? this.availableUsers,
    );
  }
}
