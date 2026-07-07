import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/duas_cubit.dart';
import '../model/duas_model.dart';
import 'package:muslim_app/utils/language_utils.dart';
import 'duas_detail_page.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/Duas/cubit/duas_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';

class BookmarkedDuasPage extends StatefulWidget {
  final String searchQuery;
  const BookmarkedDuasPage({super.key, required this.searchQuery});

  @override
  State<BookmarkedDuasPage> createState() => _BookmarkedDuasPageState();
}

class _BookmarkedDuasPageState extends State<BookmarkedDuasPage>
    with AutomaticKeepAliveClientMixin {
  List<DuasModel> bookmarkDuas = [];
  bool isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadBookmarks();
  }

  Future<void> loadBookmarks() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    final cubit = context.read<DuasCubit>();
    final userId = cubit.userId;

    if (userId != 'guest') {
      await cubit.repository.syncUserInteractionsFromFirestore(userId);
    }

    final data = await cubit.repository.getBookmarkedForUser(
      userId:       userId,
      languageCode: cubit.currentLanguageCode,
    );

    if (!mounted) return;
    setState(() {
      bookmarkDuas = data;
      isLoading = false;
    });
  }

  // ── ADD: toggle favorite directly and update local list ──
  Future<void> _toggleBookmark(DuasModel dua) async {
    context.read<DuasCubit>().toggleBookmark(dua);
    if (!dua.isBookmarked) {
      // was just unfavorited — remove from list immediately
      setState(() => bookmarkDuas.removeWhere((d) => d.id == dua.id));
    } else {
      // was just favorited — reload to get it
      await loadBookmarks();
    }
  }

  List<DuasModel> get filteredDuas {
    if (widget.searchQuery.isEmpty) return bookmarkDuas;
    final query = widget.searchQuery.toLowerCase();
    return bookmarkDuas
        .where((dua) =>
    dua.arabic.toLowerCase().contains(query) ||
        dua.title.toLowerCase().contains(query) ||
        dua.categoryTitle.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // ── ADD: listen to DuasCubit so page rebuilds on toggle ──
    return BlocListener<DuasCubit, DuasState>(
      listener: (context, state) {
        // reload favorites whenever cubit emits a new state
        // (triggered by toggleFavorite re-emit in DuasCubit)
        loadBookmarks();
      },
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final cubit = context.read<DuasCubit>();
    final isRtl = LanguageUtils.isRtl(cubit.currentLanguageCode);
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final settings = context.watch<SettingsCubit>().state;
    final l10n = AppLocalizations(settings.languageCode);
    final theme = getThemeById(settings.themeMode);

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
            color: theme.accent, strokeWidth: 3),
      );
    }

    if (bookmarkDuas.isEmpty) {
      return _EmptyState(
        icon: Icons.bookmark_remove_rounded,
        title: l10n.noBookmarkYet,
        subtitle: l10n.noBookmarkDesc,
        iconColor: const Color(0xFF64B5F6),
        theme: theme,
      );
    }

    if (filteredDuas.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off_rounded,
        title: l10n.noResultsFound,
        subtitle: l10n.tryDifferentSearch,
        iconColor: theme.textLow,
        theme: theme,
      );
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: RefreshIndicator(
        color: theme.accent,
        onRefresh: loadBookmarks,
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    w * 0.05, h * 0.02, w * 0.05, h * 0.01),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: w * 0.03, vertical: h * 0.007),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64B5F6).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_rounded,
                          size: w * 0.04, color: const Color(0xFF64B5F6)),
                      SizedBox(width: w * 0.015),
                      Text(
                        '${filteredDuas.length} ${l10n.saved}',
                        style: TextStyle(
                          fontSize: w * 0.034,
                          color: const Color(0xFF64B5F6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  w * 0.04, 0, w * 0.04, h * 0.03),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final dua = filteredDuas[index];
                    return _BookmarkCard(
                      dua: dua,
                      isRtl: isRtl,
                      theme: theme,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DuasDetailPage(dua: dua)),
                        );
                        loadBookmarks(); // ← reload after returning
                      },
                      // ── ADD: unfavorite directly from card ──
                      onRemoveBookmark: () => _toggleBookmark(dua),
                    );
                  },
                  childCount: filteredDuas.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _BookmarkCard extends StatelessWidget {
  final DuasModel dua;
  final bool isRtl;
  final AppThemeOption theme;
  final VoidCallback onTap;
  final VoidCallback onRemoveBookmark; // ── ADD ──

  const _BookmarkCard({
    required this.dua,
    required this.isRtl,
    required this.theme,
    required this.onTap,
    required this.onRemoveBookmark, // ── ADD ──
  });

  String getShortText(String text, [int limit = 50]) {
    if (text.length <= limit) return text;
    return '${text.substring(0, limit)}...';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.014),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFF64B5F6).withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF64B5F6).withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: w * 0.04, vertical: h * 0.016),
            child: Row(
              children: [
                // ── CHANGED: tap icon to unfavorite ──
                GestureDetector(
                  onTap: onRemoveBookmark,
                  child: Container(
                    width: w * 0.12,
                    height: w * 0.12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF64B5F6).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        dua.isFavorite
                            ? Icons.bookmark_rounded          // ← filled
                            : Icons.bookmark_remove_rounded,  // ← empty
                        color: const Color(0xFF64B5F6),
                        size: w * 0.055,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: w * 0.035),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          getShortText(dua.arabic),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: w * 0.042,
                            fontWeight: FontWeight.w600,
                            color: theme.textHigh,
                            height: 1.4,
                            fontFamily: 'Amiri',
                          ),
                        ),
                      ),
                      if (dua.title.isNotEmpty)
                        Text(
                          dua.title,
                          textAlign:
                          isRtl ? TextAlign.right : TextAlign.left,
                          style: TextStyle(
                            fontSize: w * 0.032,
                            color: theme.textLow,
                          ),
                        ),
                      SizedBox(height: h * 0.006),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: w * 0.025, vertical: h * 0.004),
                        decoration: BoxDecoration(
                          color: theme.accent.withOpacity(0.09),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          dua.categoryTitle,
                          style: TextStyle(
                              fontSize: w * 0.03,
                              color: theme.accent,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: w * 0.02),
                Icon(Icons.chevron_right_rounded,
                    color: theme.textLow.withOpacity(0.5), size: w * 0.055),
              ],
            ),
          ),
        ),
      ),
    );
  }
}






class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final AppThemeOption theme;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.06),
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: w * 0.14, color: iconColor),
            ),
            SizedBox(height: h * 0.025),
            Text(title,
                style: TextStyle(
                    fontSize: w * 0.048,
                    fontWeight: FontWeight.w700,
                    color: theme.textHigh),
                textAlign: TextAlign.center),
            SizedBox(height: h * 0.01),
            Text(subtitle,
                style: TextStyle(
                    fontSize: w * 0.036,
                    color: theme.textLow,
                    height: 1.5),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}