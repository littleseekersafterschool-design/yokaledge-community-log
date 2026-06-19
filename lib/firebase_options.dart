import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web configuration - extracted from google-services.json
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDldjHAEWyjPDr2x_q-AraGIfvUonIic3c',
    appId: '1:743413194971:android:e7d34ef14bad616804acfe',
    messagingSenderId: '743413194971',
    projectId: 'yocollege',
    storageBucket: 'yocollege.firebasestorage.app',
  );

  // Android configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDldjHAEWyjPDr2x_q-AraGIfvUonIic3c',
    appId: '1:743413194971:android:e7d34ef14bad616804acfe',
    messagingSenderId: '743413194971',
    projectId: 'yocollege',
    storageBucket: 'yocollege.firebasestorage.app',
  );
}
