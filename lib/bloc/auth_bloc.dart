import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:connectedu_app/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';

// Correct package import for User model
import 'package:connectedu_app/models/user.dart';

// Correctly link the part files
part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc(this.authRepository) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
    on<ProfileUpdated>(_onProfileUpdated);
    on<PasswordChanged>(_onPasswordChanged);
  }

  Future<void> _onPasswordChanged(PasswordChanged event, Emitter<AuthState> emit) async {
    // We can only update if we are already authenticated
    if (state is AuthAuthenticated) {
      final currentUser = (state as AuthAuthenticated).user;

      // 1. Emit isUpdating=true
      emit((state as AuthAuthenticated).copyWith(isUpdating: true));

      try {
        // 2. Call the repository
        await authRepository.changePassword(
          currentPassword: event.currentPassword,
          newPassword: event.newPassword,
        );

        // 3. Emit success
        // We can reuse AuthUpdateSuccess since it just pops the screen
        emit(AuthUpdateSuccess(user: currentUser));

      } catch (e) {
        debugPrint('Password Change Error: $e');
        // 4. Emit failure, but keep the user logged in
        emit(AuthUpdateFailure(
          error: e.toString().replaceFirst('Exception: ', ''),
          user: currentUser,
        ));
      }
    }
  }

  // This handler checks for an existing token on app start
  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final bool hasToken = await authRepository.hasToken();
    if (hasToken) {
      try {
        final user = await authRepository.getUserFromToken();
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthUnauthenticated());
        }
      } catch (e) {
        debugPrint('AppStarted Error: $e');
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  // This handler processes the login attempt from the login screen
  void _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Call the repository with email and password
      final user = await authRepository.login(event.email, event.password);
      // Emit Authenticated on success
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      debugPrint('Login Error: $e');
      emit(AuthFailure(error: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onProfileUpdated(ProfileUpdated event, Emitter<AuthState> emit) async {
    // We can only update if we are already authenticated
    if (state is AuthAuthenticated) {
      final currentUser = (state as AuthAuthenticated).user;

      // 1. Emit isUpdating=true to show loading on EditProfileScreen
      emit(AuthAuthenticated(user: currentUser, isUpdating: true));

      try {
        // 2. Call the repository
        final updatedUser = await authRepository.updateProfile(
          phone: event.phone,
          profileImageUrl: event.profileImageUrl,
        );

        // 3. Emit success with the new user object
        emit(AuthUpdateSuccess(user: updatedUser));

      } catch (e) {
        debugPrint('Profile Update Error: $e');
        // 4. Emit failure, but keep the user logged in with their OLD data
        emit(AuthUpdateFailure(
          error: e.toString().replaceFirst('Exception: ', ''),
          user: currentUser,
        ));
      }
    }
  }

  // This handler processes the logout action
  void _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading()); // Show loading while logging out
    await authRepository.logout();
    emit(AuthUnauthenticated());
  }
}

