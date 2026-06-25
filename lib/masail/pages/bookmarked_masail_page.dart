import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/masail_cubit.dart';
import '../cubit/masail_state.dart';
import '../model/masail_model.dart';
import 'package:muslim_app/utils/language_utils.dart';
import 'masail_detail_page.dart';
import 'category_masail_page.dart'; // for MasailCard, _Chip
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';

const Color _primary  = Color(0xFF6B1E2E);
const Color _gold     = Color(0xFFD4AF37);
const Color _bg       = Color(0xFFFAF6EF);
const Color _surface  = Color(0xFFF2EBE0);
const Color _textHi   = Color(0xFF1C0A0F);
const Color _textMid  = Color(0xFF5C3D44);
const Color _textLo   = Color(0xFF9C7A82);

class BookmarkedMasailPage extends StatefulWidget {
  final String searchQuery;
  const BookmarkedMasailPage({super.key, required this.searchQuery});

  @override
  State<BookmarkedMasailPage> createState() => _BookmarkedMasailPageState();
}

class _BookmarkedMasailPageState extends State<BookmarkedMasailPage>
    with AutomaticKeepAliveClientMixin {
  List<MasailModel> bookmarked = [];
  bool isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    final cubit  = context.read<MasailCubit>();
    final userId = cubit.userId;

    // Sync from Firestore for logged-in users
    if (userId != 'guest') {
      await cubit.repository.syncUserBookmarksFromFirestore(userId);
    }

    final data = await cubit.repository.getBookmarkedForUser(
      userId:       userId,
      languageCode: cubit.currentLanguageCode,
    );

    if (!mounted) return;
    setState(() {
      bookmarked = data;
      isLoading  = false;
    });
  }

  Future<void> _removeBookmark(MasailModel m) async {
    context.read<MasailCubit>().toggleBookmark(m);
    setState(() => bookmarked.removeWhere((x) => x.id == m.id));
  }

  List<MasailModel> get _filtered {
    if (widget.searchQuery.isEmpty) return bookmarked;
    final q = widget.searchQuery.toLowerCase();
    return bookmarked.where((m) =>
    m.question.toLowerCase().contains(q) ||
        m.answer.toLowerCase().contains(q)   ||
        m.categoryTitle.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<MasailCubit, MasailState>(
      listener: (_, state) => _load(),
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final cubit    = context.read<MasailCubit>();
    final isRtl    = LanguageUtils.isRtl(cubit.currentLanguageCode);
    final w        = MediaQuery.of(context).size.width;
    final h        = MediaQuery.of(context).size.height;
    final langCode = context.read<SettingsCubit>().state.languageCode;
    final l10n     = AppLocalizations(langCode);

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
      );
    }

    if (bookmarked.isEmpty) {
      return _EmptyBookmarks(w: w, h: h, l10n: l10n);
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          l10n.noResultsFound,
          style: TextStyle(color: _textLo, fontSize: w * 0.04),
        ),
      );
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: RefreshIndicator(
        color:     _primary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            // ── Saved count header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    w * 0.05, h * 0.022, w * 0.05, h * 0.012),
                child: Row(
                  textDirection:
                  isRtl ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: w * 0.03, vertical: h * 0.006),
                      decoration: BoxDecoration(
                        color:         _primary.withOpacity(0.09),
                        borderRadius:  BorderRadius.circular(20),
                        border: Border.all(
                            color: _primary.withOpacity(0.2), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_rounded,
                              size: w * 0.038, color: _primary),
                          SizedBox(width: w * 0.015),
                          Text(
                            '${_filtered.length} ${l10n.saved}',
                            style: TextStyle(
                              fontSize:   w * 0.032,
                              color:      _primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bookmark list ──
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  w * 0.04, 0, w * 0.04, h * 0.04),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (_, i) {
                    final m = _filtered[i];
                    return _BookmarkCard(
                      masail:          m,
                      index:           i,
                      isRtl:           isRtl,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MasailDetailPage(masail: m),
                          ),
                        );
                        _load();
                      },
                      onRemove: () => _removeBookmark(m),
                    );
                  },
                  childCount: _filtered.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Bookmark Card ─────────────────────────────────────────────────────────────
class _BookmarkCard extends StatelessWidget {
  final MasailModel  masail;
  final int          index;
  final bool         isRtl;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _BookmarkCard({
    required this.masail,
    required this.index,
    required this.isRtl,
    required this.onTap,
    required this.onRemove,
  });

  String _short(String t, [int n = 80]) =>
      t.length <= n ? t : '${t.substring(0, n)}...';

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.014),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: _primary.withOpacity(0.14), width: 1),
        boxShadow: [
          BoxShadow(
            color:      _primary.withOpacity(0.06),
            blurRadius: 12,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color:         Colors.transparent,
        borderRadius:  BorderRadius.circular(18),
        child: InkWell(
          borderRadius:   BorderRadius.circular(18),
          onTap:          onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: w * 0.04, vertical: h * 0.016),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Bookmark icon (tap to remove) ──
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width:  w * 0.12,
                    height: w * 0.12,
                    decoration: BoxDecoration(
                      color:         _primary.withOpacity(0.09),
                      borderRadius:  BorderRadius.circular(14),
                      border: Border.all(
                          color: _primary.withOpacity(0.18), width: 1),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.bookmark_rounded,
                        color: _primary,
                        size:  w * 0.052,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: w * 0.035),
                // ── Content ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: isRtl
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Arabic snippet — only if present
                      if (masail.arabic != null &&
                          masail.arabic!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: h * 0.006),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              _short(masail.arabic!, 55),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize:   w * 0.038,
                                fontWeight: FontWeight.w600,
                                color:      _textHi,
                                height:     1.5,
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ),
                        ),
                      // Question
                      Text(
                        _short(masail.question),
                        textAlign:
                        isRtl ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          fontSize:   w * 0.034,
                          color:      _textMid,
                          height:     1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: h * 0.008),
                      // ── Tags row ──
                      Row(
                        textDirection:
                        isRtl ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          // Category chip
                          _SmallChip(
                              label: masail.categoryTitle,
                              color: _primary,
                              w:     w, h: h),
                          // Madhab chip — only if present
                          if (masail.madhab != null &&
                              masail.madhab!.isNotEmpty) ...[
                            SizedBox(width: w * 0.012),
                            _SmallChip(
                                label: masail.madhab!,
                                color: const Color(0xFFB8860B),
                                w:     w, h: h),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: w * 0.015),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[300], size: w * 0.048),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ── Tiny chip ─────────────────────────────────────────────────────────────────
class _SmallChip extends StatelessWidget {
  final String label;
  final Color  color;
  final double w, h;
  const _SmallChip({
    required this.label,
    required this.color,
    required this.w,
    required this.h,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
        horizontal: w * 0.022, vertical: h * 0.004),
    decoration: BoxDecoration(
      color:         color.withOpacity(0.09),
      borderRadius:  BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize:   w * 0.027,
        color:      color,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}


// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyBookmarks extends StatelessWidget {
  final double w, h;
  final dynamic l10n;
  const _EmptyBookmarks({required this.w, required this.h, required this.l10n});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.065),
            decoration: BoxDecoration(
              color:  _primary.withOpacity(0.08),
              shape:  BoxShape.circle,
            ),
            child: Icon(Icons.bookmark_remove_rounded,
                size: w * 0.14, color: _primary.withOpacity(0.4)),
          ),
          SizedBox(height: h * 0.025),
          Text(
            l10n.noBookmarkYet,
            style: TextStyle(
              fontSize:   w * 0.046,
              fontWeight: FontWeight.w700,
              color:      _textHi,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: h * 0.01),
          Text(
            l10n.noBookmarkDesc,
            style: TextStyle(
                fontSize: w * 0.035,
                color:    _textLo,
                height:   1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}