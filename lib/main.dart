import 'package:connectedu_app/bloc/auth_bloc.dart';
import 'package:connectedu_app/bloc/home_bloc.dart';
import 'package:connectedu_app/repositories/auth_repository.dart';
import 'package:connectedu_app/repositories/certificate-service.dart';
import 'package:connectedu_app/repositories/club_repository.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
import 'package:connectedu_app/screens/auth_navigator.dart';
import 'package:connectedu_app/screens/home_screen.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:connectedu_app/services/secure_storage_service.dart';
import 'package:connectedu_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  // Initialize services and repositories ONCE here
  final SecureStorageService secureStorageService = SecureStorageService();
  final ApiService apiService = ApiService(secureStorageService); // Pass storage service
  final AuthRepository authRepository = AuthRepository(apiService, secureStorageService);
  final ClubRepository clubRepository = ClubRepository(apiService);
  final EventRepository eventRepository = EventRepository(apiService);
  final CertificateRepository certificateRepository = CertificateRepository(apiService);

  runApp(
    // Provide repositories to the entire widget tree
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: clubRepository),
        RepositoryProvider.value(value: eventRepository),
        RepositoryProvider.value(value: apiService), // Provide ApiService too
        RepositoryProvider.value(value: secureStorageService), // Provide StorageService
        RepositoryProvider.value(value: certificateRepository),
      ],
      // Provide the AuthBloc at the top level
      child: BlocProvider(
        create: (context) => AuthBloc(authRepository)..add(AppStarted()),
        child: const MyApp(), // MyApp doesn't need constructor arguments now
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConnectEdu',
      theme: AppTheme.lightTheme, // Use custom light theme
      darkTheme: AppTheme.darkTheme, // Use custom dark theme
      themeMode: ThemeMode.system, // Follow system light/dark mode setting
      debugShowCheckedModeBanner: false,
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            // If authenticated, provide HomeBloc and show HomeScreen
            return BlocProvider(
              create: (context) => HomeBloc(
                // Read repositories from the context provided above
                clubRepository: context.read<ClubRepository>(),
                eventRepository: context.read<EventRepository>(),
              )..add(LoadHomeData()), // Load data when HomeBloc is created
              child: HomeScreen(user: state.user),
            );
          }
          if (state is AuthUnauthenticated || state is AuthFailure) {
            // If unauthenticated, show the AuthNavigator (Login/Signup)
            return const AuthNavigator();
          }
          // Show loading indicator while checking authentication status initially
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

