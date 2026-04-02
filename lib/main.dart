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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown, // optional, allows upside-down portrait
  ]);

  // Initialize timezone package
  tz.initializeTimeZones();

  // Initialize storage classes
  final locationStorage = LocationStorage();
  final prayerTimesStorage = PrayerTimesStorage();
  final permissionService = PermissionService();
  final locationRepository = LocationRepository();

  // 🔹 NEW: Duas Repository
  final duasRepository = DuasRepository();
  await Firebase.initializeApp();

  // 🔥 VERY IMPORTANT: Sync JSON → SQLite
  // First sync categories
  await duasRepository.syncCategoriesFromJson('assets/json/categories.json');
  await duasRepository.syncDuasFromJson('assets/json/duas.json');

  // FireStore to SQFlite

  await duasRepository.syncCategoriesFromFirestore();
  await duasRepository.syncDuasFromFirestore();


  // Run app
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LocationCubit(
            locationRepository,
            locationStorage,
            permissionService,
          )..loadSavedLocation(), // load last saved location on app start
        ),
        BlocProvider(
          create: (context) => PrayerTimesCubit(
            locationCubit: context.read<LocationCubit>(),
            storage: prayerTimesStorage,
          ),
        ),

        // 🔹 NEW: Duas Cubit
        BlocProvider(
          create: (_) => DuasCubit(duasRepository)..loadAllDuas(),
        ),

      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prayer Times App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const PrayerTimesPage(),
    );
  }
}