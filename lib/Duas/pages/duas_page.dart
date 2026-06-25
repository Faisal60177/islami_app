import 'package:flutter/material.dart';
import 'all_duas_page.dart';
import 'category_page.dart';
import 'favorite_page.dart';
import 'bookmark_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import 'package:muslim_app/home/home_page.dart';
import 'package:muslim_app/tools/tools_page.dart';
import 'package:muslim_app/Quran/quran_page.dart';
import 'package:muslim_app/Menu/menu_page.dart';

class DuasPage extends StatefulWidget {
  const DuasPage({super.key});

  @override
  State<DuasPage> createState() => _DuasPageState();
}

class _DuasPageState extends State<DuasPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  // Active index = 3 (Duas is 4th in the nav)
  static const int _activeNavIndex = 3;

  static const List<Widget> _navPages = [
    PrayerTimesPage(),
    ToolsPage(),
    QuranPage(),
    DuasPage(),
    MenuPage(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    final settings = context.watch<SettingsCubit>().state;
    final langCode  = settings.languageCode;
    final l10n      = AppLocalizations(langCode);
    final isRtl     = l10n.isRtl;
    final theme     = getThemeById(settings.themeMode);

    final mq  = MediaQuery.of(context);
    final sw  = mq.size.width;
    final sh  = mq.size.height;
    final rsw = sw.clamp(320.0, 430.0);
    final rsh = sh.clamp(600.0, 960.0);

    final List<Map<String, dynamic>> tabs = [
      {'label': l10n.category, 'icon': Icons.grid_view_rounded},
      {'label': l10n.all,      'icon': Icons.auto_stories_rounded},
      {'label': l10n.favorite, 'icon': Icons.favorite_rounded},
      {'label': l10n.bookmark, 'icon': Icons.bookmark_rounded},
    ];

    final tabBarH = rsw * 0.048 + rsw * 0.028 + rsw * 0.036;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F3),
        // ── Bottom navigation — same as PrayerTimesPage ──────────────────
        bottomNavigationBar: _buildNav(
          context: context,
          sw: sw,
          rsw: rsw,
          theme: theme,
          l10n: l10n,
        ),
        body: Column(
          children: [
            // ── Pinned header — never scrolls ────────────────────────────
            _DuasHeader(
              rsw: rsw,
              rsh: rsh,
              isRtl: isRtl,
              l10n: l10n,
              statusBarH: mq.padding.top,
              searchController: _searchController,
              searchQuery: searchQuery,
            ),

            // ── Pinned tab bar ───────────────────────────────────────────
            _DuasTabBar(
              controller: _tabController,
              tabs: tabs,
              rsw: rsw,
              tabBarH: tabBarH,
            ),

            // ── Tab content — swipe restored ─────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  CategoryPage(searchQuery: searchQuery),
                  AllDuasPage(searchQuery: searchQuery),
                  FavoriteDuasPage(searchQuery: searchQuery),
                  BookmarkedDuasPage(searchQuery: searchQuery),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom nav (matches PrayerTimesPage exactly, active = Duas) ───────────
  Widget _buildNav({
    required BuildContext context,
    required double sw,
    required double rsw,
    required AppThemeOption theme,
    required AppLocalizations l10n,
  }) {
    final surface    = theme.surface;
    final accent     = theme.accent;
    final accentSoft = theme.primary.withOpacity(0.55);
    final textLo     = theme.textLow;

    final items = [
      (l10n.today, 'assets/icons/today.png'),
      (l10n.tools, 'assets/icons/tools.png'),
      (l10n.quran, 'assets/icons/quran.png'),
      (l10n.duas,  'assets/icons/duas.png'),
      (l10n.menu,  'assets/icons/menu.png'),
    ];

    final iconSz  = (sw * 0.058).clamp(22.0, 28.0);
    final labelSz = (sw * 0.024).clamp(9.0, 11.5);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          top: BorderSide(
              color: accentSoft.withOpacity(0.22), width: 0.8),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 20),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              final i      = e.key;
              final label  = e.value.$1;
              final asset  = e.value.$2;
              final active = i == _activeNavIndex;

              return GestureDetector(
                onTap: () {
                  if (active) return; // already here
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _navPages[i],
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.symmetric(
                    horizontal: rsw * 0.032,
                    vertical:   rsw * 0.016,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? accentSoft.withOpacity(0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(rsw * 0.038),
                    border: active
                        ? Border.all(
                      color: accentSoft.withOpacity(0.40),
                      width: 0.8,
                    )
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(asset,
                          width: iconSz, height: iconSz),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize:      labelSz,
                          fontWeight:    active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color:         active ? accent : textLo,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Pinned header ─────────────────────────────────────────────────────────────
class _DuasHeader extends StatelessWidget {
  final double rsw, rsh, statusBarH;
  final bool isRtl;
  final AppLocalizations l10n;
  final TextEditingController searchController;
  final String searchQuery;

  const _DuasHeader({
    required this.rsw,
    required this.rsh,
    required this.isRtl,
    required this.l10n,
    required this.statusBarH,
    required this.searchController,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final searchBarH = rsh * 0.060;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A5C5C), Color(0xFF0E8080)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── Decorative circles ────────────────────────────────────────
          Positioned(
            top: -rsw * 0.10,
            right: isRtl ? null : -rsw * 0.08,
            left:  isRtl ? -rsw * 0.08 : null,
            child: Container(
              width: rsw * 0.44, height: rsw * 0.44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.07), width: 2),
              ),
            ),
          ),
          Positioned(
            top: rsw * 0.08,
            right: isRtl ? null : rsw * 0.06,
            left:  isRtl ? rsw * 0.06 : null,
            child: Container(
              width: rsw * 0.20, height: rsw * 0.20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.09), width: 1.5),
              ),
            ),
          ),

          // ── Gold top accent line ──────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFD4AF37),
                    Color(0xFFF5D76E),
                    Color(0xFFD4AF37),
                  ],
                ),
              ),
            ),
          ),

          // ── Title + search ────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(
              top:    statusBarH + rsw * 0.030,
              left:   rsw * 0.045,
              right:  rsw * 0.045,
              bottom: rsw * 0.030,
            ),
            child: Column(
              crossAxisAlignment: isRtl
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row — no back button, nav handles navigation
                Row(
                  textDirection:
                  isRtl ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    Container(
                      padding: EdgeInsets.all(rsw * 0.022),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(rsw * 0.028),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: const Color(0xFFD4AF37),
                        size: rsw * 0.056,
                      ),
                    ),
                    SizedBox(width: rsw * 0.030),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: isRtl
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.duasAdhkar,
                            style: TextStyle(
                              color:      Colors.white,
                              fontSize:   rsw * 0.050,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              height: 1.15,
                            ),
                          ),
                          Text(
                            'الأدعية والأذكار',
                            style: TextStyle(
                              color:      const Color(0xFFD4AF37),
                              fontSize:   rsw * 0.034,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: rsw * 0.030),

                // Search bar
                Container(
                  height: searchBarH,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(rsw * 0.038),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.14),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    textDirection:
                    isRtl ? TextDirection.rtl : TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: l10n.searchDuasHint,
                      hintStyle: TextStyle(
                        color:      Colors.grey[400],
                        fontSize:   rsw * 0.035,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: rsw * 0.030),
                        child: Icon(
                          Icons.search_rounded,
                          color: const Color(0xFF0D6E6E),
                          size:  rsw * 0.050,
                        ),
                      ),
                      prefixIconConstraints:
                      BoxConstraints(minWidth: rsw * 0.14),
                      suffixIcon: searchQuery.isNotEmpty
                          ? GestureDetector(
                        onTap: () => searchController.clear(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: rsw * 0.025),
                          child: Icon(
                            Icons.close_rounded,
                            size:  rsw * 0.040,
                            color: Colors.grey[500],
                          ),
                        ),
                      )
                          : null,
                      suffixIconConstraints:
                      BoxConstraints(minWidth: rsw * 0.12),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: (searchBarH - rsw * 0.036) / 2,
                      ),
                    ),
                    style: TextStyle(
                      fontSize:   rsw * 0.036,
                      color:      Colors.black87,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pinned tab bar ────────────────────────────────────────────────────────────
class _DuasTabBar extends StatelessWidget {
  final TabController controller;
  final List<Map<String, dynamic>> tabs;
  final double rsw, tabBarH;

  const _DuasTabBar({
    required this.controller,
    required this.tabs,
    required this.rsw,
    required this.tabBarH,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: tabBarH,
      decoration: const BoxDecoration(
        color: Color(0xFF0B6464),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: controller,
        indicatorColor: const Color(0xFFD4AF37),
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        isScrollable: false,
        labelPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: List.generate(tabs.length, (index) {
          return AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              final isSelected = controller.index == index;
              return SizedBox(
                height: tabBarH,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tabs[index]['icon'] as IconData,
                      size: rsw * 0.046,
                      color: isSelected
                          ? const Color(0xFFD4AF37)
                          : Colors.white.withOpacity(0.50),
                    ),
                    SizedBox(height: rsw * 0.007),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFD4AF37)
                            : Colors.white.withOpacity(0.50),
                        fontSize:   rsw * 0.027,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                      child: Text(tabs[index]['label'] as String),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}