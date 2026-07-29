import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class FirebaseService {
  FirebaseService._();

  static Future<void> initialize() async {
    if (!kIsWeb &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      if (!kIsWeb) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      await _configureMessaging();
    } catch (error) {
      debugPrint('Firebase initialization is not available yet: $error');
    }
  }

  static Future<void> _configureMessaging() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        'Foreground notification: ${message.notification?.title ?? 'ConnectUs'}',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification opened: ${message.messageId}');
    });

    Supabase.instance.client.auth.onAuthStateChange.listen((authState) async {
      if (authState.session == null) return;
      try {
        final token = await messaging.getToken();
        if (token != null) await savePushToken(token);
      } catch (error) {
        debugPrint('Unable to register push token after login: $error');
      }
    });

    try {
      final token = await messaging.getToken();
      if (token != null) {
        await savePushToken(token);
      }
    } catch (error, stack) {
      debugPrint('Push token is not available yet: $error');
      if (!kIsWeb) {
        await FirebaseCrashlytics.instance.recordError(error, stack);
      }
    }

    messaging.onTokenRefresh.listen(savePushToken);
  }

  static Future<void> savePushToken(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }

    try {
      await Supabase.instance.client.from('push_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');
    } catch (error, stack) {
      debugPrint('Unable to save push token: $error');
      if (!kIsWeb) {
        await FirebaseCrashlytics.instance.recordError(error, stack);
      }
    }
  }
}
