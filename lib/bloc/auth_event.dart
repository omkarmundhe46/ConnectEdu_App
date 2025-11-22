part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

// This is the correct event dispatched from the login screen
class LoggedIn extends AuthEvent {
  final String email;
  final String password;

  const LoggedIn({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class LoggedOut extends AuthEvent {}

class ProfileUpdated extends AuthEvent {
  final String? phone;
  final String? profileImageUrl;

  const ProfileUpdated({this.phone, this.profileImageUrl});

  @override
  List<Object?> get props => [phone, profileImageUrl];
}



class PasswordChanged extends AuthEvent {
  final String currentPassword;
  final String newPassword;

  const PasswordChanged({required this.currentPassword, required this.newPassword});

  @override
  List<Object> get props => [currentPassword, newPassword];
}

class LoggedInWithToken extends AuthEvent {
  final String token;
  const LoggedInWithToken({required this.token});

  @override
  List<Object?> get props => [token];
}

