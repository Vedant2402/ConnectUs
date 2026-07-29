import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return apple;
      default:
        throw UnsupportedError('Firebase is not configured for this platform.');
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: _required('FIREBASE_API_KEY'),
    appId: _required('FIREBASE_WEB_APP_ID'),
    messagingSenderId: _required('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _required('FIREBASE_PROJECT_ID'),
    authDomain: _required('FIREBASE_AUTH_DOMAIN'),
    storageBucket: _required('FIREBASE_STORAGE_BUCKET'),
    measurementId: _required('FIREBASE_MEASUREMENT_ID'),
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: _required('FIREBASE_API_KEY'),
    appId: _required('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: _required('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _required('FIREBASE_PROJECT_ID'),
    storageBucket: _required('FIREBASE_STORAGE_BUCKET'),
  );

  static FirebaseOptions get apple => FirebaseOptions(
    apiKey: _required('FIREBASE_API_KEY'),
    appId: _required('FIREBASE_APPLE_APP_ID'),
    messagingSenderId: _required('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _required('FIREBASE_PROJECT_ID'),
    storageBucket: _required('FIREBASE_STORAGE_BUCKET'),
    iosBundleId: _required('FIREBASE_IOS_BUNDLE_ID'),
  );

  static String _required(String name) {
    final value = dotenv.env[name]?.trim();

    if (value == null || value.isEmpty) {
      throw StateError('$name is missing from the .env file.');
    }

    return value;
  }
}
