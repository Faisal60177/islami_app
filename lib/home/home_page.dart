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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:islamic_app/notification/page/notification_page.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:marquee/marquee.dart';
import 'mosque.dart';
import 'ring_animation.dart';
import 'package:islamic_app/notification/cubit/notification_cubit.dart';
import 'package:islamic_app/notification/cubit/notification_state.dart';
import 'package:islamic_app/notification/page/notification_page.dart';
// ── Settings imports ──────────────────────────────────────────────────────────
import 'package:islamic_app/settings/cubit/settings_cubit.dart';
import 'package:islamic_app/settings/cubit/settings_state.dart';
import 'package:islamic_app/settings/l10n/app_localizations.dart';
import 'package:islamic_app/settings/theme/app_themes.dart';
import '../settings/l10n/app_localizations.dart';


// ─── Palette ─────────────────────────────────────────────────────────────────
const _bgDeep    = Color(0xFF011A0D);
const _bgBase    = Color(0xFF013220);
const _surface   = Color(0xFF0D2E1C);
const _accent    = Color(0xFF4CAF82);
const _accentSoft= Color(0xFF2E7D5A);
const _textLo    = Color(0xFF7BAF92);

// Card colours by category
const _cardSalat    = Color(0xFF0A3D25);
const _cardProhib   = Color(0xFF3B0E0E);
const _cardSawm     = Color(0xFF0E2A3B);
const _cardNafal    = Color(0xFF1A1A3B);

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {

  // ── Date helpers ────────────────────────────────────────────────────────────
  String getHijriDate() {
    final hijri = HijriCalendar.now();
    return "${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH";
  }

  String getEnglishDate() {
    return DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
  }

  final List<Widget> _pages = const [
    PrayerTimesPage(),
    ToolsPage(),
    QuranPage(),
    DuasPage(),
    MenuPage(),
  ];

  // ── Current prayer ──────────────────────────────────────────────────────────
  String getCurrentPrayer(PrayerTimesModel t) {
    final now = DateTime.now();

    // Helper: check if now is within a time range, handling midnight crossover
    bool inRange(DateTime start, DateTime end) {
      if (end.isAfter(start)) {
        // Normal range (same day)
        return now.isAfter(start) && now.isBefore(end);
      } else {
        // Crosses midnight — active if after start OR before end
        return now.isAfter(start) || now.isBefore(end);
      }
    }

    if (inRange(t.fajrStart,    t.fajrEnd))       return "Fajr";
    if (inRange(t.sunRiseStart, t.sunRiseEnd))    return "SunRise";
    if (now.isAfter(t.sunRiseEnd) && now.isBefore(t.noonStart)) return "Ishraq";
    if (inRange(t.noonStart,    t.noonEnd))       return "Noon";
    if (inRange(t.dhuhrStart,   t.dhuhrEnd))      return "Dhuhr";
    if (inRange(t.asrStart,     t.asrEnd))        return "Asr";
    if (inRange(t.sunSetStart,  t.sunSetEnd))     return "SunSet";
    if (inRange(t.maghribStart, t.maghribEnd))    return "Maghrib";
    if (inRange(t.ishaStart,    t.ishaEnd))       return "Isha";
    return "";
  }

  // ── Ring data builder ───────────────────────────────────────────────────────
  List<PrayerRingEntry> buildRing(PrayerTimesModel t) {
    // Fix Isha end: if ishaEnd is before ishaStart it has crossed midnight.
    // Normalize it to the same day by adding 1 day so the sweep angle is correct.
    DateTime ishaEnd = t.ishaEnd;
    if (ishaEnd.isBefore(t.ishaStart) || ishaEnd.isAtSameMomentAs(t.ishaStart)) {
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
      // ✅ Use normalized ishaEnd so the arc sweep is always positive
      PrayerRingEntry(name: 'Isha',    start: t.ishaStart,    end: ishaEnd),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final px = sw * 0.04;

    return Scaffold(
      backgroundColor: _bgBase,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [

            // ── Header ──────────────────────────────────────────────────────
            _buildHeader(sw, sh, px),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: px),
              child: Column(
                children: [

                  // ── Date row ───────────────────────────────────────────────
                  _buildDateRow(sw),
                  SizedBox(height: sh * 0.025),

                  // ── Prayer content ─────────────────────────────────────────
                  BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
                    builder: (context, state) {
                      if (state is PrayerTimesLoading) {
                        return SizedBox(
                          height: sh * 0.4,
                          child: const Center(
                            child: CircularProgressIndicator(color: _accent),
                          ),
                        );
                      }
                      if (state is PrayerTimesError) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(px),
                            child: Text(state.message,
                                style: TextStyle(
                                    color: Colors.red[300], fontSize: sw * 0.04)),
                          ),
                        );
                      }
                      if (state is PrayerTimesLoaded) {
                        final times = state.prayerTimes;
                        final current = getCurrentPrayer(times);
                        final ring = buildRing(times);

                        return Column(
                          children: [
                            // Mosque + Ring hero
                            _buildMosqueHero(sw, sh, ring),
                            SizedBox(height: sh * 0.025),

                            // ── Prayer cards ─────────────────────────────────
                            _buildSectionLabel(sw, 'Salat Prayers'),
                            SizedBox(height: sh * 0.010),
                            _buildSalatCard(sw, times, current),
                            SizedBox(height: sh * 0.018),

                            _buildSectionLabel(sw, 'Prohibited Times'),
                            SizedBox(height: sh * 0.010),
                            _buildProhibitedCard(sw, times, current),
                            SizedBox(height: sh * 0.018),

                            _buildSectionLabel(sw, 'Sawm Times'),
                            SizedBox(height: sh * 0.010),
                            _buildSawmCard(sw, times),
                            SizedBox(height: sh * 0.018),

                            _buildSectionLabel(sw, 'Nafal Prayers'),
                            SizedBox(height: sh * 0.010),
                            _buildNafalCard(sw, times),
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
      bottomNavigationBar: _buildNav(),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(double sw, double sh, double px) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + sw * 0.03,
        left: px, right: px, bottom: sw * 0.03,
      ),
      decoration: BoxDecoration(
        color: _bgDeep,
        border: Border(
          bottom: BorderSide(color: _accentSoft.withOpacity(0.20), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Location
          Expanded(
            child: BlocBuilder<LocationCubit, LocationState>(
              builder: (context, state) {
                String text = "Locating...";
                if (state is LocationLoaded) {
                  text = "${state.location.city}, ${state.location.country}";
                } else if (state is LocationPermissionDenied) {
                  text = "Permission denied";
                }
                return GestureDetector(
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const LocationPage())),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on,
                            color: _accent, size: 16),
                      ),
                      SizedBox(width: sw * 0.020),
                      Expanded(
                        child: SizedBox(
                          height: sh * 0.030,
                          child: Marquee(
                            text: text,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: sw * 0.038,
                            ),
                            velocity: 28.0,
                            pauseAfterRound: const Duration(seconds: 2),
                            blankSpace: 24.0,
                            startPadding: 0,
                            accelerationDuration: const Duration(milliseconds: 800),
                            accelerationCurve: Curves.easeIn,
                            decelerationDuration: const Duration(milliseconds: 800),
                            decelerationCurve: Curves.easeOut,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(width: sw * 0.03),

          // Notification bell
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              final count = state is NotificationLoaded
                  ? state.unreadCount
                  : 0;
              return GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationPage())),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.10),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.red.withOpacity(0.30), width: 1),
                      ),
                      child: Icon(Icons.notifications_rounded,
                          color: Colors.red[300], size: sw * 0.055),
                    ),
                    // Only show badge when unread count > 0
                    if (count > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: sw * 0.042,
                          height: sw * 0.042,
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: sw * 0.021,
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

  // ── Date row ──────────────────────────────────────────────────────────────
  Widget _buildDateRow(double sw) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _datePill(getEnglishDate(), const Color(0xFF66BB6A), sw),
        _datePill(getHijriDate(), const Color(0xFFFFB74D), sw),
      ],
    );
  }

  Widget _datePill(String text, Color color, double sw) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sw * 0.03, vertical: sw * 0.015),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(sw * 0.05),
        border: Border.all(color: color.withOpacity(0.35), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: sw * 0.028,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ── Mosque + Ring hero ───────────────────────────────────────────────────
  Widget _buildMosqueHero(double sw, double sh, List<PrayerRingEntry> ring) {
    final ringSize = sw * 0.60;
    final mosqueH = sh * 0.22;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: sw * 0.03),
      decoration: BoxDecoration(
        color: const Color(0xFF011A0D),
        borderRadius: BorderRadius.circular(sw * 0.05),
        border: Border.all(color: _accentSoft.withOpacity(0.25), width: 1),
      ),
      child: Column(
        children: [
          // Mosque illustration (full width, sits behind/above ring)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.02),
            child: MosqueIllustration(
              accentColor: _accent,
              height: mosqueH,
            ),
          ),
          SizedBox(height: sw * 0.02),

          // Ring
          PrayerProgressRing(
            entries: ring,
            size: ringSize,
          ),
          SizedBox(height: sw * 0.01),
        ],
      ),
    );
  }

  // ── Section label ────────────────────────────────────────────────────────
  Widget _buildSectionLabel(double sw, String label) {
    return Row(
      children: [
        Container(
          width: 4, height: sw * 0.045,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: sw * 0.025),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: sw * 0.045,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ── Salat card ─────────────────────────────────────────────────────────────
  Widget _buildSalatCard(double sw, PrayerTimesModel t, String current) {
    const prayers = [
      {'name': 'Fajr',    'icon': Icons.wb_twilight},
      {'name': 'Dhuhr',   'icon': Icons.wb_sunny},
      {'name': 'Asr',     'icon': Icons.cloud},
      {'name': 'Maghrib', 'icon': Icons.nightlight_round},
      {'name': 'Isha',    'icon': Icons.dark_mode},
    ];

    final Map<String, List<DateTime>> times = {
      'Fajr':    [t.fajrStart, t.fajrEnd],
      'Dhuhr':   [t.dhuhrStart, t.dhuhrEnd],
      'Asr':     [t.asrStart, t.asrEnd],
      'Maghrib': [t.maghribStart, t.maghribEnd],
      'Isha':    [t.ishaStart, t.ishaEnd],
    };

    final Map<String, Color> prayerColors = {
      'Fajr':    const Color(0xFF5B8DEF),
      'Dhuhr':   const Color(0xFFFFD54F),
      'Asr':     const Color(0xFFFFB74D),
      'Maghrib': const Color(0xFFEF9A9A),
      'Isha':    const Color(0xFFB39DDB),
    };

    return _glassCard(
      sw,
      _cardSalat,
      const Color(0xFF66BB6A),
      children: prayers.map((p) {
        final name = p['name'] as String;
        final icon = p['icon'] as IconData;
        final isActive = name == current;
        final color = prayerColors[name] ?? _accent;
        final startEnd = times[name]!;
        return _prayerRow(
          sw, icon, name,
          '${_fmt(startEnd[0])} – ${_fmt(startEnd[1])}',
          isActive: isActive,
          activeColor: color,
        );
      }).toList(),
    );
  }

  // ── Prohibited card ────────────────────────────────────────────────────────
  Widget _buildProhibitedCard(double sw, PrayerTimesModel t, String current) {
    final items = [
      ['SunRise', Icons.wb_twilight,      t.sunRiseStart, t.sunRiseEnd],
      ['Noon',    Icons.wb_sunny,          t.noonStart,    t.noonEnd],
      ['SunSet',  Icons.cloud,             t.sunSetStart,  t.sunSetEnd],
    ];

    return _glassCard(
      sw,
      _cardProhib,
      Colors.red,
      children: items.map((item) {
        final name = item[0] as String;
        final icon = item[1] as IconData;
        final s    = item[2] as DateTime;
        final e    = item[3] as DateTime;
        final isActive = name == current;
        return _prayerRow(
          sw, icon, name, '${_fmt(s)} – ${_fmt(e)}',
          isActive: isActive,
          activeColor: Colors.red[300]!,
          isProhibited: true,
        );
      }).toList(),
    );
  }

  // ── Sawm card ──────────────────────────────────────────────────────────────
  Widget _buildSawmCard(double sw, PrayerTimesModel t) {
    return _glassCard(
      sw,
      _cardSawm,
      const Color(0xFF4FC3F7),
      children: [
        _prayerRow(sw, Icons.wb_twilight, 'Iftar',       _fmt(t.iftarTime)),
        _prayerRow(sw, Icons.wb_sunny,    'Sahri End',   _fmt(t.sahriEnd)),
      ],
    );
  }

  // ── Nafal card ─────────────────────────────────────────────────────────────
  Widget _buildNafalCard(double sw, PrayerTimesModel t) {
    return _glassCard(
      sw,
      _cardNafal,
      const Color(0xFFCE93D8),
      children: [
        _prayerRow(sw, Icons.cloud,              'Tahajjud', '${_fmt(t.tahajjudStart)} – ${_fmt(t.tahajjudEnd)}'),
        _prayerRow(sw, Icons.wb_twilight,        'Ishraq',   '${_fmt(t.ishraqStart)} – ${_fmt(t.ishraqEnd)}'),
        _prayerRow(sw, Icons.wb_sunny,           'Chasht',   '${_fmt(t.chashtStart)} – ${_fmt(t.chashtEnd)}'),
        _prayerRow(sw, Icons.dark_mode,          'Zawal',    _fmt(t.zawalStart)),
        _prayerRow(sw, Icons.nightlight_round,   'Awabin',   '${_fmt(t.awabinStart)} – ${_fmt(t.awabinEnd)}'),
      ],
    );
  }

  // ── Glass card container ──────────────────────────────────────────────────
  Widget _glassCard(double sw, Color bg, Color accentColor,
      {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(sw * 0.048),
        border: Border.all(color: accentColor.withOpacity(0.25), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.06),
            blurRadius: sw * 0.06,
            offset: Offset(0, sw * 0.010),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(sw * 0.048),
        child: Column(
          children: [
            // Accent top stripe
            Container(
              height: 2.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor.withOpacity(0.0),
                    accentColor.withOpacity(0.70),
                    accentColor.withOpacity(0.0)],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(sw * 0.042),
              child: Column(
                children: List.generate(children.length * 2 - 1, (i) {
                  if (i.isEven) return children[i ~/ 2];
                  return Divider(
                    color: accentColor.withOpacity(0.12),
                    height: sw * 0.030,
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
      double sw,
      IconData icon,
      String name,
      String time, {
        bool isActive = false,
        Color activeColor = _accent,
        bool isProhibited = false,
      }) {
    return Container(
      padding: isActive
          ? EdgeInsets.symmetric(
          horizontal: sw * 0.028, vertical: sw * 0.018)
          : EdgeInsets.symmetric(vertical: sw * 0.016),
      decoration: isActive
          ? BoxDecoration(
        color: activeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(sw * 0.030),
        border: Border.all(
            color: activeColor.withOpacity(0.40), width: 0.8),
      )
          : null,
      child: Row(
        children: [
          // Icon circle
          Container(
            width: sw * 0.092,
            height: sw * 0.092,
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withOpacity(0.20)
                  : Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: sw * 0.048,
              color: isActive ? activeColor : Colors.white54,
            ),
          ),
          SizedBox(width: sw * 0.028),

          // Name
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isActive ? activeColor : Colors.white,
                    fontSize: sw * 0.038,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (isProhibited && !isActive)
                  Text(
                    'Prohibited',
                    style: TextStyle(
                      color: Colors.red[300],
                      fontSize: sw * 0.028,
                    ),
                  ),
              ],
            ),
          ),

          // Active badge
          if (isActive) ...[
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.022, vertical: sw * 0.008),
              decoration: BoxDecoration(
                color: isProhibited
                    ? Colors.red.withOpacity(0.20)
                    : _accent.withOpacity(0.20),
                borderRadius: BorderRadius.circular(sw * 0.03),
              ),
              child: Text(
                isProhibited ? 'Now' : 'Active',
                style: TextStyle(
                  color: isProhibited ? Colors.red[300] : _accent,
                  fontSize: sw * 0.026,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: sw * 0.016),
          ],

          // Time
          Flexible(
            flex: 6,
            child: Text(
              time,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isActive ? activeColor : Colors.white70,
                fontSize: sw * 0.034,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Time formatter ─────────────────────────────────────────────────────────
  String _fmt(DateTime dt) {
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }

  // ── Bottom nav ─────────────────────────────────────────────────────────────
  Widget _buildNav() {
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
            top: BorderSide(color: _accentSoft.withOpacity(0.22), width: 0.8)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: active
                        ? _accentSoft.withOpacity(0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: active
                        ? Border.all(
                        color: _accentSoft.withOpacity(0.40), width: 0.8)
                        : null,
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
                          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                          color: active ? _accent : _textLo,
                          letterSpacing: 0.3,
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