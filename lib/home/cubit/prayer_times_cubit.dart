import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/prayer_times_models.dart';
import 'prayer_times_state.dart';
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
    _locationStream = locationCubit.stream;
    _locationStream.listen((state) {
      if (state is LocationLoaded) {
        _calculateAndSavePrayerTimes(state.location);
      }
    });
  }

  // ── today's times on location change ─────────────────────────────────────

  Future<void> _calculateAndSavePrayerTimes(LocationModel location) async {
    emit(PrayerTimesLoading());
    try {
      final times = await PrayerTimesService.getPrayerTimesForLocation(
        location,
        location.timeZone,
      );
      await storage.savePrayerTimes(times);
      emit(PrayerTimesLoaded(times));
    } catch (e) {
      emit(PrayerTimesError("Failed to calculate prayer times: $e"));
    }
  }

  // ── any date — called by MonthlyCalendarPage ──────────────────────────────

  Future<PrayerTimesModel?> calculateForDate(DateTime date) async {
    final locState = locationCubit.state;
    if (locState is! LocationLoaded) return null;

    try {
      return await PrayerTimesService.getPrayerTimesForDate(
        locState.location,
        locState.location.timeZone,
        date,
      );
    } catch (e) {
      return null;
    }
  }

  // ── manual override ───────────────────────────────────────────────────────

  Future<void> updatePrayerTimes(LocationModel location, PrayerTimesModel updated) async {
    await storage.savePrayerTimes(updated);
    emit(PrayerTimesLoaded(updated));
  }
}