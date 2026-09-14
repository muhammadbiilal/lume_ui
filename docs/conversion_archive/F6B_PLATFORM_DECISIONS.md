# F6B platform decisions

The dependencies, permissions and platform configuration F6B added for QR
scanning (decision 1) and Save image (decision 2), and why. Behaviour and
states are in `KNOWN_DIFFERENCES.md` C80 and C81.

## 1. Packages

Every version is pinned exactly in `pubspec.yaml`. Each package is imported
by one adapter file and nothing else.

| package | version | licence | publisher | used only by |
|---|---|---|---|---|
| `flutter_zxing` | 3.0.1 | MIT | khoren93 | `lib/core/platform/lume_scanner_platform.dart` |
| `image_picker` | 1.2.3 | BSD-3-Clause | flutter.dev | `lib/core/platform/lume_scanner_platform.dart` |
| `gal` | 2.3.3 | BSD-3-Clause | midoridesign.studio | `lib/core/platform/lume_image_saver_platform.dart` |

What they bring into the lock file, resolved: `camera` 0.12.1 (through
`flutter_zxing`, with `camera_android_camerax` 0.7.4+8 and
`camera_avfoundation` 0.10.3), `image` 4.10.1, `ffi` 2.2.0, and
`image_picker_android` 0.8.13+23 / `image_picker_ios` 0.8.13+7. No separate
camera dependency is declared: the scanner package covers it.

### Scanner — chosen: `flutter_zxing`

| requirement | finding |
|---|---|
| Android and iOS | both; Android minSdk 23, iOS 13 (the project's own floor) |
| Flutter / Dart | `sdk >=3.11.0`, `flutter >=3.41.0` — this project is Flutter 3.44.8 / Dart 3.12.2, and Dayroz's `sdk: ^3.11.5` |
| camera scanning | `ReaderWidget` over `camera` (CameraX on Android) |
| gallery decoding | `readBarcodesImagePathString`, decoded in a background isolate |
| lifecycle | `ReaderWidget` stops the stream on pause; Lume also removes the camera from the tree when hidden, paused or covered (C80) |
| permissions | camera only, requested by the camera plugin on the page Scan opens; `enableAudio: false` |
| analytics / network | none: zxing-cpp compiled into the app and called through FFI; the URL-reading API is never called |
| licence | MIT; zxing-cpp is Apache-2.0 |
| later Dayroz | same SDK floor; the NDK and CMake build the native decoder, so Dayroz's Android build needs the NDK Flutter already pins (`ndkVersion = flutter.ndkVersion`) |

### Rejected

| package | why |
|---|---|
| `mobile_scanner` 7.4.2 | On Android it uses Google ML Kit barcode scanning, which sends device information, performance metrics and error codes to Google as diagnostics and usage analytics, with no documented way to turn that off. That is unnecessary network and analytics for decoding a code the device can decode itself. |
| `google_mlkit_barcode_scanning` | The same ML Kit, with the same reporting. |
| a separate `camera` + a pure-Dart decoder | Two dependencies where one covers both, and a slower decoder on the frame path. |

### Gallery — `image_picker`

`pickImage(source: gallery, requestFullMetadata: false)`. The Android Photo
Picker (Android 13+, back-ported through Play services) and iOS PHPicker
(iOS 14+) grant the single item chosen, and ask for no photo-library
permission. The copy it returns lives in the app's cache and is deleted after
decoding, whatever the outcome.

### Save image — `gal`

`hasAccess` / `requestAccess` (add-only) / `putImageBytes`. Android writes
through MediaStore; iOS uses `PHPhotoLibrary` with `.addOnly` on iOS 14+. The
share sheet stays the way to keep a card below iOS 14, where Photos can only
grant the whole library (C81).

## 2. Android configuration

`android/app/src/main/AndroidManifest.xml`:

| entry | why |
|---|---|
| `CAMERA` | QR scanning; asked when Scan is pressed |
| `uses-feature camera.any required="false"` (replacing the camera plugin's required feature) | a phone without a camera can still install Lume and read a code from an image |
| `RECORD_AUDIO` `tools:node="remove"` | the camera plugin declares the microphone for video; Lume records none |
| `WRITE_EXTERNAL_STORAGE maxSdkVersion="28"` | Save image on Android 6–9 only; the camera plugin already merged the same line, and it is now declared deliberately |

Not added: `READ_MEDIA_IMAGES`, `READ_EXTERNAL_STORAGE`,
`MANAGE_EXTERNAL_STORAGE`, `ACCESS_MEDIA_LOCATION`, location, contacts,
microphone. `image_picker` merges a `FileProvider` and the Photo Picker
back-port service, neither of which is a permission. The merged manifest is
checked in the verification gate.

## 3. iOS configuration

`ios/Runner/Info.plist`:

| key | wording |
|---|---|
| `NSCameraUsageDescription` | "Lume uses the camera only while you scan a QR code. Nothing is recorded or uploaded." |
| `NSPhotoLibraryAddUsageDescription` | "Lume adds the image you choose to save to your photos. It cannot see your other photos." |

**Deliberately absent:** `NSPhotoLibraryUsageDescription` (full library),
`NSMicrophoneUsageDescription`.

**Validated, not built.** This phase runs on Windows: the plist is parsed and
its keys checked; no Xcode build, no CocoaPods install (the project has no
`Podfile` yet — Flutter generates it on the first macOS build) and no device
test has happened.

## 4. Obligations and open decisions

- **iOS build and device test** on macOS: the camera prompt, PHPicker, the
  add-only prompt, and a saved card appearing in Photos.
- **Localised permission wording.** The usage strings are English. Urdu and
  Arabic need `InfoPlist.strings` in `ur.lproj` / `ar.lproj`, added through
  Xcode so the project file references them.
- **App Store static analysis** can flag a binary that links
  `PHPhotoLibrary.requestAuthorization` without `NSPhotoLibraryUsageDescription`
  — `gal`'s pre-iOS-14 path and `image_picker` both link it. Adding the key
  grants nothing by itself but names a permission Lume never asks for; that
  is a release decision.
- **Dayroz:** the same adapters and the same allowlist; a scan history, if
  Dayroz wants one, is the reader's saved data and needs its own consent and
  retention decision.
