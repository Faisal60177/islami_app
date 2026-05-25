import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/category_model.dart';
import '../model/duas_model.dart';
import '../cubit/duas_cubit.dart';
import 'package:muslim_app/utils/language_utils.dart';
import 'duas_detail_page.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';

class CategoryDuasPage extends StatefulWidget {
  final CategoryModel category;
  const CategoryDuasPage({super.key, required this.category});

  @override
  State<CategoryDuasPage> createState() => _CategoryDuasPageState();
}

class _CategoryDuasPageState extends State<CategoryDuasPage> {
  List<DuasModel> duas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDuas();
  }

  Future<void> loadDuas() async {
    setState(() => isLoading = true);
    try {
      final cubit = context.read<DuasCubit>();
      final data = await cubit.repository.getDuasByCategory(
        categoryId:   widget.category.categoryId,
        languageCode: cubit.currentLanguageCode,
        userId:       cubit.userId,
      );
      setState(() {
        duas = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ loadDuas error: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DuasCubit>();
    final isRtl = LanguageUtils.isRtl(cubit.currentLanguageCode);
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.category.categoryTitle,
            style: TextStyle(fontSize: w * 0.05),
          ),
        ),
        body: isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0D6E6E),
            strokeWidth: 3,
          ),
        )
            : duas.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_rounded,
                  size: w * 0.15, color: Colors.grey[300]),
              SizedBox(height: h * 0.02),
              Text(
                'No Duas in this category',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: loadDuas,
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
                w * 0.04, h * 0.018, w * 0.04, h * 0.03),
            itemCount: duas.length,
            itemBuilder: (context, index) {
              final dua = duas[index];
              return _DuaCard(
                dua: dua,
                index: index,
                isRtl: isRtl,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DuasDetailPage(dua: dua),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Exact same _DuaCard from AllDuasPage ────────────────────────────────────

class _DuaCard extends StatefulWidget {
  final DuasModel dua;
  final int index;
  final bool isRtl;
  final VoidCallback onTap;

  const _DuaCard({
    required this.dua,
    required this.index,
    required this.isRtl,
    required this.onTap,
  });

  @override
  State<_DuaCard> createState() => _DuaCardState();
}

class _DuaCardState extends State<_DuaCard> {
  String getShortDescription(String text, [int limit = 55]) {
    if (text.length <= limit) return text;
    return '${text.substring(0, limit)}...';
  }

  void _toggleFavorite() {
    setState(() => widget.dua.isFavorite = !widget.dua.isFavorite);
    context.read<DuasCubit>().toggleFavorite(widget.dua);
  }

  void _toggleBookmark() {
    setState(() => widget.dua.isBookmarked = !widget.dua.isBookmarked);
    context.read<DuasCubit>().toggleBookmark(widget.dua);
  }

  @override
  Widget build(BuildContext context) {
    final dua   = widget.dua;
    final index = widget.index;
    final isRtl = widget.isRtl;
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final List<Color> avatarColors = [
      const Color(0xFF0D6E6E),
      const Color(0xFF1A7A5E),
      const Color(0xFF2E6B8A),
      const Color(0xFF6B5E2E),
    ];
    final accentColor = avatarColors[index % avatarColors.length];

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.014),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: const Color(0xFF0D6E6E).withOpacity(0.08),
          highlightColor: const Color(0xFF0D6E6E).withOpacity(0.04),
          onTap: widget.onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: h * 0.016,
            ),
            child: Row(
              children: [
                Container(
                  width: w * 0.12,
                  height: w * 0.12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      dua.id.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w700,
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
                          getShortDescription(dua.arabic),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: w * 0.042,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A2B2B),
                            height: 1.4,
                            fontFamily: 'Amiri',
                          ),
                        ),
                      ),
                      if (dua.title.isNotEmpty)
                        Text(
                          dua.title,
                          textAlign: isRtl ? TextAlign.right : TextAlign.left,
                          style: TextStyle(
                            fontSize: w * 0.032,
                            color: Colors.black54,
                          ),
                        ),
                      SizedBox(height: h * 0.006),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: w * 0.025,
                              vertical: h * 0.004,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D6E6E).withOpacity(0.09),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.label_rounded,
                                    size: w * 0.03,
                                    color: const Color(0xFF0D6E6E)),
                                SizedBox(width: w * 0.01),
                                Text(
                                  dua.categoryTitle,
                                  style: TextStyle(
                                    fontSize: w * 0.03,
                                    color: const Color(0xFF0D6E6E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _toggleFavorite,
                                child: Icon(
                                  dua.isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_outline_rounded,
                                  color: dua.isFavorite
                                      ? const Color(0xFFE57373)
                                      : Colors.grey[350],
                                  size: w * 0.05,
                                ),
                              ),
                              SizedBox(width: w * 0.02),
                              GestureDetector(
                                onTap: _toggleBookmark,
                                child: Icon(
                                  dua.isBookmarked
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_outline_rounded,
                                  color: dua.isBookmarked
                                      ? const Color(0xFF64B5F6)
                                      : Colors.grey[350],
                                  size: w * 0.05,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: w * 0.02),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[350], size: w * 0.055),
              ],
            ),
          ),
        ),
      ),
    );
  }
}