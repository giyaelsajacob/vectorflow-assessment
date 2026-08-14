# Platform Setup

The generated source is designed to be placed in a standard Flutter project.

Because this artifact does not bundle Flutter SDK-generated platform boilerplate, run:

```bash
flutter create .
```

once inside this directory if `android/` and `ios/` are not present.

Then run:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Android permissions

Add to `android/app/src/main/AndroidManifest.xml` above `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

## iOS permissions

Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>VectorFlow uses your location when creating a task package.</string>
<key>NSCameraUsageDescription</key>
<string>VectorFlow uses the camera for package attachments.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>VectorFlow uses your library for package attachments.</string>
```

## Android localhost

Android emulator:
`http://10.0.2.2:3000`

Physical phone:
use your development computer's LAN IP, for example:
`http://192.168.1.20:3000`
