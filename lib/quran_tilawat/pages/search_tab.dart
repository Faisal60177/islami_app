import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import '../cubit/quran_cubit.dart';
import '../cubit/quran_state.dart';
import '../models/surah_model.dart';
import 'quran_reader_page.dart';

class SearchOverlayPage extends StatefulWidget {
  const SearchOverlayPage({super.key});

  @override
  State<SearchOverlayPage> createState() => _SearchOverlayPageState();
}

class _SearchOverlayPageState extends State<SearchOverlayPage> {
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
        return Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: Column(
              children: [
                // ── Search bar with back button ──────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      rsw * 0.030, rsw * 0.020, rsw * 0.040, rsw * 0.014),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_rounded,
                            color: theme.textLow),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius:
                            BorderRadius.circular(rsw * 0.034),
                            border: Border.all(
                                color: theme.accent.withOpacity(0.25),
                                width: 1),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: rsw * 0.026),
                              Icon(Icons.search_rounded,
                                  color: theme.accent, size: rsw * 0.046),
                              SizedBox(width: rsw * 0.014),
                              Expanded(
                                child: TextField(
                                  controller: _ctrl,
                                  autofocus: true,
                                  style: TextStyle(
                                      color: theme.textHigh,
                                      fontSize: rsw * 0.032),
                                  decoration: InputDecoration(
                                    hintText: 'Search surah by name or number…',
                                    hintStyle: TextStyle(
                                        color: theme.textLow,
                                        fontSize: rsw * 0.026),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: rsw * 0.026),
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
                                  child: Padding(
                                    padding: EdgeInsets.all(rsw * 0.016),
                                    child: Icon(Icons.clear_rounded,
                                        color: theme.textLow,
                                        size: rsw * 0.030),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Body: empty state OR results ────────────────────
                Expanded(
                  child: _ctrl.text.trim().isEmpty
                      ? _EmptyPrompt(theme: theme, rsw: rsw)
                      : BlocBuilder<QuranCubit, QuranState>(
                    builder: (_, state) {
                      if (state is! QuranLoaded) return const SizedBox();
                      final results = state.searchResults;
                      if (results.isEmpty) {
                        return _NoResults(theme: theme, rsw: rsw);
                      }
                      return ListView.builder(
                        padding: EdgeInsets.symmetric(
                            horizontal: rsw * 0.040,
                            vertical: rsw * 0.014),
                        physics: const BouncingScrollPhysics(),
                        itemCount: results.length,
                        itemBuilder: (_, i) => _SearchResultTile(
                          surah: results[i],
                          theme: theme,
                          rsw: rsw,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  final AppThemeOption theme;
  final double rsw;

  const _EmptyPrompt({required this.theme, required this.rsw});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, color: theme.textLow.withOpacity(0.4), size: rsw * 0.14),
          SizedBox(height: rsw * 0.025),
          Text('Start typing to search surahs',
              style: TextStyle(color: theme.textLow, fontSize: rsw * 0.032)),
          SizedBox(height: rsw * 0.008),
          Text('Search by name, translation, or number',
              style: TextStyle(
                  color: theme.textLow.withOpacity(0.6),
                  fontSize: rsw * 0.024)),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final AppThemeOption theme;
  final double rsw;

  const _NoResults({required this.theme, required this.rsw});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: theme.textLow, size: rsw * 0.12),
          SizedBox(height: rsw * 0.025),
          Text('No surahs found',
              style: TextStyle(color: theme.textLow, fontSize: rsw * 0.034)),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final SurahModel surah;
  final AppThemeOption theme;
  final double rsw;

  const _SearchResultTile({
    required this.surah,
    required this.theme,
    required this.rsw,
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
          borderRadius: BorderRadius.circular(rsw * 0.030),
          border: Border.all(
              color: theme.accent.withOpacity(0.10), width: 0.8),
        ),
        child: Row(
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameTranslit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textHigh,
                      fontSize: rsw * 0.034,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Page ${surah.page - 1}  ·  ${surah.totalAyahs} Ayahs  ·  Para ${surah.para}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: theme.textLow, fontSize: rsw * 0.024),
                  ),
                ],
              ),
            ),
            SizedBox(width: rsw * 0.015),
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