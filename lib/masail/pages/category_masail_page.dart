import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/masail_cubit.dart';
import '../model/masail_category_model.dart';
import '../model/masail_model.dart';
import 'package:muslim_app/utils/language_utils.dart';
import 'masail_detail_page.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';

// ── Shared palette ────────────────────────────────────────────────────────────
const Color _primary   = Color(0xFF6B1E2E);
const Color _primaryDk = Color(0xFF4A1220);
const Color _gold      = Color(0xFFD4AF37);
const Color _goldDk    = Color(0xFFB8860B);
const Color _bg        = Color(0xFFFAF6EF);
const Color _surface   = Color(0xFFF2EBE0);
const Color _textHi    = Color(0xFF1C0A0F);
const Color _textMid   = Color(0xFF5C3D44);
const Color _textLo    = Color(0xFF9C7A82);
const Color _bookmark  = Color(0xFF6B1E2E);

class CategoryMasailPage extends StatefulWidget {
  final MasailCategoryModel category;
  const CategoryMasailPage({super.key, required this.category});

  @override
  State<CategoryMasailPage> createState() => _CategoryMasailPageState();
}

class _CategoryMasailPageState extends State<CategoryMasailPage> {
  List<MasailModel> masail = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final cubit = context.read<MasailCubit>();
      final data  = await cubit.repository.getMasailByCategory(
        categoryId:   widget.category.categoryId,
        languageCode: cubit.currentLanguageCode,
        userId:       cubit.userId,
      );
      if (mounted) setState(() { masail = data; isLoading = false; });
    } catch (e) {
      debugPrint('❌ CategoryMasailPage load error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MasailCubit>();
    final isRtl = LanguageUtils.isRtl(cubit.currentLanguageCode);
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: _MasailAppBar(
          title:    widget.category.categoryTitle,
          subtitle: 'Masail', // l10n
          isRtl:    isRtl,
          w:        w,
        ),
        body: isLoading
            ? const Center(
            child: CircularProgressIndicator(
                color: _primary, strokeWidth: 2.5))
            : masail.isEmpty
            ? _EmptyMasail(w: w, h: h)
            : RefreshIndicator(
          color: _primary,
          onRefresh: _load,
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
                w * 0.04, h * 0.018, w * 0.04, h * 0.04),
            itemCount: masail.length,
            itemBuilder: (_, i) => MasailCard(
              masail: masail[i],
              index:  i,
              isRtl:  isRtl,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MasailDetailPage(masail: masail[i]),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// all_masail_page.dart  (same file for convenience — split if preferred)
// ─────────────────────────────────────────────────────────────────────────────
class AllMasailPage extends StatefulWidget {
  final String searchQuery;
  const AllMasailPage({super.key, required this.searchQuery});

  @override
  State<AllMasailPage> createState() => _AllMasailPageState();
}

class _AllMasailPageState extends State<AllMasailPage>
    with AutomaticKeepAliveClientMixin {
  List<MasailModel> allMasail = [];
  bool isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cubit = context.read<MasailCubit>();
    final data  = await cubit.repository.getAllMasail(
      languageCode: cubit.currentLanguageCode,
      userId:       cubit.userId,
    );
    if (mounted) setState(() { allMasail = data; isLoading = false; });
  }

  List<MasailModel> get _filtered {
    if (widget.searchQuery.isEmpty) return allMasail;
    final q = widget.searchQuery.toLowerCase();
    return allMasail.where((m) =>
    (m.arabic  != null && m.arabic!.toLowerCase().contains(q)) ||
        m.question.toLowerCase().contains(q) ||
        m.answer.toLowerCase().contains(q)   ||
        m.categoryTitle.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cubit = context.read<MasailCubit>();
    final isRtl = LanguageUtils.isRtl(cubit.currentLanguageCode);
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
      );
    }

    if (_filtered.isEmpty) {
      return _EmptyMasail(w: w, h: h);
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.018, w * 0.04, h * 0.04),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => MasailCard(
          masail: _filtered[i],
          index:  i,
          isRtl:  isRtl,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MasailDetailPage(masail: _filtered[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Shared MasailCard widget
// ─────────────────────────────────────────────────────────────────────────────
class MasailCard extends StatefulWidget {
  final MasailModel masail;
  final int         index;
  final bool        isRtl;
  final VoidCallback onTap;

  const MasailCard({
    super.key,
    required this.masail,
    required this.index,
    required this.isRtl,
    required this.onTap,
  });

  @override
  State<MasailCard> createState() => _MasailCardState();
}

class _MasailCardState extends State<MasailCard> {
  String _short(String text, [int limit = 90]) =>
      text.length <= limit ? text : '${text.substring(0, limit)}...';

  void _toggleBookmark() {
    setState(() =>
    widget.masail.isBookmarked = !widget.masail.isBookmarked);
    context.read<MasailCubit>().toggleBookmark(widget.masail);
  }

  // Soft color palette for the number badge
  static const List<Color> _badgeColors = [
    Color(0xFF6B1E2E),
    Color(0xFF1E3A6B),
    Color(0xFF2D6B1E),
    Color(0xFF6B511E),
  ];

  @override
  Widget build(BuildContext context) {
    final m     = widget.masail;
    final w     = MediaQuery.of(context).size.width;
    final h     = MediaQuery.of(context).size.height;
    final badge = _badgeColors[widget.index % _badgeColors.length];

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.014),
      decoration: BoxDecoration(
        color:         Colors.white,
        borderRadius:  BorderRadius.circular(18),
        border: Border.all(color: _surface, width: 1.2),
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
          splashColor:    _primary.withOpacity(0.06),
          highlightColor: _primary.withOpacity(0.03),
          onTap: widget.onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: w * 0.04, vertical: h * 0.016),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Number badge ──
                Container(
                  width:  w * 0.11,
                  height: w * 0.11,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [badge, badge.withOpacity(0.75)],
                      begin:  Alignment.topLeft,
                      end:    Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:      badge.withOpacity(0.28),
                        blurRadius: 8,
                        offset:     const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      m.id.toString(),
                      style: TextStyle(
                        color:      Colors.white,
                        fontSize:   w * 0.034,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: w * 0.035),
                // ── Content ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: widget.isRtl
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Arabic text — only if present
                      if (m.arabic != null && m.arabic!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: h * 0.007),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              _short(m.arabic!, 70),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize:   w * 0.04,
                                fontWeight: FontWeight.w600,
                                color:      _textHi,
                                height:     1.55,
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ),
                        ),
                      // Question preview
                      Text(
                        _short(m.question),
                        textAlign:
                        widget.isRtl ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          fontSize:   w * 0.034,
                          color:      _textMid,
                          height:     1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: h * 0.009),
                      // ── Bottom row: tags + bookmark ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Category chip
                              _Chip(
                                label: m.categoryTitle,
                                icon:  Icons.folder_outlined,
                                color: _primary,
                                w:     w, h: h,
                              ),
                              // Madhab chip — only if present
                              if (m.madhab != null &&
                                  m.madhab!.isNotEmpty) ...[
                                SizedBox(width: w * 0.015),
                                _Chip(
                                  label: m.madhab!,
                                  icon:  Icons.school_outlined,
                                  color: _goldDk,
                                  w:     w, h: h,
                                ),
                              ],
                            ],
                          ),
                          // Bookmark toggle
                          GestureDetector(
                            onTap: _toggleBookmark,
                            child: Icon(
                              m.isBookmarked
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_outline_rounded,
                              color: m.isBookmarked
                                  ? _primary
                                  : Colors.grey[350],
                              size: w * 0.052,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: w * 0.015),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[300], size: w * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ── Small label chip ──────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String   label;
  final IconData icon;
  final Color    color;
  final double   w, h;
  const _Chip({
    required this.label,
    required this.icon,
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
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: w * 0.028, color: color),
        SizedBox(width: w * 0.008),
        Text(
          label,
          style: TextStyle(
            fontSize:   w * 0.028,
            color:      color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}


// ── Custom app bar for category/detail pages ──────────────────────────────────
class _MasailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final bool   isRtl;
  final double w;

  const _MasailAppBar({
    required this.title,
    required this.subtitle,
    required this.isRtl,
    required this.w,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: const Color(0xFF4A1220),
    elevation:       0,
    leading: IconButton(
      icon: Icon(
        isRtl
            ? Icons.arrow_forward_ios_rounded
            : Icons.arrow_back_ios_new_rounded,
        color: Colors.white,
        size:  18,
      ),
      onPressed: () => Navigator.pop(context),
    ),
    titleSpacing: 0,
    title: Column(
      crossAxisAlignment:
      isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color:      Colors.white,
            fontSize:   w * 0.043,
            fontWeight: FontWeight.w700,
          ),
          maxLines:  1,
          overflow:  TextOverflow.ellipsis,
        ),
        Text(
          subtitle,
          style: TextStyle(
              color: const Color(0xFFD4AF37), fontSize: w * 0.028),
        ),
      ],
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(
          height: 1,
          color: const Color(0xFFD4AF37).withOpacity(0.2)),
    ),
  );
}


// ── Empty masail placeholder ──────────────────────────────────────────────────
class _EmptyMasail extends StatelessWidget {
  final double w, h;
  const _EmptyMasail({required this.w, required this.h});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(w * 0.06),
          decoration: const BoxDecoration(
            color:  Color(0x146B1E2E),
            shape:  BoxShape.circle,
          ),
          child: Icon(Icons.menu_book_rounded,
              size:  w * 0.14,
              color: const Color(0xFF6B1E2E).withOpacity(0.4)),
        ),
        SizedBox(height: h * 0.02),
        Text(
          'No Masail found',
          style: TextStyle(
            color:      const Color(0xFF9C7A82),
            fontSize:   w * 0.042,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}