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
import 'sections/notification_settings_section.dart';
import 'sections/display_settings_section.dart';
import 'sections/session_settings_section.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';

// No local BlocProvider — reads global SettingsCubit from main.dart
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
    // Clamp so tablets render like a wide phone, not a stretched layout
    final rsw = sw.clamp(320.0, 500.0);
    // Horizontal padding: fixed on phones, generous on tablets
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
                physics: const BouncingScrollPhysics(),
                slivers: [

                  // ── Collapsing AppBar ─────────────────────────────────
                  _buildSliverAppBar(context, theme, l10n, rsw),

                  // ── Sections ──────────────────────────────────────────
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        16 + hPad, 8, 16 + hPad, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([

                        _sectionHeader(theme, '📍', l10n.locationSection, rsw),
                        SizedBox(height: rsw * 0.020),
                        _LocationTile(theme: theme, l10n: l10n),
                        SizedBox(height: rsw * 0.060),

                        _sectionHeader(theme, '🗓️', l10n.hijriSection, rsw),
                        SizedBox(height: rsw * 0.020),
                        HijriSettingsSection(theme: theme, l10n: l10n),
                        SizedBox(height: rsw * 0.060),

                        _sectionHeader(theme, '🌐', l10n.languageSection, rsw),
                        SizedBox(height: rsw * 0.020),
                        LanguageSettingsSection(theme: theme, l10n: l10n),
                        SizedBox(height: rsw * 0.060),

                        _sectionHeader(theme, '🎨', l10n.appearanceSection, rsw),
                        SizedBox(height: rsw * 0.020),
                        ThemeSettingsSection(theme: theme, l10n: l10n),
                        SizedBox(height: rsw * 0.060),

                        /*
                        _sectionHeader(theme, '🔔', l10n.notificationsSection, rsw),
                        SizedBox(height: rsw * 0.020),
                        NotificationSettingsSection(theme: theme, l10n: l10n),
                        SizedBox(height: rsw * 0.060),

                         */

                        _sectionHeader(theme, '🖥️', l10n.displaySection, rsw),
                        SizedBox(height: rsw * 0.020),
                        DisplaySettingsSection(theme: theme, l10n: l10n),
                        SizedBox(height: rsw * 0.060),

                        _sectionHeader(theme, '🔐', l10n.sessionSection, rsw),
                        SizedBox(height: rsw * 0.020),
                        SessionSettingsSection(theme: theme, l10n: l10n),
                        SizedBox(height: rsw * 0.050),

                        _buildAppInfo(theme, rsw),
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

  // ── Sliver AppBar ──────────────────────────────────────────────────────────
  Widget _buildSliverAppBar(BuildContext context,
      AppThemeOption theme, AppLocalizations l10n, double rsw) {

    // Expanded height: scales between 120 (small) and 160 (large)
    final expandedH = (rsw * 0.38).clamp(120.0, 160.0);

    return SliverAppBar(
      expandedHeight: expandedH,
      floating:       false,
      pinned:         true,
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
            color:      theme.textHigh,
            fontSize:   (rsw * 0.046).clamp(16.0, 20.0),
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
                  end:   Alignment.bottomRight,
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
                width:  rsw * 0.30,
                height: rsw * 0.30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.accent.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              right: rsw * 0.10, top: rsw * 0.05,
              child: Container(
                width:  rsw * 0.15,
                height: rsw * 0.15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.accent.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              right: rsw * 0.050, bottom: rsw * 0.040,
              child: Icon(Icons.settings_rounded,
                  size:  rsw * 0.12,
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

  // ── Section header ─────────────────────────────────────────────────────────
  Widget _sectionHeader(
      AppThemeOption theme, String emoji, String title, double rsw) {
    return Row(
      children: [
        Text(emoji, style: TextStyle(fontSize: rsw * 0.038)),
        SizedBox(width: rsw * 0.020),
        Text(
          title,
          style: TextStyle(
            color:         theme.accent,
            fontSize:      (rsw * 0.028).clamp(10.0, 13.0),
            fontWeight:    FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        SizedBox(width: rsw * 0.025),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.accent.withOpacity(0.35), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── App info footer ────────────────────────────────────────────────────────
  Widget _buildAppInfo(AppThemeOption theme, double rsw) {
    return Container(
      margin:  EdgeInsets.only(top: rsw * 0.020),
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
          Text('🕌',
              style: TextStyle(fontSize: (rsw * 0.070).clamp(24.0, 34.0))),
          SizedBox(height: rsw * 0.020),
          Text('Islamic App',
              style: TextStyle(
                  color:      theme.textHigh,
                  fontSize:   (rsw * 0.040).clamp(14.0, 18.0),
                  fontWeight: FontWeight.w700)),
          SizedBox(height: rsw * 0.010),
          Text('Version 2.5.0',
              style: TextStyle(
                  color:    theme.textLow,
                  fontSize: (rsw * 0.030).clamp(10.0, 13.0))),
          SizedBox(height: rsw * 0.030),
          Text(
            '"And seek help through patience and prayer."',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:      theme.accent.withOpacity(0.7),
              fontSize:   (rsw * 0.028).clamp(10.0, 13.0),
              fontStyle:  FontStyle.italic,
            ),
          ),
          SizedBox(height: rsw * 0.008),
          Text('— Quran 2:45',
              style: TextStyle(
                  color:    theme.textLow,
                  fontSize: (rsw * 0.025).clamp(9.0, 12.0))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Location tile
// ─────────────────────────────────────────────────────────────────────────────
class _LocationTile extends StatelessWidget {
  final AppThemeOption theme;
  final AppLocalizations l10n;
  const _LocationTile({required this.theme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      theme: theme,
      child: SettingsTile(
        theme:    theme,
        icon:     Icons.my_location_rounded,
        iconBg:   const Color(0xFF4CAF82),
        title:    'Prayer Location',
        subtitle: 'Set your city for accurate times',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Change',
                style: TextStyle(
                    color:      theme.accent,
                    fontSize:   13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded,
                color: theme.textLow, size: 13),
          ],
        ),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LocationPage())),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC shared widgets used by section files
// ─────────────────────────────────────────────────────────────────────────────
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
            color:      Colors.black.withOpacity(theme.isDark ? 0.28 : 0.06),
            blurRadius: 12,
            offset:     const Offset(0, 4),
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
  final IconData  icon;
  final Color     iconBg;
  final String    title;
  final String?   subtitle;
  final Widget?   trailing;
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
        onTap:        onTap,
        splashColor:  theme.accent.withOpacity(0.08),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: rsw * 0.040, vertical: rsw * 0.035),
          child: Row(
            children: [
              // Icon box — scales with screen
              Container(
                width:  rsw * 0.100,
                height: rsw * 0.100,
                decoration: BoxDecoration(
                  color:        iconBg.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(rsw * 0.030),
                ),
                child: Icon(icon,
                    color: iconBg, size: rsw * 0.050),
              ),
              SizedBox(width: rsw * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:      theme.textHigh,
                        fontSize:   (rsw * 0.038).clamp(13.0, 16.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: rsw * 0.008),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color:    theme.textLow,
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