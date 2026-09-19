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
| `ffi` | 2.2.0 | BSD-3-Clause | dart.dev | `lib/core/time/lume_boot_clock.dart` — already shipped through `flutter_zxing`; declared because Lume calls it (F6B closure) |
| `timezone` | 0.11.1 | BSD-2-Clause | dart.dev (`dart-lang/labs`) | `lib/core/time/lume_iana_zones.dart` only (and the alias generator, `scripts/generate_zone_aliases.dart`) — IANA tzdb 2025c, `latest_all` (approved after wave 2; `WORLD_CLOCK_TIMEZONE.md`) |
| `image_picker` | 1.2.3 | BSD-3-Clause | flutter.dev | `lib/core/platform/lume_scanner_platform.dart` |
| `gal` | 2.3.3 | BSD-3-Clause | midoridesign.studio | `lib/core/platform/lume_image_saver_platform.dart` — **iOS only** since the F6B closure; Android saves through Lume's MediaStore channel (C81) |

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
| permissions | camera only; on Android asked by Lume's own `lume/camera_permission` channel when Scan is pressed (F6B closure), elsewhere by the camera plugin on the page Scan opens; `enableAudio: false` |
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
back-port service, neither of which is a permission.

**Checked in the merged debug manifest** (`manifest-merger-debug-report.txt`):

| merged entry | from | outcome |
|---|---|---|
| `CAMERA` | app | kept |
| `WRITE_EXTERNAL_STORAGE maxSdkVersion 28` | app and `camera_android_camerax` | kept |
| `READ_EXTERNAL_STORAGE` | *implied* by the merger from the camera plugin's write permission | **removed** (`tools:node="remove"`) — found in the F6B device build |
| `RECORD_AUDIO` | `camera_android_camerax` | removed |
| `ACCESS_NETWORK_STATE` | `androidx.media3:media3-common:1.9.0`, via `camera_android_camerax` → `androidx.camera:camera-video:1.6.2` → `media3-container` | **removed** (`tools:node="remove"`, F6B closure). media3 serves a player's bandwidth estimate; Lume records and plays no media. Scan, gallery decoding, capture lifecycle and Save image ran on API 36 and API 29 with no `SecurityException` from Lume; `android_manifest_test.dart` asserts it absent from the merged debug and release manifests |
| `INTERNET` | Flutter's debug manifest | debug builds only |

**Which tool is authoritative (F6B closure).** The packaged manifest is:
`apkanalyzer manifest print` and `aapt2 dump permissions` on the release APK
show `CAMERA`, `WRITE_EXTERNAL_STORAGE maxSdkVersion="28"` and androidx's
`com.lume.lume.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, and nothing else.
`apkanalyzer manifest permissions` also lists `READ_EXTERNAL_STORAGE`; that is
the tool deriving the read Android implies for any storage write, not a
declaration — the APK does not contain it, and nothing was added or removed to
change what that tool shows. `android_manifest_test.dart` holds the merged
debug and release manifests to: no explicit `READ_EXTERNAL_STORAGE`, the write
only through API 28, no `READ_MEDIA_*`, `ACCESS_MEDIA_LOCATION` or
`MANAGE_EXTERNAL_STORAGE`, and no `ACCESS_NETWORK_STATE`.

## 3. iOS configuration

`ios/Runner/Info.plist`:

| key | wording |
|---|---|
| `NSCameraUsageDescription` | "Lume uses the camera only while you scan a QR code. Nothing is recorded or uploaded." |
| `NSPhotoLibraryAddUsageDescription` | "Lume adds the image you choose to save to your photos. It cannot see your other photos." |

**Deliberately absent:** `NSPhotoLibraryUsageDescription` (full library),
`NSMicrophoneUsageDescription`.

**Localised (F6B closure).** `Runner/{en,ur,ar}.lproj/InfoPlist.strings`
carry both descriptions in English, Urdu and Arabic, in one
`InfoPlist.strings` variant group the Xcode project bundles in Runner's
Resources phase; `knownRegions` gains `ur` and `ar`, and Info.plist declares
`CFBundleLocalizations` en, ur, ar. `NSPhotoLibraryUsageDescription` stays
absent: the system picker selects images and saving is add-only.

**Validated, not built.** This phase runs on Windows: `ios_config_test.dart`
parses Info.plist and each `.strings` file with a strict reader, checks the
keys, that English matches Info.plist, that Urdu and Arabic are translated
into their script, that no text claims broad library access, and that the
project references all three. No Xcode build, no CocoaPods install and no iOS
device test has happened.

## 4. Obligations and open decisions

- **iOS build and device test** on macOS: the camera prompt, PHPicker, the
  add-only prompt, and a saved card appearing in Photos.
- **Localised permission wording** — done as configuration (above); to be
  seen on a device in Urdu and Arabic with the iOS build.
- **App Store static analysis** can flag a binary that links
  `PHPhotoLibrary.requestAuthorization` without `NSPhotoLibraryUsageDescription`
  — `gal`'s pre-iOS-14 path and `image_picker` both link it. Approved in
  the closure: the key is **not** added speculatively; only a concrete App
  Store validation result for the shipped binary, a library-wide reading
  feature, or proof that add-only is insufficient would add it.
- **Dayroz:** the same adapters and the same allowlist; a scan history, if
  Dayroz wants one, is the reader's saved data and needs its own consent and
  retention decision.
- **iOS Settings action and boot-time clock — written, not run.**
  `AppDelegate.swift` answers `lume/app_settings` with
  `UIApplication.openSettingsURLString`, and the stopwatch reads
  `mach_continuous_time`, scaled by a `mach_timebase_info` read once, through
  dart:ffi (F6B closure correction: it read
  `clock_gettime_nsec_np(CLOCK_MONOTONIC)` before, whose counting through
  sleep had no Apple-platform evidence here). Both symbols are in libSystem
  from iOS 10 and the deployment target is 13.0, so there is no fallback: an
  unreachable symbol or a zero timebase throws `LumeBootClockUnavailable`
  instead of counting on a clock that stops in sleep. Checked as source and by
  host tests with fake ticks on Windows; neither has been built or run on iOS,
  and **real deep sleep on an Apple device is an open obligation**.
