import 'package:flutter/material.dart';
import 'package:islamic_app/Menu/menu_page.dart';
import 'package:islamic_app/Quran/quran_page.dart';
import 'package:islamic_app/home/home_page.dart';
import 'package:islamic_app/home/home_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:islamic_app/Quran/quran_page.dart';
import 'package:islamic_app/Duas/cubit/duas_cubit.dart';
import 'package:islamic_app/Duas/pages/duas_page.dart';
import 'package:islamic_app/tasbih/tasbih_page.dart';
import 'package:islamic_app/inspiration/inspiration_page.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text('Tools'), backgroundColor: Color(0xFF49796B),),
      backgroundColor: Color(0xFF004225),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(12.0),
        child: Column(
          children: [
            /// Card 1
            Card(
              color: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SizedBox(
            width: double.infinity, // take full width minus margin
            height: 140, // fixed height, adjust as needed
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Card Title
                    const Text(
                      "Knowledge",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 🔹 Buttons Grid / Wrap

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [

                        // Button 1
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => QuranPage()),
                              );
                            },
                            child: Column(
                              children: const [
                                FaIcon(FontAwesomeIcons.quran, color: Color(0xFF414A4C), size: 50),
                                SizedBox(height: 6),
                                Text(
                                  "Quran",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Button 2
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => DuasPage()),
                              );
                            },
                            child: Column(
                              children: const [
                                FaIcon(FontAwesomeIcons.pray, color: Colors.green, size: 50),
                                SizedBox(height: 6),
                                Text(
                                  "Dua",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Button 3
                        Expanded(
                          child: GestureDetector(
                            onTap: () => print("Masail tapped"),
                            child: Column(
                              children: const [
                                Icon(Icons.book, color: Colors.blue, size: 50),
                                SizedBox(height: 6),
                                Text(
                                  "Masail",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )

                  ],
                ),
              ),
            ),
            ),

            /// Card 2
            Card(
              color: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: SizedBox(
                width: double.infinity, // take full width minus margin
                height: 140, // fixed height, adjust as needed
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Card Title
                      const Text(
                        "Amal",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 🔹 Buttons Grid / Wrap

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [

                          // Button 1
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => TasbihPage()),
                                );
                              },
                              child: Column(
                                children: const [
                                  FaIcon(FontAwesomeIcons.quran, color: Colors.blue, size: 50),
                                  SizedBox(height: 6),
                                  Text(
                                    "Tasbih",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Button 2
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PrayerTimesPage()),
                                );
                              },
                              child: Column(
                                children: const [
                                  FaIcon(FontAwesomeIcons.pray, color: Colors.blue, size: 50),
                                  SizedBox(height: 6),
                                  Text(
                                    "Prayer Times",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        ],
                      )

                    ],
                  ),
                ),
              ),
            ),

            /// Card 3
            Card(
              color: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: SizedBox(
                width: double.infinity, // take full width minus margin
                height: 140, // fixed height, adjust as needed
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Card Title
                      const Text(
                        "Tools",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 🔹 Buttons Grid / Wrap

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [

                          // Button 1
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => QuranPage()),
                                );
                              },
                              child: Column(
                                children: const [
                                  FaIcon(FontAwesomeIcons.quran, color: Colors.blue, size: 50),
                                  SizedBox(height: 6),
                                  Text(
                                    "Qibla",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Button 2
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => InspirationPage()),
                                );
                              },
                              child: Column(
                                children: const [
                                  FaIcon(FontAwesomeIcons.penClip, color: Colors.red, size: 50),
                                  SizedBox(height: 6),
                                  Text(
                                    "Inspiration",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Button 3
                          Expanded(
                            child: GestureDetector(
                              onTap: () => print("Masail tapped"),
                              child: Column(
                                children: const [
                                  Icon(Icons.book, color: Colors.blue, size: 50),
                                  SizedBox(height: 6),
                                  Text(
                                    "Masail",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )

                    ],
                  ),
                ),
              ),
            ),

            ///Card 3
            Card(
              color: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: SizedBox(
                width: double.infinity, // take full width minus margin
                height: 200, // fixed height, adjust as needed
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Card Title
                      const Text(
                        "Knowledge",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 🔹 Buttons Grid / Wrap

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [

                          // Button 1
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => QuranPage()),
                                );
                              },
                              child: Column(
                                children: const [
                                  FaIcon(FontAwesomeIcons.quran, color: Colors.blue, size: 50),
                                  SizedBox(height: 6),
                                  Text(
                                    "Quran",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Button 2
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => DuasPage()),
                                );
                              },
                              child: Column(
                                children: const [
                                  FaIcon(FontAwesomeIcons.pray, color: Colors.blue, size: 50),
                                  SizedBox(height: 6),
                                  Text(
                                    "Dua",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Button 3
                          Expanded(
                            child: GestureDetector(
                              onTap: () => print("Masail tapped"),
                              child: Column(
                                children: const [
                                  Icon(Icons.book, color: Colors.blue, size: 50),
                                  SizedBox(height: 6),
                                  Text(
                                    "Masail",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )

                    ],
                  ),
                ),
              ),
            ),


          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
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
}