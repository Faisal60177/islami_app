import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:muslim_app/features/alarm/presentation/pages/alarm_launch_gate.dart';
import 'package:muslim_app/features/alarm/data/services/daily_refill_service.dart';
import 'package:muslim_app/features/location/presentation/cubit/location_cubit.dart';
import 'package:muslim_app/features/location/data/datasources/location_local_data_source.dart';
import 'package:muslim_app/core/services/permission_service.dart';
import 'package:muslim_app/features/location/data/repositories/location_repository.dart';
import 'package:muslim_app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:muslim_app/features/home/presentation/pages/home_page.dart';
import 'package:muslim_app/features/prayer_times/data/datasources/prayer_times_local_data_source.dart';
import 'package:muslim_app/features/duas/presentation/cubit/duas_cubit.dart';
import 'package:muslim_app/features/duas/data/repositories/duas_repository.dart';
import 'package:flutter/services.dart';
import 'package:muslim_app/firebase_options.dart';
import 'package:muslim_app/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:muslim_app/features/notification/data/repositories/notification_repository.dart';
import 'package:muslim_app/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:muslim_app/features/settings/presentation/cubit/settings_state.dart';
import 'package:muslim_app/app/theme/app_themes.dart';
import 'package:muslim_app/features/inspiration/presentation/cubit/inspiration_cubit.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:muslim_app/features/inspiration/data/repositories/inspiration_repository.dart';
import 'package:muslim_app/features/masail/presentation/cubit/masail_cubit.dart';
import 'package:muslim_app/features/masail/data/repositories/masail_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslim_app/features/alarm/presentation/cubit/alarm_cubit.dart';
import 'package:muslim_app/core/constants/app_info.dart';
import 'package:muslim_app/features/alarm/data/services/notification_service.dart';
import 'package:muslim_app/features/alarm/data/services/alarm_ring_service.dart';
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
