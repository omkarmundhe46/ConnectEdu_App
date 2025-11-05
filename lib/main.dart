import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:connectedu_app/bloc/auth_bloc.dart';
import 'package:connectedu_app/bloc/home_bloc.dart';
import 'package:connectedu_app/repositories/auth_repository.dart';
import 'package:connectedu_app/repositories/certificate-service.dart';
import 'package:connectedu_app/repositories/club_repository.dart';
import 'package:connectedu_app/repositories/event_repository.dart';
import 'package:connectedu_app/repositories/notification_repository.dart';
import 'package:connectedu_app/screens/auth_navigator.dart';
import 'package:connectedu_app/screens/home_screen.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:connectedu_app/services/secure_storage_service.dart';
import 'package:connectedu_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  final SecureStorageService secureStorageService = SecureStorageService();
  final ApiService apiService = ApiService(secureStorageService); // Pass storage service
  final AuthRepository authRepository = AuthRepository(apiService, secureStorageService);
  final ClubRepository clubRepository = ClubRepository(apiService);
  final EventRepository eventRepository = EventRepository(apiService);
  final CertificateRepository certificateRepository = CertificateRepository(apiService);
  final NotificationRepository notificationRepository = NotificationRepository(apiService);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: clubRepository),
        RepositoryProvider.value(value: eventRepository),
        RepositoryProvider.value(value: apiService),
        RepositoryProvider.value(value: secureStorageService),
        RepositoryProvider.value(value: certificateRepository),
        RepositoryProvider.value(value: notificationRepository),
      ],
      child: BlocProvider(
        create: (context) => AuthBloc(context.read<AuthRepository>())..add(AppStarted()),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initAppLinks();
  }
  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initAppLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }

      _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
        _handleDeepLink(uri);
      }, onError: (err) {
        debugPrint('app_links error: $err');
      });

    } on PlatformException {
      debugPrint('Failed to initialize app_links');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received deep link: $uri');

    if (uri.scheme == 'connectedu' && uri.host == 'login') {

      final token = uri.queryParameters['token'];
      if (token != null) {
        debugPrint(
            'Extracted token from deep link. Dispatching LoggedInWithToken.');

        context.read<AuthBloc>().add(LoggedInWithToken(token: token));
      } else {
        debugPrint('Deep link did not contain a token.');
      }
    }
  }

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
          if (state is AuthUnauthenticated || state is AuthFailure || state is AuthLoading) {
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

