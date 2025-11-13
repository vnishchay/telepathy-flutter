import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration for the PhoneBuddy application.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'FirebaseOptions have not been configured for web. '
        'Re-run configuration including the web platform.',
      );
    }
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDGzCtnv_2IeU5ytj8J1rEu14U5ovRITbo',
    appId: '1:527656789078:android:0ef8eee13e7e532cb9c7f7',
    messagingSenderId: '527656789078',
    projectId: 'myblogs-1f4ac',
    storageBucket: 'myblogs-1f4ac.firebasestorage.app',
  );
}
