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
    apiKey: 'AIzaSyCgYCjxqq6XymaRJkVu5U7MTS2gPs3m2gQ',
    appId: '1:695758973989:web:ba14f61b59e655a613e3cc',
    messagingSenderId: '695758973989',
    projectId: 'waterfinder-36e1b',
    authDomain: 'waterfinder-36e1b.firebaseapp.com',
    storageBucket: 'waterfinder-36e1b.firebasestorage.app',
    measurementId: 'G-HMXCMGFQXR',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCgYCjxqq6XymaRJkVu5U7MTS2gPs3m2gQ',
    appId: '1:695758973989:android:ba14f61b59e655a613e3cc',
    messagingSenderId: '695758973989',
    projectId: 'waterfinder-36e1b',
    storageBucket: 'waterfinder-36e1b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCgYCjxqq6XymaRJkVu5U7MTS2gPs3m2gQ',
    appId: '1:695758973989:ios:ba14f61b59e655a613e3cc',
    messagingSenderId: '695758973989',
    projectId: 'waterfinder-36e1b',
    storageBucket: 'waterfinder-36e1b.firebasestorage.app',
    iosBundleId: 'com.example.waterfinder',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCgYCjxqq6XymaRJkVu5U7MTS2gPs3m2gQ',
    appId: '1:695758973989:macos:ba14f61b59e655a613e3cc',
    messagingSenderId: '695758973989',
    projectId: 'waterfinder-36e1b',
    storageBucket: 'waterfinder-36e1b.firebasestorage.app',
    iosBundleId: 'com.example.waterfinder',
  );
}