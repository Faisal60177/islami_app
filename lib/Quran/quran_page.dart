import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:islamic_app/settings/cubit/settings_cubit.dart';
import 'package:islamic_app/settings/cubit/settings_state.dart';
import 'package:islamic_app/settings/theme/app_themes.dart';
import 'cubit/quran_cubit.dart';
import 'cubit/quran_state.dart';
import 'repository/quran_repository.dart';
import 'pages/surah_list_tab.dart';
import 'pages/para_list_tab.dart';
import 'pages/bookmark_tab.dart';
import 'pages/search_tab.dart';
import 'pages/last_read_tab.dart';
import 'package:islamic_app/home/home_page.dart';
import 'package:islamic_app/tools/tools_page.dart';
import 'package:islamic_app/Duas/pages/duas_page.dart';
import 'package:islamic_app/Menu/menu_page.dart';

class QuranPage extends StatelessWidget {
  const QuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuranCubit(QuranRepository())..init(),
      child: const _QuranPageBody(),
    );
  }
}

class _QuranPageBody extends StatefulWidget {
  const _QuranPageBody();

  @override
  State<_QuranPageBody> createState() => _QuranPageBodyState();
}

class _QuranPageBodyState extends State<_QuranPageBody>
    with TickerProviderStateMixin {
  // Tab indices:
  // 0 = Search, 1 = Last Read, 2 = Surah, 3 = Para, 4 = Bookmark
  late TabController _tabCtrl;

  final List<Widget> _navPages = const [
    PrayerTimesPage(),
    ToolsPage(),
    QuranPage(),
    DuasPage(),
    MenuPage(),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this, initialIndex: 2);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (ctx, settings) {
        final theme = getThemeById(settings.themeMode);
        final mq    = MediaQuery.of(context);
        final sw    = mq.size.width;
        final rsw   = sw.clamp(320.0, 420.0);

        return Scaffold(
          backgroundColor: theme.background,
          body: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              _QuranHeader(theme: theme, rsw: rsw, mq: mq),

              // ── Tab bar ─────────────────────────────────────────────
              _QuranTabBar(
                ctrl: _tabCtrl,
                theme: theme,
                rsw: rsw,
              ),

              // ── Tab content ─────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: const [
                    SearchTab(),
                    LastReadTab(),
                    SurahListTab(),
                    ParaListTab(),
                    BookmarkTab(),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildNav(context, theme, rsw, sw),
        );
      },
    );
  }

  Widget _buildNav(BuildContext context, AppThemeOption theme,
      double rsw, double sw) {
    final items = [
      ('Today', 'assets/icons/today.png'),
      ('Tools', 'assets/icons/tools.png'),
      ('Quran', 'assets/icons/quran.png'),
      ('Duas',  'assets/icons/duas.png'),
      ('Menu',  'assets/icons/menu.png'),
    ];
    final iconSz  = (sw * 0.058).clamp(22.0, 28.0);
    final labelSz = (sw * 0.024).clamp(9.0, 11.5);

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
            top: BorderSide(color: theme.accent.withOpacity(0.18), width: 0.8)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
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
              final active = i == 2;
              return GestureDetector(
                onTap: () {
                  if (!active) {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => _navPages[i]));
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.symmetric(
                      horizontal: rsw * 0.028, vertical: rsw * 0.014),
                  decoration: BoxDecoration(
                    color: active
                        ? theme.accent.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(rsw * 0.034),
                    border: active
                        ? Border.all(
                        color: theme.accent.withOpacity(0.35), width: 0.8)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(asset, width: iconSz, height: iconSz),
                      const SizedBox(height: 3),
                      Text(label,
                          style: TextStyle(
                            fontSize: labelSz,
                            fontWeight:
                            active ? FontWeight.w700 : FontWeight.w400,
                            color: active ? theme.accent : theme.textLow,
                          )),
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

// ── Quran header ──────────────────────────────────────────────────────────────
class _QuranHeader extends StatelessWidget {
  final AppThemeOption theme;
  final double rsw;
  final MediaQueryData mq;

  const _QuranHeader({
    required this.theme,
    required this.rsw,
    required this.mq,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          bottom:
          BorderSide(color: theme.accent.withOpacity(0.15), width: 0.8),
        ),
      ),
      padding: EdgeInsets.only(
        top: mq.padding.top + rsw * 0.025,
        left: rsw * 0.045,
        right: rsw * 0.045,
        bottom: rsw * 0.028,
      ),
      child: Row(
        children: [
          // Mosque icon
          Container(
            width: rsw * 0.115,
            height: rsw * 0.115,
            decoration: BoxDecoration(
              color: theme.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(rsw * 0.028),
              border:
              Border.all(color: theme.accent.withOpacity(0.25), width: 0.8),
            ),
            child: Center(
              child: Text('📖',
                  style: TextStyle(fontSize: rsw * 0.052)),
            ),
          ),
          SizedBox(width: rsw * 0.030),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'القرآن الكريم',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    color: theme.accent,
                    fontSize: rsw * 0.050,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                Text(
                  'The Holy Quran · 15-line Mushaf',
                  style: TextStyle(
                    color: theme.textLow,
                    fontSize: rsw * 0.026,
                  ),
                ),
              ],
            ),
          ),

          // Bookmark count badge
          BlocBuilder<QuranCubit, QuranState>(
            builder: (_, state) {
              final bCount =
              state is QuranLoaded ? state.bookmarks.length : 0;
              return Container(
                padding: EdgeInsets.symmetric(
                    horizontal: rsw * 0.022, vertical: rsw * 0.010),
                decoration: BoxDecoration(
                  color: theme.accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(rsw * 0.035),
                  border: Border.all(
                      color: theme.accent.withOpacity(0.28), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_rounded,
                        color: theme.accent, size: rsw * 0.032),
                    SizedBox(width: rsw * 0.010),
                    Text(
                      '$bCount',
                      style: TextStyle(
                        color: theme.accent,
                        fontSize: rsw * 0.028,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────
class _QuranTabBar extends StatelessWidget {
  final TabController ctrl;
  final AppThemeOption theme;
  final double rsw;

  const _QuranTabBar({
    required this.ctrl,
    required this.theme,
    required this.rsw,
  });

  @override
  Widget build(BuildContext context) {
    // Row 1: Search | Last Read (full width, equal)
    // Row 2: Surah | Para | Bookmark (full width, equal)
    return Container(
      color: theme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row 1: Search + Last Read ────────────────────────────
          Row(
            children: [
              _TabBtn(
                ctrl: ctrl,
                index: 0,
                icon: Icons.search_rounded,
                label: 'Search',
                theme: theme,
                rsw: rsw,
                isFirst: true,
                flex: 1,
              ),
              Container(
                  width: 0.8,
                  height: rsw * 0.10,
                  color: theme.accent.withOpacity(0.12)),
              _TabBtn(
                ctrl: ctrl,
                index: 1,
                icon: Icons.history_rounded,
                label: 'Last Read',
                theme: theme,
                rsw: rsw,
                isFirst: false,
                flex: 1,
              ),
            ],
          ),

          Divider(
              height: 0.8,
              thickness: 0.8,
              color: theme.accent.withOpacity(0.12)),

          // ── Row 2: Surah | Para | Bookmark ──────────────────────
          Row(
            children: [
              _TabBtn(
                ctrl: ctrl,
                index: 2,
                icon: Icons.menu_book_rounded,
                label: 'Surah',
                theme: theme,
                rsw: rsw,
                isFirst: true,
                flex: 1,
              ),
              Container(
                  width: 0.8,
                  height: rsw * 0.10,
                  color: theme.accent.withOpacity(0.12)),
              _TabBtn(
                ctrl: ctrl,
                index: 3,
                icon: Icons.layers_rounded,
                label: 'Para',
                theme: theme,
                rsw: rsw,
                isFirst: false,
                flex: 1,
              ),
              Container(
                  width: 0.8,
                  height: rsw * 0.10,
                  color: theme.accent.withOpacity(0.12)),
              _TabBtn(
                ctrl: ctrl,
                index: 4,
                icon: Icons.bookmark_rounded,
                label: 'Bookmark',
                theme: theme,
                rsw: rsw,
                isFirst: false,
                flex: 1,
              ),
            ],
          ),

          // Active indicator line
          AnimatedBuilder(
            animation: ctrl,
            builder: (_, __) {
              return Container(
                height: 2.5,
                decoration: BoxDecoration(
                  color: theme.accent.withOpacity(0.15),
                ),
                child: Align(
                  alignment: ctrl.index == 0
                      ? Alignment.centerLeft
                      : ctrl.index == 1
                      ? Alignment.centerRight
                      : ctrl.index == 2
                      ? Alignment(-0.67, 0)
                      : ctrl.index == 3
                      ? Alignment(0, 0)
                      : Alignment(0.67, 0),
                  child: FractionallySizedBox(
                    widthFactor: ctrl.index < 2 ? 0.5 : 1 / 3,
                    child: Container(
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: theme.accent,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2)),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final TabController ctrl;
  final int index;
  final IconData icon;
  final String label;
  final AppThemeOption theme;
  final double rsw;
  final bool isFirst;
  final int flex;

  const _TabBtn({
    required this.ctrl,
    required this.index,
    required this.icon,
    required this.label,
    required this.theme,
    required this.rsw,
    required this.isFirst,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) {
          final active = ctrl.index == index;
          return GestureDetector(
            onTap: () => ctrl.animateTo(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(vertical: rsw * 0.024),
              decoration: BoxDecoration(
                color: active
                    ? theme.accent.withOpacity(0.08)
                    : Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: rsw * 0.038,
                    color: active ? theme.accent : theme.textLow,
                  ),
                  SizedBox(width: rsw * 0.012),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: rsw * 0.028,
                        fontWeight:
                        active ? FontWeight.w700 : FontWeight.w400,
                        color: active ? theme.accent : theme.textLow,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}