import 'package:flutter/material.dart';
import 'package:islamic_app/Menu/menu_page.dart';
import 'package:islamic_app/Quran/quran_page.dart';
import 'package:islamic_app/home/home_page.dart';
import 'package:islamic_app/Duas/pages/duas_page.dart';
import 'package:islamic_app/tasbih/tasbih_page.dart';
import 'package:islamic_app/inspiration/inspiration_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:islamic_app/notification/page/notification_page.dart';
import 'package:islamic_app/calendar/pages/calendar_page.dart';
import 'package:islamic_app/qibla/pages/qibla_page.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  final List<Widget> _pages = const [
    PrayerTimesPage(),
    ToolsPage(),
    QuranPage(),
    DuasPage(),
    MenuPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // SCREEN DIMENSIONS
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.04;

    // Scalable sizes
    final iconSize = screenWidth * 0.08; // ~8% of screen width
    final fontSize = screenWidth * 0.035; // ~3.5% of screen width

    // Dynamic crossAxisCount based on screen width
    int crossAxisCount = screenWidth > 900
        ? 5
        : screenWidth > 600
        ? 4
        : 3;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Tools',
          textAlign: TextAlign.center,
        ),
        backgroundColor: const Color(0xFF49796B),
      ),
      backgroundColor: const Color(0xFF013220),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.03,
            horizontal: padding,
          ),
          child: Column(
            children: [
              // Knowledge Section
              _buildSection(
                context,
                title: "Knowledge",
                tools: [
                  _toolItem(
                    "Quran",
                       Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'assets/icons/quran.png',  // your image path
                          fit: BoxFit.contain,
                        ),
                      ),

                        () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => QuranPage()));
                    },
                    fontSize,
                  ),
                  _toolItem(
                    "Duas",
                    Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'assets/icons/duas.png',  // your image path
                          fit: BoxFit.contain,
                        ),
                    ),
                        () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => DuasPage()));
                    },
                    fontSize,
                  ),
                  _toolItem(
                    "Masail",
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        'assets/icons/masail.png',  // your image path
                        fit: BoxFit.contain,
                      ),
                    ),
                        () => print("Masail tapped"),
                    fontSize,
                  ),
                ],
                crossAxisCount: crossAxisCount,
              ),

              SizedBox(height: screenHeight * 0.03),

              // Amal Section
              _buildSection(
                context,
                title: "Amal",
                tools: [
                  _toolItem(
                    "Tasbih",
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/icons/tasbih.png',  // your image path
                        fit: BoxFit.contain,
                      ),
                    ),
                        () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => TasbihPage()));
                    },
                    fontSize,
                  ),
                  _toolItem(
                    "Prayer Times",
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/icons/prayer_time.png',  // your image path
                        fit: BoxFit.contain,
                      ),
                    ),
                        () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => PrayerTimesPage()));
                    },
                    fontSize,
                  ),
                  _toolItem(
                    "Inspiration",
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/icons/inspiration.png',  // your image path
                        fit: BoxFit.contain,
                      ),
                    ),
                        () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => InspirationPage()));
                    },
                    fontSize,
                  ),
                ],
                crossAxisCount: crossAxisCount,
              ),

              SizedBox(height: screenHeight * 0.03),

              // Tools Section
              _buildSection(
                context,
                title: "Tools",
                tools: [
                  _toolItem(
                    "Qibla",
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(
                        'assets/icons/qibla.png',  // your image path
                        fit: BoxFit.contain,
                      ),
                    ),
                        () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => QiblaPage()));
                    },
                    fontSize,
                  ),
                  _toolItem(
                    "Calendar",
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(
                        'assets/icons/calendar.png',  // your image path
                        fit: BoxFit.contain,
                      ),
                    ),
                        () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => CalendarPage()));
                    },
                    fontSize,
                  ),
                  _toolItem(
                    "Notification",
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(
                        'assets/icons/notification.png',  // your image path
                        fit: BoxFit.contain,
                      ),
                    ),
                        () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => NotificationPage()));
                    },
                    fontSize,
                  ),
                  _toolItem(
                    "Menu",
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                    child: Image.asset(
                      'assets/icons/menu.png',  // your image path
                      fit: BoxFit.contain,
                      ),
                    ),
                                    () {
                      Navigator.push(
                          context, MaterialPageRoute(builder: (_) => MenuPage()));
                    },
                    fontSize,
                  ),
                ],
                crossAxisCount: crossAxisCount,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white,
        backgroundColor: const Color(0xFF013220),
        onTap: (index) {
          if (index != 1) {
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

  /// Reusable section builder
  Widget _buildSection(BuildContext context,
      {required String title,
        required List<Widget> tools,
        required int crossAxisCount}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: tools,
        ),
      ],
    );
  }

  /// Tool item widget (works for Icon or FaIcon)
  Widget _toolItem(String title, Widget iconWidget, VoidCallback onTap, double fontSize) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(padding: EdgeInsets.all(5),
          child:
        Column(
          children: [
            Expanded(
              flex: 3, // 🔥 icon takes more space
              child: Align(
                alignment: Alignment.bottomCenter, // 🔥 push icon down
                child: iconWidget,
              ),
            ),

            // 🔽 VERY SMALL GAP
            const SizedBox(height: 0.1),

            Expanded(
              flex: 1, // 🔥 text takes less space
              child: Center(
                child: Align(
                  alignment: Alignment.topCenter, // 🔥 pull text up
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize * 1, // 🔥 slightly smaller
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}