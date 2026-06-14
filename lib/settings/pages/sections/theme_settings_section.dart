import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/settings_cubit.dart';
import '../../cubit/settings_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_themes.dart';

class ThemeSettingsSection extends StatelessWidget {
  final AppThemeOption theme;
  final AppLocalizations l10n;
  const ThemeSettingsSection({super.key, required this.theme, required this.l10n});

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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: thm.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('🎨', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Color Theme',
                          style: TextStyle(
                            color: thm.textHigh,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Choose your preferred look',
                          style: TextStyle(color: thm.textLow, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Theme grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: appThemes.length,
                  itemBuilder: (context, index) {
                    final t         = appThemes[index];
                    final isSelected = state.themeMode == t.id;

                    return GestureDetector(
                      onTap: () => cubit.setTheme(t.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: t.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? t.accent
                                : thm.textLow.withOpacity(0.2),
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: t.accent.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                              : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Theme preview
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Simulated header bar
                                  Container(
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: t.surface,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 6, height: 6,
                                          decoration: BoxDecoration(
                                            color: t.accent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          width: 28, height: 4,
                                          decoration: BoxDecoration(
                                            color: t.textLow.withOpacity(0.5),
                                            borderRadius:
                                            BorderRadius.circular(2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Simulated card
                                  Container(
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: t.surface.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color:
                                          t.accent.withOpacity(0.30)),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 14, height: 14,
                                          decoration: BoxDecoration(
                                            color: t.accent.withOpacity(0.20),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 28, height: 3,
                                              color: t.textHigh
                                                  .withOpacity(0.7),
                                            ),
                                            const SizedBox(height: 3),
                                            Container(
                                              width: 20, height: 3,
                                              color: t.textLow
                                                  .withOpacity(0.5),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Accent strip
                                  Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: t.accent.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Name + emoji
                                  Row(
                                    children: [
                                      Text(t.emoji,
                                          style: const TextStyle(
                                              fontSize: 12)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          t.name,
                                          style: TextStyle(
                                            color: t.textHigh,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Selected checkmark overlay
                            if (isSelected)
                              Positioned(
                                top: 6, right: 6,
                                child: Container(
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(
                                    color: t.accent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color:
                                          t.accent.withOpacity(0.4),
                                          blurRadius: 6)
                                    ],
                                  ),
                                  child: const Icon(Icons.check,
                                      color: Colors.white, size: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}