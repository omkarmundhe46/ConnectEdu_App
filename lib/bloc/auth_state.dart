part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  // This will tell the UI if an update is happening in the background
  final bool isUpdating;

  const AuthAuthenticated({required this.user, this.isUpdating = false}); // Add default value

  @override
  List<Object> get props => [user, isUpdating];
  // Helper to create a copy
  AuthAuthenticated copyWith({
    User? user,
    bool? isUpdating,
  }) {
    return AuthAuthenticated(
      user: user ?? this.user,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}

class AuthUnauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String error;
  const AuthFailure({required this.error});

  @override
  List<Object> get props => [error];


}
// --- ADD THESE NEW STATES ---

// State when profile update is successful
// We use this to signal to the EditProfileScreen to pop
class AuthUpdateSuccess extends AuthAuthenticated {
  const AuthUpdateSuccess({required super.user}) : super(isUpdating: false);
}

// State when profile update fails
// This keeps the user logged in with their OLD data
class AuthUpdateFailure extends AuthAuthenticated {
  final String error;
  const AuthUpdateFailure({required this.error, required super.user}) : super(isUpdating: false);

  @override
  List<Object> get props => [user, isUpdating, error];
}
// --- END OF NEW STATES ---

