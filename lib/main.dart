import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'alarm/pages/alarm_launch_gate.dart';
import 'alarm/services/daily_refill_service.dart';
import 'location/cubit/location_cubit.dart';
import 'location/services/location_storage.dart';
import 'location/services/permission_service.dart';
import 'location/repository/location_repository.dart';
import 'home/cubit/prayer_times_cubit.dart';
import 'home/home_page.dart';
import 'home/services/prayer_times_storage.dart';
import 'Duas/cubit/duas_cubit.dart';
import 'package:muslim_app/Duas/repository/duas_repository.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'package:muslim_app/notification/cubit/notification_cubit.dart';
import 'package:muslim_app/notification/repository/notification_repository.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import 'inspiration/cubit/inspiration_cubit.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'inspiration/repository/inspiration_repository.dart';
import 'package:muslim_app/masail/cubit/masail_cubit.dart';
import 'package:muslim_app/masail/repository/masail_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'alarm/cubit/alarm_cubit.dart';
import 'package:muslim_app/core/app_info.dart';
import 'package:muslim_app/alarm/services/notification_service.dart';
import 'package:muslim_app/alarm/services/alarm_ring_service.dart';

void main() async {
  // ── 1. Flutter binding — must always be first ──────────────────────────
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // ── 2. UI setup — no dependencies, safe to run early ────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // ── 3. Alarm/notification system — strict order required ───────────────
  // AndroidAlarmManager must init first (plugin requirement: as early as
  // possible, right after the Flutter binding is ready).
  await AlarmRingService.initialize();


  // Timezone data must be loaded before NotificationService.init() runs,
  // since that call sets tz.local using this data.
  tz.initializeTimeZones();

  // Creates notification channels and sets the local timezone location.
  await NotificationService.instance.init();

  // Must come after init() — requesting permission before channels exist
  // is safe but pointless; keeping it after init() avoids any ordering risk.
  await NotificationService.instance.requestPermissions();

  // Registers the daily WorkManager task. Must come AFTER notifications
  // are initialized and permitted — the background task calls
  // NotificationService.instance.init() again internally (safe, it's
  // idempotent) but scheduling before permissions exist would risk the
  // first background run silently failing to post anything.
  await DailyRefillService.ensureChainStarted();

  // ── 4. Firebase ──────────────────────────────────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── 5. App metadata ──────────────────────────────────────────────────────
  await AppInfo.init();

  // ── 6. Saved language, needed before creating language-aware cubits ─────
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('language') ?? 'en';

  // ── 7. Storage / repository instances ─────────────────────────────────────
  final locationStorage    = LocationStorage();
  final prayerTimesStorage = PrayerTimesStorage();
  final permissionService  = PermissionService();
  final locationRepository = LocationRepository();

  final duasRepository        = DuasRepository();
  final inspirationRepository = InspirationRepository();
  final masailRepository      = MasailRepository();

  // ── 8. Pre-built SQLite copies — no internet required ────────────────────
  await duasRepository.initDatabase();
  await inspirationRepository.initDatabase();
  await masailRepository.initDatabase();

  // ── 9. Splash removed only once everything above is ready ────────────────
  FlutterNativeSplash.remove();

  runApp(
    ProviderScope(
      child: MultiBlocProvider(
        providers: [
          // Settings first — theme/language wraps the whole app.
          BlocProvider<SettingsCubit>(create: (_) => SettingsCubit()),

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
            create: (_) => DuasCubit(duasRepository)
              ..updateLanguage(savedLanguage),
          ),
          BlocProvider(
            create: (_) => InspirationCubit(inspirationRepository)
              ..updateLanguage(savedLanguage),
          ),
          BlocProvider(
            create: (_) => MasailCubit(masailRepository)
              ..updateLanguage(savedLanguage),
          ),
          BlocProvider(create: (_) => AlarmCubit()..load()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ── React to settings changes so theme + RTL apply globally ─────────────
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final appTheme = getThemeById(settingsState.themeMode);

        // Arabic & Urdu are RTL
        final isRtl = settingsState.languageCode == 'ar' ||
            settingsState.languageCode == 'ur';

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Prayer Times App',
          theme: buildThemeData(appTheme),

          // ── RTL / LTR support ─────────────────────────────────────────
          builder: (context, child) => Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),

          home: AlarmLaunchGate(
              child: const PrayerTimesPage(),
            ),
        );
      },
    );
  }
}