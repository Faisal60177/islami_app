import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/Quran/quran_page.dart';
import 'package:muslim_app/location/home/location_page.dart';
import 'package:muslim_app/tools/tools_page.dart';
import '../../../location/cubit/location_cubit.dart';
import '../../../location/cubit/location_state.dart';
import 'package:muslim_app/home/cubit/prayer_times_cubit.dart';
import 'package:muslim_app/home/cubit/prayer_times_state.dart';
import '../../../home/model/prayer_times_models.dart';
import 'package:muslim_app/Duas/pages/duas_page.dart';
import 'package:muslim_app/Menu/menu_page.dart';
import 'package:muslim_app/notification/page/notification_page.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:marquee/marquee.dart';
import 'package:muslim_app/notification/cubit/notification_cubit.dart';
import 'package:muslim_app/notification/cubit/notification_state.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import 'widgets/prayer_times_card.dart';
import 'widgets/mosque.dart';
import 'widgets/ring_animation.dart';
import 'package:flutter/services.dart';
import 'package:muslim_app/alarm/cubit/alarm_cubit.dart';
import 'package:muslim_app/alarm/pages/alarm_list_page.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {

  ({
  String topLabel,
  String bottomLabel,
  DateTime periodStart,
  DateTime periodEnd,
  bool isProhibited,
  }) _ringData(PrayerTimesModel t) {
    final current = _currentPrayer(t);

    switch (current) {
      case 'Fajr':
        return (topLabel: 'Fajr', bottomLabel: 'waqt ends in', periodStart: t.fajrStart, periodEnd: t.sunRiseStart, isProhibited: false);
      case 'SunRise':
        return (topLabel: 'Sunrise', bottomLabel: 'ends in', periodStart: t.sunRiseStart, periodEnd: t.ishraqStart, isProhibited: true);
      case 'Ishraq':
        return (topLabel: 'Ishraq', bottomLabel: 'waqt ends in', periodStart: t.ishraqStart, periodEnd: t.noonStart, isProhibited: false);
      case 'Noon':
        return (topLabel: 'Noon', bottomLabel: 'ends in', periodStart: t.noonStart, periodEnd: t.dhuhrStart, isProhibited: true);
      case 'Dhuhr':
        return (topLabel: 'Dhuhr', bottomLabel: 'waqt ends in', periodStart: t.dhuhrStart, periodEnd: t.asrStart, isProhibited: false);
      case 'Asr':
        return (topLabel: 'Asr', bottomLabel: 'waqt ends in', periodStart: t.asrStart, periodEnd: t.sunSetStart, isProhibited: false);
      case 'SunSet':
        return (topLabel: 'Sunset', bottomLabel: 'ends in', periodStart: t.sunSetStart, periodEnd: t.maghribStart, isProhibited: true);
      case 'Maghrib':
        return (topLabel: 'Maghrib', bottomLabel: 'waqt ends in', periodStart: t.maghribStart, periodEnd: t.ishaStart, isProhibited: false);
      case 'Isha':
      default:
        return (topLabel: 'Isha', bottomLabel: 'waqt ends in', periodStart: t.ishaStart, periodEnd: t.fajrStart.add(const Duration(days: 1)), isProhibited: false);
    }
  }

  static const List<Widget> _pages = [
    PrayerTimesPage(),
    ToolsPage(),
    QuranPage(),
    DuasPage(),
    MenuPage(),
  ];

  String _localizedDate(AppLocalizations l10n) {
    final now = DateTime.now();
    final weekdays = [l10n.monday, l10n.tuesday, l10n.wednesday, l10n.thursday, l10n.friday, l10n.saturday, l10n.sunday];
    final weekday = weekdays[now.weekday - 1];
    final months = [l10n.january, l10n.february, l10n.march, l10n.april, l10n.mayMonth, l10n.june, l10n.july, l10n.august, l10n.september, l10n.october, l10n.november, l10n.december];
    final month = months[now.month - 1];
    final day  = _localizeDigits('${now.day}', l10n);
    final year = _localizeDigits('${now.year}', l10n);
    return '$weekday, $day $month $year';
  }

  String _localizedHijriDate(int offset, AppLocalizations l10n) {
    final adjusted = DateTime.now().add(Duration(days: offset));
    final h = HijriCalendar.fromDate(adjusted);
    final hijriMonths = List.generate(12, (i) => _hijriMonthName(i + 1, l10n));
    final monthName = hijriMonths[h.hMonth - 1];
    final day  = _localizeDigits('${h.hDay}', l10n);
    final year = _localizeDigits('${h.hYear}', l10n);
    final ah   = _ahLabel(l10n);
    return '$day $monthName $year $ah';
  }

  String _localizeDigits(String input, AppLocalizations l10n) {
    const digits = ['0','1','2','3','4','5','6','7','8','9'];
    final local  = [l10n.zero, l10n.one, l10n.two, l10n.three, l10n.four, l10n.five, l10n.six, l10n.seven, l10n.eight, l10n.nine];
    return input.split('').map((c) {
      final i = digits.indexOf(c);
      return i >= 0 ? local[i] : c;
    }).join();
  }

  String _hijriMonthName(int month, AppLocalizations l10n) => l10n.translate('hijri_month_$month');
  String _ahLabel(AppLocalizations l10n) => l10n.translate('hijri_ah');

  String _currentPrayer(PrayerTimesModel t) {
    final now = DateTime.now();
    bool after(DateTime s) => now.isAfter(s);
    bool before(DateTime e) => now.isBefore(e);
    bool inRange(DateTime s, DateTime e) => after(s) && before(e);

    if (inRange(t.fajrStart,    t.sunRiseStart))  return 'Fajr';
    if (inRange(t.sunRiseStart, t.ishraqStart))   return 'SunRise';
    if (inRange(t.ishraqStart,  t.noonStart))     return 'Ishraq';
    if (inRange(t.noonStart,    t.dhuhrStart))    return 'Noon';
    if (inRange(t.dhuhrStart,   t.asrStart))      return 'Dhuhr';
    if (inRange(t.asrStart,     t.sunSetStart))   return 'Asr';
    if (inRange(t.sunSetStart,  t.maghribStart))  return 'SunSet';
    if (inRange(t.maghribStart, t.ishaStart))     return 'Maghrib';
    if (after(t.ishaStart) || before(t.fajrStart)) return 'Isha';
    return 'Isha';
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final rsw = sw.clamp(320.0, 420.0);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        final theme      = getThemeById(settings.themeMode);
        final l10n       = AppLocalizations(settings.languageCode);
        final hijriOff   = settings.hijriOffset;
        final use24h     = settings.use24Hour;

        final bgBase     = theme.background;
        final surface    = theme.surface;
        final accent     = theme.accent;
        final accentSoft = theme.primary.withOpacity(0.55);
        final textLo     = theme.textLow;

        return Scaffold(
          extendBodyBehindAppBar: true,
          extendBody: true,
          backgroundColor: bgBase,
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
            ),
            child: RefreshIndicator(
              color: accent,
              backgroundColor: surface,
              displacement: 80,
              onRefresh: () async {
                final locationCubit = context.read<LocationCubit>();
                locationCubit.getGPSLocation();

                final result = await Future.any([
                  Stream.periodic(const Duration(milliseconds: 100))
                      .asyncMap((_) => locationCubit.state)
                      .firstWhere((s) => s is LocationLoaded || s is LocationPermissionDenied),
                  Future.delayed(const Duration(seconds: 10)),
                ]);

                if (!context.mounted) return;

                if (result is LocationLoaded) {
                  await locationCubit.saveCurrentLocation();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.locationUpdatedSuccessfully),
                      backgroundColor: accent,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else if (result is LocationPermissionDenied) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.permissionDenied),
                      backgroundColor: theme.danger,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.permissionDenied),
                      backgroundColor: Colors.orange[400],
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
                      builder: (context, state) {
                        // Hero reduced from 0.46 -> 0.40 of screen height so
                        // users reach the prayer-times cards with less scroll.
                        final heroH  = (sh * 0.40).clamp(280.0, 380.0);
                        final ringSz = (rsw * 0.50).clamp(165.0, 205.0);

                        String current = '';
                        ({
                        String topLabel,
                        String bottomLabel,
                        DateTime periodStart,
                        DateTime periodEnd,
                        bool isProhibited,
                        })? ringData;

                        if (state is PrayerTimesLoaded) {
                          current  = _currentPrayer(state.prayerTimes);
                          ringData = _ringData(state.prayerTimes);
                        }

                        return SizedBox(
                          width:  double.infinity,
                          height: heroH,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [

                              Positioned.fill(
                                child: MosqueHeroWidget(
                                  height:        heroH,
                                  currentPrayer: current,
                                ),
                              ),

                              Positioned(
                                top:   MediaQuery.of(context).padding.top + sh * 0.008,
                                left:  sw * 0.04,
                                right: sw * 0.04,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: BlocBuilder<LocationCubit, LocationState>(
                                            builder: (context, locState) {
                                              String text = l10n.locating;
                                              if (locState is LocationLoaded) {
                                                text = '${locState.location.city}, ${locState.location.country}';
                                              } else if (locState is LocationPermissionDenied) {
                                                text = l10n.permissionDenied;
                                              }
                                              final maxTextWidth = sw * 0.4;
                                              return GestureDetector(
                                                onTap: () => Navigator.push(context,
                                                    MaterialPageRoute(builder: (_) => const LocationPage())),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.all(rsw * 0.015),
                                                      decoration: BoxDecoration(
                                                        color: accent.withOpacity(0.15),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(Icons.location_on, color: accent),
                                                    ),
                                                    SizedBox(width: rsw * 0.020),
                                                    Flexible(
                                                      child: SizedBox(
                                                        width:  maxTextWidth,
                                                        height: sh * 0.030,
                                                        // FIX: only marquee-scroll text that actually
                                                        // overflows; short text ("Teknaf, Bangladesh")
                                                        // was showing a looping/duplicate peek before.
                                                        child: _buildLocationText(text, maxTextWidth),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        SizedBox(width: rsw * 0.03),
                                        BlocBuilder<NotificationCubit, NotificationState>(
                                          builder: (context, notifState) {
                                            final count = notifState is NotificationLoaded
                                                ? notifState.unreadCount : 0;
                                            return GestureDetector(
                                              onTap: () => Navigator.push(context,
                                                  MaterialPageRoute(builder: (_) => const NotificationPage())),
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.all(rsw * 0.020),
                                                    decoration: BoxDecoration(
                                                      color:  theme.danger.withOpacity(0.10),
                                                      shape:  BoxShape.circle,
                                                      border: Border.all(color: theme.danger.withOpacity(0.30), width: 1),
                                                    ),
                                                    child: Icon(Icons.notifications_rounded,
                                                        color: theme.danger, size: rsw * 0.055),
                                                  ),
                                                  if (count > 0)
                                                    Positioned(
                                                      right: 0, top: 0,
                                                      child: Container(
                                                        width: 16, height: 16,
                                                        decoration: BoxDecoration(color: theme.danger, shape: BoxShape.circle),
                                                        alignment: Alignment.center,
                                                        child: Text(
                                                          count > 99 ? '99+' : '$count',
                                                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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
                                    SizedBox(height: sh * 0.008),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(_localizedDate(l10n), style: TextStyle(
                                          fontSize: (rsw * 0.030).clamp(11.0, 13.5),
                                          color: Colors.white,
                                          shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                                        )),
                                        Text(_localizedHijriDate(hijriOff, l10n), style: TextStyle(
                                          fontSize: (rsw * 0.030).clamp(11.0, 13.5),
                                          color: Colors.white,
                                          shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                                        )),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              if (state is PrayerTimesLoaded && ringData != null)
                                Positioned(
                                  top:   heroH * 0.34,
                                  left:  0, right: 0,
                                  child: Center(
                                    // NEW: soft circular backdrop so the outer
                                    // minaret shafts fade behind the ring
                                    // instead of visibly crossing its stroke.
                                    child: Container(
                                      width:  ringSz + 26,
                                      height: ringSz + 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black.withOpacity(0.16),
                                      ),
                                      child: Center(
                                        child: PrayerRingWidget(
                                          topLabel:        ringData.topLabel,
                                          bottomLabel:     ringData.bottomLabel,
                                          periodStart:     ringData.periodStart,
                                          periodEnd:       ringData.periodEnd,
                                          isProhibited:    ringData.isProhibited,
                                          accentColor:     accent,
                                          prohibitedColor: theme.danger,
                                          size:            ringSz,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              if (state is PrayerTimesLoading)
                                Positioned.fill(
                                  child: Center(child: CircularProgressIndicator(color: accent)),
                                ),

                            ],
                          ),
                        );
                      },
                    ),

                    BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
                      builder: (context, state) {
                        if (state is PrayerTimesError) {
                          return Padding(
                            padding: EdgeInsets.all(sw * 0.04),
                            child: Text(state.message,
                                style: TextStyle(color: theme.danger, fontSize: rsw * 0.04)),
                          );
                        }
                        if (state is PrayerTimesLoaded) {
                          return Padding(
                            padding: EdgeInsets.fromLTRB(sw * 0.04, 16, sw * 0.04, sw * 0.04),
                            child: PrayerTimesCard(
                              prayerTimes: state.prayerTimes,
                              use24h:      use24h,
                              l10n:        l10n,
                              theme:       theme,
                              onAlarmTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AlarmListPage(theme: theme, l10n: l10n)),
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 60),

                  ],
                ),
              ),
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

    final iconSz  = (sw * 0.058).clamp(22.0, 28.0);
    final labelSz = (sw * 0.024).clamp(9.0,  11.5);

    return Container(
      decoration: BoxDecoration(
        color:  surface,
        border: Border(top: BorderSide(color: accentSoft.withOpacity(0.22), width: 0.8)),
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
                    Navigator.push(context, MaterialPageRoute(builder: (_) => _pages[i]));
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.symmetric(horizontal: rsw * 0.032, vertical: rsw * 0.016),
                  decoration: BoxDecoration(
                    color: active ? accentSoft.withOpacity(0.22) : Colors.transparent,
                    borderRadius: BorderRadius.circular(rsw * 0.038),
                    border: active ? Border.all(color: accentSoft.withOpacity(0.40), width: 0.8) : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(asset, width: iconSz, height: iconSz),
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

  Widget _buildLocationText(String text, double maxWidth) {
    const style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
    );

    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    if (tp.width <= maxWidth) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return Marquee(
      text: text,
      style: style,
      velocity: 28.0,
      pauseAfterRound: const Duration(seconds: 2),
      blankSpace: 24.0,
      startPadding: 0,
      accelerationDuration: const Duration(milliseconds: 800),
      accelerationCurve: Curves.easeIn,
      decelerationDuration: const Duration(milliseconds: 800),
      decelerationCurve: Curves.easeOut,
    );
  }

}