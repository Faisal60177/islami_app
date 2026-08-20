import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import '../cubit/alarm_cubit.dart';
import '../model/alarm_settings_model.dart';
import '../services/alarm_sound_preview.dart';

class AlarmDetailPage extends StatefulWidget {
  final AppThemeOption theme;
  final AppLocalizations l10n;
  final String prayerId;

  const AlarmDetailPage({
    super.key,
    required this.theme,
    required this.l10n,
    required this.prayerId,
  });

  @override
  State<AlarmDetailPage> createState() => _AlarmDetailPageState();
}

class _AlarmDetailPageState extends State<AlarmDetailPage> {
  late PrayerAlarmSetting _draft;
  final _preview = AlarmSoundPreview();

  static const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _draft = context.read<AlarmCubit>().settingFor(widget.prayerId);
  }

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  String get _prayerName {
    switch (widget.prayerId) {
      case 'fajr':     return widget.l10n.fajr;
      case 'dhuhr':    return widget.l10n.dhuhr;
      case 'asr':      return widget.l10n.asr;
      case 'maghrib':  return widget.l10n.maghrib;
      case 'isha':     return widget.l10n.isha;
      case 'chasht':   return widget.l10n.chasht;
      case 'tahajjud': return widget.l10n.tahajjud;
      default:         return widget.prayerId;
    }
  }

  String _offsetLabel(int minutes) {
    if (minutes == 0) return widget.l10n.translate('Exact Time');
    final sign = minutes > 0 ? '+' : '';
    return '$sign$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final l10n  = widget.l10n;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_prayerName,
            style: TextStyle(color: theme.textHigh, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            theme,
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: theme.accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(Icons.notifications_active_rounded, color: theme.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.translate('Prayer Alarm'),
                          style: TextStyle(
                              color: theme.textHigh, fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        _draft.enabled
                            ? l10n.translate('Alarm On')
                            : l10n.translate('Alarm Off'),
                        style: TextStyle(color: theme.textLow, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _draft.enabled,
                  activeColor: theme.accent,
                  onChanged: (v) => setState(() => _draft = _draft.copyWith(enabled: v)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Waqt-start passive notification toggle ─────────────────────────
          _card(
            theme,
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: theme.textLow.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info_outline_rounded, color: theme.textLow, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.translate('Prayer Notification'),
                          style: TextStyle(
                              color: theme.textHigh, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(l10n.translate('Waqt Start Notice'),
                          style: TextStyle(color: theme.textLow, fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  value: _draft.waqtStartNotificationEnabled,
                  activeColor: theme.accent,
                  onChanged: (v) =>
                      setState(() => _draft = _draft.copyWith(waqtStartNotificationEnabled: v)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _card(
            theme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.translate('Time Adjustment'),
                        style: TextStyle(
                            color: theme.textHigh, fontSize: 14, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.accent.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.notifications, color: theme.accent, size: 14),
                          const SizedBox(width: 4),
                          Text(_offsetLabel(_draft.offsetMinutes),
                              style: TextStyle(
                                  color: theme.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _draft.offsetMinutes.toDouble(),
                  min: -60, max: 60, divisions: 120,
                  activeColor: theme.accent,
                  inactiveColor: theme.textLow.withOpacity(0.25),
                  onChanged: (v) => setState(() => _draft = _draft.copyWith(offsetMinutes: v.round())),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('-60 min', style: TextStyle(color: theme.textLow, fontSize: 11)),
                    Text(_offsetLabel(_draft.offsetMinutes),
                        style: TextStyle(color: theme.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('+60 min', style: TextStyle(color: theme.textLow, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _card(
            theme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.translate('Repeat'),
                    style: TextStyle(color: theme.textHigh, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _repeatOption(
                        theme, RepeatMode.everyday, l10n.translate('Everyday'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _repeatOption(
                        theme, RepeatMode.customDays, l10n.translate('Custom days'),
                      ),
                    ),
                  ],
                ),
                if (_draft.repeatMode == RepeatMode.customDays) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      final selected = _draft.customWeekdays.contains(day);
                      return GestureDetector(
                        onTap: () {
                          final updated = Set<int>.from(_draft.customWeekdays);
                          if (selected) {
                            updated.remove(day);
                          } else {
                            updated.add(day);
                          }
                          setState(() => _draft = _draft.copyWith(customWeekdays: updated));
                        },
                        child: Container(
                          width: 42, height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? theme.accent : theme.textLow.withOpacity(0.10),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? theme.accent : theme.textLow.withOpacity(0.25),
                            ),
                          ),
                          child: Text(_weekdayLabels[i],
                              style: TextStyle(
                                color: selected ? Colors.white : theme.textLow,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          _card(
            theme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.translate('Alarm Sound'),
                    style: TextStyle(color: theme.textHigh, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                _soundOption(theme, AlarmSoundType.silent, l10n.translate('Silent/vibrate'), canPreview: true),
                const SizedBox(height: 8),
                _soundOption(theme, AlarmSoundType.beep, l10n.translate('Long Beep')),
                const SizedBox(height: 8),
                _soundOption(theme, AlarmSoundType.adhan, l10n.translate('Adhan Makka')),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _card(
            theme,
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: theme.accent.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.vibration_rounded, color: theme.accent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.translate('vibration'),
                          style: TextStyle(
                              color: theme.textHigh, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(l10n.translate('Vibrate with Alarm'),
                          style: TextStyle(color: theme.textLow, fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  value: _draft.vibrationEnabled,
                  activeColor: theme.accent,
                  onChanged: (v) => setState(() => _draft = _draft.copyWith(vibrationEnabled: v)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
              onPressed: () async {
                await context.read<AlarmCubit>().update(_draft);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.translate('Save')),
                    backgroundColor: theme.accent,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                  ),
                );
                Navigator.pop(context);
              },
              child: Text(l10n.translate('Save'),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 16),

        ],
      ),
    );
  }

  Widget _card(AppThemeOption theme, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.textLow.withOpacity(0.16)),
      ),
      child: child,
    );
  }

  Widget _repeatOption(AppThemeOption theme, RepeatMode mode, String label) {
    final selected = _draft.repeatMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _draft = _draft.copyWith(repeatMode: mode)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? theme.accent.withOpacity(0.14) : theme.textLow.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? theme.accent.withOpacity(0.5) : theme.textLow.withOpacity(0.15),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? theme.accent : theme.textHigh,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            )),
      ),
    );
  }

  Widget _soundOption(AppThemeOption theme, AlarmSoundType type, String label, {bool canPreview = true}) {
    final isSelected = _draft.soundType == type;
    return GestureDetector(
      onTap: () => setState(() => _draft = _draft.copyWith(soundType: type)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.accent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? theme.accent.withOpacity(0.5) : theme.textLow.withOpacity(0.15),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? theme.accent : theme.textLow,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    color: isSelected ? theme.accent : theme.textHigh,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  )),
            ),
            if (canPreview)
              GestureDetector(
                onTap: () => _preview.play(type),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: theme.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}