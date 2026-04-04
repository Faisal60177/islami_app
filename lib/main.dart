import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'location/cubit/location_cubit.dart';
import 'location/services/location_storage.dart';
import 'location/services/permission_service.dart';
import 'location/repository/location_repository.dart';
import 'home/cubit/prayer_times_cubit.dart';
import 'home/home_page.dart';
import 'home/services/prayer_times_storage.dart';
import 'Duas/cubit/duas_cubit.dart';
import 'package:islamic_app/Duas/repository/duas_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:islamic_app/Menu/auth/auth_controller.dart';
import 'firebase_options.dart';
import 'package:islamic_app/notification/cubit/notification_cubit.dart';
import 'package:islamic_app/notification/repository/notification_repository.dart';

// ── Settings imports ──────────────────────────────────────────────────────────
import 'package:islamic_app/settings/cubit/settings_cubit.dart';
import 'package:islamic_app/settings/cubit/settings_state.dart';
import 'package:islamic_app/settings/theme/app_themes.dart';

// ── Prayer Times Page ─────────────────────────────────────────────────────────
import 'package:islamic_app/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize timezone package
  tz.initializeTimeZones();

  // ✅ Always pass DefaultFirebaseOptions — prevents silent auth failures
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Register AuthController AFTER Firebase is ready
  Get.put(AuthController());

  // Initialize storage classes
  final locationStorage    = LocationStorage();
  final prayerTimesStorage = PrayerTimesStorage();
  final permissionService  = PermissionService();
  final locationRepository = LocationRepository();

  // Duas Repository
  final duasRepository = DuasRepository();

  // Sync JSON → SQLite
  await duasRepository.syncCategoriesFromJson('assets/json/categories.json');
  await duasRepository.syncDuasFromJson('assets/json/duas.json');

  // Firestore → SQLite
  await duasRepository.syncCategoriesFromFirestore();
  await duasRepository.syncDuasFromFirestore();

  runApp(
    MultiBlocProvider(
      providers: [
        // ── Settings (must be first — theme/language wraps the whole app) ──
        BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit(),
        ),

        BlocProvider(
          create: (_) => LocationCubit(
            locationRepository,
            locationStorage,
            permissionService,
          )..loadSavedLocation(),
        ),
        BlocProvider(
          create: (context) => PrayerTimesCubit(
            locationCubit: context.read<LocationCubit>(),
            storage: prayerTimesStorage,
          ),
        ),
        BlocProvider(
          create: (_) => NotificationCubit(NotificationRepository()),
        ),
        BlocProvider(
          create: (_) => DuasCubit(duasRepository)..loadAllDuas(),
        ),
      ],
      child:  MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
   MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ── React to settings changes so theme + RTL apply globally ─────────────
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final appTheme = getThemeById(settingsState.themeMode);

        // Arabic & Urdu are RTL
        final isRtl = settingsState.languageCode == 'ar' ||
            settingsState.languageCode == 'ur';

        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Prayer Times App',
          theme: buildThemeData(appTheme),

          // ── RTL / LTR support ─────────────────────────────────────────
          builder: (context, child) {
            return Directionality(
              textDirection:
              isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            );
          },

          home: PrayerTimesPage(),
        );
      },
    );
  }
}