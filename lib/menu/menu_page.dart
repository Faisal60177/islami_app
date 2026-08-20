import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth/auth_notifier.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import 'profile/profile_page.dart';
import 'package:muslim_app/settings/pages/settings_page.dart';
import 'contact/contact_page.dart';
import 'share/share_page.dart';
import 'rate/rate_page.dart';
import 'about/about_page.dart';
import 'auth/sign_out_page.dart';
import 'package:muslim_app/home/home_page.dart';
import 'package:muslim_app/tools/tools_page.dart';
import 'package:muslim_app/quran_tilawat/pages/quran_page.dart';
import 'package:muslim_app/duas/pages/duas_page.dart';
import 'package:muslim_app/core/app_info.dart';

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
    // ✅ Single BlocBuilder at the top — l10n + theme flow down to every child
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final l10n = AppLocalizations(state.languageCode);
        final thm  = getThemeById(state.themeMode);

        return Scaffold(
          backgroundColor: thm.background,
          appBar: _buildAppBar(context, l10n, thm),
          body: _buildBody(context, l10n, thm),
          bottomNavigationBar: _buildNav(context, l10n, thm),
        );
      },
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
      BuildContext context, AppLocalizations l10n, AppThemeOption thm) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: thm.surface,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: thm.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/icons/AppIcon.png',
                width: 22,
                height: 22,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.menuTitle,
            style: TextStyle(
              color: thm.textHigh,
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
                color: thm.accent.withOpacity(0.6),
                border: Border.all(color: thm.accent.withOpacity(0.5)),
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
  Widget _buildBody(
      BuildContext context, AppLocalizations l10n, AppThemeOption thm) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth > 600 ? 24.0 : 16.0;

        return SingleChildScrollView(
          child: Column(
            children: [
              _UserGreetingCard(l10n: l10n, thm: thm),
              Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Account section ──────────────────────────────────
                    _sectionLabel(l10n.account, thm),
                    const SizedBox(height: 10),
                    _MenuSection(
                      thm: thm,
                      items: [
                        _MenuItem(
                          icon: Icons.person_rounded,
                          iconColor: const Color(0xFF4CAF82),
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

                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Support section ──────────────────────────────────
                    _sectionLabel(l10n.support, thm),
                    const SizedBox(height: 10),
                    _MenuSection(
                      thm: thm,
                      items: [
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
                          iconColor: thm.accent,
                          title: l10n.rateUs,
                          subtitle: l10n.rateSubtitle,
                          page: const RatePage(),
                          badge: '⭐',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Info section ─────────────────────────────────────
                    _sectionLabel(l10n.info, thm),
                    const SizedBox(height: 10),
                    _MenuSection(
                      thm: thm,
                      items: [
                        _MenuItem(
                          icon: Icons.info_outline_rounded,
                          iconColor: const Color(0xFFFF9800),
                          title: l10n.aboutApp,
                          subtitle: '${l10n.aboutSubtitle} • v${AppInfo.version}',
                          page: const AboutPage(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Session section ──────────────────────────────────
                    _sectionLabel(l10n.sessionLabel, thm),
                    const SizedBox(height: 10),
                    _SignOutTile(l10n: l10n, thm: thm),
                    const SizedBox(height: 32),
                    _bottomQuote(l10n, thm),
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
  Widget _sectionLabel(String text, AppThemeOption thm) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: thm.textLow,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // ── Bottom quote ─────────────────────────────────────────────────────────
  Widget _bottomQuote(AppLocalizations l10n, AppThemeOption thm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            thm.accent.withOpacity(0.1),
            thm.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: thm.accent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text('🌙', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          Text(
            l10n.quoteHardship,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: thm.accent,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.quoteHardshipRef,
            style: TextStyle(color: thm.textLow, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Bottom Nav ───────────────────────────────────────────────────────────
  Widget _buildNav(
      BuildContext context, AppLocalizations l10n, AppThemeOption thm) {
    final items = [
      (l10n.today,  'assets/icons/today.png'),
      (l10n.tools,  'assets/icons/features.png'),
      (l10n.quran,  'assets/icons/quran_tilawat.png'),
      (l10n.duas,   'assets/icons/duas.png'),
      (l10n.menu,   'assets/icons/menu.png'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: thm.surface,
        border: Border(
          top: BorderSide(color: thm.accent.withOpacity(0.25), width: 1),
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
                        ? thm.accent.withOpacity(0.22)
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
                          color: active ? thm.accent : thm.textLow,
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
class _UserGreetingCard extends ConsumerWidget {
  final AppLocalizations l10n;
  final AppThemeOption thm;
  const _UserGreetingCard({required this.l10n, required this.thm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [thm.surface, thm.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: thm.accent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(thm.isDark ? 0.3 : 0.08),
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
                color: thm.accent.withOpacity(0.6),
                border: Border.all(color: thm.accent.withOpacity(0.5), width: 2),
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
                  style: TextStyle(color: thm.textLow, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  auth.isLoggedIn
                      ? (auth.displayName.isNotEmpty
                      ? auth.displayName
                      : l10n.muslimUser)
                      : l10n.signInSubtitle,
                  style: TextStyle(
                      color: thm.textHigh,
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
                          color: thm.accent.withOpacity(0.6),
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
                color: thm.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: thm.accent.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text('🌙', style: TextStyle(fontSize: 16)),
                  Text(l10n.activeBadge,
                      style: TextStyle(
                          color: thm.accent,
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

// ─── menu Section ─────────────────────────────────────────────────────────────
class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;
  final AppThemeOption thm;
  const _MenuSection({required this.items, required this.thm});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: thm.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: thm.accent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(thm.isDark ? 0.2 : 0.05),
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
              _MenuTile(item: item, thm: thm),
              if (!isLast)
                Divider(
                  height: 1,
                  color: thm.accent.withOpacity(0.15),
                  indent: 58,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── menu Tile ────────────────────────────────────────────────────────────────
class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  final AppThemeOption thm;
  const _MenuTile({required this.item, required this.thm});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => item.page,
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
        splashColor: thm.accent.withOpacity(0.1),
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
                          style: TextStyle(
                            color: thm.textHigh,
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
                        style: TextStyle(
                          color: thm.textLow,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: thm.textLow,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── menu Item data class ─────────────────────────────────────────────────────
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
class _SignOutTile extends StatelessWidget {
  final AppLocalizations l10n;
  final AppThemeOption thm;
  const _SignOutTile({required this.l10n, required this.thm});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: thm.cardColor,
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
                        l10n.signOut,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.signOutSubtitle,
                        style: TextStyle(
                          color: thm.textLow,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: thm.textLow,
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