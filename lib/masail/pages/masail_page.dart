import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'masail_category_page.dart';
import 'all_masail_page.dart';
import 'bookmarked_masail_page.dart';

class MasailPage extends StatefulWidget {
  const MasailPage({super.key});

  @override
  State<MasailPage> createState() => _MasailPageState();
}

class _MasailPageState extends State<MasailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  // ── Masail color palette (warm parchment / manuscript) ──
  static const Color _bg         = Color(0xFFFAF6EF);
  static const Color _primary    = Color(0xFF6B1E2E); // deep burgundy
  static const Color _primaryDk  = Color(0xFF4A1220);
  static const Color _gold       = Color(0xFFB8860B);
  static const Color _goldLight  = Color(0xFFD4AF37);
  static const Color _surface    = Color(0xFFF2EBE0);
  static const Color _textHi     = Color(0xFF1C0A0F);
  static const Color _textMid    = Color(0xFF5C3D44);

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.watch<SettingsCubit>().state.languageCode;
    final l10n     = AppLocalizations(langCode);
    final isRtl    = l10n.isRtl;

    final size = MediaQuery.of(context).size;
    final sw   = size.width;
    final sh   = size.height;

    final tabs = [
      {'label': l10n.category,  'icon': Icons.grid_view_rounded},
      {'label': l10n.all,       'icon': Icons.menu_book_rounded},
      {'label': l10n.bookmark,  'icon': Icons.bookmark_rounded},
    ];

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: sh * 0.24,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: _primaryDk,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4A1220), Color(0xFF7B2235)],
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
                          child: CustomPaint(
                            painter: _GeometricPatternPainter(),
                          ),
                        ),
                      ),
                      // ── Gold top border ──
                      Positioned(
                        top: 0, left: 0, right: 0,
                        child: Container(
                          height: 3,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFB8860B),
                                Color(0xFFD4AF37),
                                Color(0xFFB8860B),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // ── Gold bottom border ──
                      Positioned(
                        bottom: sh * 0.065, left: 0, right: 0,
                        child: Container(
                          height: 1,
                          color: _goldLight.withOpacity(0.25),
                        ),
                      ),
                      // ── Decorative arch circles ──
                      Positioned(
                        top: -sw * 0.15,
                        right: isRtl ? null : -sw * 0.1,
                        left:  isRtl ? -sw * 0.1 : null,
                        child: Container(
                          width: sw * 0.5, height: sw * 0.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _goldLight.withOpacity(0.1),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: sh * 0.07,
                        left: isRtl ? null : -sw * 0.08,
                        right: isRtl ? -sw * 0.08 : null,
                        child: Container(
                          width: sw * 0.32, height: sw * 0.32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.03),
                            border: Border.all(
                              color: _goldLight.withOpacity(0.08),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      // ── Header content ──
                      Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + sh * 0.015,
                          left: sw * 0.05,
                          right: sw * 0.05,
                        ),
                        child: Column(
                          crossAxisAlignment: isRtl
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Row(
                              textDirection: isRtl
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              children: [
                                // ── Ornamental icon box ──
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: _goldLight.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _goldLight.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.auto_stories_rounded,
                                    color: _goldLight,
                                    size: sw * 0.06,
                                  ),
                                ),
                                SizedBox(width: sw * 0.03),
                                Column(
                                  crossAxisAlignment: isRtl
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Masail', // replace with l10n.masail
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: sw * 0.058,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      'مسائل فقہیہ', // always Arabic
                                      style: TextStyle(
                                        color: _goldLight,
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
                                  color: _goldLight.withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                textDirection: isRtl
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: sw * 0.036,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search masail...', // l10n
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    fontSize: sw * 0.035,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: _goldLight,
                                    size: sw * 0.05,
                                  ),
                                  suffixIcon: searchQuery.isNotEmpty
                                      ? IconButton(
                                    icon: Icon(Icons.close_rounded,
                                        size: sw * 0.042,
                                        color: Colors.white54),
                                    onPressed: () =>
                                        _searchController.clear(),
                                  )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: sh * 0.012),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(sh * 0.062),
                child: Container(
                  color: _primaryDk,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: _goldLight,
                    indicatorWeight: 2.5,
                    indicatorSize: TabBarIndicatorSize.label,
                    isScrollable: false,
                    labelPadding: EdgeInsets.zero,
                    tabs: List.generate(tabs.length, (i) {
                      final isSelected = _tabController.index == i;
                      return Tab(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                              horizontal: sw * 0.015),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                tabs[i]['icon'] as IconData,
                                size: sw * 0.046,
                                color: isSelected
                                    ? _goldLight
                                    : Colors.white.withOpacity(0.45),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tabs[i]['label'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? _goldLight
                                      : Colors.white.withOpacity(0.45),
                                  fontSize: sw * 0.027,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: [
              MasailCategoryPage(searchQuery: searchQuery),
              AllMasailPage(searchQuery: searchQuery),
              BookmarkedMasailPage(searchQuery: searchQuery),
            ],
          ),
        ),
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
        // Draw small 8-point star
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