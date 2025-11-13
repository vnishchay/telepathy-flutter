import 'package:flutter/material.dart';

enum AudioProfile {
  silent,
  vibrate,
  ringing,
}

extension AudioProfileUi on AudioProfile {
  String get label {
    switch (this) {
      case AudioProfile.silent:
        return 'Silent';
      case AudioProfile.vibrate:
        return 'Vibrate';
      case AudioProfile.ringing:
        return 'Ringing';
    }
  }

  IconData get icon {
    switch (this) {
      case AudioProfile.silent:
        return Icons.volume_off;
      case AudioProfile.vibrate:
        return Icons.vibration;
      case AudioProfile.ringing:
        return Icons.volume_up;
    }
  }

  Color get accent {
    switch (this) {
      case AudioProfile.silent:
        return const Color(0xFFEF5350);
      case AudioProfile.vibrate:
        return const Color(0xFFFFA726);
      case AudioProfile.ringing:
        return const Color(0xFF66BB6A);
    }
  }
}

