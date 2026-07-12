import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muslim_app/home/model/prayer_times_models.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';

class PrayerTimesCard extends StatelessWidget {
  final PrayerTimesModel prayerTimes;
  final bool use24h;
  final AppLocalizations l10n;
  final AppThemeOption theme;
  final VoidCallback? onAlarmTap;

  const PrayerTimesCard({
    super.key,
    required this.prayerTimes,
    required this.l10n,
    required this.theme,
    this.use24h = true,
    this.onAlarmTap,
  });

  String _fmt(DateTime dt) {
    if (use24h) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return DateFormat('h:mm a').format(dt);
  }

  String _range(DateTime s, DateTime e) => '${_fmt(s)} – ${_fmt(e)}';

  String? _activeSalat() {
    final now = DateTime.now().toUtc();
    bool inRange(DateTime s, DateTime e) =>
        now.isAfter(s.toUtc()) && now.isBefore(e.toUtc());
    if (inRange(prayerTimes.fajrStart,    prayerTimes.fajrEnd))    return 'Fajr';
    if (inRange(prayerTimes.dhuhrStart,   prayerTimes.dhuhrEnd))   return 'Dhuhr';
    if (inRange(prayerTimes.asrStart,     prayerTimes.asrEnd))     return 'Asr';
    if (inRange(prayerTimes.maghribStart, prayerTimes.maghribEnd)) return 'Maghrib';
    final now_ = DateTime.now();
    if (now_.isAfter(prayerTimes.ishaStart) || now_.isBefore(prayerTimes.fajrStart)) {
      return 'Isha';
    }
    return null;
  }

  String? _activeProhibited() {
    final now = DateTime.now().toUtc();
    bool inRange(DateTime s, DateTime e) =>
        now.isAfter(s.toUtc()) && now.isBefore(e.toUtc());
    if (inRange(prayerTimes.sunRiseStart, prayerTimes.sunRiseEnd)) return 'Sunrise';
    if (inRange(prayerTimes.noonStart,    prayerTimes.noonEnd))    return 'Noon';
    if (inRange(prayerTimes.sunSetStart,  prayerTimes.sunSetEnd))  return 'Sunset';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final activeSalat      = _activeSalat();
    final activeProhibited = _activeProhibited();

    return Column(
      children: [
        // ── Salat times — one unified list ──────────────────────────────────
        _ListCard(
          theme: theme,
          title: l10n.salatPrayers,
          trailing: onAlarmTap == null
              ? null
              : GestureDetector(
            onTap: onAlarmTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.accent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_active_outlined,
                      color: theme.accent, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Alarm',
                    style: TextStyle(
                      color: theme.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          children: [
            _Row(theme: theme, name: l10n.fajr,    icon: Icons.wb_twilight_outlined,
                time: _range(prayerTimes.fajrStart, prayerTimes.fajrEnd),
                isActive: activeSalat == 'Fajr', activeLabel: l10n.active),
            _Row(theme: theme, name: l10n.dhuhr,   icon: Icons.wb_sunny_outlined,
                time: _range(prayerTimes.dhuhrStart, prayerTimes.dhuhrEnd),
                isActive: activeSalat == 'Dhuhr', activeLabel: l10n.active),
            _Row(theme: theme, name: l10n.asr,     icon: Icons.cloud_outlined,
                time: _range(prayerTimes.asrStart, prayerTimes.asrEnd),
                isActive: activeSalat == 'Asr', activeLabel: l10n.active),
            _Row(theme: theme, name: l10n.maghrib, icon: Icons.nightlight_outlined,
                time: _range(prayerTimes.maghribStart, prayerTimes.maghribEnd),
                isActive: activeSalat == 'Maghrib', activeLabel: l10n.active),
            _Row(theme: theme, name: l10n.isha,    icon: Icons.dark_mode_outlined,
                time: _range(prayerTimes.ishaStart, prayerTimes.ishaEnd),
                isActive: activeSalat == 'Isha', activeLabel: l10n.active, isLast: true),
          ],
        ),

        const SizedBox(height: 12),

        // ── Prohibited times — compact 3-segment strip ──────────────────────
        _SegmentStrip(
          theme: theme,
          caption: l10n.prohibitedTimes,
          segments: [
            _Segment(label: l10n.sunrise, time: _range(prayerTimes.sunRiseStart, prayerTimes.sunRiseEnd), isActive: activeProhibited == 'Sunrise'),
            _Segment(label: l10n.noon,    time: _range(prayerTimes.noonStart, prayerTimes.noonEnd),       isActive: activeProhibited == 'Noon'),
            _Segment(label: l10n.sunset,  time: _range(prayerTimes.sunSetStart, prayerTimes.sunSetEnd),   isActive: activeProhibited == 'Sunset'),
          ],
        ),

        const SizedBox(height: 12),

        // ── Sawm times — compact 2-segment strip ─────────────────────────────
        _SegmentStrip(
          theme: theme,
          caption: l10n.sawmTimes,
          segments: [
            _Segment(label: l10n.iftar, time: _fmt(prayerTimes.iftarTime)),
            _Segment(label: l10n.sahri, time: _fmt(prayerTimes.sahriEnd)),
          ],
        ),
        const SizedBox(height: 12),

        // ── Nafal prayers — secondary list, lighter weight ───────────────────
        _ListCard(
          theme: theme,
          title: l10n.nafalPrayers,
          secondary: true,
          children: [
            _Row(theme: theme, name: l10n.tahajjud, icon: Icons.bedtime_outlined,
                time: _range(prayerTimes.tahajjudStart, prayerTimes.tahajjudEnd), secondary: true),
            _Row(theme: theme, name: l10n.ishraq,   icon: Icons.wb_twilight_outlined,
                time: _range(prayerTimes.ishraqStart, prayerTimes.ishraqEnd), secondary: true),
            _Row(theme: theme, name: l10n.chasht,   icon: Icons.wb_sunny_outlined,
                time: _range(prayerTimes.chashtStart, prayerTimes.chashtEnd), secondary: true),
            _Row(theme: theme, name: l10n.zawal,    icon: Icons.remove_circle_outline,
                time: _fmt(prayerTimes.zawalStart), secondary: true),
            _Row(theme: theme, name: l10n.awabin,   icon: Icons.nightlight_outlined,
                time: _range(prayerTimes.awabinStart, prayerTimes.awabinEnd), secondary: true, isLast: true),
          ],
        ),
      ],
    );
  }
}

// ── Unified list card ──────────────────────────────────────────────────────
class _ListCard extends StatelessWidget {
  final AppThemeOption theme;
  final String title;
  final List<Widget> children;
  final bool secondary;
  final Widget? trailing;

  const _ListCard({
    required this.theme,
    required this.title,
    required this.children,
    this.secondary = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: theme.textLow.withOpacity(0.16), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: secondary ? theme.textLow : theme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                        color:         secondary ? theme.textLow : theme.textHigh,
                        fontSize:      13,
                        fontWeight:    FontWeight.w600,
                        letterSpacing: 0.2,
                      )),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

// ── Row (Salat + Nafal) ─────────────────────────────────────────────────────
class _Row extends StatelessWidget {
  final AppThemeOption theme;
  final String   name;
  final String   time;
  final IconData icon;
  final bool     isActive;
  final bool     isLast;
  final bool     secondary;
  final String?  activeLabel;

  const _Row({
    required this.theme,
    required this.name,
    required this.time,
    required this.icon,
    this.isActive   = false,
    this.isLast     = false,
    this.secondary  = false,
    this.activeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final rowColor  = isActive ? theme.accent : (secondary ? theme.textLow : theme.textHigh);
    final iconColor = isActive ? theme.accent : theme.textLow;

    return Column(
      children: [
        Container(
          color: isActive ? theme.accent.withOpacity(0.10) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name,
                    style: TextStyle(
                      color:      rowColor,
                      fontSize:   secondary ? 13 : 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
              if (isActive && activeLabel != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color:        theme.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(activeLabel!,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
              ],
              Text(time,
                  style: TextStyle(
                    color:      isActive ? theme.accent : theme.textLow,
                    fontSize:   13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  )),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 1, color: theme.textLow.withOpacity(0.14), indent: 14, endIndent: 14),
      ],
    );
  }
}

// ── Segment strip (Prohibited + Sawm) ───────────────────────────────────────
class _Segment {
  final String label;
  final String time;
  final bool   isActive;
  _Segment({required this.label, required this.time, this.isActive = false});
}

class _SegmentStrip extends StatelessWidget {
  final AppThemeOption theme;
  final String caption;
  final List<_Segment> segments;

  const _SegmentStrip({
    required this.theme,
    required this.caption,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color:        theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: theme.textLow.withOpacity(0.16), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(caption,
              style: TextStyle(
                color:      theme.textLow,
                fontSize:   12,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              children: [
                for (int i = 0; i < segments.length; i++) ...[
                  if (i != 0)
                    VerticalDivider(
                      color: theme.textLow.withOpacity(0.35),
                      width: 20,
                      thickness: 1.2,
                      indent: 2,
                      endIndent: 2,
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(segments[i].label,
                            style: TextStyle(
                              color:      segments[i].isActive ? theme.danger : theme.textLow,
                              fontSize:   12,
                              fontWeight: FontWeight.w500,
                            )),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              segments[i].time.isEmpty ? '--:--' : segments[i].time,
                              maxLines: 1,
                              style: TextStyle(
                                color:      segments[i].isActive ? theme.danger : theme.textHigh,
                                fontSize:   14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}