import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/audio_profile.dart';
import '../services/audio_manager.dart';
import '../services/fcm_service.dart';
import '../services/firebase_service.dart';
import 'app_state_controller.dart';

class StatusController extends ChangeNotifier {
  StatusController({
    required this.deviceId,
    required this.appState,
    FirebaseService? service,
    AudioManager? audioManager,
    FcmService? fcmService,
    Future<void> Function()? ensureFirebase,
  })  : _service = service ?? FirebaseService(),
        _audioManager = audioManager ?? AudioManager(),
        _fcmService = fcmService ?? FcmService(),
        _ensureFirebase = ensureFirebase ??
            (() async {
              await FirebaseService.ensureInitialized();
            }) {
    appState.addListener(_handleAppStateChange);
  }

  final String deviceId;
  final AppStateController appState;
  final FirebaseService _service;
  final AudioManager _audioManager;
  final FcmService _fcmService;
  final Future<void> Function() _ensureFirebase;

  StreamSubscription<RoomSnapshot>? _roomSubscription;
  String? _activePairingCode;

  bool _permissionsGranted = false;
  bool _isLoading = false;
  bool _isConnected = false;
  String? _errorMessage;

  AudioProfile _localProfile = AudioProfile.ringing;
  AudioProfile _partnerProfile = AudioProfile.ringing;
  DeviceStatus? _partnerStatus;
  DeviceStatus? _localStatusSnapshot;

  DateTime? _lastPartnerUpdate;

  bool get permissionsGranted => _permissionsGranted;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String? get errorMessage => _errorMessage;
  AudioProfile get partnerProfile => _partnerProfile;
  DateTime? get lastPartnerUpdate => _lastPartnerUpdate;
  bool get hasPartner => _partnerStatus != null;
  bool get isRemote => appState.isRemoteController;
  bool get canCyclePartnerProfile =>
      isRemote && hasPartner && !isLoading && appState.isPaired;

  Future<void> initialize() async {
    await _ensureFirebase();
    try {
      await _fcmService.initialize();
      _listenToFcmProfileUpdates();
    } catch (e) {
      // FCM might not be available in tests
      debugPrint('FCM initialization failed: $e');
    }
    await bootstrapLocalState();
    _handleAppStateChange();
  }

  void _listenToFcmProfileUpdates() {
    _fcmService.profileUpdates.listen((profileName) {
      final profile = AudioProfile.values.firstWhere(
        (p) => p.name == profileName,
        orElse: () => AudioProfile.ringing,
      );
      unawaited(_applyLocalProfile(profile, sync: false));
    });
  }

  Future<void> bootstrapLocalState() async {
    final granted = await _audioManager.hasPolicyAccess();
    final profile = await _audioManager.getCurrentProfile();
    _permissionsGranted = granted;
    _localProfile = profile;
    notifyListeners();
  }

  Future<bool> requestPolicyPermissions() async {
    final granted = await _audioManager.requestPolicyAccess();
    _permissionsGranted = granted;
    notifyListeners();
    if (granted && appState.isPaired && !isRemote) {
      unawaited(_syncLocalStatus());
    }
    return granted;
  }

  Future<void> openPolicySettings() async {
    await _audioManager.openPolicySettings();
  }

  Future<void> connect({
    required String pairingCode,
    required bool asRemote,
  }) async {
    final normalized = _normalizeCode(pairingCode);
    if (normalized.isEmpty) {
      _setError('Enter a pairing code to connect.');
      return;
    }
    if (_isLoading) return;

    _setLoading(true);
    try {
      await _ensureFirebase();
      try {
        debugPrint('Auth state: ${FirebaseAuth.instance.currentUser?.uid}');
      } catch (e) {
        debugPrint('Auth check failed (expected in tests): $e');
      }
      await appState.setRemoteController(asRemote);
      await appState.setPairingCode(normalized);
      _listenToRoom(normalized);
      await _syncLocalStatus();
      _setError(null);
    } catch (error, stackTrace) {
      debugPrint('Failed to connect: $error\n$stackTrace');
      _setError('Failed to connect. Please try again.');
      await _teardownSubscription();
      await appState.clearPairing();
    } finally {
      _setLoading(false);
    }
  }

  Future<String> createRoom() async {
    if (_isLoading) throw Exception('Already processing');

    _setLoading(true);
    try {
      await _ensureFirebase();

      // Room creation doesn't require authentication
      await appState.setRemoteController(true);

      // Generate 14-character secure code
      final code = _generateSecureCode();
      debugPrint('Generated room code: $code');
      await appState.setPairingCode(code);

      _listenToRoom(code);

      // Wait for authentication before syncing status (device creation requires auth)
      await _waitForAuthentication();
      await _syncLocalStatus();

      _setError(null);
      return code;
    } catch (error, stackTrace) {
      debugPrint('Failed to create room: $error\n$stackTrace');
      _setError('Failed to create room. Please try again.');
      await _teardownSubscription();
      await appState.clearPairing();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> joinRoom(String roomCode) async {
    final normalized = _normalizeCode(roomCode);
    if (normalized.isEmpty) {
      _setError('Enter a valid room code to join.');
      return;
    }
    if (_isLoading) return;

    _setLoading(true);
    try {
      await _ensureFirebase();
      await appState.setRemoteController(false);
      await appState.setPairingCode(normalized);

      // Wait for authentication before checking room
      await _waitForAuthentication();

      // Check if room exists and has space
      final devicesSnapshot = await _service.devicesRef(normalized).get();
      if (devicesSnapshot.docs.isEmpty) {
        throw Exception('Room not found. Please check the code.');
      }
      if (devicesSnapshot.docs.length >= 2) {
        throw Exception('Room is full. Maximum 2 devices allowed.');
      }

      _listenToRoom(normalized);
      await _syncLocalStatus();
      _setError(null);
    } catch (error, stackTrace) {
      debugPrint('Failed to join room: $error\n$stackTrace');
      _setError(error.toString().replaceFirst('Exception: ', ''));
      await _teardownSubscription();
      await appState.clearPairing();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> unpair() async {
    final code = _activePairingCode;
    if (code != null) {
      try {
        await _service.deleteDevice(
          pairingCode: code,
          deviceId: deviceId,
        );
      } catch (error, stackTrace) {
        debugPrint('Failed to delete device status: $error\n$stackTrace');
      }
    }
    await _teardownSubscription();
    await appState.clearPairing();
    _isConnected = false;
    _partnerStatus = null;
    _partnerProfile = AudioProfile.ringing;
    _lastPartnerUpdate = null;
    notifyListeners();
  }

  Future<void> cyclePartnerProfile() async {
    if (!canCyclePartnerProfile) return;
    final partner = _partnerStatus;
    final code = _activePairingCode;
    if (partner == null || code == null) return;

    final next = _cycleProfile(partner.profile);
    _setLoading(true);
    try {
      await _service.upsertStatus(
        pairingCode: code,
        status: partner.copyWith(profile: next),
      );
      _setError(null);
    } catch (error, stackTrace) {
      debugPrint('Failed to update partner profile: $error\n$stackTrace');
      _setError('Could not update partner. Try again.');
    } finally {
      _setLoading(false);
    }
  }

  void clearError() => _setError(null);

  @override
  void dispose() {
    appState.removeListener(_handleAppStateChange);
    unawaited(_teardownSubscription());
    _fcmService.dispose();
    super.dispose();
  }

  void _handleAppStateChange() {
    final code = appState.pairingCode;
    final normalized = code == null ? null : _normalizeCode(code);
    final roleChanged = appState.isRemoteController !=
        (_localStatusSnapshot?.role == DeviceRole.remote);

    if (_activePairingCode == normalized && !roleChanged) {
      return;
    }

    if (normalized == null || normalized.isEmpty) {
      _teardownSubscription();
      _activePairingCode = null;
      _isConnected = false;
      notifyListeners();
      return;
    }

    _listenToRoom(normalized);
    unawaited(_syncLocalStatus());
  }

  void _listenToRoom(String pairingCode) {
    final normalized = _normalizeCode(pairingCode);
    if (normalized.isEmpty) return;
    if (_activePairingCode == normalized && _roomSubscription != null) {
      return;
    }

    _teardownSubscription();
    _activePairingCode = normalized;
    _roomSubscription = _service.watchRoom(normalized).listen(
      _handleRoomSnapshot,
      onError: (error, stackTrace) {
        debugPrint('Room listener error: $error\n$stackTrace');
        _setError('Connection lost. Retrying…');
      },
    );
  }

  Future<void> _teardownSubscription() async {
    await _roomSubscription?.cancel();
    _roomSubscription = null;
  }

  void _handleRoomSnapshot(RoomSnapshot snapshot) {
    _isConnected = snapshot.devices.isNotEmpty;

    final local = snapshot.deviceById(deviceId);
    if (local != null) {
      _localStatusSnapshot = local;
      final previousProfile = _localProfile;
      _localProfile = local.profile;
      _permissionsGranted = local.permissionsGranted;

      if (!isRemote &&
          local.profile != previousProfile &&
          !isLoading &&
          permissionsGranted) {
        unawaited(_applyLocalProfile(local.profile, sync: false));
      }
    }

    final partnerRole = isRemote ? DeviceRole.receiver : DeviceRole.remote;
    _partnerStatus = snapshot.firstWhereRole(
      partnerRole,
      excluding: deviceId,
    );
    _partnerProfile = _partnerStatus?.profile ?? _partnerProfile;
    _lastPartnerUpdate = _partnerStatus?.updatedAt;
    notifyListeners();
  }

  Future<void> _syncLocalStatus() async {
    final code = _activePairingCode;
    if (code == null || code.isEmpty) return;

    final status = DeviceStatus(
      deviceId: deviceId,
      role: isRemote ? DeviceRole.remote : DeviceRole.receiver,
      profile: _localProfile,
      permissionsGranted: _permissionsGranted,
      updatedAt: DateTime.now(),
      fcmToken: _fcmService.fcmToken,
    );

    try {
      await _service.upsertStatus(
        pairingCode: code,
        status: status,
      );
      _localStatusSnapshot = status;
    } catch (error, stackTrace) {
      debugPrint('Failed to sync local status: $error\n$stackTrace');

      // If it's a permission error, it might be due to auth issues
      if (error.toString().contains('permission-denied') ||
          error.toString().contains('PERMISSION_DENIED')) {
        debugPrint('Permission denied - authentication may not be working');
        _setError('Connection issue. Please restart the app and try again.');
      } else {
        _setError('Failed to sync status. Check your connection.');
      }
    }
  }

  Future<void> _applyLocalProfile(
    AudioProfile profile, {
    bool sync = true,
  }) async {
    if (isRemote) return;
    if (!permissionsGranted) {
      _setError('Grant Do Not Disturb access to control sound.');
      return;
    }

    try {
      await _audioManager.setAudioProfile(profile);
      _localProfile = profile;
      if (sync) {
        await _syncLocalStatus();
      }
      _setError(null);
    } catch (error, stackTrace) {
      debugPrint('Failed to apply local profile: $error\n$stackTrace');
      _setError('Unable to update ringer mode.');
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    if (_errorMessage == message) return;
    _errorMessage = message;
    notifyListeners();
  }

  static AudioProfile _cycleProfile(AudioProfile current) {
    switch (current) {
      case AudioProfile.ringing:
        return AudioProfile.vibrate;
      case AudioProfile.vibrate:
        return AudioProfile.silent;
      case AudioProfile.silent:
        return AudioProfile.ringing;
    }
  }

  static String _generateSecureCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(14, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _waitForAuthentication() async {
    // Wait up to 10 seconds for authentication to complete
    const maxWaitTime = Duration(seconds: 10);
    final startTime = DateTime.now();

    debugPrint('Waiting for authentication...');

    while (DateTime.now().difference(startTime) < maxWaitTime) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          debugPrint('Authentication ready: ${currentUser.uid}');
          return;
        } else {
          debugPrint('Still waiting for authentication...');
        }
      } catch (e) {
        debugPrint('Firebase auth check failed: $e');
        // Firebase not initialized yet, continue waiting
      }

      // Wait 200ms before checking again
      await Future.delayed(const Duration(milliseconds: 200));
    }

    debugPrint('Warning: Authentication not ready after ${maxWaitTime.inSeconds} seconds, proceeding anyway');
  }

  static String _normalizeCode(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}
