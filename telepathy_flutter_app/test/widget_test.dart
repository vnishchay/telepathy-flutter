// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telepathy_flutter_app/app/app_theme.dart';
import 'package:telepathy_flutter_app/models/audio_profile.dart';
import 'package:telepathy_flutter_app/services/audio_manager.dart';
import 'package:telepathy_flutter_app/services/auth_service.dart';
import 'package:telepathy_flutter_app/services/deep_link_service.dart';
import 'package:telepathy_flutter_app/services/firebase_service.dart';
import 'package:telepathy_flutter_app/state/app_state_controller.dart';
import 'package:telepathy_flutter_app/state/status_controller.dart';
import 'package:telepathy_flutter_app/ui/home/home_shell.dart';

class _MockFirebaseService extends Mock implements FirebaseService {}

class _MockAudioManager extends Mock implements AudioManager {}

class _MockAuthService extends Mock implements AuthService {}

class _MockUser extends Mock implements User {}

class _MockDeepLinkService extends Mock implements DeepLinkService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const audioChannel = MethodChannel('telepathy/audio');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      audioChannel,
      (call) async {
        switch (call.method) {
          case 'hasPolicyAccess':
            return false;
          case 'getRingerMode':
            return 2;
          case 'requestPolicyAccess':
          case 'openPolicySettings':
          case 'setRingerMode':
            return null;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, null);
  });

  setUpAll(() {
    registerFallbackValue(AudioProfile.ringing);
    registerFallbackValue(
      DeviceStatus(
        deviceId: 'fallback',
        role: DeviceRole.remote,
        profile: AudioProfile.ringing,
        permissionsGranted: false,
        updatedAt: DateTime.now(),
      ),
    );
  });

  testWidgets('Shows pairing flow once onboarding is complete', (tester) async {
    final firebaseService = _MockFirebaseService();
    final audioManager = _MockAudioManager();
    final authService = _MockAuthService();
    final mockUser = _MockUser();
    SharedPreferences.setMockInitialValues({});
    final appState = AppStateController();
    await appState.load();
    await appState.completeOnboarding();

    // Mock auth service
    when(() => authService.isAuthenticated).thenReturn(true);
    when(() => authService.currentUser).thenReturn(mockUser);
    when(() => authService.ensureAuthenticated()).thenAnswer((_) async => mockUser);
    when(() => mockUser.uid).thenReturn('test-user-uid');

    when(
      () => firebaseService.upsertStatus(
        pairingCode: any(named: 'pairingCode'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async {});
    when(() => firebaseService.watchRoom(any())).thenAnswer(
      (_) => const Stream<RoomSnapshot>.empty(),
    );

    when(() => audioManager.hasPolicyAccess()).thenAnswer((_) async => false);
    when(() => audioManager.getCurrentProfile())
        .thenAnswer((_) async => AudioProfile.ringing);
    when(() => audioManager.requestPolicyAccess())
        .thenAnswer((_) async => false);
    when(() => audioManager.openPolicySettings())
        .thenAnswer((_) async {});
    when(() => audioManager.setAudioProfile(any()))
        .thenAnswer((_) async {});

    final statusController = StatusController(
      deviceId: 'TEST123',
      appState: appState,
      authService: authService,
      service: firebaseService,
      audioManager: audioManager,
      ensureFirebase: () async {},
    );
    await statusController.initialize();

    final deepLinkService = _MockDeepLinkService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appState),
          ChangeNotifierProvider.value(value: statusController),
          Provider.value(value: deepLinkService),
        ],
        child: MaterialApp(
          theme: AppTheme.create(),
          home: const HomeShell(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Let’s pair'), findsOneWidget);
    expect(find.text('Not paired'), findsOneWidget);
    // The text now changes based on remote/receiver mode - check for the button
    expect(find.widgetWithText(ElevatedButton, 'Create Room'), findsOneWidget);

    statusController.dispose();
  });
}
