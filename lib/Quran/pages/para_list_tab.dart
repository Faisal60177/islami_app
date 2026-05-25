import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import '../cubit/quran_cubit.dart';
import '../cubit/quran_state.dart';
import '../models/surah_model.dart';
import 'quran_reader_page.dart';

const _paraNames = [
  'Alif Lam Meem',      'Sayaqool',           'Tilka al-Rusul',
  'Lan Tanaloo',        'Wal Mohsanat',       'La Yuhibbullah',
  'Wa Iza Samiu',       'Wa Lau Annana',      'Qalal Malao',
  'Wa Alamu',           'Yatazeroon',         'Wa Mamin Dabbah',
  'Wa Ma Ubarriu',      'Rubama',             'Subhanalladhi',
  'Qal Alam',           'Iqtaraba',           'Qad Aflaha',
  'Wa Qalalladheena',   'Amman Khalaqa',      'Utlu Ma Oohi',
  'Wa Manyaqnut',       'Wa Mali',            'Faman Azlamu',
  'Ilayhi Yuraddu',     'Ha Meem',            'Qala Fama Khatbukum',
  'Qad Sami Allah',     'Tabarakalladhi',     'Amma',
];

const _paraColors = [
  Color(0xFF4CAF82), Color(0xFF64B5F6), Color(0xFFFFB74D),
  Color(0xFFEF9A9A), Color(0xFFB39DDB), Color(0xFF80DEEA),
  Color(0xFFA5D6A7), Color(0xFFFFCC80), Color(0xFFF48FB1),
  Color(0xFF90CAF9),
];

class ParaListTab extends StatelessWidget {
  const ParaListTab({super.key});

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
            final surahs = state.surahs;

            return GridView.builder(
              padding: EdgeInsets.all(rsw * 0.028),
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: rsw * 0.028,
                crossAxisSpacing: rsw * 0.028,
                childAspectRatio: 1.15,
              ),
              itemCount: 30,
              itemBuilder: (_, i) {
                final paraNum = i + 1;
                final first = surahs.firstWhere(
                      (s) => s.para == paraNum,
                  orElse: () => surahs.first,
                );
                final count = surahs.where((s) => s.para == paraNum).length;
                final color = _paraColors[i % _paraColors.length];

                return _ParaCard(
                  paraNumber: paraNum,
                  paraName: _paraNames[i],
                  surahCount: count,
                  firstSurah: first,
                  color: color,
                  theme: theme,
                  rsw: rsw,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ParaCard extends StatelessWidget {
  final int paraNumber;
  final String paraName;
  final int surahCount;
  final SurahModel firstSurah;
  final Color color;
  final AppThemeOption theme;
  final double rsw;

  const _ParaCard({
    required this.paraNumber,
    required this.paraName,
    required this.surahCount,
    required this.firstSurah,
    required this.color,
    required this.theme,
    required this.rsw,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final page = await context.read<QuranCubit>().getParaPage(paraNumber);
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<QuranCubit>(),
              child: QuranReaderPage(
                  initialPage: page, surah: firstSurah),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(rsw * 0.038),
          border: Border.all(color: color.withOpacity(0.30), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Number ring
            Container(
              width: rsw * 0.128,
              height: rsw * 0.128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.12),
                border: Border.all(color: color.withOpacity(0.45), width: 1.5),
              ),
              child: Center(
                child: Text(
                  '$paraNumber',
                  style: TextStyle(
                    color: color,
                    fontSize: rsw * 0.038,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SizedBox(height: rsw * 0.016),

            Text(
              'Para $paraNumber',
              style: TextStyle(
                color: Colors.white,
                fontSize: rsw * 0.030,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: rsw * 0.005),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: rsw * 0.018),
              child: Text(
                paraName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: theme.textLow, fontSize: rsw * 0.022),
              ),
            ),
            SizedBox(height: rsw * 0.008),

            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: rsw * 0.016, vertical: rsw * 0.005),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(rsw * 0.020),
              ),
              child: Text(
                '$surahCount Surahs',
                style: TextStyle(
                  color: color,
                  fontSize: rsw * 0.020,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}