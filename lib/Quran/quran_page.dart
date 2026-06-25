import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import 'cubit/quran_cubit.dart';
import 'cubit/quran_state.dart';
import 'repository/quran_repository.dart';
import 'pages/surah_list_tab.dart';
import 'pages/para_list_tab.dart';
import 'pages/bookmark_tab.dart';
import 'pages/search_tab.dart';
import 'pages/quran_reader_page.dart';
import 'package:muslim_app/home/home_page.dart';
import 'package:muslim_app/tools/tools_page.dart';
import 'package:muslim_app/Duas/pages/duas_page.dart';
import 'package:muslim_app/Menu/menu_page.dart';
import 'pages/quran_download_screen.dart';
import 'services/quran_download_service.dart';

class QuranPage extends StatelessWidget {
  const QuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: QuranDownloadService.isDownloadComplete(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return BlocProvider(
            create: (_) => QuranCubit(QuranRepository())..init(),
            child: const _QuranPageBody(),
          );
        } else {
          return BlocProvider(
            create: (_) => QuranCubit(QuranRepository())..init(),
            child: const QuranDownloadScreen(),
          );
        }
      },
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
  // Tab indices: 0 = Surah, 1 = Para, 2 = Bookmark
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
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _openSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<QuranCubit>(),
          child: const SearchOverlayPage(),
        ),
      ),
    );
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
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────
                _QuranHeader(
                  theme: theme,
                  rsw: rsw,
                  onSearchTap: () => _openSearch(context),
                ),

                // ── Scrollable content ───────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        // Quick action cards
                        _QuickActionsRow(theme: theme, rsw: rsw),

                        SizedBox(height: rsw * 0.030),

                        // Tab bar
                        _QuranTabBar(ctrl: _tabCtrl, theme: theme, rsw: rsw),

                        // Tab content
                        SizedBox(
                          height: mq.size.height * 0.62,
                          child: TabBarView(
                            controller: _tabCtrl,
                            children: const [
                              SurahListTab(),
                              ParaListTab(),
                              BookmarkTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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

// ── Quran header ─────────────────────────────────────────────────────────────
class _QuranHeader extends StatelessWidget {
  final AppThemeOption theme;
  final double rsw;
  final VoidCallback onSearchTap;

  const _QuranHeader({
    required this.theme,
    required this.rsw,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          bottom: BorderSide(color: theme.accent.withOpacity(0.12), width: 0.8),
        ),
      ),
      // ✅ extra vertical padding so it doesn't feel cramped against the cards below
      padding: EdgeInsets.fromLTRB(
        rsw * 0.045,
        rsw * 0.045,
        rsw * 0.045,
        rsw * 0.045,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Hifz Quran',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.accent,
                fontSize: rsw * 0.054,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              padding: EdgeInsets.all(rsw * 0.018),
              child: Icon(Icons.search_rounded,
                  color: theme.accent, size: rsw * 0.062),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick action cards row — Last Read + Go to Page only ──────────────────────
class _QuickActionsRow extends StatelessWidget {
  final AppThemeOption theme;
  final double rsw;

  const _QuickActionsRow({required this.theme, required this.rsw});

  void _goToLastRead(BuildContext context, int lastReadPage,
      List<dynamic> surahs) {
    if (surahs.isEmpty) return;
    var s = surahs.first;
    for (final x in surahs) {
      if (x.page <= lastReadPage) s = x;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<QuranCubit>(),
          child: QuranReaderPage(initialPage: lastReadPage, surah: s),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranCubit, QuranState>(
      builder: (_, state) {
        final lastReadPage = state is QuranLoaded ? state.lastReadPage : 3;
        final surahs       = state is QuranLoaded ? state.surahs : const [];

        return Padding(
          // ✅ gap from header above
          padding: EdgeInsets.fromLTRB(
            rsw * 0.040,
            rsw * 0.022,
            rsw * 0.040,
            rsw * 0.010,
          ),
          child: Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.menu_book_rounded,
                  label: 'Last Read',
                  theme: theme,
                  rsw: rsw,
                  onTap: () =>
                      _goToLastRead(context, lastReadPage, surahs),
                ),
              ),
              SizedBox(width: rsw * 0.028),
              Expanded(
                child: _ActionCard(
                  icon: Icons.tag_rounded,
                  label: 'Go to Page',
                  theme: theme,
                  rsw: rsw,
                  onTap: () => _showGoToPageSheet(context, theme, rsw, surahs),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ Fixed: now correctly finds the surah and pushes QuranReaderPage
  void _showGoToPageSheet(BuildContext context, AppThemeOption theme,
      double rsw, List<dynamic> surahs) {
    final ctrl = TextEditingController();
    final cubit = context.read<QuranCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(rsw * 0.05)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            rsw * 0.05,
            rsw * 0.05,
            rsw * 0.05,
            MediaQuery.of(sheetCtx).viewInsets.bottom + rsw * 0.05,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Go to Page',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: rsw * 0.040,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: rsw * 0.008),
              Text('Enter a Quran page number from 1 to 611',
                  style: TextStyle(
                      color: theme.textLow, fontSize: rsw * 0.026)),
              SizedBox(height: rsw * 0.026),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: TextStyle(color: Colors.white, fontSize: rsw * 0.036),
                decoration: InputDecoration(
                  hintText: 'e.g. 50',
                  hintStyle: TextStyle(color: theme.textLow),
                  filled: true,
                  fillColor: theme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(rsw * 0.030),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: rsw * 0.030, vertical: rsw * 0.026),
                ),
              ),
              SizedBox(height: rsw * 0.026),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accent,
                    padding: EdgeInsets.symmetric(vertical: rsw * 0.032),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(rsw * 0.030),
                    ),
                  ),
                  onPressed: () {
                    final n = int.tryParse(ctrl.text.trim());
                    if (n == null || n < 1 || n > 611) {
                      ScaffoldMessenger.of(sheetCtx).showSnackBar(
                        const SnackBar(
                            content:
                            Text('Enter a valid page number (1–611)')),
                      );
                      return;
                    }

                    // Quran page N corresponds to image page N + 2
                    final imagePage = n + 1;

                    if (surahs.isEmpty) return;
                    var s = surahs.first;
                    for (final x in surahs) {
                      if (x.page <= imagePage) s = x;
                    }

                    Navigator.pop(sheetCtx); // close sheet first
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: cubit,
                          child: QuranReaderPage(
                              initialPage: imagePage, surah: s),
                        ),
                      ),
                    );
                  },
                  child: Text('Go',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: rsw * 0.034,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppThemeOption theme;
  final double rsw;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.theme,
    required this.rsw,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: rsw * 0.030),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(rsw * 0.032),
          border: Border.all(
              color: theme.accent.withOpacity(0.16), width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.accent, size: rsw * 0.078),
            SizedBox(height: rsw * 0.016),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: rsw * 0.028,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab bar — single row, 3 tabs ────────────────────────────────────────────────
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
    return Container(
      margin: EdgeInsets.symmetric(horizontal: rsw * 0.040),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.accent.withOpacity(0.12), width: 1),
        ),
      ),
      child: Row(
        children: [
          _TabBtn(ctrl: ctrl, index: 0, label: 'Surah', theme: theme, rsw: rsw),
          _TabBtn(ctrl: ctrl, index: 1, label: 'Para', theme: theme, rsw: rsw),
          _TabBtn(ctrl: ctrl, index: 2, label: 'Bookmark', theme: theme, rsw: rsw),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final TabController ctrl;
  final int index;
  final String label;
  final AppThemeOption theme;
  final double rsw;

  const _TabBtn({
    required this.ctrl,
    required this.index,
    required this.label,
    required this.theme,
    required this.rsw,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) {
          final active = ctrl.index == index;
          return GestureDetector(
            onTap: () => ctrl.animateTo(index),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: rsw * 0.026),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? theme.accent : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: rsw * 0.034,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? theme.accent : theme.textLow,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}