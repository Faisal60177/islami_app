import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:islamic_app/Quran/quran_page.dart';
import 'package:islamic_app/location/home/location_page.dart';
import 'package:islamic_app/tools/tools_page.dart';
import '../../../location/cubit/location_cubit.dart';
import '../../../location/cubit/location_state.dart';
import 'package:islamic_app/home/cubit/prayer_times_cubit.dart';
import 'package:islamic_app/home/state/prayer_times_state.dart';
import '../../../home/model/prayer_times_models.dart';
import 'package:intl/intl.dart';
import 'package:islamic_app/Duas/pages/duas_page.dart';
import 'package:islamic_app/Menu/menu_page.dart';
import 'package:islamic_app/notification/page/notification_page.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:marquee/marquee.dart';
import 'mosque.dart';
import 'ring_animation.dart';
import 'package:islamic_app/notification/cubit/notification_cubit.dart';
import 'package:islamic_app/notification/cubit/notification_state.dart';
import 'package:islamic_app/settings/cubit/settings_cubit.dart';
import 'package:islamic_app/settings/cubit/settings_state.dart';
import 'package:islamic_app/settings/l10n/app_localizations.dart';
import 'package:islamic_app/settings/theme/app_themes.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {

  final List<Widget> _pages = const [
    PrayerTimesPage(),
    ToolsPage(),
    QuranPage(),
    DuasPage(),
    MenuPage(),
  ];

  String _hijriDate(int offset) {
    final adjusted = DateTime.now().add(Duration(days: offset));
    final h = HijriCalendar.fromDate(adjusted);
    return "${h.hDay} ${h.longMonthName} ${h.hYear} AH";
  }

  String _englishDate() =>
      DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

  String _fmt(DateTime dt, {required bool use24h}) {
    if (use24h) {
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    }
    final h  = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m  = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }

  String _currentPrayer(PrayerTimesModel t) {
    final now = DateTime.now();
    bool inRange(DateTime s, DateTime e) =>
        e.isAfter(s) ? now.isAfter(s) && now.isBefore(e)
            : now.isAfter(s) || now.isBefore(e);

    if (inRange(t.fajrStart,    t.fajrEnd))    return 'Fajr';
    if (inRange(t.sunRiseStart, t.sunRiseEnd)) return 'SunRise';
    if (now.isAfter(t.sunRiseEnd) && now.isBefore(t.noonStart)) return 'Ishraq';
    if (inRange(t.noonStart,    t.noonEnd))    return 'Noon';
    if (inRange(t.dhuhrStart,   t.dhuhrEnd))   return 'Dhuhr';
    if (inRange(t.asrStart,     t.asrEnd))     return 'Asr';
    if (inRange(t.sunSetStart,  t.sunSetEnd))  return 'SunSet';
    if (inRange(t.maghribStart, t.maghribEnd)) return 'Maghrib';
    if (inRange(t.ishaStart,    t.ishaEnd))    return 'Isha';
    return '';
  }

  List<PrayerRingEntry> _buildRing(PrayerTimesModel t) {
    DateTime ishaEnd = t.ishaEnd;
    if (!ishaEnd.isAfter(t.ishaStart)) {
      ishaEnd = ishaEnd.add(const Duration(days: 1));
    }
    return [
      PrayerRingEntry(name: 'Fajr',    start: t.fajrStart,    end: t.sunRiseStart),
      PrayerRingEntry(name: 'SunRise', start: t.sunRiseStart, end: t.sunRiseEnd),
      PrayerRingEntry(name: 'Ishraq',  start: t.sunRiseEnd,   end: t.noonStart),
      PrayerRingEntry(name: 'Noon',    start: t.noonStart,    end: t.noonEnd),
      PrayerRingEntry(name: 'Dhuhr',   start: t.dhuhrStart,   end: t.asrStart),
      PrayerRingEntry(name: 'Asr',     start: t.asrStart,     end: t.maghribStart),
      PrayerRingEntry(name: 'SunSet',  start: t.sunSetStart,  end: t.sunSetEnd),
      PrayerRingEntry(name: 'Maghrib', start: t.maghribStart, end: t.maghribEnd),
      PrayerRingEntry(name: 'Isha',    start: t.ishaStart,    end: ishaEnd),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final px = sw * 0.04;

    // Clamp sw so layouts never break on tablets (max effective width = 420)
    final rsw = sw.clamp(320.0, 420.0);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        final theme      = getThemeById(settings.themeMode);
        final l10n       = AppLocalizations(settings.languageCode);
        final hijriOff   = settings.hijriOffset;
        final use24h     = settings.use24Hour;

        final bgDeep     = Color.lerp(theme.background, Colors.black,
            theme.isDark ? 0.30 : 0.0)!;
        final bgBase     = theme.background;
        final surface    = theme.surface;
        final accent     = theme.accent;
        final accentSoft = theme.primary.withOpacity(0.55);
        final textLo     = theme.textLow;

        final cardSalat  = theme.isDark ? const Color(0xFF0A3D25) : const Color(0xFFE8F5E9);
        final cardProhib = theme.isDark ? const Color(0xFF3B0E0E) : const Color(0xFFFFEBEE);
        final cardSawm   = theme.isDark ? const Color(0xFF0E2A3B) : const Color(0xFFE3F2FD);
        final cardNafal  = theme.isDark ? const Color(0xFF1A1A3B) : const Color(0xFFF3E5F5);

        return Scaffold(
          backgroundColor: bgBase,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(sw, rsw, sh, px,
                    bgDeep: bgDeep, accent: accent,
                    accentSoft: accentSoft, l10n: l10n),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: px),
                  child: Column(
                    children: [
                      _buildDateRow(rsw, hijriOff),
                      SizedBox(height: sh * 0.025),

                      BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
                        builder: (context, state) {
                          if (state is PrayerTimesLoading) {
                            return SizedBox(
                              height: sh * 0.4,
                              child: Center(
                                child: CircularProgressIndicator(color: accent),
                              ),
                            );
                          }
                          if (state is PrayerTimesError) {
                            return Padding(
                              padding: EdgeInsets.all(px),
                              child: Text(state.message,
                                  style: TextStyle(
                                      color: Colors.red[300],
                                      fontSize: rsw * 0.04)),
                            );
                          }
                          if (state is PrayerTimesLoaded) {
                            final t       = state.prayerTimes;
                            final current = _currentPrayer(t);
                            final ring    = _buildRing(t);

                            return Column(
                              children: [
                                _buildMosqueHero(rsw, sh, ring,
                                    accent: accent, accentSoft: accentSoft),
                                SizedBox(height: sh * 0.025),

                                _sectionLabel(rsw, l10n.salatPrayers, accent: accent),
                                SizedBox(height: sh * 0.010),
                                _buildSalatCard(rsw, t, current, cardSalat,
                                    use24h: use24h, accent: accent, l10n: l10n),
                                SizedBox(height: sh * 0.018),

                                _sectionLabel(rsw, l10n.prohibitedTimes, accent: accent),
                                SizedBox(height: sh * 0.010),
                                _buildProhibitedCard(rsw, t, current, cardProhib,
                                    use24h: use24h, l10n: l10n),
                                SizedBox(height: sh * 0.018),

                                _sectionLabel(rsw, l10n.sawmTimes, accent: accent),
                                SizedBox(height: sh * 0.010),
                                _buildSawmCard(rsw, t, cardSawm,
                                    use24h: use24h, l10n: l10n),
                                SizedBox(height: sh * 0.018),

                                _sectionLabel(rsw, l10n.nafalPrayers, accent: accent),
                                SizedBox(height: sh * 0.010),
                                _buildNafalCard(rsw, t, cardNafal,
                                    use24h: use24h, l10n: l10n),
                                SizedBox(height: sh * 0.030),
                              ],
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildNav(
            sw: sw, rsw: rsw,
            surface: surface, accentSoft: accentSoft,
            accent: accent, textLo: textLo, l10n: l10n,
          ),
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(double sw, double rsw, double sh, double px, {
    required Color bgDeep,
    required Color accent,
    required Color accentSoft,
    required AppLocalizations l10n,
  }) {
    // Responsive sizes — all relative to rsw (clamped width)
    final iconSize    = rsw * 0.042;   // location icon
    final bellSize    = rsw * 0.055;   // notification bell
    final fontSize    = rsw * 0.038;   // marquee text
    final badgeSize   = rsw * 0.042;   // notification badge circle
    final badgeFontSz = rsw * 0.021;
    final topPad      = MediaQuery.of(context).padding.top + rsw * 0.03;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          top: topPad, left: px, right: px, bottom: rsw * 0.03),
      decoration: BoxDecoration(
        color:  bgDeep,
        border: Border(
            bottom: BorderSide(color: accentSoft.withOpacity(0.20), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: BlocBuilder<LocationCubit, LocationState>(
              builder: (context, state) {
                String text = l10n.locating;
                if (state is LocationLoaded) {
                  text = '${state.location.city}, ${state.location.country}';
                } else if (state is LocationPermissionDenied) {
                  text = l10n.permissionDenied;
                }
                return GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LocationPage())),
                  child: Row(
                    children: [
                      // Responsive icon bubble
                      Container(
                        padding: EdgeInsets.all(rsw * 0.015),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.location_on,
                            color: accent, size: iconSize),
                      ),
                      SizedBox(width: rsw * 0.020),
                      Expanded(
                        child: SizedBox(
                          height: sh * 0.030,
                          child: Marquee(
                            text:  text,
                            style: TextStyle(
                              color:      Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize:   fontSize,
                            ),
                            velocity:             28.0,
                            pauseAfterRound:      const Duration(seconds: 2),
                            blankSpace:           24.0,
                            startPadding:         0,
                            accelerationDuration: const Duration(milliseconds: 800),
                            accelerationCurve:    Curves.easeIn,
                            decelerationDuration: const Duration(milliseconds: 800),
                            decelerationCurve:    Curves.easeOut,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(width: rsw * 0.03),

          // Notification bell
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              final count =
              state is NotificationLoaded ? state.unreadCount : 0;
              return GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationPage())),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: EdgeInsets.all(rsw * 0.020),
                      decoration: BoxDecoration(
                        color:  Colors.red.withOpacity(0.10),
                        shape:  BoxShape.circle,
                        border: Border.all(
                            color: Colors.red.withOpacity(0.30), width: 1),
                      ),
                      child: Icon(Icons.notifications_rounded,
                          color: Colors.red[300], size: bellSize),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 0, top: 0,
                        child: Container(
                          width:  badgeSize,
                          height: badgeSize,
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: TextStyle(
                                color:      Colors.white,
                                fontSize:   badgeFontSz,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Date row ───────────────────────────────────────────────────────────────
  Widget _buildDateRow(double rsw, int hijriOff) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: _datePill(_englishDate(),       const Color(0xFF66BB6A), rsw)),
        SizedBox(width: rsw * 0.02),
        Flexible(child: _datePill(_hijriDate(hijriOff), const Color(0xFFFFB74D), rsw)),
      ],
    );
  }

  Widget _datePill(String text, Color color, double rsw) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: rsw * 0.030, vertical: rsw * 0.014),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(rsw * 0.05),
        border:       Border.all(color: color.withOpacity(0.35), width: 0.8),
      ),
      child: Text(
        text,
        maxLines:  1,
        overflow:  TextOverflow.ellipsis,
        style: TextStyle(
            fontSize:   rsw * 0.028,
            fontWeight: FontWeight.w600,
            color:      color),
      ),
    );
  }

  // ── Mosque hero ─────────────────────────────────────────────────────────────
  Widget _buildMosqueHero(double rsw, double sh,
      List<PrayerRingEntry> ring, {
        required Color accent,
        required Color accentSoft,
      }) {
    // Ring size: between 220 and 260 px regardless of screen
    final ringSize = (rsw * 0.60).clamp(200.0, 260.0);
    final mosqueH  = (sh * 0.20).clamp(130.0, 210.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: rsw * 0.03),
      decoration: BoxDecoration(
        color:        accent.withOpacity(0.04),
        borderRadius: BorderRadius.circular(rsw * 0.05),
        border:       Border.all(color: accentSoft.withOpacity(0.25), width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: rsw * 0.02),
            child: MosqueIllustration(accentColor: accent, height: mosqueH),
          ),
          SizedBox(height: rsw * 0.02),
          PrayerProgressRing(entries: ring, size: ringSize),
          SizedBox(height: rsw * 0.01),
        ],
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _sectionLabel(double rsw, String label, {required Color accent}) {
    return Row(
      children: [
        Container(
          width: 4, height: rsw * 0.045,
          decoration: BoxDecoration(
              color: accent, borderRadius: BorderRadius.circular(2)),
        ),
        SizedBox(width: rsw * 0.025),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:         Colors.white,
              fontSize:      rsw * 0.043,
              fontWeight:    FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  // ── Salat card ─────────────────────────────────────────────────────────────
  Widget _buildSalatCard(
      double rsw, PrayerTimesModel t, String current, Color cardColor, {
        required bool use24h,
        required Color accent,
        required AppLocalizations l10n,
      }) {
    final prayers = [
      (key: 'Fajr',    name: l10n.fajr,    icon: Icons.wb_twilight,      s: t.fajrStart,    e: t.fajrEnd),
      (key: 'Dhuhr',   name: l10n.dhuhr,   icon: Icons.wb_sunny,          s: t.dhuhrStart,   e: t.dhuhrEnd),
      (key: 'Asr',     name: l10n.asr,     icon: Icons.cloud,             s: t.asrStart,     e: t.asrEnd),
      (key: 'Maghrib', name: l10n.maghrib,  icon: Icons.nightlight_round,  s: t.maghribStart, e: t.maghribEnd),
      (key: 'Isha',    name: l10n.isha,    icon: Icons.dark_mode,         s: t.ishaStart,    e: t.ishaEnd),
    ];
    const colors = {
      'Fajr':    Color(0xFF5B8DEF),
      'Dhuhr':   Color(0xFFFFD54F),
      'Asr':     Color(0xFFFFB74D),
      'Maghrib': Color(0xFFEF9A9A),
      'Isha':    Color(0xFFB39DDB),
    };
    return _glassCard(rsw, cardColor, const Color(0xFF66BB6A),
      children: prayers.map((p) => _prayerRow(rsw, p.icon, p.name,
        '${_fmt(p.s, use24h: use24h)} – ${_fmt(p.e, use24h: use24h)}',
        isActive:    p.key == current,
        activeColor: colors[p.key] ?? accent,
        accent:      accent,
        activeLabel: l10n.active,
      )).toList(),
    );
  }

  // ── Prohibited card ────────────────────────────────────────────────────────
  Widget _buildProhibitedCard(
      double rsw, PrayerTimesModel t, String current, Color cardColor, {
        required bool use24h,
        required AppLocalizations l10n,
      }) {
    final items = [
      (key: 'SunRise', name: l10n.sunrise, icon: Icons.wb_twilight, s: t.sunRiseStart, e: t.sunRiseEnd),
      (key: 'Noon',    name: l10n.noon,    icon: Icons.wb_sunny,    s: t.noonStart,    e: t.noonEnd),
      (key: 'SunSet',  name: l10n.sunset,  icon: Icons.cloud,       s: t.sunSetStart,  e: t.sunSetEnd),
    ];
    return _glassCard(rsw, cardColor, Colors.red,
      children: items.map((item) => _prayerRow(rsw, item.icon, item.name,
        '${_fmt(item.s, use24h: use24h)} – ${_fmt(item.e, use24h: use24h)}',
        isActive:        item.key == current,
        activeColor:     Colors.red[300]!,
        isProhibited:    true,
        accent:          Colors.red,
        activeLabel:     l10n.now,
        prohibitedLabel: l10n.prohibited,
      )).toList(),
    );
  }

  // ── Sawm card ──────────────────────────────────────────────────────────────
  Widget _buildSawmCard(
      double rsw, PrayerTimesModel t, Color cardColor, {
        required bool use24h,
        required AppLocalizations l10n,
      }) {
    return _glassCard(rsw, cardColor, const Color(0xFF4FC3F7),
      children: [
        _prayerRow(rsw, Icons.wb_twilight, l10n.iftar,
            _fmt(t.iftarTime, use24h: use24h),
            accent: const Color(0xFF4FC3F7)),
        _prayerRow(rsw, Icons.wb_sunny, l10n.sahri,
            _fmt(t.sahriEnd, use24h: use24h),
            accent: const Color(0xFF4FC3F7)),
      ],
    );
  }

  // ── Nafal card ─────────────────────────────────────────────────────────────
  Widget _buildNafalCard(
      double rsw, PrayerTimesModel t, Color cardColor, {
        required bool use24h,
        required AppLocalizations l10n,
      }) {
    return _glassCard(rsw, cardColor, const Color(0xFFCE93D8),
      children: [
        _prayerRow(rsw, Icons.cloud, l10n.tahajjud,
            '${_fmt(t.tahajjudStart, use24h: use24h)} – ${_fmt(t.tahajjudEnd, use24h: use24h)}',
            accent: const Color(0xFFCE93D8)),
        _prayerRow(rsw, Icons.wb_twilight, l10n.ishraq,
            '${_fmt(t.ishraqStart, use24h: use24h)} – ${_fmt(t.ishraqEnd, use24h: use24h)}',
            accent: const Color(0xFFCE93D8)),
        _prayerRow(rsw, Icons.wb_sunny, l10n.chasht,
            '${_fmt(t.chashtStart, use24h: use24h)} – ${_fmt(t.chashtEnd, use24h: use24h)}',
            accent: const Color(0xFFCE93D8)),
        _prayerRow(rsw, Icons.dark_mode, l10n.zawal,
            _fmt(t.zawalStart, use24h: use24h),
            accent: const Color(0xFFCE93D8)),
        _prayerRow(rsw, Icons.nightlight_round, l10n.awabin,
            '${_fmt(t.awabinStart, use24h: use24h)} – ${_fmt(t.awabinEnd, use24h: use24h)}',
            accent: const Color(0xFFCE93D8)),
      ],
    );
  }

  // ── Glass card ─────────────────────────────────────────────────────────────
  Widget _glassCard(double rsw, Color bg, Color accentColor,
      {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(rsw * 0.048),
        border: Border.all(color: accentColor.withOpacity(0.25), width: 0.8),
        boxShadow: [
          BoxShadow(
            color:      accentColor.withOpacity(0.06),
            blurRadius: rsw * 0.06,
            offset:     Offset(0, rsw * 0.010),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(rsw * 0.048),
        child: Column(
          children: [
            Container(
              height: 2.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  accentColor.withOpacity(0.0),
                  accentColor.withOpacity(0.70),
                  accentColor.withOpacity(0.0),
                ]),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(rsw * 0.042),
              child: Column(
                children: List.generate(children.length * 2 - 1, (i) {
                  if (i.isEven) return children[i ~/ 2];
                  return Divider(
                    color:     accentColor.withOpacity(0.12),
                    height:    rsw * 0.030,
                    thickness: 0.6,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Prayer row ─────────────────────────────────────────────────────────────
  Widget _prayerRow(
      double rsw, IconData icon, String name, String time, {
        bool   isActive        = false,
        Color  activeColor     = const Color(0xFF4CAF82),
        bool   isProhibited    = false,
        required Color accent,
        String activeLabel     = 'Active',
        String prohibitedLabel = 'Prohibited',
      }) {
    // All sizes relative to rsw — safe on small (320) and large (420+) screens
    final iconCircle  = rsw * 0.088;
    final iconSz      = rsw * 0.044;
    final nameFontSz  = rsw * 0.036;
    final subFontSz   = rsw * 0.027;
    final badgeFontSz = rsw * 0.025;
    final timeFontSz  = rsw * 0.032;

    return Container(
      padding: isActive
          ? EdgeInsets.symmetric(
          horizontal: rsw * 0.025, vertical: rsw * 0.016)
          : EdgeInsets.symmetric(vertical: rsw * 0.014),
      decoration: isActive
          ? BoxDecoration(
        color:        activeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(rsw * 0.028),
        border:       Border.all(
            color: activeColor.withOpacity(0.40), width: 0.8),
      )
          : null,
      child: Row(
        children: [
          // Icon circle
          Container(
            width:  iconCircle,
            height: iconCircle,
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withOpacity(0.20)
                  : Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size:  iconSz,
                color: isActive ? activeColor : Colors.white54),
          ),
          SizedBox(width: rsw * 0.025),

          // Name + sub-label
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines:  1,
                  overflow:  TextOverflow.ellipsis,
                  style: TextStyle(
                    color:      isActive ? activeColor : Colors.white,
                    fontSize:   nameFontSz,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (isProhibited && !isActive)
                  Text(
                    prohibitedLabel,
                    style: TextStyle(
                        color: Colors.red[300], fontSize: subFontSz),
                  ),
              ],
            ),
          ),

          // Active / Now badge
          if (isActive) ...[
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: rsw * 0.020, vertical: rsw * 0.007),
              decoration: BoxDecoration(
                color: isProhibited
                    ? Colors.red.withOpacity(0.20)
                    : accent.withOpacity(0.20),
                borderRadius: BorderRadius.circular(rsw * 0.028),
              ),
              child: Text(
                activeLabel,
                style: TextStyle(
                  color:      isProhibited ? Colors.red[300] : accent,
                  fontSize:   badgeFontSz,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: rsw * 0.014),
          ],

          // Time
          Flexible(
            flex: 6,
            child: Text(
              time,
              textAlign: TextAlign.right,
              maxLines:  1,
              overflow:  TextOverflow.ellipsis,
              style: TextStyle(
                color:         isActive ? activeColor : Colors.white70,
                fontSize:      timeFontSz,
                fontWeight:    isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom nav ─────────────────────────────────────────────────────────────
  Widget _buildNav({
    required double sw,
    required double rsw,
    required Color surface,
    required Color accentSoft,
    required Color accent,
    required Color textLo,
    required AppLocalizations l10n,
  }) {
    final items = [
      (l10n.today, 'assets/icons/today.png'),
      (l10n.tools, 'assets/icons/tools.png'),
      (l10n.quran, 'assets/icons/quran.png'),
      (l10n.duas,  'assets/icons/duas.png'),
      (l10n.menu,  'assets/icons/menu.png'),
    ];

    // Nav icon size scales with real screen width, clamped
    final iconSz   = (sw * 0.058).clamp(22.0, 28.0);
    final labelSz  = (sw * 0.024).clamp(9.0,  11.5);

    return Container(
      decoration: BoxDecoration(
        color:  surface,
        border: Border(
            top: BorderSide(color: accentSoft.withOpacity(0.22), width: 0.8)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
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
              final active = i == 0;

              return GestureDetector(
                onTap: () {
                  if (!active) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => _pages[i]));
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.symmetric(
                      horizontal: rsw * 0.032, vertical: rsw * 0.016),
                  decoration: BoxDecoration(
                    color: active
                        ? accentSoft.withOpacity(0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(rsw * 0.038),
                    border: active
                        ? Border.all(
                        color: accentSoft.withOpacity(0.40), width: 0.8)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(asset,
                          width: iconSz, height: iconSz),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize:      labelSz,
                          fontWeight:    active ? FontWeight.w700 : FontWeight.w400,
                          color:         active ? accent : textLo,
                          letterSpacing: 0.2,
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