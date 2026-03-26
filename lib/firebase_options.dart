import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyABMZT8aOcxo_UbPXeqZxlYb0t03rKIC1c',
    appId: '1:392047337628:android:1bbb8ea7feb6424db70d59',
    messagingSenderId: '392047337628',
    projectId: 'fap-auto-80a6c',
    storageBucket: 'fap-auto-80a6c.firebasestorage.app',
  );

  // Update these values if you add iOS to Firebase console
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyABMZT8aOcxo_UbPXeqZxlYb0t03rKIC1c',
    appId: '1:392047337628:ios:000000000000000000000000',
    messagingSenderId: '392047337628',
    projectId: 'fap-auto-80a6c',
    storageBucket: 'fap-auto-80a6c.firebasestorage.app',
    iosBundleId: 'com.fapauto.app',
  );
}
