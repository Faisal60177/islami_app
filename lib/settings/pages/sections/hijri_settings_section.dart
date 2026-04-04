import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../cubit/settings_cubit.dart';
import '../../cubit/settings_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_themes.dart';
import 'package:islamic_app/home/home_page.dart';

class HijriSettingsSection extends StatelessWidget {
  final AppThemeOption theme;
  final AppLocalizations l10n;
  const HijriSettingsSection({super.key, required this.theme, required this.l10n});

  String _hijriDateWithOffset(int offset) {
    final now  = DateTime.now().add(Duration(days: offset));
    final hijri = HijriCalendar.fromDate(now);
    return "${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH";
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final cubit  = context.read<SettingsCubit>();
        final offset = state.hijriOffset;
        final thm    = getThemeById(state.themeMode);

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
              // Preview banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFD4AF37).withOpacity(0.12),
                      const Color(0xFFD4AF37).withOpacity(0.04),
                    ],
                  ),
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
                  border: Border(
                    bottom: BorderSide(
                        color: const Color(0xFFD4AF37).withOpacity(0.20)),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('🌙', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hijri Date Adjustment',
                              style: TextStyle(
                                color: thm.textHigh,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Fine-tune moon sighting discrepancy',
                              style: TextStyle(
                                  color: thm.textLow, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Live date preview
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: child,
                              )),
                      child: Container(
                        key: ValueKey(offset),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFD4AF37).withOpacity(0.30)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📅', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              _hijriDateWithOffset(offset),
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Offset selector
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day Offset',
                      style: TextStyle(
                          color: thm.textLow,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [-2, -1, 0, 1, 2].map((val) {
                        final isSelected = offset == val;
                        return GestureDetector(
                          onTap: () => cubit.setHijriOffset(val),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFD4AF37)
                                  : thm.cardColor.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFD4AF37)
                                    : thm.textLow.withOpacity(0.2),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37)
                                      .withOpacity(0.30),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ]
                                  : [],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  val == 0
                                      ? '0'
                                      : (val > 0 ? '+$val' : '$val'),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.black
                                        : thm.textHigh,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  val == 0 ? 'Default' : (val > 0 ? 'days' : 'days'),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.black87
                                        : thm.textLow,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        offset == 0
                            ? 'Using calculated Hijri date'
                            : offset > 0
                            ? 'Shifted $offset day(s) forward'
                            : 'Shifted ${-offset} day(s) backward',
                        style: TextStyle(
                          color: const Color(0xFFD4AF37).withOpacity(0.7),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
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
}