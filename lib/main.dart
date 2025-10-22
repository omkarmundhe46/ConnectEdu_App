import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectedu_app/bloc/auth_bloc.dart';
import 'package:connectedu_app/bloc/home_bloc.dart';
import 'package:connectedu_app/repositories/auth_repository.dart';
import 'package:connectedu_app/repositories/club_repository.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
import 'package:connectedu_app/screens/auth_navigator.dart';
import 'package:connectedu_app/screens/home_screen.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:connectedu_app/services/secure_storage_service.dart';
import 'package:connectedu_app/theme/theme.dart';

void main() {
  // Initialize services and repositories
  final SecureStorageService secureStorageService = SecureStorageService();
  final ApiService apiService = ApiService(secureStorageService);
  final AuthRepository authRepository = AuthRepository(apiService, secureStorageService);
  final ClubRepository clubRepository = ClubRepository(apiService);
  final EventRepository eventRepository = EventRepository(apiService);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: clubRepository),
        RepositoryProvider.value(value: eventRepository),
      ],
      child: BlocProvider(
        create: (context) => AuthBloc(authRepository)..add(AppStarted()),
        child: const MyApp(),
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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return BlocProvider(
              create: (context) => HomeBloc(
                clubRepository: context.read<ClubRepository>(),
                eventRepository: context.read<EventRepository>(),
              )..add(LoadHomeData()),
              child: HomeScreen(user: state.user),
            );
          }
          if (state is AuthUnauthenticated || state is AuthFailure) {
            return const AuthNavigator();
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

