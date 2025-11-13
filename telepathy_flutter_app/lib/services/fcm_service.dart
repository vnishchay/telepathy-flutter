import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  FirebaseMessaging? _firebaseMessaging;
  FirebaseMessaging get _getFirebaseMessaging => _firebaseMessaging ??= FirebaseMessaging.instance;

  final StreamController<String> _profileUpdateController =
      StreamController<String>.broadcast();

  Stream<String> get profileUpdates => _profileUpdateController.stream;

  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
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

  void _handleMessage(RemoteMessage message) {
    debugPrint('FCM foreground message: ${message.data}');
    final profile = message.data['profile'];
    if (profile != null) {
      _profileUpdateController.add(profile);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM message opened app: ${message.data}');
    final profile = message.data['profile'];
    if (profile != null) {
      _profileUpdateController.add(profile);
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
  debugPrint('FCM background message: ${message.data}');

  // This handler runs in a separate isolate, so we can't use the FcmService instance
  // The Android native code handles background audio changes
  // This is just for logging purposes
}
