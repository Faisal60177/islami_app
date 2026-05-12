import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Pages
import 'profile/profile_page.dart';
import 'package:muslim_app/settings/pages/settings_page.dart';
import 'contact/contact_page.dart';
import 'share/share_page.dart';
import 'rate/rate_page.dart';
import 'about/about_page.dart';
import 'auth/sign_out_page.dart';
import 'auth/auth_controller.dart';
import 'package:muslim_app/home/home_page.dart';
import 'package:muslim_app/tools/tools_page.dart';
import 'package:muslim_app/Quran/quran_page.dart';
import 'package:muslim_app/Duas/pages/duas_page.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const _bg        = Color(0xFF011A0E);
const _surface   = Color(0xFF0D2E1C);
const _card      = Color(0xFF122E1E);
const _accent    = Color(0xFF4CAF82);
const _accentSoft= Color(0xFF2E7D5A);
const _gold      = Color(0xFFD4AF37);
const _textHi    = Color(0xFFE8F5EC);
const _textLo    = Color(0xFF7BAF92);

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  // ✅ Updated to use real pages with asset icon nav
  static final List<Widget> _pages = [
    const PrayerTimesPage(),
    const ToolsPage(),
    const QuranPage(),
    const DuasPage(),
    const MenuPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildNav(context),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: _surface,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accentSoft.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('🕌', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          const Text(
            'Menu',
            style: TextStyle(
              color: _textHi,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      actions: [
        Obx(() {
          final auth = Get.find<AuthController>();
          if (auth.isLoggedIn) {
            return GestureDetector(
              onTap: () => Get.to(() => const ProfilePage()),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                width: 38, height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentSoft,
                  border: Border.all(color: _gold.withOpacity(0.5)),
                ),
                child: auth.photoUrl.value.isNotEmpty
                    ? ClipOval(
                    child: Image.network(auth.photoUrl.value,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _initials(auth.displayName.value)))
                    : _initials(auth.displayName.value),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _initials(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'M',
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return LayoutBuilder(                                         // ← responsive
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth > 600 ? 24.0 : 16.0;
        return SingleChildScrollView(
          child: Column(
            children: [
              _UserGreetingCard(),
              Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Account'),
                    const SizedBox(height: 10),
                    _MenuSection(items: [
                      _MenuItem(
                        icon: Icons.person_rounded,
                        iconColor: const Color(0xFF4CAF82),
                        title: 'Profile',
                        subtitle: 'View & edit your profile',
                        page: const ProfilePage(),
                      ),
                      // ── NEW Settings entry ──────────────────────────────
                      _MenuItem(
                        icon: Icons.settings_rounded,
                        iconColor: const Color(0xFF9E9E9E),
                        title: 'Settings',
                        subtitle: 'App preferences & configuration',
                        page: const SettingsPage(),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _sectionLabel('Support'),
                    const SizedBox(height: 10),
                    _MenuSection(items: [
                      _MenuItem(
                        icon: Icons.headset_mic_outlined,
                        iconColor: const Color(0xFF2196F3),
                        title: 'Contact Us',
                        subtitle: 'Get help from our team',
                        page: const ContactPage(),
                      ),
                      _MenuItem(
                        icon: Icons.share_rounded,
                        iconColor: const Color(0xFF25D366),
                        title: 'Share App',
                        subtitle: 'Spread the good',
                        page: const SharePage(),
                      ),
                      _MenuItem(
                        icon: Icons.star_rounded,
                        iconColor: _gold,
                        title: 'Rate Us',
                        subtitle: 'Your review means a lot',
                        page: const RatePage(),
                        badge: '⭐',
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _sectionLabel('Info'),
                    const SizedBox(height: 10),
                    _MenuSection(items: [
                      _MenuItem(
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFFFF9800),
                        title: 'About App',
                        subtitle: 'Version 2.5.0 — What\'s new',
                        page: const AboutPage(),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _sectionLabel('Session'),
                    const SizedBox(height: 10),
                    _SignOutTile(),
                    const SizedBox(height: 32),
                    _bottomQuote(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: _textLo,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _bottomQuote() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accentSoft.withOpacity(0.1),
            _gold.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withOpacity(0.2)),
      ),
      child: const Column(
        children: [
          Text('🌙', style: TextStyle(fontSize: 32)),
          SizedBox(height: 10),
          Text(
            '"Indeed, with hardship comes ease."',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _gold,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 4),
          Text('— Quran 94:5',
              style: TextStyle(color: _textLo, fontSize: 12)),
        ],
      ),
    );
  }

  // ── Bottom Nav — asset-icon version, active = index 4 (Menu) ─────────────
  Widget _buildNav(BuildContext context) {
    // ✅ Replaced emoji list with asset icon list from your new nav
    final items = [
      ('Today', 'assets/icons/today.png'),
      ('Tools', 'assets/icons/tools.png'),
      ('Quran', 'assets/icons/quran.png'),
      ('Duas',  'assets/icons/duas.png'),
      ('Menu',  'assets/icons/menu.png'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border(
            top: BorderSide(color: _accentSoft.withOpacity(0.25), width: 1)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 20),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              final i     = e.key;
              final label = e.value.$1;
              final asset = e.value.$2;
              // ✅ Menu tab is index 4 — always active on this page
              final active = i == 4;

              return GestureDetector(
                onTap: () {
                  if (!active) {
                    // ✅ Use Get.off so back-stack doesn't pile up
                    Get.off(
                          () => _pages[i],
                      transition: Transition.noTransition,
                    );
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
                      // ✅ Asset image icon with color tint for active state
                      Image.asset(
                        asset,
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: active ? _accent : _textLo,
                        ),
                      ),
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
}

// ── User Greeting Card ────────────────────────────────────────────────────────
class _UserGreetingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final auth = Get.find<AuthController>();
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D2E1C), Color(0xFF122E1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Get.to(() => const ProfilePage()),
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentSoft,
                  border:
                  Border.all(color: _gold.withOpacity(0.5), width: 2),
                ),
                child: auth.isLoggedIn && auth.photoUrl.value.isNotEmpty
                    ? ClipOval(
                    child: Image.network(auth.photoUrl.value,
                        fit: BoxFit.cover))
                    : Center(
                  child: Text(
                    auth.isLoggedIn &&
                        auth.displayName.value.isNotEmpty
                        ? auth.displayName.value[0].toUpperCase()
                        : '🙋',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.isLoggedIn ? 'Assalamu Alaikum,' : 'Welcome!',
                    style: const TextStyle(color: _textLo, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    auth.isLoggedIn
                        ? (auth.displayName.value.isNotEmpty
                        ? auth.displayName.value
                        : 'Muslim User')
                        : 'Sign in to sync progress',
                    style: const TextStyle(
                      color: _textHi,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!auth.isLoggedIn)
                    GestureDetector(
                      onTap: () => Get.to(() => const ProfilePage()),
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _accentSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Sign In',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
            if (auth.isLoggedIn)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _gold.withOpacity(0.3)),
                ),
                child: const Column(
                  children: [
                    Text('🌙', style: TextStyle(fontSize: 16)),
                    Text('Active',
                        style: TextStyle(
                            color: _gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ── Menu Section ──────────────────────────────────────────────────────────────
class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accentSoft.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i      = e.key;
          final item   = e.value;
          final isLast = i == items.length - 1;
          return Column(
            children: [
              _MenuTile(item: item),
              if (!isLast)
                Divider(
                    height: 1,
                    color: _accentSoft.withOpacity(0.15),
                    indent: 58),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Get.to(() => item.page,
            transition: Transition.rightToLeft,
            duration: const Duration(milliseconds: 280)),
        splashColor: _accentSoft.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: item.iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(item.title,
                            style: const TextStyle(
                                color: _textHi,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        if (item.badge != null) ...[
                          const SizedBox(width: 6),
                          Text(item.badge!,
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ],
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(item.subtitle!,
                          style: const TextStyle(
                              color: _textLo, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: _textLo, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? badge;
  final Widget page;
  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.badge,
    required this.page,
  });
}

// ── Sign Out Tile ─────────────────────────────────────────────────────────────
class _SignOutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Get.to(() => const SignOutPage(),
              transition: Transition.rightToLeft,
              duration: const Duration(milliseconds: 280)),
          splashColor: Colors.red.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.redAccent, size: 20),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sign Out',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      SizedBox(height: 2),
                      Text('End your current session',
                          style: TextStyle(color: _textLo, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: _textLo, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Placeholder ───────────────────────────────────────────────────────────────
class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: Text(title, style: const TextStyle(color: _textHi)),
      ),
      body: Center(
        child: Text(title,
            style: const TextStyle(color: _textLo, fontSize: 18)),
      ),
    );
  }
}