import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:islamic_app/Quran/quran_page.dart';
import 'package:islamic_app/location/home/location_page.dart';
import 'package:islamic_app/tools/tools_page.dart';
import '../../../location/cubit/location_cubit.dart';
import '../../../location/cubit/location_state.dart';
import 'package:islamic_app/home/cubit/prayer_times_cubit.dart';
import 'package:islamic_app/home/state/prayer_times_state.dart';
import '../../../home/model/prayer_times_models.dart';
import 'package:intl/intl.dart';
import 'package:islamic_app/Duas/pages/duas_page.dart';
import 'package:islamic_app/Menu/menu_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:islamic_app/notification/page/notification_page.dart';
import 'package:hijri/hijri_calendar.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {

  String getHijriDate() {
    final hijri = HijriCalendar.now();
    // Get English weekday of today
    final now = DateTime.now();
    final weekday = DateFormat('EEEE').format(now); // e.g., Wednesday


    return "${weekday}, ${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH";
  }

  String getEnglishDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, d MMMM yyyy'); // e.g., Wednesday, 18 March 2026
    return formatter.format(now);
  }

  final List<Widget> _pages = const [
    PrayerTimesPage(),
    ToolsPage(),
    QuranPage(),
    DuasPage(),
    MenuPage(),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF013220),
      body: SingleChildScrollView(child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BlocBuilder<LocationCubit, LocationState>(
                  builder: (context, state) {
                    String text = "Location";

                    if (state is LocationLoaded) {
                      text = "${state.location.city}, ${state.location.country}";
                    } else if (state is LocationLoading) {
                      text = " Location Loading...";
                    } else if (state is LocationPermissionDenied) {
                      text = " Location Permission denied";
                    }
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LocationPage()),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 24),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 140, // limit text width
                            child: Text(
                              text,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // 🔹 RIGHT: Notification
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotificationPage()),
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications, color: Colors.red, size: 28),
                      // Optional badge
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20,),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getEnglishDate(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red),
                ),
                const SizedBox(width: 12),
                Text(
                  getHijriDate(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 200,),

          // 3️⃣ Scrollable Prayer Cards
            BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
              builder: (context, state) {
                if (state is PrayerTimesLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is PrayerTimesLoaded) {
                  final times = state.prayerTimes;
                  return Column(
                      children: [

                        Card(
                          color: Color(0xFF00693E),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                const Text(
                                  "Salat Prayers",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                prayerRow(
                                  Icons.wb_twilight,
                                  "Fajr",
                                  "${_formatTime(times.fajrStart)} - ${_formatTime(times.fajrEnd)}",
                                ),

                                const SizedBox(height: 12),

                                prayerRow(
                                  Icons.wb_sunny,
                                  "Dhuhr",
                                  "${_formatTime(times.dhuhrStart)} - ${_formatTime(times.dhuhrEnd)}",
                                ),

                                const SizedBox(height: 12),

                                prayerRow(
                                  Icons.cloud,
                                  "Asr",
                                  "${_formatTime(times.asrStart)} - ${_formatTime(times.asrEnd)}",
                                ),

                                const SizedBox(height: 12),

                                prayerRow(
                                  Icons.nightlight_round,
                                  "Maghrib",
                                  "${_formatTime(times.maghribStart)} - ${_formatTime(times.maghribEnd)}",
                                ),

                                const SizedBox(height: 12),

                                prayerRow(
                                  Icons.dark_mode,
                                  "Isha",
                                  "${_formatTime(times.ishaStart)} - ${_formatTime(times.ishaEnd)}",
                                ),
                              ],
                            ),
                          ),
                        ),



                        const SizedBox(height: 0),

                        Card(
                          color: Color(0xFF00693E),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                const Text(
                                  "Prohibited Times",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                prayerRow(
                                  Icons.wb_twilight,
                                  "SunRise",
                                  "${_formatTime(times.sunRiseStart)} - ${_formatTime(times.sunRiseEnd)}",
                                ),

                                const SizedBox(height: 12),

                                prayerRow(
                                  Icons.wb_sunny,
                                  "Noon",
                                  "${_formatTime(times.noonStart)} - ${_formatTime(times.noonEnd)}",
                                ),

                                const SizedBox(height: 12),

                                prayerRow(
                                  Icons.cloud,
                                  "SunSet",
                                  "${_formatTime(times.sunSetStart)} - ${_formatTime(times.sunSetEnd)}",
                                ),

                                const SizedBox(height: 0),

                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 0),

                        Card(
                          color: Color(0xFF00693E),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                const Text(
                                  "Sawm Times",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                prayerRow(
                                  Icons.wb_twilight,
                                  "Iftar Start",
                                  "${_formatTime(times.iftarTime)}",
                                ),

                                const SizedBox(height: 12),

                                prayerRow(
                                  Icons.wb_sunny,
                                  "Sahri End",
                                  "${_formatTime(times.sahriEnd)}",
                                ),

                                const SizedBox(height: 0),

                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 0),

                        Card(
                          color: Color(0xFF00693E),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                const Text(
                                  "Nafal Prayers",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                prayerRow(
                                  Icons.cloud,
                                  "Tahajjud",
                                  "${_formatTime(times.tahajjudStart)} - ${_formatTime(times.tahajjudEnd)}",
                                ),

                                const SizedBox(height: 12),

                                prayerRow(
                                  Icons.wb_twilight,
                                  "Ishraq",
                                  "${_formatTime(times.ishraqStart)} - ${_formatTime(times.ishraqEnd)}",
                                ),

                                const SizedBox(height: 12),

                                prayerRow(
                                  Icons.wb_sunny,
                                  "Chasht",
                                  "${_formatTime(times.chashtStart)} - ${_formatTime(times.chashtEnd)}",
                                ),

                                const SizedBox(height: 12),

                                prayerRow(
                                  Icons.dark_mode,
                                  "Zawal",
                                  "${_formatTime(times.zawalStart)}",
                                ),
                                const SizedBox(height: 12),

                                prayerRow(
                                  Icons.nightlight_round,
                                  "Awabin",
                                  "${_formatTime(times.awabinStart)} - ${_formatTime(times.awabinEnd)}",
                                ),
                                const SizedBox(height: 0),

                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),

                      ],
                  );

                  return const SizedBox();

                } else if (state is PrayerTimesError) {
                  return Center(child: Text(state.message));
                } else {
                  return const SizedBox();
                }
              },
            ),
        ],
      ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.blue,
        backgroundColor: Colors.white,
        onTap: (index) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => _pages[index]),
            );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: "Today"),
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.tools), label: "tools"),
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.quran), label: "Quran"),
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.pray), label: "Duas"),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: "Menu"),
        ],
      ),


    );
  }

  Widget prayerRow(IconData icon, String name, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 26,
          color: Colors.blueAccent,
        ),

        const SizedBox(width: 12),

        // Expanded ensures the text doesn't overflow and shrinks if needed
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis, // prevents yellow box on small width
          ),
        ),

        const SizedBox(width: 12),

        // Wrap time in Flexible to prevent overflow
        Flexible(
          child: Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis, // optional
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }



  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $ampm";
  }
}