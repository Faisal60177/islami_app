import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

// Export shared widgets
export 'settings_page.dart' show _SettingsCard, _SettingsTile;

import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_themes.dart';
import '../../location/home/location_page.dart';
import 'sections/hijri_settings_section.dart';
import 'sections/language_settings_section.dart';
import 'sections/theme_settings_section.dart';
import 'sections/notification_settings_section.dart';
import 'sections/display_settings_section.dart';
import 'sections/session_settings_section.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView>
    with SingleTickerProviderStateMixin {

  late final AnimationController _animCtrl;
  late final Animation<double>    _fadeAnim;
  late final Animation<Offset>    _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final theme  = getThemeById(state.themeMode);
        final l10n   = AppLocalizations(state.languageCode);

        return Scaffold(
          backgroundColor: theme.background,
          body: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Collapsing App Bar ──────────────────────────────────
                  _buildSliverAppBar(context, theme, l10n),

                  // ── Settings Sections ───────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([

                        // Location
                        _buildSectionHeader(theme, '📍', 'Location', l10n),
                        const SizedBox(height: 8),
                        _LocationTile(theme: theme, l10n: l10n),
                        const SizedBox(height: 24),

                        // Hijri Calendar
                        _buildSectionHeader(theme, '🗓️', 'Hijri Calendar', l10n),
                        const SizedBox(height: 8),
                        HijriSettingsSection(theme: theme, l10n: l10n),
                        const SizedBox(height: 24),

                        // Language
                        _buildSectionHeader(theme, '🌐', 'Language', l10n),
                        const SizedBox(height: 8),
                        LanguageSettingsSection(theme: theme, l10n: l10n),
                        const SizedBox(height: 24),

                        // Appearance / Theme
                        _buildSectionHeader(theme, '🎨', 'Appearance', l10n),
                        const SizedBox(height: 8),
                        ThemeSettingsSection(theme: theme, l10n: l10n),
                        const SizedBox(height: 24),

                        // Notifications
                        _buildSectionHeader(theme, '🔔', 'Notifications', l10n),
                        const SizedBox(height: 8),
                        NotificationSettingsSection(theme: theme, l10n: l10n),
                        const SizedBox(height: 24),

                        // Display
                        _buildSectionHeader(theme, '🖥️', 'Display', l10n),
                        const SizedBox(height: 8),
                        DisplaySettingsSection(theme: theme, l10n: l10n),
                        const SizedBox(height: 24),

                        // Session
                        _buildSectionHeader(theme, '🔐', 'Session', l10n),
                        const SizedBox(height: 8),
                        SessionSettingsSection(theme: theme, l10n: l10n),
                        const SizedBox(height: 16),

                        // App Info footer
                        _buildAppInfo(theme),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Sliver App Bar ─────────────────────────────────────────────────────────
  Widget _buildSliverAppBar(
      BuildContext context, AppThemeOption theme, AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: theme.surface,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios_rounded, color: theme.accent, size: 20),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: Text(
          l10n.settings,
          style: TextStyle(
            color: theme.textHigh,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.surface,
                    theme.accent.withOpacity(0.08),
                    theme.surface,
                  ],
                ),
              ),
            ),
            // Decorative pattern
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.accent.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              right: 40,
              top: 20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.accent.withOpacity(0.08),
                ),
              ),
            ),
            // Settings icon
            Positioned(
              right: 20,
              bottom: 16,
              child: Icon(
                Icons.settings_rounded,
                size: 48,
                color: theme.accent.withOpacity(0.15),
              ),
            ),
            // Bottom border
            Positioned(
              bottom: 0,
              left: 0, right: 0,
              child: Container(
                height: 1,
                color: theme.accent.withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      AppThemeOption theme, String emoji, String title, AppLocalizations l10n) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: theme.accent,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.accent.withOpacity(0.4), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfo(AppThemeOption theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.accent.withOpacity(0.06),
            theme.surface.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.accent.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text('🕌', style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            'Islamic App',
            style: TextStyle(
              color: theme.textHigh,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 2.5.0',
            style: TextStyle(color: theme.textLow, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            '"And seek help through patience and prayer."',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.accent.withOpacity(0.7),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          Text(
            '— Quran 2:45',
            style: TextStyle(color: theme.textLow, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ── Location Tile ─────────────────────────────────────────────────────────────
class _LocationTile extends StatelessWidget {
  final AppThemeOption theme;
  final AppLocalizations l10n;
  const _LocationTile({required this.theme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      theme: theme,
      child: _SettingsTile(
        theme:    theme,
        icon:     Icons.my_location_rounded,
        iconBg:   const Color(0xFF4CAF82),
        title:    'Prayer Location',
        subtitle: 'Set your city for accurate times',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change',
              style: TextStyle(color: theme.accent, fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded,
                color: theme.textLow, size: 13),
          ],
        ),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const LocationPage())),
      ),
    );
  }
}

// ── Reusable Card ─────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final AppThemeOption theme;
  final Widget child;
  final EdgeInsets? padding;

  const _SettingsCard({
    required this.theme,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.accent.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: child,
      ),
    );
  }
}

// ── Reusable Tile ─────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final AppThemeOption theme;
  final IconData icon;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const _SettingsTile({
    required this.theme,
    required this.icon,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: theme.accent.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconBg, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.textHigh,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(color: theme.textLow, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

