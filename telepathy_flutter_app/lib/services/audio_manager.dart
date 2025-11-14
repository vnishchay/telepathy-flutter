import 'package:flutter/services.dart';

import '../models/audio_profile.dart';

class AudioManager {
  AudioManager({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('telepathy/audio');

  final MethodChannel _channel;

  Future<bool> hasPolicyAccess() async {
    final result = await _channel.invokeMethod<bool>('hasPolicyAccess');
    return result ?? false;
  }

  Future<bool> requestNotificationPermission() async {
    final result = await _channel.invokeMethod<bool>('requestNotificationPermission');
    return result ?? false;
  }

  Future<bool> disableDoNotDisturb() async {
    final result = await _channel.invokeMethod<bool>('disableDoNotDisturb');
    return result ?? false;
  }

  Future<String> getDoNotDisturbStatus() async {
    final result = await _channel.invokeMethod<String>('getDoNotDisturbStatus');
    return result ?? 'unknown';
  }

  Future<bool> requestPolicyAccess() async {
    final granted = await _channel.invokeMethod<bool>('requestPolicyAccess');
    if (granted == true) {
      return true;
    }
    // The user must grant access manually in system settings. Poll afterwards.
    return await hasPolicyAccess();
  }

  Future<void> openPolicySettings() async {
    await _channel.invokeMethod<void>('openPolicySettings');
  }

  Future<AudioProfile> getCurrentProfile() async {
    final mode = await _channel.invokeMethod<int>('getRingerMode') ?? 2;
    return _profileFromMode(mode);
  }

  Future<void> setAudioProfile(AudioProfile profile) async {
    await _channel.invokeMethod<void>(
      'setRingerMode',
      <String, dynamic>{'mode': _modeFromProfile(profile)},
    );
  }

  /// Trigger a short vibration feedback
  Future<void> vibrate({int duration = 100}) async {
    await _channel.invokeMethod<void>(
      'vibrate',
      <String, dynamic>{'duration': duration},
    );
  }

  /// Start the foreground service for background audio control
  Future<void> startForegroundService() async {
    await _channel.invokeMethod<void>('startForegroundService');
  }

  /// Stop the foreground service
  Future<void> stopForegroundService() async {
    await _channel.invokeMethod<void>('stopForegroundService');
  }

  int _modeFromProfile(AudioProfile profile) {
    switch (profile) {
      case AudioProfile.silent:
        return 0;
      case AudioProfile.vibrate:
        return 1;
      case AudioProfile.ringing:
        return 2;
    }
  }

  AudioProfile _profileFromMode(int mode) {
    switch (mode) {
      case 0:
        return AudioProfile.silent;
      case 1:
        return AudioProfile.vibrate;
      case 2:
      default:
        return AudioProfile.ringing;
    }
  }
}

