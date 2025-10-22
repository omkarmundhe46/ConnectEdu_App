part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated({required this.user});

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthLoading extends AuthState {}

class AuthFailure extends AuthState {
  final String error;
  const AuthFailure({required this.error});

  @override
  List<Object> get props => [error];
}

