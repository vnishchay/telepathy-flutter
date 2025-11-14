import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  FirebaseMessaging? _firebaseMessaging;
  FirebaseMessaging get _getFirebaseMessaging => _firebaseMessaging ??= FirebaseMessaging.instance;

  static const _prefsKeySyncedToken = 'fcm_token_synced';

  final StreamController<String> _profileUpdateController =
      StreamController<String>.broadcast();

  Stream<String> get profileUpdates => _profileUpdateController.stream;

  String? _fcmToken;
  String? _lastSyncedToken;

  String? get fcmToken => _fcmToken;
  String? get lastSyncedToken => _lastSyncedToken;
  bool get hasUnsyncedToken =>
      _fcmToken != null && _fcmToken?.isNotEmpty == true && _fcmToken != _lastSyncedToken;

  Future<void> initialize() async {
    await _loadSyncedToken();

    // Request permission
    final settings = await _getFirebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('FCM permission status: ${settings.authorizationStatus}');

    // Get FCM token
    _fcmToken = await _getFirebaseMessaging.getToken();
    debugPrint('FCM Token: $_fcmToken');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleMessage);

    // Handle background messages when app is opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _loadSyncedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastSyncedToken = prefs.getString(_prefsKeySyncedToken);
      debugPrint('Loaded last synced FCM token: $_lastSyncedToken');
    } catch (e) {
      debugPrint('Failed to load synced FCM token: $e');
    }
  }

  Future<void> markTokenSynced() async {
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeySyncedToken, _fcmToken!);
      _lastSyncedToken = _fcmToken;
      debugPrint('Persisted synced FCM token: $_fcmToken');
    } catch (e) {
      debugPrint('Failed to persist synced FCM token: $e');
    }
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint('FCM foreground message received');
    debugPrint('Message data: ${message.data}');
    debugPrint('Message notification: ${message.notification?.title} - ${message.notification?.body}');

    final profile = message.data['profile'];
    if (profile != null) {
      debugPrint('Extracted profile from FCM: $profile');
      _profileUpdateController.add(profile);
    } else {
      debugPrint('No profile found in FCM message data');
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM message opened app');
    debugPrint('Message data: ${message.data}');
    debugPrint('Message notification: ${message.notification?.title} - ${message.notification?.body}');

    final profile = message.data['profile'];
    if (profile != null) {
      debugPrint('Extracted profile from FCM: $profile');
      _profileUpdateController.add(profile);
    } else {
      debugPrint('No profile found in FCM message data');
    }
  }

  Future<void> refreshToken() async {
    _fcmToken = await _getFirebaseMessaging.getToken();
    debugPrint('FCM Token refreshed: $_fcmToken');
  }

  void dispose() {
    _profileUpdateController.close();
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message received');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title} - ${message.notification?.body}');

  // This handler runs in a separate isolate, so we can't use the FcmService instance
  // But we can still trigger the Android service for audio profile changes
  final profile = message.data['profile'];
  if (profile != null) {
    debugPrint('Background FCM message contains profile: $profile');
    debugPrint('Android native service should handle this automatically');

    // Note: The Android FirebaseMessagingService should handle this, but as a fallback,
    // we could potentially trigger the Android service from here if needed.
    // However, since we're in a separate isolate, we can't directly communicate with Android services.
  }
}
