import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/duas_cubit.dart';
import '../model/duas_model.dart';
import 'package:muslim_app/utils/language_utils.dart';
import 'duas_detail_page.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';

class AllDuasPage extends StatefulWidget {
  final String searchQuery;
  const AllDuasPage({super.key, required this.searchQuery});

  @override
  State<AllDuasPage> createState() => _AllDuasPageState();
}

class _AllDuasPageState extends State<AllDuasPage>
    with AutomaticKeepAliveClientMixin {
  List<DuasModel> allDuas = [];
  bool isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadDuas();
  }

  Future<void> loadDuas() async {
    final cubit = context.read<DuasCubit>();

    // ✅ getAllDuas also needs languageCode now
    final duas = await cubit.repository.getAllDuas(
      languageCode: cubit.currentLanguageCode,
      userId:       cubit.userId,
    );
    setState(() {
      allDuas = duas;
      isLoading = false;
    });
  }

  List<DuasModel> get filteredDuas {
    if (widget.searchQuery.isEmpty) return allDuas;
    final query = widget.searchQuery.toLowerCase();
    return allDuas
        .where((dua) =>
    dua.arabic.toLowerCase().contains(query) ||
        dua.title.toLowerCase().contains(query) ||
        dua.transliteration.toLowerCase().contains(query) ||
        dua.categoryTitle.toLowerCase().contains(query))
        .toList();
  }

  String getShortDescription(String text, [int limit = 55]) {
    if (text.length <= limit) return text;
    return '${text.substring(0, limit)}...';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cubit = context.read<DuasCubit>();
    final isRtl = LanguageUtils.isRtl(cubit.currentLanguageCode);
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    // ✅ theme
    final settings = context.watch<SettingsCubit>().state;
    final theme = getThemeById(settings.themeMode);

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: w * 0.12,
              height: w * 0.12,
              child: CircularProgressIndicator(
                color: theme.accent,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: h * 0.02),
            Text(
              'Loading duas...',
              style: TextStyle(color: theme.textLow, fontSize: w * 0.038),
            ),
          ],
        ),
      );
    }

    if (filteredDuas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: w * 0.15, color: theme.textLow.withOpacity(0.4)),
            SizedBox(height: h * 0.02),
            Text(
              'No duas found',
              style: TextStyle(
                color: theme.textLow,
                fontSize: w * 0.045,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // ✅ Directionality wraps entire list
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: ListView.builder(
        padding:
        EdgeInsets.fromLTRB(w * 0.04, h * 0.018, w * 0.04, h * 0.03),
        itemCount: filteredDuas.length,
        itemBuilder: (context, index) {
          final dua = filteredDuas[index];
          return _DuaCard(
            dua: dua,
            index: index,
            isRtl: isRtl,
            theme: theme,
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
    );
  }
}

class _DuaCard extends StatefulWidget {
  final DuasModel dua;
  final int index;
  final bool isRtl;
  final AppThemeOption theme;
  final VoidCallback onTap;

  const _DuaCard({
    required this.dua,
    required this.index,
    required this.isRtl,
    required this.theme,
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

  // ✅ Optimistic toggle directly on card
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
    final theme = widget.theme;
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
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.isDark ? 0.20 : 0.055),
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
          splashColor: theme.accent.withOpacity(0.08),
          highlightColor: theme.accent.withOpacity(0.04),
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
                            color: theme.textHigh,
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
                            color: theme.textLow,
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
                              color: theme.accent.withOpacity(0.09),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.label_rounded,
                                    size: w * 0.03,
                                    color: theme.accent),
                                SizedBox(width: w * 0.01),
                                Text(
                                  dua.categoryTitle,
                                  style: TextStyle(
                                    fontSize: w * 0.03,
                                    color: theme.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // ✅ Inline favorite/bookmark toggles
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
                                      : theme.textLow.withOpacity(0.5),
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
                                      : theme.textLow.withOpacity(0.5),
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
                    color: theme.textLow.withOpacity(0.5), size: w * 0.055),
              ],
            ),
          ),
        ),
      ),
    );
  }
}