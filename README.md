<div align="center">

# 🕌 Muslim Life — Islamic Companion App

**A feature-rich Flutter application for Muslim daily life**  
Prayer Times · Quran · Duas · Tasbeeh · Qibla · Hijri Calendar · Notifications

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20FCM-FFCA28?logo=firebase)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](https://flutter.dev)

</div>

---

## ✨ Features

### 🕐 Prayer Times
- GPS-based automatic location detection for accurate prayer times
- Adhan calculation using the [`adhan_dart`](https://pub.dev/packages/adhan_dart) library
- Live countdown ring to the next prayer
- Animated mosque hero widget on the home screen
- Timezone-aware scheduling with `flutter_timezone` and `lat_lng_to_timezone`

### 📖 Quran
- Full Quran reading with a page-flip animation effect
- Metadata-driven navigation via local JSON (`quran_metadata.json`)

### 🤲 Duas, Masail & Inspirational Quotes
- Content synced from **Firebase Firestore** to a local **SQLite** database (`sqflite`)
- Multilingual support: **English · Bengali · Arabic · Urdu**
- RTL layout auto-applied for Arabic and Urdu users
- User bookmarks and favorites synced via Firestore (requires login)

### 📿 Tasbeeh Counter
- Digital dhikr counter with haptic feedback (`vibration`)
- Audio click sound on each tap (`audioplayers`)

### 🧭 Qibla Finder
- Live compass-based Qibla direction using `flutter_compass`
- Works offline after initial calibration

### 📅 Hijri Calendar
- Dual display of Gregorian and Hijri dates
- Built with the `hijri` package

### 🔔 Smart Notifications
- Prayer time reminders via `flutter_local_notifications`
- Push notifications powered by **Firebase Cloud Messaging (FCM)**
- User-configurable notification preferences

### 👤 Authentication & Cloud Sync
- Email/password and Google Sign-In via **Firebase Auth**
- Firestore sync for bookmarks and favorites across devices
- Profile management with photo upload via Firebase Storage

---

## 🏗️ Architecture

This project follows the **BLoC / Cubit** pattern throughout, ensuring clear separation of concerns and testable business logic.

```
lib/
├── home/                   # Prayer times page (PrayerTimesCubit)
├── location/               # GPS & location management (LocationCubit)
├── notification/           # Local & push notifications (NotificationCubit)
├── settings/               # Theme & language management (SettingsCubit)
├── Duas/                   # Duas feature (DuasCubit + DuasRepository)
├── inspiration/            # Inspirational quotes (InspirationCubit)
├── masail/                 # Masail feature (MasailCubit)
├── Menu/                   # Auth & navigation (AuthController via GetX)
└── main.dart               # App entry point, BLoC providers, Firebase init
```

**State Management:** BLoC / Cubit (`flutter_bloc`) for all feature layers  
**Navigation:** `GetX` for global controller injection  
**Local DB:** `sqflite` with a `translations` table pattern + COALESCE JOINs for multilingual content  
**Remote DB:** Firebase Firestore with subcollection design for categories and items  
**Sync Strategy:** Firestore → SQLite on app start for offline-first experience

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x / Dart 3.x |
| **State Management** | flutter_bloc (Cubit pattern) |
| **Dependency Injection** | GetX |
| **Authentication** | Firebase Auth, Google Sign-In |
| **Remote Database** | Cloud Firestore |
| **Local Database** | SQLite (sqflite) |
| **File Storage** | Firebase Storage |
| **Push Notifications** | Firebase Cloud Messaging |
| **Local Notifications** | flutter_local_notifications |
| **Prayer Calculation** | adhan_dart |
| **Location** | geolocator, geocoding |
| **Compass / Qibla** | flutter_compass |
| **Offline Caching** | shared_preferences, sqflite |
| **Networking** | http, dio, connectivity_plus |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.x`
- Dart SDK `^3.10.8`
- Android Studio / Xcode
- A Firebase project with **Auth, Firestore, Storage, and FCM** enabled

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/muslim_app.git
cd muslim_app

# 2. Install dependencies
flutter pub get

# 3. Add Firebase config files
#    Android: place google-services.json  →  android/app/
#    iOS:     place GoogleService-Info.plist  →  ios/Runner/

# 4. Run the app
flutter run
```

> **Note:** `firebase_options.dart` is git-ignored. Generate it with:
> ```bash
> flutterfire configure
> ```

---

## 🌐 Multilingual Support

| Language | Code | Direction |
|---|---|---|
| English | `en` | LTR |
| Bengali | `bn` | LTR |
| Arabic | `ar` | **RTL** |
| Urdu | `ur` | **RTL** |

RTL layout is applied globally via `Directionality` in `MyApp`. The saved language preference is loaded from `SharedPreferences` before any cubit is initialized, ensuring zero UI flash on startup.

---

## 📦 Key Dependencies

```yaml
flutter_bloc: ^9.1.1                  # State management
firebase_core: ^4.6.0                 # Firebase initialization
cloud_firestore: ^6.2.0               # Remote database
firebase_auth: ^6.3.0                 # Authentication
sqflite: ^2.4.2                       # Local database
adhan_dart: ^2.0.1                    # Prayer time calculation
geolocator: ^14.0.2                   # GPS location
flutter_compass: ^0.8.1               # Qibla direction
hijri: ^3.0.0                         # Hijri calendar
flutter_local_notifications: ^21.0.0  # Local reminders
firebase_messaging: ^16.2.1           # Push notifications
get: ^4.6.6                           # Global controller injection
```

Full list in [`pubspec.yaml`](pubspec.yaml).

---

## 🔒 Permissions

| Permission | Purpose |
|---|---|
| `ACCESS_FINE_LOCATION` | GPS-based prayer times & Qibla |
| `INTERNET` | Firebase sync, FCM |
| `RECEIVE_BOOT_COMPLETED` | Reschedule notifications on reboot |
| `VIBRATE` | Tasbeeh haptic feedback |
| `POST_NOTIFICATIONS` | Android 13+ push notifications |

---

## 🧑‍💻 Developer Notes

- **Splash Screen** — handled natively via `flutter_native_splash` with a dark green (`#0A3D1F`) background and adaptive icon support for Android 12+.
- **Orientation** — locked to portrait on all screens.
- **Firebase init order** — Firebase is initialized before any cubit or controller to prevent silent auth failures.
- **AuthController** — registered as `permanent: true` via GetX to survive navigation without being garbage collected.

---

## 📄 License

This project is privately maintained. All rights reserved.

---

<div align="center">
  Made with ❤️ using Flutter &nbsp;|&nbsp; <i>Bismillah</i>
</div>