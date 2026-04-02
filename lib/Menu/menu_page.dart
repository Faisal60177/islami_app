import 'package:flutter/material.dart';
import 'package:islamic_app/Quran/quran_page.dart';
import 'package:islamic_app/Duas/pages/duas_page.dart';
import 'package:islamic_app/tools/tools_page.dart';
import 'package:islamic_app/home/home_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final List<Widget> _pages =  const [
    PrayerTimesPage(),
    ToolsPage(),
    QuranPage(),
    DuasPage(),
    MenuPage(),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF013220),
      appBar: AppBar(
        title: const Text(
          'Menu',
          textAlign: TextAlign.center,
        ),
        backgroundColor: const Color(0xFF49796B),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white,
        backgroundColor: const Color(0xFF013220),
        onTap: (index) {
          if (index != 4) { // 4 = MenuPage current index
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => _pages[index]),
            );
          }
        },
        items:  [
          const BottomNavigationBarItem(icon: Icon(Icons.today), label: "Today"),
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
}
