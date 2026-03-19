import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/prayer_times_models.dart';
import '../state/prayer_times_state.dart';
import '../services/prayer_times_service.dart';
import '../../../location/cubit/location_cubit.dart';
import '../../../location/cubit/location_state.dart';
import '../../../location/model/location_model.dart';
import 'package:islamic_app/home/services/prayer_times_storage.dart';

class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  final LocationCubit locationCubit;
  final PrayerTimesStorage storage;

  late final Stream<LocationState> _locationStream;

  PrayerTimesCubit({required this.locationCubit, required this.storage})
      : super(PrayerTimesInitial()) {
    // Listen to any location change
    _locationStream = locationCubit.stream;
    _locationStream.listen((state) {
      if (state is LocationLoaded) {
        // Calculate and save prayer times whenever location changes
        _calculateAndSavePrayerTimes(state.location);
      }
    });
  }

  /// Calculate prayer times and save immediately
  Future<void> _calculateAndSavePrayerTimes(LocationModel location) async {
    emit(PrayerTimesLoading());

    try {
      final times = await PrayerTimesService.getPrayerTimesForLocation(
        location,
        "Asia/Dhaka", // Change your timezone if needed
      );

      // Save to SharedPreferences
      await storage.savePrayerTimes(times);

      emit(PrayerTimesLoaded(times));
    } catch (e) {
      emit(PrayerTimesError("Failed to calculate prayer times: $e"));
    }
  }

  /// Optional: manually update prayer times
  Future<void> updatePrayerTimes(LocationModel location, PrayerTimesModel updated) async {
    await storage.savePrayerTimes(updated);
    emit(PrayerTimesLoaded(updated));
  }
}