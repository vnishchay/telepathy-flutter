import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:telepathy_flutter_app/models/audio_profile.dart';
import 'package:telepathy_flutter_app/services/audio_manager.dart';
import 'package:telepathy_flutter_app/services/auth_service.dart';
import 'package:telepathy_flutter_app/services/firebase_service.dart';
import 'package:telepathy_flutter_app/state/app_state_controller.dart';
import 'package:telepathy_flutter_app/state/status_controller.dart';

class _MockFirebaseService extends Mock implements FirebaseService {}

class _MockAudioManager extends Mock implements AudioManager {}

class _MockAuthService extends Mock implements AuthService {}

class _MockUser extends Mock implements User {}

class _FakeDeviceStatus extends Fake implements DeviceStatus {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeDeviceStatus());
    registerFallbackValue(AudioProfile.ringing);
  });

  late _MockFirebaseService firebaseService;
  late _MockAudioManager audioManager;
  late _MockAuthService authService;
  late AppStateController appState;
  late StatusController controller;
  late StreamController<RoomSnapshot> roomController;
  DeviceStatus? lastStatus;

  Future<StatusController> buildController() async {
    return StatusController(
      deviceId: 'DEVICE_A',
      appState: appState,
      authService: authService,
      service: firebaseService,
      audioManager: audioManager,
      ensureFirebase: () async {},
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    appState = AppStateController();
    await appState.load();

    firebaseService = _MockFirebaseService();
    audioManager = _MockAudioManager();
    authService = _MockAuthService();
    final mockUser = _MockUser();

    // Mock auth service
    when(() => authService.isAuthenticated).thenReturn(true);
    when(() => authService.currentUser).thenReturn(mockUser);
    when(() => authService.ensureAuthenticated()).thenAnswer((_) async => mockUser);
    when(() => mockUser.uid).thenReturn('test-user-uid');

    roomController = StreamController<RoomSnapshot>.broadcast();
    lastStatus = null;

    when(
      () => firebaseService.upsertStatus(
        pairingCode: any(named: 'pairingCode'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((invocation) async {
      lastStatus = invocation.namedArguments[#status] as DeviceStatus;
    });

    when(
      () => firebaseService.watchRoom(any()),
    ).thenAnswer((_) => roomController.stream);

    when(() => audioManager.hasPolicyAccess()).thenAnswer((_) async => false);
    when(() => audioManager.getCurrentProfile())
        .thenAnswer((_) async => AudioProfile.ringing);
    when(() => audioManager.setAudioProfile(any()))
        .thenAnswer((_) async {});
    when(() => audioManager.requestPolicyAccess())
        .thenAnswer((_) async => false);
    when(() => audioManager.openPolicySettings())
        .thenAnswer((_) async {});

    controller = await buildController();
    await controller.initialize();
  });

  tearDown(() async {
    controller.dispose();
    await roomController.close();
  });

  test('connect without pairing code sets error', () async {
    await controller.connect(pairingCode: '', asRemote: true);
    expect(controller.errorMessage, isNotNull);
  });

  test('receives partner updates and toggles partner profile', () async {
    await controller.connect(pairingCode: 'tele', asRemote: true);

    expect(appState.pairingCode, equals('TELE'));

    final initialSnapshot = RoomSnapshot(
      pairingCode: 'TELE',
      devices: [
        DeviceStatus(
          deviceId: 'DEVICE_A',
          role: DeviceRole.remote,
          profile: AudioProfile.ringing,
          permissionsGranted: false,
          updatedAt: DateTime.now(),
        ),
        DeviceStatus(
          deviceId: 'DEVICE_B',
          role: DeviceRole.receiver,
          profile: AudioProfile.ringing,
          permissionsGranted: true,
          updatedAt: DateTime.now(),
        ),
      ],
    );

    roomController.add(initialSnapshot);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(controller.partnerProfile, equals(AudioProfile.ringing));
    expect(controller.canCyclePartnerProfile, isTrue);

    when(
      () => firebaseService.upsertStatus(
        pairingCode: any(named: 'pairingCode'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((invocation) async {
      lastStatus = invocation.namedArguments[#status] as DeviceStatus;
    });

    await controller.cyclePartnerProfile();

    expect(lastStatus, isNotNull);
    expect(lastStatus!.deviceId, equals('DEVICE_B'));
    expect(lastStatus!.profile, equals(AudioProfile.vibrate));
  });
}

