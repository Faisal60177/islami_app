import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import '../cubit/alarm_cubit.dart';
import 'package:muslim_app/alarm/cubit/alarm_state.dart';
import '../model/alarm_settings_model.dart';
import 'alarm_detail_page.dart';

class AlarmListPage extends StatelessWidget {
  final AppThemeOption theme;
  final AppLocalizations l10n;
  const AlarmListPage({super.key, required this.theme, required this.l10n});

  String _nameFor(String id) {
    switch (id) {
      case 'fajr':     return l10n.fajr;
      case 'dhuhr':    return l10n.dhuhr;
      case 'asr':      return l10n.asr;
      case 'maghrib':  return l10n.maghrib;
      case 'isha':     return l10n.isha;
      case 'chasht':   return l10n.chasht;
      case 'tahajjud': return l10n.tahajjud;
      default:         return id;
    }
  }

  IconData _iconFor(String id) {
    switch (id) {
      case 'fajr':     return Icons.wb_twilight_outlined;
      case 'dhuhr':    return Icons.wb_sunny_outlined;
      case 'asr':      return Icons.cloud_outlined;
      case 'maghrib':  return Icons.nightlight_outlined;
      case 'isha':     return Icons.dark_mode_outlined;
      case 'chasht':   return Icons.wb_sunny_outlined;
      case 'tahajjud': return Icons.bedtime_outlined;
      default:         return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.translate('set_alarm'),
            style: TextStyle(color: theme.textHigh, fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<AlarmCubit, AlarmState>(
        builder: (context, state) {
          if (state.isLoading) {
            return Center(child: CircularProgressIndicator(color: theme.accent));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionLabel(l10n.translate('farz_prayers')),
              _card(context, farzPrayerIds),
              const SizedBox(height: 20),
              _sectionLabel(l10n.translate('nafal_prayers')),
              _card(context, nafalPrayerIds),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(text,
        style: TextStyle(
            color: theme.textLow,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3)),
  );

  Widget _card(BuildContext context, List<String> ids) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.textLow.withOpacity(0.16)),
      ),
      child: Column(
        children: ids.asMap().entries.map((e) {
          final id = e.value;
          final isLast = e.key == ids.length - 1;
          final setting = context.watch<AlarmCubit>().settingFor(id);
          return Column(
            children: [
              ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlarmDetailPage(
                      theme: theme,
                      l10n: l10n,
                      prayerId: id,
                    ),
                  ),
                ),
                leading: Icon(_iconFor(id), color: theme.textLow, size: 20),
                title: Text(_nameFor(id),
                    style: TextStyle(
                        color: theme.textHigh, fontSize: 14, fontWeight: FontWeight.w500)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      setting.enabled
                          ? l10n.translate('alarm_on')
                          : l10n.translate('alarm_off'),
                      style: TextStyle(
                        color: setting.enabled ? theme.accent : theme.textLow,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      setting.enabled
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                      color: setting.enabled ? theme.accent : theme.textLow,
                      size: 18,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: theme.textLow.withOpacity(0.14), indent: 14, endIndent: 14),
            ],
          );
        }).toList(),
      ),
    );
  }
}