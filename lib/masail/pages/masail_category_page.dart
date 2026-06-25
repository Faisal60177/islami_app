import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/masail_cubit.dart';
import '../model/masail_category_model.dart';
import 'package:muslim_app/utils/language_utils.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'category_masail_page.dart';

class MasailCategoryPage extends StatefulWidget {
  final String searchQuery;
  const MasailCategoryPage({super.key, required this.searchQuery});

  @override
  State<MasailCategoryPage> createState() => _MasailCategoryPageState();
}

class _MasailCategoryPageState extends State<MasailCategoryPage> {
  List<MasailCategoryModel> _categories = [];
  bool _isLoading = true;

  // ── Rich palette for category cards ──
  static const List<List<Color>> _cardGradients = [
    [Color(0xFF6B1E2E), Color(0xFF9B3040)],
    [Color(0xFF1E3A6B), Color(0xFF2E5499)],
    [Color(0xFF2D6B1E), Color(0xFF3D9B2A)],
    [Color(0xFF6B511E), Color(0xFF9B7730)],
    [Color(0xFF4A1E6B), Color(0xFF6B2E9B)],
    [Color(0xFF1E5F6B), Color(0xFF2E8A9B)],
    [Color(0xFF6B1E4A), Color(0xFF9B2E6B)],
    [Color(0xFF1E6B4A), Color(0xFF2E9B6B)],
  ];

  static const Color _bg      = Color(0xFFFAF6EF);
  static const Color _primary = Color(0xFF6B1E2E);
  static const Color _gold    = Color(0xFFD4AF37);
  static const Color _surface = Color(0xFFF2EBE0);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final cubit = context.read<MasailCubit>();
    final data  = await cubit.repository.getAllCategories(
      cubit.currentLanguageCode,
    );
    if (mounted) {
      setState(() {
        _categories = data;
        _isLoading  = false;
      });
    }
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'prayer':    return Icons.mosque_rounded;
      case 'fasting':   return Icons.nightlight_round;
      case 'zakat':     return Icons.volunteer_activism_rounded;
      case 'hajj':      return Icons.fort_rounded;
      case 'trade':     return Icons.storefront_rounded;
      case 'marriage':  return Icons.favorite_rounded;
      case 'food':      return Icons.restaurant_rounded;
      case 'purity':    return Icons.water_drop_rounded;
      case 'funeral':   return Icons.local_florist_rounded;
      case 'quran':     return Icons.menu_book_rounded;
      default:          return Icons.auto_stories_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit  = context.read<MasailCubit>();
    final isRtl  = LanguageUtils.isRtl(cubit.currentLanguageCode);
    final w      = MediaQuery.of(context).size.width;
    final h      = MediaQuery.of(context).size.height;
    final langCode = context.read<SettingsCubit>().state.languageCode;
    final l10n   = AppLocalizations(langCode);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: _primary, strokeWidth: 2.5,
        ),
      );
    }

    final categories = _categories
        .where((c) => c.categoryTitle
        .toLowerCase()
        .contains(widget.searchQuery.toLowerCase()))
        .toList();

    if (categories.isEmpty) {
      return _EmptyState(
        icon: Icons.category_outlined,
        title: l10n.noCategoriesFound,
        color: _primary,
      );
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: RefreshIndicator(
        color: _primary,
        onRefresh: _loadCategories,
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            // ── Section header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    w * 0.05, h * 0.022, w * 0.05, h * 0.012),
                child: Row(
                  textDirection:
                  isRtl ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _gold,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: w * 0.025),
                    Text(
                      '${categories.length} ${l10n.categories}',
                      style: TextStyle(
                        fontSize: w * 0.038,
                        color: const Color(0xFF5C3D44),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Category grid ──
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  w * 0.04, 0, w * 0.04, h * 0.04),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: w * 0.04,
                  mainAxisSpacing: w * 0.04,
                  childAspectRatio: 1.05,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final cat     = categories[index];
                    final colors  = _cardGradients[index % _cardGradients.length];
                    final iconData = _iconFor(cat.categoryIcon);

                    return _CategoryCard(
                      category:   cat,
                      colors:     colors,
                      iconData:   iconData,
                      isRtl:      isRtl,
                      index:      index,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CategoryMasailPage(category: cat),
                        ),
                      ),
                    );
                  },
                  childCount: categories.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Card ─────────────────────────────────────────────────────────────
class _CategoryCard extends StatefulWidget {
  final MasailCategoryModel category;
  final List<Color> colors;
  final IconData iconData;
  final bool isRtl;
  final int index;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.colors,
    required this.iconData,
    required this.isRtl,
    required this.index,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTapDown:    (_) => _ctrl.forward(),
      onTapUp:      (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel:  ()  => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.colors[0].withOpacity(0.38),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // ── Decorative half-circle ──
              Positioned(
                top: -w * 0.07,
                right: widget.isRtl ? null : -w * 0.07,
                left:  widget.isRtl ? -w * 0.07 : null,
                child: Container(
                  width:  w * 0.32,
                  height: w * 0.32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
              ),
              // ── Gold corner ornament ──
              Positioned(
                bottom: 0,
                left:   widget.isRtl ? null : 0,
                right:  widget.isRtl ? 0 : null,
                child: Container(
                  width:  w * 0.15,
                  height: w * 0.15,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: widget.isRtl
                        ? const BorderRadius.only(
                        topLeft:      Radius.circular(40),
                        bottomRight:  Radius.circular(20))
                        : const BorderRadius.only(
                        topRight:    Radius.circular(40),
                        bottomLeft:  Radius.circular(20)),
                  ),
                ),
              ),
              // ── Number badge ──
              Positioned(
                top:   h * 0.012,
                right: widget.isRtl ? null : w * 0.03,
                left:  widget.isRtl ? w * 0.03 : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // ── Content ──
              Padding(
                padding: EdgeInsets.all(w * 0.045),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon in ornamental box
                    Container(
                      padding: EdgeInsets.all(w * 0.03),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(widget.iconData,
                          color: Colors.white, size: w * 0.065),
                    ),
                    // Title + arrow
                    Column(
                      crossAxisAlignment: widget.isRtl
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.categoryTitle,
                          style: TextStyle(
                            color:      Colors.white,
                            fontSize:   w * 0.037,
                            fontWeight: FontWeight.w700,
                            height:     1.25,
                          ),
                          textAlign: widget.isRtl
                              ? TextAlign.right
                              : TextAlign.left,
                          maxLines:  2,
                          overflow:  TextOverflow.ellipsis,
                        ),
                        SizedBox(height: h * 0.006),
                        Row(
                          mainAxisAlignment: widget.isRtl
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Icon(
                              widget.isRtl
                                  ? Icons.arrow_back_rounded
                                  : Icons.arrow_forward_rounded,
                              size:  w * 0.032,
                              color: Colors.white.withOpacity(0.65),
                            ),
                            SizedBox(width: w * 0.008),
                            Text(
                              'View All', // l10n.viewAll
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: w * 0.027,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.06),
            decoration: BoxDecoration(
              color:  color.withOpacity(0.08),
              shape:  BoxShape.circle,
            ),
            child: Icon(icon, size: w * 0.14, color: color.withOpacity(0.5)),
          ),
          SizedBox(height: h * 0.022),
          Text(
            title,
            style: TextStyle(
              fontSize:   w * 0.042,
              color:      color.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}