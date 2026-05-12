import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import '../cubit/quran_cubit.dart';
import '../cubit/quran_state.dart';
import '../models/surah_model.dart';
import 'quran_reader_page.dart';

class SurahListTab extends StatelessWidget {
  const SurahListTab({super.key});

  @override
  Widget build(BuildContext context) {
    final sw  = MediaQuery.of(context).size.width;
    final rsw = sw.clamp(320.0, 420.0);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (_, settings) {
        final theme = getThemeById(settings.themeMode);
        return BlocBuilder<QuranCubit, QuranState>(
          builder: (_, state) {
            if (state is QuranLoading || state is QuranInitial) {
              return Center(
                  child: CircularProgressIndicator(color: theme.accent));
            }
            if (state is QuranError) {
              return Center(
                  child: Text(state.message,
                      style: TextStyle(color: Colors.red[300])));
            }
            final surahs = (state as QuranLoaded).surahs;

            return ListView.builder(
              padding: EdgeInsets.symmetric(
                  horizontal: rsw * 0.030, vertical: rsw * 0.018),
              physics: const BouncingScrollPhysics(),
              itemCount: surahs.length,
              itemBuilder: (_, i) =>
                  _SurahTile(surah: surahs[i], theme: theme, rsw: rsw),
            );
          },
        );
      },
    );
  }
}

class _SurahTile extends StatelessWidget {
  final SurahModel surah;
  final AppThemeOption theme;
  final double rsw;

  const _SurahTile(
      {required this.surah, required this.theme, required this.rsw});

  // Cycle through accent colours based on surah number
  static const _accentColors = [
    Color(0xFF4CAF82), Color(0xFF64B5F6), Color(0xFFFFB74D),
    Color(0xFFEF9A9A), Color(0xFFB39DDB), Color(0xFF80DEEA),
  ];

  Color get _rowAccent => _accentColors[surah.number % _accentColors.length];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<QuranCubit>(),
            child: QuranReaderPage(
                initialPage: surah.page + 2, surah: surah),
          ),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: rsw * 0.018),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(rsw * 0.032),
          border: Border.all(
              color: _rowAccent.withOpacity(0.18), width: 0.8),
        ),
        child: Row(
          children: [
            // Coloured number badge
            Container(
              width: rsw * 0.125,
              margin: EdgeInsets.all(rsw * 0.020),
              decoration: BoxDecoration(
                color: _rowAccent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(rsw * 0.018),
              child: AspectRatio(
                aspectRatio: 1,
                child: Center(
                  child: Text(
                    '${surah.number}',
                    style: TextStyle(
                      color: _rowAccent,
                      fontSize: rsw * 0.026,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),

            // Name + chips
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: rsw * 0.018),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.nameTranslit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: rsw * 0.036,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: rsw * 0.008),
                    Wrap(
                      spacing: rsw * 0.012,
                      runSpacing: rsw * 0.006,
                      children: [
                        _Chip('${surah.totalAyahs} Ayahs',
                            theme.accent, rsw),
                        _Chip(surah.revelationType,
                            const Color(0xFF64B5F6), rsw),
                        _Chip('Para ${surah.para}',
                            const Color(0xFFFFB74D), rsw),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Arabic name
            Padding(
              padding: EdgeInsets.symmetric(horizontal: rsw * 0.025),
              child: Text(
                surah.nameAr,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  color: _rowAccent,
                  fontSize: rsw * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Chevron
            Padding(
              padding: EdgeInsets.only(right: rsw * 0.020),
              child: Icon(Icons.chevron_right_rounded,
                  color: theme.textLow, size: rsw * 0.040),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  final double rsw;

  const _Chip(this.text, this.color, this.rsw);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: rsw * 0.014, vertical: rsw * 0.005),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(rsw * 0.020),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: rsw * 0.020,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}