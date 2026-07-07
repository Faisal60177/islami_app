import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/settings_cubit.dart';
import '../../cubit/settings_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_themes.dart';

class DisplaySettingsSection extends StatelessWidget {
  final AppThemeOption theme;
  final AppLocalizations l10n;
  const DisplaySettingsSection(
      {super.key, required this.theme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final cubit = context.read<SettingsCubit>();
        final thm   = getThemeById(state.themeMode);

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
            children: [
              // Time format
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCE93D8).withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.access_time_rounded,
                          color: Color(0xFFCE93D8), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time Format',
                            style: TextStyle(
                              color: thm.textHigh,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            state.use24Hour ? '24-hour (14:30)' : '12-hour (2:30 PM)',
                            style: TextStyle(
                                color: thm.textLow, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Toggle row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _formatPill(
                          label: '12h',
                          isSelected: !state.use24Hour,
                          color: const Color(0xFFCE93D8),
                          thm: thm,
                          onTap: () => cubit.toggle24Hour(false),
                        ),
                        const SizedBox(width: 6),
                        _formatPill(
                          label: '24h',
                          isSelected: state.use24Hour,
                          color: const Color(0xFFCE93D8),
                          thm: thm,
                          onTap: () => cubit.toggle24Hour(true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Divider(height: 1,
                  color: thm.accent.withOpacity(0.10), indent: 58),

              // Dark header
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF26C6DA).withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.dark_mode_rounded,
                          color: Color(0xFF26C6DA), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dark Header',
                            style: TextStyle(
                              color: thm.textHigh,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Deep dark tone in navigation bar',
                            style: TextStyle(
                                color: thm.textLow, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: state.darkHeader,
                        onChanged: (v) => cubit.toggleDarkHeader(v),
                        activeColor: const Color(0xFF26C6DA),
                        activeTrackColor:
                        const Color(0xFF26C6DA).withOpacity(0.3),
                        inactiveThumbColor: thm.textLow,
                        inactiveTrackColor: thm.textLow.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _formatPill({
    required String label,
    required bool isSelected,
    required Color color,
    required AppThemeOption thm,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.6) : thm.textLow.withOpacity(0.25),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : thm.textLow,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Display Settings Page ─────────────────────────────────────────────────────
class DisplaySettingsPage extends StatelessWidget {
  final AppThemeOption theme;
  final AppLocalizations l10n;
  const DisplaySettingsPage(
      {super.key, required this.theme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final thm = getThemeById(state.themeMode);
        return Scaffold(
          backgroundColor: thm.background,
          appBar: AppBar(
            backgroundColor: thm.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: thm.accent),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Display',
                style: TextStyle(
                    color: thm.textHigh, fontWeight: FontWeight.w700)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DisplaySettingsSection(theme: thm, l10n: l10n),
          ),
        );
      },
    );
  }
}