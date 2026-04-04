import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/settings_cubit.dart';
import '../../cubit/settings_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_themes.dart';

class NotificationSettingsSection extends StatelessWidget {
  final AppThemeOption theme;
  final AppLocalizations l10n;
  const NotificationSettingsSection(
      {super.key, required this.theme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final cubit = context.read<SettingsCubit>();
        final thm   = getThemeById(state.themeMode);

        final items = [
          _NotifItem(
            icon:     Icons.notifications_active_rounded,
            iconColor:const Color(0xFF4CAF82),
            title:    'Prayer Notifications',
            subtitle: 'Get alerts for each prayer time',
            value:    state.notificationsEnabled,
            onChanged:(v) => cubit.toggleNotifications(v),
          ),
          _NotifItem(
            icon:     Icons.music_note_rounded,
            iconColor:const Color(0xFF5B8DEF),
            title:    'Adhan Sound',
            subtitle: 'Play Adhan when prayer begins',
            value:    state.adhanEnabled,
            onChanged:(v) => cubit.toggleAdhan(v),
            disabled: !state.notificationsEnabled,
          ),
          _NotifItem(
            icon:     Icons.vibration_rounded,
            iconColor:const Color(0xFFFFB74D),
            title:    'Vibration',
            subtitle: 'Vibrate on prayer notification',
            value:    state.vibrationEnabled,
            onChanged:(v) => cubit.toggleVibration(v),
            disabled: !state.notificationsEnabled,
          ),
        ];

        return Container(
          decoration: BoxDecoration(
            color: thm.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: thm.accent.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(thm.isDark ? 0.3 : 0.06),
                blurRadius: 12, offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final i      = e.key;
              final item   = e.value;
              final isLast = i == items.length - 1;
              return Column(
                children: [
                  _buildTile(thm, item),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: thm.accent.withOpacity(0.10),
                      indent: 58,
                    ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTile(AppThemeOption thm, _NotifItem item) {
    return AnimatedOpacity(
      opacity: item.disabled ? 0.45 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: item.iconColor.withOpacity(
                    item.disabled ? 0.06 : 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon,
                  color: item.iconColor
                      .withOpacity(item.disabled ? 0.5 : 1),
                  size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: thm.textHigh,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(item.subtitle,
                      style: TextStyle(color: thm.textLow, fontSize: 12)),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: item.value && !item.disabled,
                onChanged: item.disabled ? null : item.onChanged,
                activeColor: item.iconColor,
                activeTrackColor: item.iconColor.withOpacity(0.3),
                inactiveThumbColor: thm.textLow,
                inactiveTrackColor: thm.textLow.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool disabled;

  const _NotifItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.disabled = false,
  });
}