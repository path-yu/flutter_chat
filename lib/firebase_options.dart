// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBCRj-pzeE_5XpdGdn4L-IBI04C4wUfHRE',
    appId: '1:928535285999:web:2f28da0d0a3cb167010b1a',
    messagingSenderId: '928535285999',
    projectId: 'chat-fe875',
    authDomain: 'chat-fe875.firebaseapp.com',
    storageBucket: 'chat-fe875.appspot.com',
    measurementId: 'G-P6ERGEE385',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBYZmNwmyQ6-Bv-mag_7GBOjRnQPuPULQA',
    appId: '1:928535285999:android:e9c5958e9e8dcf2d010b1a',
    messagingSenderId: '928535285999',
    projectId: 'chat-fe875',
    storageBucket: 'chat-fe875.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBMp35tJPTbMYfciOFvwnyTWEnnZ-QHUjc',
    appId: '1:928535285999:ios:ccc3f8a81e1e6b6b010b1a',
    messagingSenderId: '928535285999',
    projectId: 'chat-fe875',
    storageBucket: 'chat-fe875.appspot.com',
    iosClientId:
        '928535285999-4nops9nmapsplpp9relpo0vuthpc4h0u.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterChat',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBMp35tJPTbMYfciOFvwnyTWEnnZ-QHUjc',
    appId: '1:928535285999:ios:ccc3f8a81e1e6b6b010b1a',
    messagingSenderId: '928535285999',
    projectId: 'chat-fe875',
    storageBucket: 'chat-fe875.appspot.com',
    iosClientId:
        '928535285999-4nops9nmapsplpp9relpo0vuthpc4h0u.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterChat',
  );
}
