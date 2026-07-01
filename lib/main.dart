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
import 'package:muslim_app/Duas/repository/duas_repository.dart';
import 'package:flutter/services.dart';
import 'package:muslim_app/Menu/auth/auth_notifier.dart';
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




void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize timezone package
  tz.initializeTimeZones();

  // ✅ Always pass DefaultFirebaseOptions — prevents silent auth failures
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Load saved language BEFORE creating cubits ──────────────
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('language') ?? 'en';


  // Initialize storage classes
  final locationStorage    = LocationStorage();
  final prayerTimesStorage = PrayerTimesStorage();
  final permissionService  = PermissionService();
  final locationRepository = LocationRepository();

  final duasRepository        = DuasRepository();
  final inspirationRepository = InspirationRepository();
  final masailRepository      = MasailRepository();

  // ✅ Pre-built SQLite copy — internet লাগে না
  await duasRepository.initDatabase();
  await inspirationRepository.initDatabase();
  await masailRepository.initDatabase();


  FlutterNativeSplash.remove();

  runApp(
      ProviderScope(child:
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
      ],
      child: const MyApp(),
    ),
  )
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
          builder: (context, child)
            => Directionality(
              textDirection:
              isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: child!,

            ),

          home: const PrayerTimesPage(),
        );
      },
    );
  }
}