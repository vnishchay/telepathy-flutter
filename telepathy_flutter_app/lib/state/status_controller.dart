import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/audio_profile.dart';
import '../services/audio_manager.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../services/firebase_service.dart';
import 'app_state_controller.dart';

class StatusController extends ChangeNotifier {
  StatusController({
    required this.deviceId,
    required this.appState,
    required AuthService authService,
    FirebaseService? service,
    AudioManager? audioManager,
    FcmService? fcmService,
    Future<void> Function()? ensureFirebase,
  })  : _authService = authService,
        _service = service ?? FirebaseService(),
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
  final AuthService _authService;
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
  AudioProfile get localProfile => _localProfile;
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
      debugPrint('FCM profile update received: $profileName');
      final profile = AudioProfile.values.firstWhere(
        (p) => p.name == profileName,
        orElse: () => AudioProfile.ringing,
      );
      // Only apply if this is a receiver device
      if (!isRemote && permissionsGranted) {
        debugPrint('Applying FCM profile update: $profile');
        unawaited(_applyLocalProfile(profile, sync: false));
      } else {
        debugPrint('Skipping FCM profile update: isRemote=$isRemote, permissionsGranted=$permissionsGranted');
      }
    });
  }

  Future<void> bootstrapLocalState() async {
    final granted = await _audioManager.hasPolicyAccess();
    final profile = await _audioManager.getCurrentProfile();
    _permissionsGranted = granted;
    _localProfile = profile;
    notifyListeners();

    // If this device is configured as a receiver and is paired, ensure permissions
    if (!appState.isRemoteController && appState.isPaired) {
      debugPrint('Device is paired receiver, checking permissions...');
      await _ensureReceiverPermissions();
    }
  }

  Future<bool> requestPolicyPermissions() async {
    debugPrint('Requesting audio control permissions...');
    final granted = await _audioManager.requestPolicyAccess();
    _permissionsGranted = granted;
    notifyListeners();

    if (granted) {
      debugPrint('Audio control permission granted!');
      // Refresh current profile after permission is granted
      final currentProfile = await _audioManager.getCurrentProfile();
      _localProfile = currentProfile;
      notifyListeners();

      if (appState.isPaired && !isRemote) {
        debugPrint('Syncing status after permission grant...');
        unawaited(_syncLocalStatus());
      }
    } else {
      debugPrint('Audio control permission not granted. User needs to enable in settings.');
    }

    return granted;
  }

  /// Check if device has required permissions for receiver functionality
  Future<bool> checkPermissions() async {
    final hasPolicyAccess = await _audioManager.hasPolicyAccess();
    return hasPolicyAccess;
  }

  /// Disable Do Not Disturb mode
  Future<bool> disableDoNotDisturb() async {
    try {
      final result = await _audioManager.disableDoNotDisturb();
      debugPrint('DND disable result: $result');
      return result;
    } catch (e) {
      debugPrint('Error disabling DND: $e');
      return false;
    }
  }

  Future<void> openPolicySettings() async {
    await _audioManager.openPolicySettings();
  }

  /// Ensure receiver device has all required permissions for remote control
  Future<void> _ensureReceiverPermissions() async {
    debugPrint('Checking receiver permissions...');

    // Check if we already have the required permissions
    final hasPolicyAccess = await _audioManager.hasPolicyAccess();
    final hasNotificationPermission = await _audioManager.requestNotificationPermission();

    if (!hasPolicyAccess) {
      debugPrint('Receiver device missing audio control permissions. Requesting...');

      // Try to request permissions
      final granted = await requestPolicyPermissions();

      if (!granted) {
        debugPrint('Audio control permission not granted for receiver device');
        _setError('Audio control permission required. Please grant access in Settings to receive remote control commands.');
      } else {
        debugPrint('Audio control permission granted for receiver device');
      }
    } else {
      debugPrint('Receiver device has required permissions');
    }

    // Also ensure notification permission for Android 13+
    if (!hasNotificationPermission) {
      debugPrint('Requesting notification permission for receiver device...');
      await _audioManager.requestNotificationPermission();
    }
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

      // Ensure user is authenticated before connecting
      await _waitForAuthentication();

      await appState.setRemoteController(asRemote);
      await appState.setPairingCode(normalized);
      await _storePairingInfo(normalized);
      _listenToRoom(normalized);
      await _syncLocalStatus();

      // Ensure permissions are granted for receiver devices
      if (!asRemote) {
        await _ensureReceiverPermissions();
      }

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

      // Ensure user is authenticated before creating room
      await _waitForAuthentication();

      await appState.setRemoteController(true);

      // Generate 14-character secure code
      final code = _generateSecureCode();
      debugPrint('Generated room code: $code');
      await appState.setPairingCode(code);
      await _storePairingInfo(code);

      _listenToRoom(code);
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
      
      // Wait for authentication before checking room
      await _waitForAuthentication();
      
      // Check if room exists and has space BEFORE joining
      final devicesSnapshot = await _service.devicesRef(normalized).get();
      if (devicesSnapshot.docs.isEmpty) {
        throw Exception('Room not found. Please check the code.');
      }
      
      // Check if current user's device already exists in room
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('Authentication required. Please sign in again.');
      }
      
      // Count unique devices (check by deviceId, not by document count)
      final deviceIds = devicesSnapshot.docs
          .map((doc) => doc.data()['deviceId'] as String? ?? doc.id)
          .toSet();

      // Check if this device is already in the room
      final deviceIdToUse = _getDeviceId();
      if (deviceIds.contains(deviceIdToUse)) {
        // Device already in room, just reconnect
        debugPrint('Device already in room, reconnecting...');
      } else if (deviceIds.length >= 2) {
        // Room is full - check if this would exceed capacity
        throw Exception('Room is full. Maximum 2 devices allowed.');
      }

      await appState.setRemoteController(false);
      await appState.setPairingCode(normalized);
      await _storePairingInfo(normalized);

      _listenToRoom(normalized);
      await _syncLocalStatus();

      // Ensure permissions are granted for receiver devices
      await _ensureReceiverPermissions();

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
        final deviceIdToUse = _getDeviceId();
        await _service.deleteDevice(
          pairingCode: code,
          deviceId: deviceIdToUse,
        );
      } catch (error, stackTrace) {
        debugPrint('Failed to delete device status: $error\n$stackTrace');
      }
    }
    await _clearStoredPairingInfo();
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

    // If device became a receiver, ensure permissions
    if (!appState.isRemoteController && roleChanged) {
      debugPrint('Device role changed to receiver, checking permissions...');
      unawaited(_ensureReceiverPermissions());
    }
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

    final deviceIdToUse = _getDeviceId();
    final local = snapshot.deviceById(deviceIdToUse);
    if (local != null) {
      _localStatusSnapshot = local;
      final previousProfile = _localProfile;
      final previousPermissions = _permissionsGranted;
      
      _localProfile = local.profile;
      _permissionsGranted = local.permissionsGranted;

      // If receiver device's profile changed in Firestore, apply it locally
      if (!isRemote &&
          local.profile != previousProfile &&
          !isLoading &&
          permissionsGranted) {
        debugPrint('Receiver profile changed in Firestore: $previousProfile -> ${local.profile}');
        unawaited(_applyLocalProfile(local.profile, sync: false));
      }
      
      // If permissions were just granted, sync status
      if (!previousPermissions && _permissionsGranted && !isRemote) {
        debugPrint('Permissions granted, syncing receiver status');
        unawaited(_syncLocalStatus());
      }
    }

    final partnerRole = isRemote ? DeviceRole.receiver : DeviceRole.remote;
    final previousPartnerStatus = _partnerStatus;
    _partnerStatus = snapshot.firstWhereRole(
      partnerRole,
      excluding: deviceIdToUse,
    );
    
    // Update partner profile
    final newPartnerProfile = _partnerStatus?.profile ?? AudioProfile.ringing;
    if (_partnerProfile != newPartnerProfile) {
      debugPrint('Partner profile changed: $_partnerProfile -> $newPartnerProfile');
      _partnerProfile = newPartnerProfile;
    }
    
    _lastPartnerUpdate = _partnerStatus?.updatedAt;
    notifyListeners();
  }

  Future<void> _syncLocalStatus() async {
    final code = _activePairingCode;
    if (code == null || code.isEmpty) return;

    // Use Firebase Auth UID combined with device ID for uniqueness
    final deviceIdToUse = _getDeviceId();

    final status = DeviceStatus(
      deviceId: deviceIdToUse,
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
    if (isRemote) {
      debugPrint('Skipping profile apply: device is remote controller');
      return;
    }
    if (!permissionsGranted) {
      debugPrint('Cannot apply profile: permissions not granted');
      _setError('Grant Do Not Disturb access to control sound.');
      return;
    }

    try {
      debugPrint('Applying audio profile: $profile');

      // Disable Do Not Disturb mode if setting to ring or vibrate
      if (profile == AudioProfile.ringing || profile == AudioProfile.vibrate) {
        debugPrint('Disabling Do Not Disturb mode for audible profile');
        try {
          await _audioManager.disableDoNotDisturb();
          debugPrint('Do Not Disturb mode disabled');
        } catch (e) {
          debugPrint('Failed to disable DND: $e');
          // Continue with profile change even if DND disable fails
        }
      }

      await _audioManager.setAudioProfile(profile);

      // Provide vibration feedback when profile changes (only if not already in that mode)
      if (_localProfile != profile) {
        try {
          await _audioManager.vibrate(duration: 150);
          debugPrint('Vibration feedback triggered for profile change');
        } catch (e) {
          debugPrint('Failed to vibrate: $e');
          // Don't fail the whole operation if vibration fails
        }
      }

      // Update local profile and notify listeners for UI update
      _localProfile = profile;
      notifyListeners(); // Ensure UI updates immediately

      if (sync) {
        await _syncLocalStatus();
      }
      _setError(null);
      debugPrint('Successfully applied audio profile: $profile');
    } catch (error, stackTrace) {
      debugPrint('Failed to apply local profile: $error\n$stackTrace');
      _setError('Unable to update ringer mode.');
      notifyListeners(); // Notify even on error
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
    try {
      // Check if already authenticated
      if (_authService.isAuthenticated) {
        debugPrint('Already authenticated: ${_authService.currentUser?.uid}');
        return;
      }

      // Sign in with Google if not authenticated
      debugPrint('Not authenticated, signing in with Google...');
      await _authService.ensureAuthenticated();
      debugPrint('Authentication successful: ${_authService.currentUser?.uid}');
    } catch (e) {
      debugPrint('Authentication failed: $e');
      throw Exception('Failed to authenticate. Please try again.');
    }
  }

  /// Get unique device ID using only the device ID
  /// This ensures each physical device can only be in one room at a time
  String _getDeviceId() {
    // Use device ID only to prevent the same device from joining multiple rooms
    return deviceId;
  }

  static String _normalizeCode(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// Store pairing information in SharedPreferences for background service access
  Future<void> _storePairingInfo(String pairingCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pairing_code', pairingCode);
      await prefs.setString('device_id', _getDeviceId());
      await prefs.setBool('is_remote', isRemote);
      debugPrint('Stored pairing info for background service: $pairingCode, device: ${_getDeviceId()}, remote: $isRemote');
    } catch (e) {
      debugPrint('Failed to store pairing info: $e');
    }
  }

  /// Clear pairing information from SharedPreferences
  Future<void> _clearStoredPairingInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pairing_code');
      await prefs.remove('device_id');
      await prefs.remove('is_remote');
      debugPrint('Cleared stored pairing info');
    } catch (e) {
      debugPrint('Failed to clear pairing info: $e');
    }
  }
}
