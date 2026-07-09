import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_themes.dart';
import '../../location/home/location_page.dart';
import 'sections/hijri_settings_section.dart';
import 'sections/language_settings_section.dart';
import 'sections/theme_settings_section.dart';
import 'sections/display_settings_section.dart';
import 'sections/session_settings_section.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'sections/notification_settings_section.dart';
import '../../core/app_info.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw  = MediaQuery.of(context).size.width;
    final rsw = sw.clamp(320.0, 500.0);
    final hPad = sw > 500 ? (sw - 500) / 2 : 0.0;

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final theme = getThemeById(state.themeMode);
        final l10n  = AppLocalizations(state.languageCode);

        return Scaffold(
          backgroundColor: theme.background,
          body: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(context, theme, l10n, rsw),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        16 + hPad, 8, 16 + hPad, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([

                        _NavTile(
                          theme: theme, rsw: rsw,
                          emoji: '📍',
                          title: 'Location',
                          subtitle: 'Set your city for accurate prayer times',
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const LocationPage())),
                        ),
                        SizedBox(height: rsw * 0.020),

                        _NavTile(
                          theme: theme, rsw: rsw,
                          emoji: '🗓️',
                          title: l10n.hijriSection,
                          subtitle: 'Adjust Hijri date offset',
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => HijriSettingsPage(
                                      theme: theme, l10n: l10n))),
                        ),
                        SizedBox(height: rsw * 0.020),

                        _NavTile(
                          theme: theme, rsw: rsw,
                          emoji: '🌐',
                          title: l10n.languageSection,
                          subtitle: 'Choose your app language',
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => LanguageSettingsPage(
                                      theme: theme, l10n: l10n))),
                        ),
                        SizedBox(height: rsw * 0.020),

                        _NavTile(
                          theme: theme, rsw: rsw,
                          emoji: '🎨',
                          title: l10n.appearanceSection,
                          subtitle: 'Select color theme',
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => ThemeSettingsPage(
                                      theme: theme, l10n: l10n))),
                        ),
                        SizedBox(height: rsw * 0.020),

                        _NavTile(
                          theme: theme, rsw: rsw,
                          emoji: '🖥️',
                          title: l10n.displaySection,
                          subtitle: 'Time format and header style',
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => DisplaySettingsPage(
                                      theme: theme, l10n: l10n))),
                        ),
                        SizedBox(height: rsw * 0.020),

                        _NavTile(
                          theme: theme, rsw: rsw,
                          emoji: '🔔',
                          title: l10n.notificationsSection,
                          subtitle: 'Notification settings',
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => NotificationSettingsPage(
                                      theme: theme, l10n: l10n))),
                        ),
                        SizedBox(height: rsw * 0.020),

                        _NavTile(
                          theme: theme, rsw: rsw,
                          emoji: '🔐',
                          title: l10n.sessionSection,
                          subtitle: 'Privacy policy and sign out',
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => SessionSettingsPage(
                                      theme: theme, l10n: l10n))),
                        ),
                        SizedBox(height: rsw * 0.050),

                        _buildAppInfo(theme, rsw),
                        SizedBox(height: rsw * 0.020),

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

  Widget _buildSliverAppBar(BuildContext context,
      AppThemeOption theme, AppLocalizations l10n, double rsw) {
    final expandedH = (rsw * 0.38).clamp(120.0, 160.0);
    return SliverAppBar(
      expandedHeight: expandedH,
      floating: false,
      pinned: true,
      backgroundColor: theme.surface,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios_rounded,
            color: theme.accent, size: rsw * 0.050),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: rsw * 0.140, bottom: rsw * 0.040),
        title: Text(
          l10n.settings,
          style: TextStyle(
            color: theme.textHigh,
            fontSize: (rsw * 0.046).clamp(16.0, 20.0),
            fontWeight: FontWeight.w800,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
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
            Positioned(
              right: -(rsw * 0.05), top: -(rsw * 0.05),
              child: Container(
                width: rsw * 0.30, height: rsw * 0.30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.accent.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              right: rsw * 0.10, top: rsw * 0.05,
              child: Container(
                width: rsw * 0.15, height: rsw * 0.15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.accent.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              right: rsw * 0.050, bottom: rsw * 0.040,
              child: Icon(Icons.settings_rounded,
                  size: rsw * 0.12,
                  color: theme.accent.withOpacity(0.15)),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                  height: 1, color: theme.accent.withOpacity(0.15)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo(AppThemeOption theme, double rsw) {
    return Container(
      margin: EdgeInsets.only(top: rsw * 0.020),
      padding: EdgeInsets.all(rsw * 0.050),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.accent.withOpacity(0.06),
            theme.surface.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(rsw * 0.050),
        border: Border.all(color: theme.accent.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular((rsw * 0.020).clamp(8.0, 12.0)),
            child: Image.asset(
              'assets/icons/AppIcon.png',
              width: (rsw * 0.090).clamp(32.0, 46.0),
              height: (rsw * 0.090).clamp(32.0, 46.0),
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: rsw * 0.020),
          Text('Muslim Life',
              style: TextStyle(
                  color: theme.textHigh,
                  fontSize: (rsw * 0.040).clamp(14.0, 18.0),
                  fontWeight: FontWeight.w700)),
          SizedBox(height: rsw * 0.010),
          Text('Version ${AppInfo.version} (Build ${AppInfo.buildNumber})',
              style: TextStyle(
                  color: theme.textLow,
                  fontSize: (rsw * 0.030).clamp(10.0, 13.0))),
          SizedBox(height: rsw * 0.030),
          Text(
            '"And seek help through patience and prayer."',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.accent.withOpacity(0.7),
              fontSize: (rsw * 0.028).clamp(10.0, 13.0),
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: rsw * 0.008),
          Text('— Quran 2:45',
              style: TextStyle(
                  color: theme.textLow,
                  fontSize: (rsw * 0.025).clamp(9.0, 12.0))),
        ],
      ),
    );
  }
}

// ── Nav Tile ──────────────────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final AppThemeOption theme;
  final double rsw;
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.theme,
    required this.rsw,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: rsw * 0.040,
            vertical: rsw * 0.038,
          ),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.accent.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(theme.isDark ? 0.25 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: rsw * 0.110,
                height: rsw * 0.110,
                decoration: BoxDecoration(
                  color: theme.accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(rsw * 0.030),
                ),
                child: Center(
                  child: Text(emoji,
                      style: TextStyle(fontSize: rsw * 0.048)),
                ),
              ),
              SizedBox(width: rsw * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.textHigh,
                        fontSize: (rsw * 0.040).clamp(14.0, 17.0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: rsw * 0.008),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.textLow,
                        fontSize: (rsw * 0.030).clamp(10.0, 13.0),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.textLow,
                size: rsw * 0.035,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets (same as before) ──────────────────────────────────────────
class SettingsCard extends StatelessWidget {
  final AppThemeOption theme;
  final Widget child;
  const SettingsCard({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.accent.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.isDark ? 0.28 : 0.06),
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

class SettingsTile extends StatelessWidget {
  final AppThemeOption theme;
  final IconData icon;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.theme,
    required this.icon,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sw  = MediaQuery.of(context).size.width;
    final rsw = sw.clamp(320.0, 500.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: theme.accent.withOpacity(0.08),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: rsw * 0.040, vertical: rsw * 0.035),
          child: Row(
            children: [
              Container(
                width: rsw * 0.100,
                height: rsw * 0.100,
                decoration: BoxDecoration(
                  color: iconBg.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(rsw * 0.030),
                ),
                child: Icon(icon, color: iconBg, size: rsw * 0.050),
              ),
              SizedBox(width: rsw * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textHigh,
                        fontSize: (rsw * 0.038).clamp(13.0, 16.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: rsw * 0.008),
                      Text(subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: theme.textLow,
                            fontSize: (rsw * 0.030).clamp(10.0, 13.0)),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: rsw * 0.020),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}