import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/Duas/cubit/duas_cubit.dart';
import '../../cubit/settings_cubit.dart';
import '../../cubit/settings_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_themes.dart';

class LanguageSettingsSection extends StatefulWidget {
  final AppThemeOption theme;
  final AppLocalizations l10n;
  const LanguageSettingsSection({super.key, required this.theme, required this.l10n});

  @override
  State<LanguageSettingsSection> createState() => _LanguageSettingsSectionState();
}

class _LanguageSettingsSectionState extends State<LanguageSettingsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final cubit  = context.read<SettingsCubit>();
        final thm    = getThemeById(state.themeMode);
        final current = supportedLanguages.firstWhere(
              (l) => l.code == state.languageCode,
          orElse: () => supportedLanguages.first,
        );

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
              // Current language tile (tappable to expand)
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B8DEF).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Center(
                          child: Text(current.flag,
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'App Language',
                              style: TextStyle(
                                color: thm.textHigh,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  current.name,
                                  style: TextStyle(
                                      color: const Color(0xFF5B8DEF),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '•  ${current.nativeName}',
                                  style: TextStyle(
                                      color: thm.textLow, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(Icons.keyboard_arrow_down_rounded,
                            color: thm.textLow, size: 22),
                      ),
                    ],
                  ),
                ),
              ),

              // Animated language list
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Column(
                  children: [
                    Divider(height: 1,
                        color: thm.accent.withOpacity(0.12)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 4, bottom: 8),
                            child: Text(
                              'SELECT LANGUAGE',
                              style: TextStyle(
                                color: thm.textLow,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          ...supportedLanguages.map((lang) {
                            final isSelected =
                                lang.code == state.languageCode;
                            return GestureDetector(
                              onTap: () {
                                cubit.setLanguage(lang.code);
                                context.read<DuasCubit>().updateLanguage(lang.code); // ← DuasCubit
                                setState(() => _isExpanded = false);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(
                                    milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF5B8DEF)
                                      .withOpacity(0.15)
                                      : thm.cardColor.withOpacity(0.5),
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF5B8DEF)
                                        .withOpacity(0.50)
                                        : thm.textLow.withOpacity(0.12),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(lang.flag,
                                        style: const TextStyle(
                                            fontSize: 20)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lang.name,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? const Color(
                                                  0xFF5B8DEF)
                                                  : thm.textHigh,
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            lang.nativeName,
                                            style: TextStyle(
                                              color: thm.textLow,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (lang.isRtl)
                                      Container(
                                        padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFB74D)
                                              .withOpacity(0.15),
                                          borderRadius:
                                          BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'RTL',
                                          style: TextStyle(
                                            color: Color(0xFFFFB74D),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    if (isSelected)
                                      Container(
                                        width: 20, height: 20,
                                        decoration: BoxDecoration(
                                          color:
                                          const Color(0xFF5B8DEF),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check,
                                            color: Colors.white,
                                            size: 13),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}