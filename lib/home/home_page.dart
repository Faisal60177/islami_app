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
import 'package:marquee/marquee.dart';
import 'mosque.dart';
import 'ring_animation.dart';



class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  String getHijriDate() {
    final hijri = HijriCalendar.now();
    return "${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH";
  }

  String getEnglishDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, d MMMM yyyy');
    return formatter.format(now);
  }

  final List<Widget> _pages = const [
    PrayerTimesPage(),
    ToolsPage(),
    QuranPage(),
    DuasPage(),
    MenuPage(),
  ];


  // ✅ CURRENT PRAYER
  String getCurrentPrayer(PrayerTimesModel t) {
    final now = DateTime.now();

    if (now.isAfter(t.fajrStart) && now.isBefore(t.fajrEnd)) return "Fajr";
    if (now.isAfter(t.sunRiseStart) && now.isBefore(t.sunRiseEnd)) return "SunRise";
    if (now.isAfter(t.sunRiseEnd) && now.isBefore(t.noonStart)) return "Ishraq";
    if (now.isAfter(t.noonStart) && now.isBefore(t.noonEnd)) return "Noon";
    if (now.isAfter(t.dhuhrStart) && now.isBefore(t.dhuhrEnd)) return "Dhuhr";
    if (now.isAfter(t.asrStart) && now.isBefore(t.asrEnd)) return "Asr";
    if (now.isAfter(t.sunSetStart) && now.isBefore(t.sunSetEnd)) return "SunSet";
    if (now.isAfter(t.maghribStart) && now.isBefore(t.maghribEnd)) return "Maghrib";
    if (now.isAfter(t.ishaStart) && now.isBefore(t.ishaEnd)) return "Isha";

    return "";
  }

  // ✅ COLOR FIX
  Color _prayerAccentColor(String name, String current) {
    return name == current ? Colors.green : Colors.red;
  }

  // ✅ RING DATA BUILDER
  List<PrayerRingEntry> buildRing(PrayerTimesModel t) {
    return [
      PrayerRingEntry(name: 'Fajr', start: t.fajrStart, end: t.sunRiseStart),
      PrayerRingEntry(name: 'SunRise', start: t.sunRiseStart, end: t.sunRiseEnd),
      PrayerRingEntry(name: 'Ishraq', start: t.sunRiseEnd, end: t.noonStart),
      PrayerRingEntry(name: 'Noon', start: t.noonStart, end: t.noonEnd),
      PrayerRingEntry(name: 'Dhuhr', start: t.dhuhrStart, end: t.asrStart),
      PrayerRingEntry(name: 'Asr', start: t.asrStart, end: t.maghribStart),
      PrayerRingEntry(name: 'SunSet', start: t.sunSetStart, end: t.sunSetEnd),
      PrayerRingEntry(name: 'Maghrib', start: t.maghribStart, end: t.ishaStart),
      PrayerRingEntry(name: 'Isha', start: t.ishaStart, end: t.tahajjudStart),
    ];
  }



  @override
  Widget build(BuildContext context) {

    // SCREEN DIMENSIONS
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.04; // 4% of screen width

    return Scaffold(
      backgroundColor: const Color(0xFF013220),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 2),
          child: Column(
            children: [
              // LOCATION + NOTIFICATION

                        Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BlocBuilder<LocationCubit, LocationState>(
                              builder: (context, state) {
                                String text = "Location";

                                if (state is LocationLoaded) {
                                  text = "${state.location.city}, ${state.location.country}";
                                } else if (state is LocationLoading) {
                                  text = "Location Loading...";
                                } else if (state is LocationPermissionDenied) {
                                  text = "Location Permission denied";
                                }

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const LocationPage()),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Color(0xFF4CAF50)),
                                      SizedBox(width: screenWidth * 0.02),
                                      SizedBox(
                                        width: screenWidth * 0.4, // space allocated for marquee
                                        height: screenHeight * 0.035,
                                        child: Marquee(
                                          text: text,
                                          style: TextStyle(
                                            color: Colors.grey[100],
                                            fontWeight: FontWeight.w600,
                                            fontSize: screenWidth * 0.04,
                                          ),
                                          velocity: 30.0,        // speed of scrolling
                                          pauseAfterRound: const Duration(seconds: 1),
                                          blankSpace: 20.0,      // gap between repeats
                                          startPadding: 0,
                                          accelerationDuration: const Duration(seconds: 1),
                                          accelerationCurve: Curves.linear,
                                          decelerationDuration: const Duration(seconds: 1),
                                          decelerationCurve: Curves.easeOut,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // Notification icon remains the same
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NotificationPage()),
                                );
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(Icons.notifications, color: Color(0xFFFF5252), size: screenWidth * 0.07),
                                  Positioned(
                                    right: -screenWidth * 0.015,
                                    top: -screenWidth * 0.015,
                                    child: Container(
                                      padding: EdgeInsets.all(screenWidth * 0.012),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '2',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.028,
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

              SizedBox(height: screenHeight * 0.02),

              // DATES
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getEnglishDate(),
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    getHijriDate(),
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.03),

              // PRAYER CARDS
              BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
                builder: (context, state) {
                  if (state is PrayerTimesLoading) {
                    return Center(child: CircularProgressIndicator());
                  } else if (state is PrayerTimesLoaded) {
                    final times = state.prayerTimes;
                    final current = getCurrentPrayer(times);
                    final ring = buildRing(times);


                    return Column(
                      children: [

                        // 🔥 MOSQUE + RING
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            MosqueIllustration(height: screenHeight * 0.28),
                            Positioned(
                              bottom: 10,
                              child: PrayerProgressRing(
                                entries: ring,
                                size: screenWidth * 0.55,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: screenHeight * 0.0),

                        /// Now the Prayer times Card
                        buildPrayerCard(
                          screenWidth,
                          "Salat Prayers",
                          [
                            prayerRow(screenWidth, Icons.wb_twilight, "Fajr",
                                "${_formatTime(times.fajrStart)} - ${_formatTime(times.fajrEnd)}"),
                            prayerRow(screenWidth, Icons.wb_sunny, "Dhuhr",
                                "${_formatTime(times.dhuhrStart)} - ${_formatTime(times.dhuhrEnd)}"),
                            prayerRow(screenWidth, Icons.cloud, "Asr",
                                "${_formatTime(times.asrStart)} - ${_formatTime(times.asrEnd)}"),
                            prayerRow(screenWidth, Icons.nightlight_round, "Maghrib",
                                "${_formatTime(times.maghribStart)} - ${_formatTime(times.maghribEnd)}"),
                            prayerRow(screenWidth, Icons.dark_mode, "Isha",
                                "${_formatTime(times.ishaStart)} - ${_formatTime(times.ishaEnd)}"),
                          ],
                        ),

                        buildPrayerCard(
                          screenWidth,
                          "Prohibited Times",
                          [
                            prayerRow(screenWidth, Icons.wb_twilight, "SunRise",
                                "${_formatTime(times.sunRiseStart)} - ${_formatTime(times.sunRiseEnd)}"),
                            prayerRow(screenWidth, Icons.wb_sunny, "Noon",
                                "${_formatTime(times.noonStart)} - ${_formatTime(times.noonEnd)}"),
                            prayerRow(screenWidth, Icons.cloud, "SunSet",
                                "${_formatTime(times.sunSetStart)} - ${_formatTime(times.sunSetEnd)}"),
                          ],
                        ),

                        buildPrayerCard(
                          screenWidth,
                          "Sawm Times",
                          [
                            prayerRow(screenWidth, Icons.wb_twilight, "Iftar Start",
                                "${_formatTime(times.iftarTime)}"),
                            prayerRow(screenWidth, Icons.wb_sunny, "Sahri End",
                                "${_formatTime(times.sahriEnd)}"),
                          ],
                        ),

                        buildPrayerCard(
                          screenWidth,
                          "Nafal Prayers",
                          [
                            prayerRow(screenWidth, Icons.cloud, "Tahajjud",
                                "${_formatTime(times.tahajjudStart)} - ${_formatTime(times.tahajjudEnd)}"),
                            prayerRow(screenWidth, Icons.wb_twilight, "Ishraq",
                                "${_formatTime(times.ishraqStart)} - ${_formatTime(times.ishraqEnd)}"),
                            prayerRow(screenWidth, Icons.wb_sunny, "Chasht",
                                "${_formatTime(times.chashtStart)} - ${_formatTime(times.chashtEnd)}"),
                            prayerRow(screenWidth, Icons.dark_mode, "Zawal",
                                "${_formatTime(times.zawalStart)}"),
                            prayerRow(screenWidth, Icons.nightlight_round, "Awabin",
                                "${_formatTime(times.awabinStart)} - ${_formatTime(times.awabinEnd)}"),
                          ],
                        ),
                      ],
                    );
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
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white,
        backgroundColor: const Color(0xFF013220),
        onTap: (index) {
          if (index != 0) { // 4 = MenuPage current index
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => _pages[index]),
            );
          }
        },
        items:  [
          BottomNavigationBarItem(icon: SizedBox(
            width: 30,
            height: 30,
            child: Image.asset('assets/icons/today.png'),
          ), label: "Today"),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 30,
              height: 30,
              child: Image.asset('assets/icons/tools.png'),
            ),
            label: "Tools",
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 30,
              height: 30,
              child: Image.asset('assets/icons/quran.png'),
            ),
            label: "Quran",
          ),
          BottomNavigationBarItem(icon: SizedBox(
            width: 30,
            height: 30,
            child: Image.asset('assets/icons/duas.png',),
          ),
            label: "Duas",),
          BottomNavigationBarItem(icon: SizedBox(
            width: 30,
            height: 30,
            child: Image.asset('assets/icons/menu.png',),
          ),
          label: "Menu",),
        ],
      ),
    );
  }

  // RESPONSIVE PRAYER ROW
  Widget prayerRow(double screenWidth, IconData icon, String name, String time) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Icon(icon, size: screenWidth * 0.07, color: Colors.white),
          SizedBox(width: screenWidth * 0.03),

          // Prayer Name
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          SizedBox(width: screenWidth * 0.03),

          // Prayer Time
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.centerRight, // always right edge
                  child: FittedBox(
                    fit: BoxFit.scaleDown, // shrink only if too long
                    alignment: Alignment.centerRight,
                    child: Text(
                      time,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // RESPONSIVE PRAYER CARD
  Widget buildPrayerCard(double screenWidth, String title, List<Widget> children) {
    return Card(
      color: const Color(0xFF74C365),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.00001,
        vertical: screenWidth * 0.02,
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenWidth * 0.03),
            ...children,
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $ampm";
  }
}