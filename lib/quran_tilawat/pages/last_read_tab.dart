import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import '../cubit/quran_cubit.dart';
import '../cubit/quran_state.dart';
import '../models/surah_model.dart';
import 'quran_reader_page.dart';

class LastReadTab extends StatelessWidget {
  const LastReadTab({super.key});

  @override
  Widget build(BuildContext context) {
    final sw  = MediaQuery.of(context).size.width;
    final rsw = sw.clamp(320.0, 420.0);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (_, settings) {
        final theme = getThemeById(settings.themeMode);
        return BlocBuilder<QuranCubit, QuranState>(
          builder: (_, state) {
            if (state is! QuranLoaded) {
              return Center(
                  child: CircularProgressIndicator(color: theme.accent));
            }

            final page   = state.lastReadPage;
            final surahs = state.surahs;

            // Find current surah for this page
            SurahModel currentSurah = surahs.first;
            for (final s in surahs.reversed) {
              if (s.page <= page) { currentSurah = s; break; }
            }

            // Progress calculation (pages 3–612 = 610 quran_tilawat pages)
            final isQuranRange = page >= 3 && page <= 612;
            final quranPage    = isQuranRange ? page - 2 : (page < 3 ? 0 : 610);
            final progress     = (quranPage / 610).clamp(0.0, 1.0);

            return SingleChildScrollView(
              padding: EdgeInsets.all(rsw * 0.045),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: rsw * 0.020),

                  // ── Hero resume card ────────────────────────────
                  _ResumeCard(
                    theme: theme,
                    rsw: rsw,
                    page: page,
                    quranPage: quranPage,
                    progress: progress,
                    currentSurah: currentSurah,
                    isQuranRange: isQuranRange,
                    surahs: surahs,
                  ),

                  SizedBox(height: rsw * 0.030),

                  // ── Quick jump buttons row ───────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _QuickBtn(
                          icon: Icons.first_page_rounded,
                          label: 'Beginning',
                          sub: 'Page 1',
                          theme: theme,
                          rsw: rsw,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<QuranCubit>(),
                                child: QuranReaderPage(
                                  initialPage: 3,
                                  surah: surahs.first,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: rsw * 0.025),
                      Expanded(
                        child: _QuickBtn(
                          icon: Icons.last_page_rounded,
                          label: 'Last Page',
                          sub: 'Page 610',
                          theme: theme,
                          rsw: rsw,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<QuranCubit>(),
                                child: QuranReaderPage(
                                  initialPage: 612,
                                  surah: surahs.last,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: rsw * 0.030),

                  // ── Stats row ────────────────────────────────────
                  Row(
                    children: [
                      _StatCard(
                        label: 'quran_tilawat page',
                        value: '$quranPage',
                        sub: 'of 610',
                        color: theme.accent,
                        theme: theme,
                        rsw: rsw,
                      ),
                      SizedBox(width: rsw * 0.020),
                      _StatCard(
                        label: 'Completed',
                        value:
                        '${(progress * 100).toStringAsFixed(1)}%',
                        sub: 'of quran_tilawat',
                        color: const Color(0xFF64B5F6),
                        theme: theme,
                        rsw: rsw,
                      ),
                      SizedBox(width: rsw * 0.020),
                      _StatCard(
                        label: 'Para',
                        value: '${currentSurah.para}',
                        sub: 'of 30',
                        color: const Color(0xFFFFB74D),
                        theme: theme,
                        rsw: rsw,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Resume hero card ──────────────────────────────────────────────────────────
class _ResumeCard extends StatelessWidget {
  final AppThemeOption theme;
  final double rsw;
  final int page;
  final int quranPage;
  final double progress;
  final SurahModel currentSurah;
  final bool isQuranRange;
  final List<SurahModel> surahs;

  const _ResumeCard({
    required this.theme,
    required this.rsw,
    required this.page,
    required this.quranPage,
    required this.progress,
    required this.currentSurah,
    required this.isQuranRange,
    required this.surahs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(rsw * 0.048),
        border: Border.all(color: theme.accent.withOpacity(0.22), width: 1),
      ),
      child: Column(
        children: [
          // Top section: icon + surah info
          Padding(
            padding: EdgeInsets.all(rsw * 0.050),
            child: Column(
              children: [
                Container(
                  width: rsw * 0.18,
                  height: rsw * 0.18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.accent.withOpacity(0.10),
                    border: Border.all(
                        color: theme.accent.withOpacity(0.25), width: 1),
                  ),
                  child: Icon(Icons.history_edu_rounded,
                      color: theme.accent, size: rsw * 0.095),
                ),
                SizedBox(height: rsw * 0.025),
                Text(
                  'Continue Reading',
                  style: TextStyle(
                      color: theme.textLow, fontSize: rsw * 0.028),
                ),
                SizedBox(height: rsw * 0.008),
                Text(
                  isQuranRange ? currentSurah.nameTranslit : 'Al-quran_tilawat',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: rsw * 0.046,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (isQuranRange)
                  Text(
                    currentSurah.nameAr,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      color: theme.accent,
                      fontSize: rsw * 0.055,
                    ),
                  ),
                SizedBox(height: rsw * 0.025),

                // Progress bar
                Row(
                  children: [
                    Text(
                      'quran_tilawat page $quranPage of 610',
                      style: TextStyle(
                          color: theme.textLow, fontSize: rsw * 0.024),
                    ),
                    const Spacer(),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: theme.accent,
                        fontSize: rsw * 0.024,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: rsw * 0.012),
                ClipRRect(
                  borderRadius: BorderRadius.circular(rsw * 0.008),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: rsw * 0.014,
                    backgroundColor: theme.accent.withOpacity(0.12),
                    valueColor:
                    AlwaysStoppedAnimation<Color>(theme.accent),
                  ),
                ),
              ],
            ),
          ),

          // Resume button (full width, bottom of card)
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<QuranCubit>(),
                  child: QuranReaderPage(
                      initialPage: page, surah: currentSurah),
                ),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: rsw * 0.038),
              decoration: BoxDecoration(
                color: theme.accent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(rsw * 0.048),
                  bottomRight: Radius.circular(rsw * 0.048),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: rsw * 0.052),
                  SizedBox(width: rsw * 0.016),
                  Text(
                    'Resume — Page $quranPage',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: rsw * 0.034,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick jump button ─────────────────────────────────────────────────────────
class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final AppThemeOption theme;
  final double rsw;
  final VoidCallback onTap;

  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.sub,
    required this.theme,
    required this.rsw,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: rsw * 0.030, horizontal: rsw * 0.020),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(rsw * 0.032),
          border: Border.all(
              color: theme.accent.withOpacity(0.18), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.textLow, size: rsw * 0.042),
            SizedBox(width: rsw * 0.014),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: rsw * 0.028,
                        fontWeight: FontWeight.w600)),
                Text(sub,
                    style: TextStyle(
                        color: theme.textLow, fontSize: rsw * 0.022)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final AppThemeOption theme;
  final double rsw;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.theme,
    required this.rsw,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: rsw * 0.025, horizontal: rsw * 0.015),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(rsw * 0.028),
          border: Border.all(color: color.withOpacity(0.22), width: 0.8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: rsw * 0.036,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(sub,
                style: TextStyle(
                    color: theme.textLow, fontSize: rsw * 0.020)),
            SizedBox(height: rsw * 0.004),
            Text(label,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: rsw * 0.022,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}