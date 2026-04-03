import 'package:flutter/material.dart';
import 'package:islamic_app/Quran/quran_page.dart';
import 'package:islamic_app/Duas/pages/duas_page.dart';
import 'package:islamic_app/tools/tools_page.dart';
import 'package:islamic_app/home/home_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

    // SCREEN DIMENSIONS
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.04;


    return Scaffold(
      backgroundColor: const Color(0xFF013220),
      appBar: AppBar(
        title: const Text(
          'Menu',
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF49796B),
      ),


      body: Padding(
        padding: EdgeInsets.all(padding),
        child: ListView(
          children: [

            _menuCard(
              icon: Icons.verified_user,
              title: "Profile",
              onTap: () {},
            ),

            _menuCard(
              icon: Icons.settings,
              title: "Settings",
              onTap: () {},
            ),

            _menuCard(
              icon: Icons.contact_mail,
              title: "Contact Us",
              onTap: () {},
            ),

            _menuCard(
              icon: Icons.share,
              title: "Share App",
              onTap: () {},
            ),

            _menuCard(
              icon: Icons.rate_review,
              title: "Rate Us",
              onTap: () {},
            ),


            _menuCard(
              icon: Icons.info,
              title: "About App",
              onTap: () {},
            ),

            _menuCard(
              icon: Icons.logout,
              title: "Sign Out",
              onTap: () {},
            ),
          ],
        ),
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
  Widget _menuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF49796B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.1),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white70,
          size: 16,
        ),
      ),
    );
  }


}
