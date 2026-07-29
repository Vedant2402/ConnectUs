import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
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

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyAEKLsjuU9Apv3Ds06NZ8bH1aNcnOm8u4Y',
    appId: '1:594829754514:web:a467518f9af7e169dde64b',
    messagingSenderId: '594829754514',
    projectId: 'connectus-a5c18',
    authDomain: 'connectus-a5c18.firebaseapp.com',
    storageBucket: 'connectus-a5c18.firebasestorage.app',
    measurementId: 'G-W19LC9Z4MG',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyAEKLsjuU9Apv3Ds06NZ8bH1aNcnOm8u4Y',
    appId: '1:594829754514:android:b4bccda8ce8f2760dde64b',
    messagingSenderId: '594829754514',
    projectId: 'connectus-a5c18',
    storageBucket: 'connectus-a5c18.firebasestorage.app',
  );

  static const apple = FirebaseOptions(
    apiKey: 'AIzaSyAEKLsjuU9Apv3Ds06NZ8bH1aNcnOm8u4Y',
    appId: '1:594829754514:ios:acdb91e37d12711ddde64b',
    messagingSenderId: '594829754514',
    projectId: 'connectus-a5c18',
    storageBucket: 'connectus-a5c18.firebasestorage.app',
    iosBundleId: 'com.vedantkankate.connectus',
  );
}
