import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import '../cubit/quran_cubit.dart';
import '../cubit/quran_state.dart';
import '../models/bookmark_model.dart';
import '../models/surah_model.dart';
import 'quran_reader_page.dart';


class BookmarkTab extends StatelessWidget {
  const BookmarkTab({super.key});

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
            final bookmarks = state.bookmarks;
            if (bookmarks.isEmpty) {
              return _EmptyBookmarks(theme: theme, rsw: rsw);
            }
            return ListView.builder(
              padding: EdgeInsets.all(rsw * 0.030),
              physics: const ClampingScrollPhysics(),
              itemCount: bookmarks.length,
              itemBuilder: (_, i) => _BookmarkTile(
                bm: bookmarks[i],
                theme: theme,
                rsw: rsw,
                surahs: state.surahs,
              ),
            );
          },
        );
      },
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final BookmarkModel bm;
  final AppThemeOption theme;
  final double rsw;
  final List<SurahModel> surahs;

  const _BookmarkTile({
    required this.bm,
    required this.theme,
    required this.rsw,
    required this.surahs,
  });

  @override
  Widget build(BuildContext context) {
    final surah = surahs.firstWhere(
          (s) => s.number == bm.surahNumber,
      orElse: () => surahs.first,
    );
    final isQuranPage = bm.pageNumber >= 3 && bm.pageNumber <= 612;
    final quranPage   = isQuranPage ? bm.pageNumber - 2 : bm.pageNumber;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<QuranCubit>(),
            child: QuranReaderPage(
                initialPage: bm.pageNumber, surah: surah),
          ),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: rsw * 0.018),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(rsw * 0.032),
          border: Border.all(
              color: const Color(0xFFFFB74D).withOpacity(0.28), width: 0.8),
        ),
        child: Row(
          children: [
            // Gold bookmark icon bar
            Container(
              width: rsw * 0.012,
              height: rsw * 0.18,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(rsw * 0.032),
                  bottomLeft: Radius.circular(rsw * 0.032),
                ),
              ),
            ),
            SizedBox(width: rsw * 0.025),

            // Bookmark icon
            Icon(Icons.bookmark_rounded,
                color: const Color(0xFFFFB74D), size: rsw * 0.055),
            SizedBox(width: rsw * 0.022),

            // Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: rsw * 0.022),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bm.surahNameEn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textHigh,
                        fontSize: rsw * 0.034,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: rsw * 0.005),
                    Text(
                      isQuranPage
                          ? 'Quran page $quranPage  ·  Image ${bm.pageNumber}'
                          : 'Image page ${bm.pageNumber}',
                      style: TextStyle(
                          color: theme.textLow, fontSize: rsw * 0.024),
                    ),
                  ],
                ),
              ),
            ),

            // Delete button
            GestureDetector(
              onTap: () => context
                  .read<QuranCubit>()
                  .toggleBookmark(bm.pageNumber, surah),
              child: Container(
                margin: EdgeInsets.all(rsw * 0.020),
                padding: EdgeInsets.all(rsw * 0.016),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.red.withOpacity(0.20), width: 0.5),
                ),
                child: Icon(Icons.delete_outline_rounded,
                    color: Colors.red[300], size: rsw * 0.038),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBookmarks extends StatelessWidget {
  final AppThemeOption theme;
  final double rsw;

  const _EmptyBookmarks({required this.theme, required this.rsw});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: rsw * 0.22,
            height: rsw * 0.22,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D).withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFFFFB74D).withOpacity(0.20),
                  width: 1),
            ),
            child: Icon(Icons.bookmark_border_rounded,
                color: const Color(0xFFFFB74D).withOpacity(0.60),
                size: rsw * 0.12),
          ),
          SizedBox(height: rsw * 0.040),
          Text(
            'No bookmarks yet',
            style: TextStyle(
              color: theme.textHigh,
              fontSize: rsw * 0.040,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: rsw * 0.012),
          Text(
            'Long-press any page while reading\nto save your place',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textLow,
              fontSize: rsw * 0.028,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}