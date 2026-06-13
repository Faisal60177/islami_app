import 'package:flutter/material.dart';
import 'package:muslim_app/home/model/prayer_times_models.dart';
import 'package:intl/intl.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';

class PrayerTimesCard extends StatelessWidget {
  final PrayerTimesModel prayerTimes;
  final bool use24h;
  final AppLocalizations l10n;

  const PrayerTimesCard({
    super.key,
    required this.prayerTimes,
    required this.l10n,
    this.use24h = true,
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
        // ── Salat times ──────────────────────────────────────────────────────
        _SectionCard(
          dotColor:    const Color(0xFF7B5EA7),
          title:       l10n.salatPrayers,
          titleColor:  const Color(0xFFB39DDB),
          bgColor:     const Color(0xFF151D2E),
          accentColor: const Color(0xFF7B5EA7),
          children: [
            _SalatRow(name: l10n.fajr,    icon: Icons.wb_twilight,       time: _range(prayerTimes.fajrStart,    prayerTimes.fajrEnd),    isActive: activeSalat == 'Fajr', l10n: l10n),
            _SalatRow(name: l10n.dhuhr,   icon: Icons.wb_sunny_outlined, time: _range(prayerTimes.dhuhrStart,   prayerTimes.dhuhrEnd),   isActive: activeSalat == 'Dhuhr', l10n: l10n),
            _SalatRow(name: l10n.asr,     icon: Icons.cloud_outlined,    time: _range(prayerTimes.asrStart,     prayerTimes.asrEnd),     isActive: activeSalat == 'Asr', l10n: l10n),
            _SalatRow(name: l10n.maghrib, icon: Icons.nights_stay,       time: _range(prayerTimes.maghribStart, prayerTimes.maghribEnd), isActive: activeSalat == 'Maghrib', l10n: l10n),
            _SalatRow(name: l10n.isha,    icon: Icons.dark_mode_outlined,time: _range(prayerTimes.ishaStart,    prayerTimes.ishaEnd),    isActive: activeSalat == 'Isha', isLast: true, l10n: l10n),
          ],
        ),

        const SizedBox(height: 12),

        // ── Prohibited times ─────────────────────────────────────────────────
        _SectionCard(
          dotColor:    const Color(0xFFB71C1C),
          title:       l10n.prohibitedTimes,
          titleColor:  const Color(0xFFEF9A9A),
          bgColor:     const Color(0xFF1E1212),
          accentColor: Colors.red,
          children: [
            _ProhibitedRow(name: l10n.sunrise, icon: Icons.wb_twilight,    time: _range(prayerTimes.sunRiseStart, prayerTimes.sunRiseEnd), isActive: activeProhibited == 'Sunrise', l10n: l10n),
            _ProhibitedRow(name: l10n.noon,    icon: Icons.wb_sunny,       time: _range(prayerTimes.noonStart,    prayerTimes.noonEnd),    isActive: activeProhibited == 'Noon', l10n: l10n),
            _ProhibitedRow(name: l10n.sunset,  icon: Icons.wb_cloudy,      time: _range(prayerTimes.sunSetStart,  prayerTimes.sunSetEnd),  isActive: activeProhibited == 'Sunset', isLast: true, l10n: l10n),
          ],
        ),

        const SizedBox(height: 12),

        // ── Sawm times ───────────────────────────────────────────────────────
        _SectionCard(
          dotColor:    const Color(0xFF1565C0),
          title:       l10n.sawmTimes,
          titleColor:  const Color(0xFF90CAF9),
          bgColor:     const Color(0xFF151D2E),
          accentColor: const Color(0xFF1565C0),
          children: [
            _SimpleRow(name: l10n.iftar,      icon: Icons.wb_sunny_outlined, time: _fmt(prayerTimes.iftarTime)),
            _SimpleRow(name: l10n.sahri, icon: Icons.bedtime_outlined,  time: _fmt(prayerTimes.sahriEnd), isLast: true),
          ],
        ),

        const SizedBox(height: 12),

        // ── Nafal prayers ────────────────────────────────────────────────────
        _SectionCard(
          dotColor:    const Color(0xFF6A1B9A),
          title:       l10n.nafalPrayers,
          titleColor:  const Color(0xFFCE93D8),
          bgColor:     const Color(0xFF151D2E),
          accentColor: const Color(0xFF6A1B9A),
          children: [
            _SimpleRow(name: l10n.tahajjud, icon: Icons.bedtime,              time: _range(prayerTimes.tahajjudStart, prayerTimes.tahajjudEnd)),
            _SimpleRow(name: l10n.ishraq,   icon: Icons.wb_twilight,          time: _range(prayerTimes.ishraqStart,   prayerTimes.ishraqEnd)),
            _SimpleRow(name: l10n.chasht,   icon: Icons.wb_sunny_outlined,    time: _range(prayerTimes.chashtStart,   prayerTimes.chashtEnd)),
            _SimpleRow(name: l10n.zawal,    icon: Icons.do_not_disturb_on,    time: _fmt(prayerTimes.zawalStart)),
            _SimpleRow(name: l10n.awabin,   icon: Icons.nights_stay_outlined, time: _range(prayerTimes.awabinStart,   prayerTimes.awabinEnd), isLast: true),
          ],
        ),
      ],
    );
  }
}

// ── Section wrapper card ──────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final Color  dotColor;
  final String title;
  final Color  titleColor;
  final Color  bgColor;
  final Color  accentColor;
  final List<Widget> children;

  const _SectionCard({
    required this.dotColor,
    required this.title,
    required this.titleColor,
    required this.bgColor,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        bgColor,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: const Color(0xFF1E2A40), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent top shimmer bar
          Container(
            height: 2,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              gradient: LinearGradient(colors: [
                accentColor.withOpacity(0.0),
                accentColor.withOpacity(0.6),
                accentColor.withOpacity(0.0),
              ]),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                      color:         titleColor,
                      fontSize:      14,
                      fontWeight:    FontWeight.w700,
                      letterSpacing: 0.3,
                    )),
              ],
            ),
          ),
          // Rows
          ...children,
        ],
      ),
    );
  }
}

// ── Salat row ─────────────────────────────────────────────────────────────────
class _SalatRow extends StatelessWidget {
  final String   name;
  final String   time;
  final IconData icon;      // ← add
  final bool     isActive;
  final bool     isLast;
  final AppLocalizations l10n;

  const _SalatRow({
    required this.name,
    required this.time,
    required this.icon,
    required this.l10n,
    this.isActive = false,
    this.isLast   = false,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFCE93D8);
    const activeBg    = Color(0xFF1A1535);

    return Column(
      children: [
        Container(
          color:   isActive ? activeBg : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(icon,                                      // ← add
                size:  16,
                color: isActive ? activeColor : const Color(0xFF8899AA),
              ),
              const SizedBox(width: 10),                     // ← add
              Expanded(
                child: Text(name,
                    style: TextStyle(
                      color:      isActive ? activeColor : Colors.white,
                      fontSize:   14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
              if (isActive) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color:        const Color(0xFF7B5EA7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child:  Text(l10n.active,
                      style: TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
              ],
              Text(time,
                  style: TextStyle(
                    color:      isActive ? activeColor : const Color(0xFF8899AA),
                    fontSize:   13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  )),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, thickness: 1, color: Color(0xFF1A2438), indent: 14, endIndent: 14),
      ],
    );
  }
}

// ── Prohibited row ────────────────────────────────────────────────────────────
class _ProhibitedRow extends StatelessWidget {
  final String   name;
  final String   time;
  final IconData icon;      // ← add
  final bool     isActive;
  final bool     isLast;
  final AppLocalizations l10n;

  const _ProhibitedRow({
    required this.name,
    required this.time,
    required this.icon,
    required this.l10n,
    this.isActive = false,
    this.isLast   = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFFEF5350)),   // ← add
              const SizedBox(width: 10),                               // ← add
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                      color:      Color(0xFFEF5350),
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                    )),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color:        const Color(0xFF7F1D1D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? l10n.now : l10n.prohibited,
                  style: const TextStyle(
                      color: Color(0xFFFFCDD2), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              Text(time,
                  style: const TextStyle(color: Color(0xFFE57373), fontSize: 13)),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, thickness: 1, color: Color(0xFF2C1A1A), indent: 14, endIndent: 14),
      ],
    );
  }
}

// ── Simple row (Sawm + Nafal) ─────────────────────────────────────────────────
class _SimpleRow extends StatelessWidget {
  final String   name;
  final String   time;
  final IconData icon;      // ← add
  final bool     isLast;

  const _SimpleRow({
    required this.name,
    required this.time,
    required this.icon,     // ← add
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF8899AA)),   // ← add
              const SizedBox(width: 10),                               // ← add
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              Text(time,
                  style: const TextStyle(color: Color(0xFF8899AA), fontSize: 13)),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, thickness: 1, color: Color(0xFF1A2438), indent: 14, endIndent: 14),
      ],
    );
  }
}