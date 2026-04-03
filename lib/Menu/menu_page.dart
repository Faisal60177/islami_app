import 'package:flutter/material.dart';
import 'package:islamic_app/Quran/quran_page.dart';
import 'package:islamic_app/Duas/pages/duas_page.dart';
import 'package:islamic_app/tools/tools_page.dart';
import 'package:islamic_app/home/home_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';



// ─── Palette ────────────────────────────────────────────────────────────────
const _surface   = Color(0xFF0D2E1C);   // card base
const _accent    = Color(0xFF4CAF82);   // vibrant jade
const _accentSoft= Color(0xFF2E7D5A);   // muted jade
const _textLo    = Color(0xFF7BAF92);   // muted sage

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

      bottomNavigationBar: _buildNav(),

    );


  }

  // ── Bottom Nav ──────────────────────────────────────────────────────────
  Widget _buildNav() {
    final items = [
      ('Today',  'assets/icons/today.png'),
      ('Tools',  'assets/icons/tools.png'),
      ('Quran',  'assets/icons/quran.png'),
      ('Duas',   'assets/icons/duas.png'),
      ('Menu',   'assets/icons/menu.png'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _accentSoft.withOpacity(0.25), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final label = e.value.$1;
              final asset = e.value.$2;
              final active = i == 4;

              return GestureDetector(
                onTap: () {
                  if (!active) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => _pages[i]));
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? _accentSoft.withOpacity(0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(asset,
                          width: 24, height: 24,
                          ),
                      const SizedBox(height: 4),
                      Text(label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: active ? _accent : _textLo,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
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
