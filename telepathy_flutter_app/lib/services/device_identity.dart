import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdentity {
  DeviceIdentity._();

  static const _prefsKey = 'telepathy_device_id';

  static Future<String> getOrCreateId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final id = _generateId();
    await prefs.setString(_prefsKey, id);
    return id;
  }

  static String _generateId() {
    final random = Random.secure();
    final buffer = StringBuffer();
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    for (var i = 0; i < 12; i++) {
      buffer.write(alphabet[random.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }
}

