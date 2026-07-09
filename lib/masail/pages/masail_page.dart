import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import 'masail_category_page.dart';
import 'all_masail_page.dart';
import 'bookmarked_masail_page.dart';
import 'package:muslim_app/masail/cubit/masail_cubit.dart';

class MasailPage extends StatefulWidget {
  const MasailPage({super.key});

  @override
  State<MasailPage> createState() => _MasailPageState();
}

class _MasailPageState extends State<MasailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text);
    });
    context.read<MasailCubit>().loadCategoriesIfEmpty();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme    = getThemeById(context.watch<SettingsCubit>().state.themeMode);
    final langCode = context.watch<SettingsCubit>().state.languageCode;
    final l10n     = AppLocalizations(langCode);
    final isRtl    = l10n.isRtl;

    final size = MediaQuery.of(context).size;
    final sw   = size.width;
    final sh   = size.height;

    final tabs = [
      {'label': l10n.category, 'icon': Icons.grid_view_rounded},
      {'label': l10n.all,      'icon': Icons.menu_book_rounded},
      {'label': l10n.bookmark, 'icon': Icons.bookmark_rounded},
    ];

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.background,
        body: Column(
          children: [
            // ── Pinned Header ──────────────────────────────────────────
            _MasailHeader(
              sw: sw, sh: sh,
              isRtl: isRtl,
              theme: theme,
              searchController: _searchController,
              searchQuery: searchQuery,
            ),

            // ── Pinned Tab Bar ─────────────────────────────────────────
            Container(
              color: theme.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: theme.accent,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
                isScrollable: false,
                labelPadding: EdgeInsets.zero,
                dividerColor: Colors.transparent,
                tabs: List.generate(tabs.length, (i) {
                  final isSelected = _tabController.index == i;
                  return SizedBox(
                    height: sh * 0.062,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tabs[i]['icon'] as IconData,
                          size: sw * 0.046,
                          color: isSelected ? theme.accent : theme.textLow,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tabs[i]['label'] as String,
                          style: TextStyle(
                            color: isSelected ? theme.accent : theme.textLow,
                            fontSize: sw * 0.027,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            // ── Tab Content — no bounce ────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const ClampingScrollPhysics(), // ✅ no bounce
                children: [
                  MasailCategoryPage(searchQuery: searchQuery),
                  AllMasailPage(searchQuery: searchQuery),
                  BookmarkedMasailPage(searchQuery: searchQuery),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pinned Header ─────────────────────────────────────────────────────────────
class _MasailHeader extends StatelessWidget {
  final double sw, sh;
  final bool isRtl;
  final AppThemeOption theme;
  final TextEditingController searchController;
  final String searchQuery;

  const _MasailHeader({
    required this.sw,
    required this.sh,
    required this.isRtl,
    required this.theme,
    required this.searchController,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary, theme.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // ── Islamic geometric pattern overlay ──
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: CustomPaint(painter: _GeometricPatternPainter()),
            ),
          ),
          // ── Top border ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.accent.withOpacity(0.7),
                    theme.accent,
                    theme.accent.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          // ── Decorative circles ──
          Positioned(
            top: -sw * 0.15,
            right: isRtl ? null : -sw * 0.1,
            left:  isRtl ? -sw * 0.1 : null,
            child: Container(
              width: sw * 0.5, height: sw * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.1), width: 1.5),
              ),
            ),
          ),
          Positioned(
            bottom: sw * 0.04,
            left: isRtl ? null : -sw * 0.08,
            right: isRtl ? -sw * 0.08 : null,
            child: Container(
              width: sw * 0.32, height: sw * 0.32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
                border: Border.all(
                    color: Colors.white.withOpacity(0.08), width: 1),
              ),
            ),
          ),
          // ── Content ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  sw * 0.05, sh * 0.015, sw * 0.05, sw * 0.04),
              child: Column(
                crossAxisAlignment: isRtl
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    textDirection:
                    isRtl ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        child: Icon(Icons.auto_stories_rounded,
                            color: Colors.white, size: sw * 0.06),
                      ),
                      SizedBox(width: sw * 0.03),
                      Column(
                        crossAxisAlignment: isRtl
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Masail',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sw * 0.058,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'مسائل فقہیہ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: sw * 0.038,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: sh * 0.018),
                  // ── Search bar ──
                  Container(
                    height: sh * 0.052,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 1),
                    ),
                    child: TextField(
                      controller: searchController,
                      textDirection:
                      isRtl ? TextDirection.rtl : TextDirection.ltr,
                      style: TextStyle(
                          color: Colors.white, fontSize: sw * 0.036),
                      decoration: InputDecoration(
                        hintText: 'Search masail...',
                        hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: sw * 0.035),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: Colors.white.withOpacity(0.85),
                            size: sw * 0.05),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white54),
                          onPressed: () => searchController.clear(),
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                        EdgeInsets.symmetric(vertical: sh * 0.012),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Islamic Geometric Pattern Painter ─────────────────────────────────────────
class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const step = 40.0;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        final cx = x + (y / step % 2 == 0 ? 0 : step / 2);
        final path = Path();
        for (int k = 0; k < 8; k++) {
          final angle = k * 3.14159 / 4;
          final r = k % 2 == 0 ? 10.0 : 5.0;
          final px = cx + r * (k == 0 ? 1 : _cos(angle));
          final py = y  + r * _sin(angle);
          k == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  double _cos(double a) => a == 0 ? 1 : (a == 3.14159 / 2 ? 0 :
  (a == 3.14159 ? -1 : (a == 3 * 3.14159 / 2 ? 0 :
  (a < 3.14159 / 2 ? 1 - a * a / 2 : -1 + (a - 3.14159) * (a - 3.14159) / 2))));
  double _sin(double a) => a == 0 ? 0 : (a == 3.14159 / 2 ? 1 :
  (a == 3.14159 ? 0 : (a == 3 * 3.14159 / 2 ? -1 : a - a * a * a / 6)));

  @override
  bool shouldRepaint(_) => false;
}