import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/audio_profile.dart';
import '../firebase_options.dart';

class FirebaseService {
  FirebaseService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  static const String _roomsCollection = 'rooms';
  static const String _devicesCollection = 'devices';

  static Future<FirebaseApp> ensureInitialized() async {
    if (Firebase.apps.isNotEmpty) {
      return Firebase.apps.first;
    }
    return Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection(_roomsCollection);

  DocumentReference<Map<String, dynamic>> _roomDoc(String pairingCode) =>
      _roomsRef.doc(_normalizeCode(pairingCode));

  CollectionReference<Map<String, dynamic>> devicesRef(String pairingCode) =>
      _roomDoc(pairingCode).collection(_devicesCollection);

  Future<void> upsertStatus({
    required String pairingCode,
    required DeviceStatus status,
  }) async {
    final doc = devicesRef(pairingCode).doc(status.deviceId);

    await doc.set(
      status.toFirestore(),
      SetOptions(merge: true),
    );

    // FCM messages are now sent automatically by Cloud Functions trigger
    // when documents are updated
  }

  Stream<RoomSnapshot> watchRoom(String pairingCode) {
    final normalized = _normalizeCode(pairingCode);
    if (normalized.isEmpty) {
      return const Stream.empty();
    }

    return devicesRef(normalized).snapshots().map(
      (snapshot) {
        final statuses = snapshot.docs
            .map(DeviceStatus.fromSnapshot)
            .where((status) => status != null)
            .cast<DeviceStatus>()
            .toList();

        return RoomSnapshot(
          pairingCode: normalized,
          devices: statuses,
        );
      },
    );
  }

  Future<DeviceStatus?> fetchDevice({
    required String pairingCode,
    required String deviceId,
  }) async {
    final doc = await devicesRef(pairingCode).doc(deviceId).get();
    return DeviceStatus.fromSnapshot(doc);
  }

  Future<void> deleteDevice({
    required String pairingCode,
    required String deviceId,
  }) async {
    final doc = devicesRef(pairingCode).doc(deviceId);
    await doc.delete();

    final devices = await devicesRef(pairingCode).limit(1).get();
    if (devices.docs.isEmpty) {
      await _roomDoc(pairingCode).delete();
    }
  }

  // Manual FCM sending via Cloud Functions (fallback method)
  Future<void> sendFCMMessage({
    required List<String> tokens,
    required AudioProfile profile,
    String? pairingCode,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendFCMMessage');
      final result = await callable.call({
        'tokens': tokens,
        'profile': profile.name,
        'pairingCode': pairingCode,
      });
      print('FCM message sent via Cloud Functions: ${result.data}');
    } catch (e) {
      print('Error sending FCM message via Cloud Functions: $e');
    }
  }

  // Note: Automatic FCM sending is now handled by the deployed Cloud Function trigger
  // on Firestore document updates (sendAudioProfileUpdate function)

  static String _normalizeCode(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

enum DeviceRole { remote, receiver }

class RoomSnapshot {
  const RoomSnapshot({
    required this.pairingCode,
    required this.devices,
  });

  final String pairingCode;
  final List<DeviceStatus> devices;

  DeviceStatus? deviceById(String deviceId) {
    for (final status in devices) {
      if (status.deviceId == deviceId) {
        return status;
      }
    }
    return null;
  }

  DeviceStatus? firstWhereRole(DeviceRole role, {String? excluding}) {
    for (final status in devices) {
      if (status.role == role && status.deviceId != excluding) {
        return status;
      }
    }
    return null;
  }
}

class DeviceStatus {
  const DeviceStatus({
    required this.deviceId,
    required this.role,
    required this.profile,
    required this.permissionsGranted,
    required this.updatedAt,
    this.fcmToken,
  });

  final String deviceId;
  final DeviceRole role;
  final AudioProfile profile;
  final bool permissionsGranted;
  final DateTime? updatedAt;
  final String? fcmToken;

  DeviceStatus copyWith({
    DeviceRole? role,
    AudioProfile? profile,
    bool? permissionsGranted,
    DateTime? updatedAt,
    String? fcmToken,
  }) {
    return DeviceStatus(
      deviceId: deviceId,
      role: role ?? this.role,
      profile: profile ?? this.profile,
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'deviceId': deviceId,
      'role': role.name,
      'profile': profile.name,
      'permissionsGranted': permissionsGranted,
      'updatedAt': FieldValue.serverTimestamp(),
      if (fcmToken != null) 'fcmToken': fcmToken,
    };
  }

  static DeviceStatus? fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) return null;

    return DeviceStatus(
      deviceId: data['deviceId'] as String? ?? snapshot.id,
      role: _roleFromString(data['role'] as String?),
      profile: _profileFromString(data['profile'] as String?),
      permissionsGranted: data['permissionsGranted'] as bool? ?? false,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      fcmToken: data['fcmToken'] as String?,
    );
  }

  static DeviceRole _roleFromString(String? value) {
    if (value == DeviceRole.remote.name) return DeviceRole.remote;
    return DeviceRole.receiver;
  }

  static AudioProfile _profileFromString(String? value) {
    return AudioProfile.values.firstWhere(
      (profile) => profile.name == value,
      orElse: () => AudioProfile.ringing,
    );
  }
}

