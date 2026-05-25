import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/duas_cubit.dart';
import '../model/category_model.dart';
import 'package:muslim_app/utils/language_utils.dart';
import 'category_duas_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';

class CategoryPage extends StatefulWidget {
  final String searchQuery;
  const CategoryPage({super.key, required this.searchQuery});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  static const List<List<Color>> cardGradients = [
    [Color(0xFF0D6E6E), Color(0xFF1A9090)],
    [Color(0xFF2E6B8A), Color(0xFF3D8FB5)],
    [Color(0xFF6B4E2E), Color(0xFF9A7045)],
    [Color(0xFF1A7A5E), Color(0xFF2EA87F)],
    [Color(0xFF6B2E5E), Color(0xFF9A4585)],
    [Color(0xFF4E6B2E), Color(0xFF6E9A42)],
    [Color(0xFF2E4E6B), Color(0xFF3D6E8A)],
    [Color(0xFF6B5E2E), Color(0xFF9A8745)],
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final cubit = context.read<DuasCubit>();

    // ✅ pass currentLanguageCode — COALESCE resolves correct language
    final data = await cubit.repository.getAllCategories(
      cubit.currentLanguageCode,
    );
    setState(() {
      _categories = data;
      _isLoading = false;
    });
  }

  IconData _getCategoryIconData(String iconName) {
    switch (iconName) {
      case 'sun':        return Icons.wb_sunny_rounded;
      case 'moon':       return Icons.nights_stay_rounded;
      case 'star':       return Icons.star_rounded;
      case 'home':       return Icons.home_rounded;
      case 'food':       return Icons.restaurant_rounded;
      case 'travel':     return Icons.airplanemode_active_rounded;
      case 'prayer':     return Icons.mosque_rounded;
      case 'sleep':      return Icons.bedtime_rounded;
      case 'health':     return Icons.favorite_rounded;
      case 'rain':       return Icons.water_drop_rounded;
      case 'wind':       return Icons.air_rounded;
      case 'protection': return Icons.shield_rounded;
      default:           return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DuasCubit>();
    final isRtl = LanguageUtils.isRtl(cubit.currentLanguageCode);
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final langCode = context.read<SettingsCubit>().state.languageCode;
    final l10n = AppLocalizations(langCode);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0D6E6E),
          strokeWidth: 3,
        ),
      );
    }

    final categories = _categories
        .where((cat) => cat.categoryTitle
        .toLowerCase()
        .contains(widget.searchQuery.toLowerCase()))
        .toList();

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined,
                size: w * 0.15, color: Colors.grey[300]),
            SizedBox(height: h * 0.02),
            Text(
              l10n.noCategoriesFound,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: w * 0.045,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // ✅ Directionality wraps entire category grid
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: RefreshIndicator(
        onRefresh: _loadCategories,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    w * 0.05, h * 0.022, w * 0.05, h * 0.01),
                child: Text(
                  '${categories.length} ${l10n.categories}',
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    fontSize: w * 0.038,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  w * 0.04, 0, w * 0.04, h * 0.04),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: w * 0.04,
                  mainAxisSpacing: w * 0.04,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final cat = categories[index];
                    final gradientColors =
                    cardGradients[index % cardGradients.length];
                    final iconData = _getCategoryIconData(cat.categoryIcon);

                    return _CategoryCard(
                      category: cat,
                      gradientColors: gradientColors,
                      iconData: iconData,
                      isRtl: isRtl, // ✅ pass RTL flag to card
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CategoryDuasPage(category: cat),
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

class _CategoryCard extends StatefulWidget {
  final CategoryModel category;
  final List<Color> gradientColors;
  final IconData iconData;
  final bool isRtl; // ✅ NEW
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.gradientColors,
    required this.iconData,
    required this.isRtl,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final langCode = context.read<SettingsCubit>().state.languageCode;
    final l10n = AppLocalizations(langCode);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors[0].withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -w * 0.06,
                right: -w * 0.06,
                child: Container(
                  width: w * 0.3,
                  height: w * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
              ),
              Positioned(
                bottom: -w * 0.04,
                left: -w * 0.04,
                child: Container(
                  width: w * 0.2,
                  height: w * 0.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(w * 0.045),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(w * 0.028),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(widget.iconData,
                          color: Colors.white, size: w * 0.065),
                    ),
                    Column(
                      // ✅ align text to right for RTL languages
                      crossAxisAlignment: widget.isRtl
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.categoryTitle,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.038,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          textAlign: widget.isRtl
                              ? TextAlign.right
                              : TextAlign.left,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: h * 0.006),
                        Row(
                          // ✅ flip arrow direction for RTL
                          mainAxisAlignment: widget.isRtl
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Icon(
                              widget.isRtl
                                  ? Icons.arrow_back_rounded
                                  : Icons.arrow_forward_rounded,
                              size: w * 0.035,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            SizedBox(width: w * 0.01),
                            Text(
                              l10n.viewAll,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: w * 0.028,
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