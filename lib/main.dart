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
import 'duas/cubit/duas_cubit.dart';
import 'package:muslim_app/duas/repository/duas_repository.dart';
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
import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.siratalmustaqeem.muslimlife.audio',
    androidNotificationChannelName: 'Quran Tafsir Audio',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );

  await AlarmRingService.initialize();

  tz.initializeTimeZones();

  await NotificationService.instance.init();

  await NotificationService.instance.requestPermissions();

  await DailyRefillService.ensureChainStarted();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await AppInfo.init();

  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('language') ?? 'en';

  final locationStorage = LocationStorage();
  final prayerTimesStorage = PrayerTimesStorage();
  final permissionService = PermissionService();
  final locationRepository = LocationRepository();

  final duasRepository = DuasRepository();
  final inspirationRepository = InspirationRepository();
  final masailRepository = MasailRepository();

  await duasRepository.initDatabase();
  await inspirationRepository.initDatabase();
  await masailRepository.initDatabase();

  FlutterNativeSplash.remove();

  runApp(
    ProviderScope(
      child: MultiBlocProvider(
        providers: [
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
            create: (_) =>
                DuasCubit(duasRepository)..updateLanguage(savedLanguage),
          ),
          BlocProvider(
            create: (_) =>
                InspirationCubit(inspirationRepository)
                  ..updateLanguage(savedLanguage),
          ),
          BlocProvider(
            create: (_) =>
                MasailCubit(masailRepository)..updateLanguage(savedLanguage),
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
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final appTheme = getThemeById(settingsState.themeMode);

        final isRtl =
            settingsState.languageCode == 'ar' ||
            settingsState.languageCode == 'ur';

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Prayer Times App',
          theme: buildThemeData(appTheme),

          builder: (context, child) => Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),

          home: AlarmLaunchGate(child: const HomePage()),
        );
      },
    );
  }
}
