// File generated manually - replace with `flutterfire configure` output
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Run `flutterfire configure` to generate real values for your Firebase project.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'run flutterfire configure to update this file.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TODO: Replace these placeholder values with your real Firebase config

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCz-bQlc3WEFsuHtcskoPpHwvFpXMRzTGQ',
    appId: '1:405112418174:android:0afb5951671037be5bcd2f',
    messagingSenderId: '405112418174',
    projectId: 'ai-speaki',
    storageBucket: 'ai-speaki.firebasestorage.app',
  );

  // Run: flutterfire configure

  // TODO: Replace these placeholder values with your real Firebase config

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBsUiYybao0zW14mpV9BkZJGyO46vz8mLU',
    appId: '1:405112418174:ios:15bc624800366ce35bcd2f',
    messagingSenderId: '405112418174',
    projectId: 'ai-speaki',
    storageBucket: 'ai-speaki.firebasestorage.app',
    androidClientId: '405112418174-21609rc0c45g9cus28vank3mqspm12i9.apps.googleusercontent.com',
    iosClientId: '405112418174-fg3dbs7vd1mdaad4ekr44g347gge9m8b.apps.googleusercontent.com',
    iosBundleId: 'com.example.AISpeaking',
  );

  // Run: flutterfire configure

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCftXvfBayGQK4piHkp0UTZra2r_Jk8abk',
    appId: '1:405112418174:web:fe8259e5d636648f5bcd2f',
    messagingSenderId: '405112418174',
    projectId: 'ai-speaki',
    authDomain: 'ai-speaki.firebaseapp.com',
    storageBucket: 'ai-speaki.firebasestorage.app',
    measurementId: 'G-MLZ3KHHNPR',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBsUiYybao0zW14mpV9BkZJGyO46vz8mLU',
    appId: '1:405112418174:ios:2b24e9b95510e1425bcd2f',
    messagingSenderId: '405112418174',
    projectId: 'ai-speaki',
    storageBucket: 'ai-speaki.firebasestorage.app',
    androidClientId: '405112418174-21609rc0c45g9cus28vank3mqspm12i9.apps.googleusercontent.com',
    iosClientId: '405112418174-13v8tioc0acbr1ao93l8b8qk3a8jhg7a.apps.googleusercontent.com',
    iosBundleId: 'com.example.blocCleanArchitecture',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCftXvfBayGQK4piHkp0UTZra2r_Jk8abk',
    appId: '1:405112418174:web:0615f1ab1a9b64325bcd2f',
    messagingSenderId: '405112418174',
    projectId: 'ai-speaki',
    authDomain: 'ai-speaki.firebaseapp.com',
    storageBucket: 'ai-speaki.firebasestorage.app',
    measurementId: 'G-7RVMNQZ6C9',
  );

}