import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:connectedu_app/repositories/auth_repository.dart';

import '../models/user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc(this.authRepository) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
  }

  void _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final hasToken = await authRepository.hasToken();
    if (hasToken) {
      final user = await authRepository.getUserFromToken();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  void _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.login(event.email, event.password);
      final user = await authRepository.getUserFromToken();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthFailure(error: "Could not retrieve user details from token."));
      }
    } catch (e) {
      emit(AuthFailure(error: "Login failed. Please check your credentials."));
    }
  }

  void _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await authRepository.logout();
    emit(AuthUnauthenticated());
  }
}

