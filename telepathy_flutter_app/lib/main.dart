import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'app/app_theme.dart';
import 'firebase_options.dart';
import 'services/device_identity.dart';
import 'services/deep_link_service.dart';
import 'state/app_state_controller.dart';
import 'state/status_controller.dart';
import 'ui/home/home_shell.dart';
import 'ui/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Sign in anonymously for Firestore access
  try {
    debugPrint('Starting anonymous authentication...');
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    debugPrint('Anonymous auth successful: ${userCredential.user?.uid}');

    // Verify the user is actually authenticated
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      debugPrint('Current user confirmed: ${currentUser.uid}');
    } else {
      debugPrint('Warning: No current user after anonymous sign-in');
    }

    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      debugPrint('Auth state changed: ${user?.uid}');
    });
  } catch (e) {
    debugPrint('Anonymous auth failed: $e');
    debugPrint('Note: Make sure Anonymous Authentication is enabled in Firebase Console');
    // Continue anyway - room creation doesn't require auth
  }

  final deviceId = await DeviceIdentity.getOrCreateId();
  final appState = AppStateController();
  await appState.load();

  final deepLinkService = DeepLinkService();
  await deepLinkService.initialize();

  final statusController = StatusController(
    deviceId: deviceId,
    appState: appState,
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
    ),
  );
}

class TelepathyApp extends StatelessWidget {
  const TelepathyApp({
    super.key,
    required this.appState,
    required this.statusController,
    required this.deepLinkService,
  });

  final AppStateController appState;
  final StatusController statusController;
  final DeepLinkService deepLinkService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: statusController),
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

    if (!appState.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    if (!appState.onboardingComplete) {
      return const OnboardingScreen();
    }

    return const HomeShell();
  }
}

