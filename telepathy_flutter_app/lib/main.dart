import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'app/app_theme.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/device_identity.dart';
import 'services/deep_link_service.dart';
import 'state/app_state_controller.dart';
import 'state/status_controller.dart';
import 'ui/auth/login_screen.dart';
import 'ui/home/home_shell.dart';
import 'ui/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize auth service - authentication will happen when needed
  final authService = AuthService();
  
  // Listen for auth state changes
  authService.authStateChanges.listen((user) {
    debugPrint('Auth state changed: ${user?.uid ?? 'signed out'}');
  });

  final deviceId = await DeviceIdentity.getOrCreateId();
  final appState = AppStateController();
  await appState.load();

  final deepLinkService = DeepLinkService();
  await deepLinkService.initialize();

  final statusController = StatusController(
    deviceId: deviceId,
    appState: appState,
    authService: authService,
  );
  await statusController.initialize();

  // Handle incoming deep links for room joining
  deepLinkService.roomCodeStream.listen((roomCode) {
    if (roomCode != null && !statusController.isConnected) {
      // Auto-join room from deep link
      statusController.joinRoom(roomCode);
    }
  });

  runApp(
    TelepathyApp(
      appState: appState,
      statusController: statusController,
      deepLinkService: deepLinkService,
      authService: authService,
    ),
  );
}

class TelepathyApp extends StatelessWidget {
  const TelepathyApp({
    super.key,
    required this.appState,
    required this.statusController,
    required this.deepLinkService,
    required this.authService,
  });

  final AppStateController appState;
  final StatusController statusController;
  final DeepLinkService deepLinkService;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: statusController),
        ChangeNotifierProvider.value(value: authService),
        Provider.value(value: deepLinkService),
      ],
      child: MaterialApp(
        title: 'Telepathy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.create(),
        home: const AppEntryShell(),
      ),
    );
  }
}

class AppEntryShell extends StatelessWidget {
  const AppEntryShell({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();
    final authService = context.watch<AuthService>();

    if (!appState.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    // Check authentication first
    if (!authService.isAuthenticated) {
      return const LoginScreen();
    }

    if (!appState.onboardingComplete) {
      return const OnboardingScreen();
    }

    return const HomeShell();
  }
}

