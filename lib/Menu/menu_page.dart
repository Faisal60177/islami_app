import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth/auth_notifier.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'profile/profile_page.dart';
import 'package:muslim_app/settings/pages/settings_page.dart';
import 'contact/contact_page.dart';
import 'share/share_page.dart';
import 'rate/rate_page.dart';
import 'about/about_page.dart';
import 'auth/sign_out_page.dart';
import 'auth/auth_notifier.dart';
import 'package:muslim_app/home/home_page.dart';
import 'package:muslim_app/tools/tools_page.dart';
import 'package:muslim_app/Quran/quran_page.dart';
import 'package:muslim_app/Duas/pages/duas_page.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
const _bg         = Color(0xFF011A0E);
const _surface    = Color(0xFF0D2E1C);
const _card       = Color(0xFF122E1E);
const _accent     = Color(0xFF4CAF82);
const _accentSoft = Color(0xFF2E7D5A);
const _gold       = Color(0xFFD4AF37);
const _textHi     = Color(0xFFE8F5EC);
const _textLo     = Color(0xFF7BAF92);

// ─── MenuPage ────────────────────────────────────────────────────────────────
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  static final List<Widget> _pages = [
    const PrayerTimesPage(),
    const ToolsPage(),
    const QuranPage(),
    const DuasPage(),
    const MenuPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // ✅ Single BlocBuilder at the top — l10n flows down to every child
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final l10n = AppLocalizations(state.languageCode);

        return Scaffold(
          backgroundColor: _bg,
          appBar: _buildAppBar(context, l10n),
          body: _buildBody(context, l10n),
          bottomNavigationBar: _buildNav(context, l10n),
        );
      },
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context, AppLocalizations l10n) {
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
          // ✅ l10n.menuTitle instead of hardcoded 'Menu'
          Text(
            l10n.menuTitle,
            style: const TextStyle(
              color: _textHi,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      actions: [
        Consumer(builder: (_, ref, __) {
          final auth = ref.watch(authNotifierProvider);
          if (!auth.isLoggedIn) return const SizedBox.shrink();
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentSoft,
                border: Border.all(color: _gold.withOpacity(0.5)),
              ),
              child: auth.photoUrl.isNotEmpty
                  ? ClipOval(
                child: Image.network(
                  auth.photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _initials(auth.displayName),
                ),
              )
                  : _initials(auth.displayName),
            ),
          );
        }),
      ],
    );
  }

  Widget _initials(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'M',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth > 600 ? 24.0 : 16.0;

        return SingleChildScrollView(
          child: Column(
            children: [
              // ✅ Pass l10n down to greeting card
              _UserGreetingCard(l10n: l10n),
              Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Account section ──────────────────────────────────
                    _sectionLabel(l10n.account),
                    const SizedBox(height: 10),
                    _MenuSection(items: [
                      _MenuItem(
                        icon: Icons.person_rounded,
                        iconColor: const Color(0xFF4CAF82),
                        // ✅ l10n strings
                        title: l10n.profile,
                        subtitle: l10n.profileSubtitle,
                        page: const ProfilePage(),
                      ),
                      _MenuItem(
                        icon: Icons.settings_rounded,
                        iconColor: const Color(0xFF9E9E9E),
                        title: l10n.settings,
                        subtitle: l10n.settingsSubtitle,
                        page: const SettingsPage(),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // ── Support section ──────────────────────────────────
                    _sectionLabel(l10n.support),
                    const SizedBox(height: 10),
                    _MenuSection(items: [
                      _MenuItem(
                        icon: Icons.headset_mic_outlined,
                        iconColor: const Color(0xFF2196F3),
                        title: l10n.contactUs,
                        subtitle: l10n.contactSubtitle,
                        page: const ContactPage(),
                      ),
                      _MenuItem(
                        icon: Icons.share_rounded,
                        iconColor: const Color(0xFF25D366),
                        title: l10n.shareApp,
                        subtitle: l10n.shareSubtitle,
                        page: const SharePage(),
                      ),
                      _MenuItem(
                        icon: Icons.star_rounded,
                        iconColor: _gold,
                        title: l10n.rateUs,
                        subtitle: l10n.rateSubtitle,
                        page: const RatePage(),
                        badge: '⭐',
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // ── Info section ─────────────────────────────────────
                    _sectionLabel(l10n.info),
                    const SizedBox(height: 10),
                    _MenuSection(items: [
                      _MenuItem(
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFFFF9800),
                        title: l10n.aboutApp,
                        subtitle: l10n.aboutSubtitle,
                        page: const AboutPage(),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // ── Session section ──────────────────────────────────
                    _sectionLabel(l10n.sessionLabel),
                    const SizedBox(height: 10),
                    // ✅ Pass l10n to sign-out tile
                    _SignOutTile(l10n: l10n),
                    const SizedBox(height: 32),
                    _bottomQuote(l10n),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Section label ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        // toUpperCase() works fine on already-uppercase scripts too
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

  // ── Bottom quote ─────────────────────────────────────────────────────────
  Widget _bottomQuote(AppLocalizations l10n) {
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
      child: Column(
        children: [
          const Text('🌙', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          // ✅ Localized quote
          Text(
            l10n.quoteHardship,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _gold,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.quoteHardshipRef,
            style: const TextStyle(color: _textLo, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Bottom Nav ───────────────────────────────────────────────────────────
  Widget _buildNav(BuildContext context, AppLocalizations l10n) {
    // ✅ Nav labels now use l10n
    final items = [
      (l10n.today,  'assets/icons/today.png'),
      (l10n.tools,  'assets/icons/tools.png'),
      (l10n.quran,  'assets/icons/quran.png'),
      (l10n.duas,   'assets/icons/duas.png'),
      (l10n.menu,   'assets/icons/menu.png'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border(
          top: BorderSide(color: _accentSoft.withOpacity(0.25), width: 1),
        ),
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
              final i      = e.key;
              final label  = e.value.$1;
              final asset  = e.value.$2;
              final active = i == 4;

              return GestureDetector(
                onTap: () {
                  if (!active) {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => _pages[i],
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? _accentSoft.withOpacity(0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(asset, width: 24, height: 24),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                          active ? FontWeight.w700 : FontWeight.w400,
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

// ─── User Greeting Card ───────────────────────────────────────────────────────
// ✅ Now accepts l10n as a required parameter
class _UserGreetingCard extends ConsumerWidget {
  final AppLocalizations l10n;
  const _UserGreetingCard({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);

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
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentSoft,
                border: Border.all(color: _gold.withOpacity(0.5), width: 2),
              ),
              child: auth.isLoggedIn && auth.photoUrl.isNotEmpty
                  ? ClipOval(
                  child: Image.network(auth.photoUrl, fit: BoxFit.cover))
                  : Center(
                child: Text(
                  auth.isLoggedIn && auth.displayName.isNotEmpty
                      ? auth.displayName[0].toUpperCase()
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

          // Name / greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.isLoggedIn ? l10n.assalamuAlaikum : l10n.welcome,
                  style: const TextStyle(color: _textLo, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  auth.isLoggedIn
                      ? (auth.displayName.isNotEmpty
                      ? auth.displayName
                      : l10n.muslimUser)
                      : l10n.signInSubtitle,
                  style: const TextStyle(
                      color: _textHi,
                      fontWeight: FontWeight.w700,
                      fontSize: 17),
                  overflow: TextOverflow.ellipsis,
                ),
                if (!auth.isLoggedIn)
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: _accentSoft,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(l10n.signIn,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),

          // Active badge
          if (auth.isLoggedIn)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _gold.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text('🌙', style: TextStyle(fontSize: 16)),
                  Text(l10n.activeBadge,
                      style: const TextStyle(
                          color: _gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Menu Section ─────────────────────────────────────────────────────────────
// (no text inside — no l10n needed here)
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
            offset: const Offset(0, 4),
          ),
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
                  indent: 58,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Menu Tile ────────────────────────────────────────────────────────────────
// (title/subtitle already come in as translated strings via _MenuItem)
class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => item.page,                    // = () => item.page
            transitionDuration: const Duration(milliseconds: 280),     // = duration: 280ms
            reverseTransitionDuration: const Duration(milliseconds: 280),
            transitionsBuilder: (_, animation, __, child) {             // = transition: Transition.rightToLeft
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          ),
        ),
        splashColor: _accentSoft.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
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
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: _textHi,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (item.badge != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            item.badge!,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: const TextStyle(
                          color: _textLo,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _textLo,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Menu Item data class ─────────────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final Color    iconColor;
  final String   title;
  final String?  subtitle;
  final String?  badge;
  final Widget   page;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.badge,
    required this.page,
  });
}

// ─── Sign Out Tile ────────────────────────────────────────────────────────────
// ✅ Now accepts l10n
class _SignOutTile extends StatelessWidget {
  final AppLocalizations l10n;
  const _SignOutTile({required this.l10n});

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
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const SignOutPage(),
              transitionDuration: const Duration(milliseconds: 280),
              reverseTransitionDuration: const Duration(milliseconds: 280),
              transitionsBuilder: (_, animation, __, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
            ),
          ),
          splashColor: Colors.red.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // ✅ Localized
                        l10n.signOut,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        // ✅ Localized
                        l10n.signOutSubtitle,
                        style: const TextStyle(
                          color: _textLo,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _textLo,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}