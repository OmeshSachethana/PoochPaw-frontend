// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB3wf81dNB1g8yaZmXcmNjoqMyEwoHXH1c',
    appId: '1:556121819481:web:028df7229ea9f8ad31e448',
    messagingSenderId: '556121819481',
    projectId: 'poochpaw-8b913',
    authDomain: 'poochpaw-8b913.firebaseapp.com',
    databaseURL: 'https://poochpaw-8b913-default-rtdb.firebaseio.com',
    storageBucket: 'poochpaw-8b913.appspot.com',
    measurementId: 'G-G9C46W356S',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDDi6q-eqxY0tuTIAfeBUCwNo_DOZbF9l0',
    appId: '1:556121819481:android:6d87c882eda278b431e448',
    messagingSenderId: '556121819481',
    projectId: 'poochpaw-8b913',
    databaseURL: 'https://poochpaw-8b913-default-rtdb.firebaseio.com',
    storageBucket: 'poochpaw-8b913.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCqkP9XUffc2P2VZULwJcpz--vRkT6uS1I',
    appId: '1:556121819481:ios:7e2f316f41ad045931e448',
    messagingSenderId: '556121819481',
    projectId: 'poochpaw-8b913',
    databaseURL: 'https://poochpaw-8b913-default-rtdb.firebaseio.com',
    storageBucket: 'poochpaw-8b913.appspot.com',
    androidClientId:
        '556121819481-017l3b9chrsv8rbcrq8kmv8ondsqqvjl.apps.googleusercontent.com',
    iosClientId:
        '556121819481-lr2d6926tl0pg2t9c89e52lpbriih0mf.apps.googleusercontent.com',
    iosBundleId: 'com.example.poochpaw',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB3wf81dNB1g8yaZmXcmNjoqMyEwoHXH1c',
    appId: '1:556121819481:web:7ccde84dcf3c99b331e448',
    messagingSenderId: '556121819481',
    projectId: 'poochpaw-8b913',
    authDomain: 'poochpaw-8b913.firebaseapp.com',
    databaseURL: 'https://poochpaw-8b913-default-rtdb.firebaseio.com',
    storageBucket: 'poochpaw-8b913.appspot.com',
    measurementId: 'G-HMX70TYVH1',
  );
}
