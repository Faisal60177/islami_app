import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:islamic_app/settings/cubit/settings_cubit.dart';
import 'package:islamic_app/settings/cubit/settings_state.dart';
import 'package:islamic_app/settings/theme/app_themes.dart';
import '../cubit/quran_cubit.dart';
import '../cubit/quran_state.dart';
import '../models/surah_model.dart';
import 'quran_reader_page.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw  = MediaQuery.of(context).size.width;
    final rsw = sw.clamp(320.0, 420.0);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (_, settings) {
        final theme = getThemeById(settings.themeMode);
        return Column(
          children: [
            // ── Search bar ──────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                  rsw * 0.04, rsw * 0.035, rsw * 0.04, rsw * 0.012),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(rsw * 0.038),
                  border: Border.all(
                      color: theme.accent.withOpacity(0.28), width: 1),
                ),
                child: Row(
                  children: [
                    SizedBox(width: rsw * 0.030),
                    Icon(Icons.search_rounded,
                        color: theme.accent, size: rsw * 0.050),
                    SizedBox(width: rsw * 0.018),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        style: TextStyle(
                            color: Colors.white, fontSize: rsw * 0.034),
                        decoration: InputDecoration(
                          hintText: 'Search surah by name or number…',
                          hintStyle: TextStyle(
                              color: theme.textLow,
                              fontSize: rsw * 0.028),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: rsw * 0.030),
                        ),
                        onChanged: (v) =>
                            context.read<QuranCubit>().search(v),
                      ),
                    ),
                    if (_ctrl.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _ctrl.clear();
                          context.read<QuranCubit>().search('');
                        },
                        child: Container(
                          margin: EdgeInsets.all(rsw * 0.018),
                          padding: EdgeInsets.all(rsw * 0.010),
                          decoration: BoxDecoration(
                            color: theme.textLow.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.clear_rounded,
                              color: theme.textLow, size: rsw * 0.034),
                        ),
                      )
                    else
                      SizedBox(width: rsw * 0.030),
                  ],
                ),
              ),
            ),

            // ── Result count label ──────────────────────────────
            BlocBuilder<QuranCubit, QuranState>(
              builder: (_, state) {
                if (state is! QuranLoaded) return const SizedBox();
                final count = state.searchResults.length;
                return Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: rsw * 0.04, vertical: rsw * 0.008),
                  child: Row(
                    children: [
                      Text(
                        _ctrl.text.isEmpty
                            ? '114 Surahs'
                            : '$count result${count != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: theme.textLow,
                          fontSize: rsw * 0.026,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Results list ────────────────────────────────────
            Expanded(
              child: BlocBuilder<QuranCubit, QuranState>(
                builder: (_, state) {
                  if (state is! QuranLoaded) return const SizedBox();
                  final results = state.searchResults;
                  if (results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              color: theme.textLow, size: rsw * 0.12),
                          SizedBox(height: rsw * 0.025),
                          Text('No surahs found',
                              style: TextStyle(
                                  color: theme.textLow,
                                  fontSize: rsw * 0.034)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                        horizontal: rsw * 0.030, vertical: rsw * 0.010),
                    physics: const BouncingScrollPhysics(),
                    itemCount: results.length,
                    itemBuilder: (_, i) => _SearchTile(
                      surah: results[i],
                      theme: theme,
                      rsw: rsw,
                      query: state.searchQuery,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchTile extends StatelessWidget {
  final SurahModel surah;
  final AppThemeOption theme;
  final double rsw;
  final String query;

  const _SearchTile({
    required this.surah,
    required this.theme,
    required this.rsw,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<QuranCubit>(),
            child: QuranReaderPage(
                initialPage: surah.page, surah: surah),
          ),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: rsw * 0.016),
        padding: EdgeInsets.symmetric(
            horizontal: rsw * 0.030, vertical: rsw * 0.022),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(rsw * 0.028),
          border: Border.all(
              color: theme.accent.withOpacity(0.10), width: 0.8),
        ),
        child: Row(
          children: [
            // Number circle
            Container(
              width: rsw * 0.082,
              height: rsw * 0.082,
              decoration: BoxDecoration(
                  color: theme.accent.withOpacity(0.12),
                  shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '${surah.number}',
                  style: TextStyle(
                    color: theme.accent,
                    fontSize: rsw * 0.024,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(width: rsw * 0.025),

            // Name + page info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameTranslit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: rsw * 0.034,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Image p.${surah.page}  ·  ${surah.totalAyahs} Ayahs  ·  Para ${surah.para}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: theme.textLow, fontSize: rsw * 0.024),
                  ),
                ],
              ),
            ),
            SizedBox(width: rsw * 0.015),

            // Arabic
            Text(
              surah.nameAr,
              style: TextStyle(
                fontFamily: 'Amiri',
                color: theme.accent,
                fontSize: rsw * 0.038,
              ),
            ),
          ],
        ),
      ),
    );
  }
}