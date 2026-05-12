import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import '../cubit/quran_cubit.dart';
import '../cubit/quran_state.dart';
import '../models/surah_model.dart';

class QuranReaderPage extends StatefulWidget {
  final int initialPage;
  final SurahModel surah;

  const QuranReaderPage({
    super.key,
    required this.initialPage,
    required this.surah,
  });

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  static const int _totalImages = 619;
  static const int _quranStart  = 3;
  static const int _quranEnd    = 612;

  late PageController _pageCtrl;
  late int _currentPage;
  bool _showOverlay  = true;
  bool _isBookmarked = false;

  // ── RTL page mapping ────────────────────────────────────────────────────────
  // In the PageView, index 0 = last image (619), index 618 = first image (1)
  // This makes swiping RIGHT show the next Quran page (higher image number)
  // and swiping LEFT show the previous Quran page (lower image number),
  // exactly matching how a physical Arabic Mushaf is read.

  /// Convert a PDF page number (1–619) to a PageView index (0–618)
  int _pageToIndex(int page) => _totalImages - page;

  /// Convert a PageView index (0–618) to a PDF page number (1–619)
  int _indexToPage(int index) => _totalImages - index;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, _totalImages);
    // Start at the reversed index for the initial page
    _pageCtrl = PageController(initialPage: _pageToIndex(_currentPage));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBookmark());
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _checkBookmark() {
    final state = context.read<QuranCubit>().state;
    if (state is QuranLoaded && mounted) {
      setState(() {
        _isBookmarked =
            state.bookmarks.any((b) => b.pageNumber == _currentPage);
      });
    }
  }

  void _onPageChanged(int index) {
    // Convert reversed index back to actual PDF page number
    final page = _indexToPage(index);
    if (!mounted) return;
    setState(() => _currentPage = page);
    context.read<QuranCubit>().saveLastRead(page);

    final state = context.read<QuranCubit>().state;
    if (state is QuranLoaded) {
      setState(() {
        _isBookmarked = state.bookmarks.any((b) => b.pageNumber == page);
      });
    }
  }

  String _imagePath(int pdfPage) {
    return 'assets/quran/pages/${pdfPage.toString().padLeft(3, '0')}.jpg';
  }

  SurahModel _surahForPage(int page, List<SurahModel> surahs) {
    if (surahs.isEmpty) return widget.surah;
    final quranPage = page - 2;
    SurahModel result = surahs.first;
    for (final s in surahs) {
      if (s.page <= page) result = s;
    }
    return result;
  }

  Future<void> _toggleBookmark(SurahModel surah) async {
    await context.read<QuranCubit>().toggleBookmark(_currentPage, surah);
    final state = context.read<QuranCubit>().state;
    if (state is QuranLoaded && mounted) {
      setState(() {
        _isBookmarked =
            state.bookmarks.any((b) => b.pageNumber == _currentPage);
      });
    }
  }

  void _jumpToPage(int page) {
    final target = page.clamp(1, _totalImages);
    // Animate to the reversed index
    _pageCtrl.animateToPage(
      _pageToIndex(target),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq  = MediaQuery.of(context);
    final sw  = mq.size.width;
    final rsw = sw.clamp(320.0, 420.0);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (_, settings) {
        final theme = getThemeById(settings.themeMode);
        return BlocBuilder<QuranCubit, QuranState>(
          builder: (_, state) {
            final surahs       = state is QuranLoaded ? state.surahs : <SurahModel>[];
            final currentSurah = _surahForPage(_currentPage, surahs);
            final isQuranPage  =
                _currentPage >= _quranStart && _currentPage <= _quranEnd;

            return Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  // ── Page viewer (RTL: index 0 = page 619, index 618 = page 1) ──
                  GestureDetector(
                    onTap: () => setState(() => _showOverlay = !_showOverlay),
                    onLongPress: () => _toggleBookmark(currentSurah),
                    child: PageView.builder(
                      controller: _pageCtrl,
                      // Reversed: swiping right increases index → decreases page number
                      // but we want swiping right to go to NEXT page (higher number)
                      // So we reverse the mapping: index 0 = page 619
                      itemCount: _totalImages,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (_, index) {
                        // Reversed index → actual PDF page number
                        final pdfPage = _indexToPage(index);
                        final isQP   =
                            pdfPage >= _quranStart && pdfPage <= _quranEnd;
                        return InteractiveViewer(
                          minScale: 0.85,
                          maxScale: 5.0,
                          child: Image.asset(
                            _imagePath(pdfPage),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _PagePlaceholder(
                              page: pdfPage,
                              surah: isQP
                                  ? _surahForPage(pdfPage, surahs)
                                  : widget.surah,
                              rsw: rsw,
                              isQuranPage: isQP,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Top overlay ──────────────────────────────────────────────
                  AnimatedOpacity(
                    opacity: _showOverlay ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_showOverlay,
                      child: _TopBar(
                        theme: theme,
                        rsw: rsw,
                        mq: mq,
                        surah: currentSurah,
                        currentPage: _currentPage,
                        isBookmarked: _isBookmarked,
                        isQuranPage: isQuranPage,
                        onBack: () => Navigator.pop(context),
                        onBookmark: () => _toggleBookmark(currentSurah),
                      ),
                    ),
                  ),

                  // ── Bottom overlay ───────────────────────────────────────────
                  AnimatedOpacity(
                    opacity: _showOverlay ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_showOverlay,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _BottomBar(
                          theme: theme,
                          rsw: rsw,
                          mq: mq,
                          currentPage: _currentPage,
                          // Next page = higher number = swipe RIGHT
                          // Previous page = lower number = swipe LEFT
                          // Arrow buttons must match: right arrow → next page
                          onNext: () => _jumpToPage(_currentPage + 1),
                          onPrev: () => _jumpToPage(_currentPage - 1),
                          onJump: _jumpToPage,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final AppThemeOption theme;
  final double rsw;
  final MediaQueryData mq;
  final SurahModel surah;
  final int currentPage;
  final bool isBookmarked;
  final bool isQuranPage;
  final VoidCallback onBack;
  final VoidCallback onBookmark;

  const _TopBar({
    required this.theme,
    required this.rsw,
    required this.mq,
    required this.surah,
    required this.currentPage,
    required this.isBookmarked,
    required this.isQuranPage,
    required this.onBack,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final quranPageNum = isQuranPage ? currentPage - 2 : null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xDD000000), Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(
        top: mq.padding.top + rsw * 0.015,
        left: rsw * 0.035,
        right: rsw * 0.035,
        bottom: rsw * 0.055,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          _CircleBtn(
            icon: Icons.arrow_back_ios_rounded,
            onTap: onBack,
            rsw: rsw,
          ),
          SizedBox(width: rsw * 0.022),

          // Surah info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isQuranPage ? surah.nameTranslit : 'Al-Quran',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: rsw * 0.036,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isQuranPage
                      ? 'Quran p.${quranPageNum!} · Para ${surah.para}'
                      : currentPage < 3
                      ? 'Cover page'
                      : 'Appendix page',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: rsw * 0.024,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: rsw * 0.015),

          // Arabic name (only for Quran pages)
          if (isQuranPage)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: rsw * 0.28),
              child: Text(
                surah.nameAr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  color: theme.accent,
                  fontSize: rsw * 0.042,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          SizedBox(width: rsw * 0.018),

          // Bookmark button
          _CircleBtn(
            icon: isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            onTap: onBookmark,
            rsw: rsw,
            color: isBookmarked
                ? const Color(0xFFFFB74D)
                : Colors.white70,
            bgColor: isBookmarked
                ? const Color(0xFFFFB74D).withOpacity(0.20)
                : Colors.white.withOpacity(0.12),
          ),
        ],
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final AppThemeOption theme;
  final double rsw;
  final MediaQueryData mq;
  final int currentPage;
  final VoidCallback onNext;   // go to next page (higher number, swipe RIGHT)
  final VoidCallback onPrev;   // go to prev page (lower number, swipe LEFT)
  final void Function(int) onJump;

  const _BottomBar({
    required this.theme,
    required this.rsw,
    required this.mq,
    required this.currentPage,
    required this.onNext,
    required this.onPrev,
    required this.onJump,
  });

  String get _pageLabel {
    if (currentPage < 3)  return 'Cover';
    if (currentPage > 612) return 'Appendix';
    return 'Quran ${currentPage - 2} / 610';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xEE000000), Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(
        bottom: mq.padding.bottom + rsw * 0.025,
        left:   rsw * 0.030,
        right:  rsw * 0.030,
        top:    rsw * 0.045,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page label
          Text(
            _pageLabel,
            style: TextStyle(
              color: Colors.white60,
              fontSize: rsw * 0.026,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: rsw * 0.010),

          // ── Direction hint ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_forward_rounded,
                  color: Colors.white24, size: rsw * 0.028),
              SizedBox(width: rsw * 0.010),
              Text(
                'Swipe right for next page',
                style: TextStyle(
                    color: Colors.white24, fontSize: rsw * 0.020),
              ),
            ],
          ),
          SizedBox(height: rsw * 0.008),

          // ── Nav row ──────────────────────────────────────────────
          // Layout (RTL Mushaf style):
          //   [← PREV]  ─────slider─────  [NEXT →]
          // Pressing PREV goes to lower page number (left in Mushaf)
          // Pressing NEXT goes to higher page number (right in Mushaf)
          // Slider left = page 1, slider right = page 619
          Row(
            children: [
              // PREV button (go to lower page number)
              _CircleBtn(
                icon: Icons.chevron_left_rounded,
                onTap: onPrev,
                rsw: rsw,
                size: rsw * 0.090,
              ),
              SizedBox(width: rsw * 0.015),

              // Slider — left = page 1, right = page 619 (normal LTR slider)
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: rsw * 0.020),
                    overlayShape: RoundSliderOverlayShape(
                        overlayRadius: rsw * 0.032),
                    activeTrackColor:   theme.accent,
                    inactiveTrackColor: Colors.white24,
                    thumbColor:         theme.accent,
                    overlayColor:       theme.accent.withOpacity(0.18),
                  ),
                  child: Slider(
                    value: currentPage.toDouble().clamp(1.0, 619.0),
                    min: 1,
                    max: 619,
                    onChanged: (v) => onJump(v.round()),
                  ),
                ),
              ),

              SizedBox(width: rsw * 0.015),
              // NEXT button (go to higher page number)
              _CircleBtn(
                icon: Icons.chevron_right_rounded,
                onTap: onNext,
                rsw: rsw,
                size: rsw * 0.090,
              ),
            ],
          ),

          SizedBox(height: rsw * 0.008),

          // Image index pill
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: rsw * 0.030, vertical: rsw * 0.008),
            decoration: BoxDecoration(
              color:        Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(rsw * 0.025),
              border:       Border.all(color: Colors.white24, width: 0.5),
            ),
            child: Text(
              'Image $currentPage / 619',
              style: TextStyle(
                color:    Colors.white38,
                fontSize: rsw * 0.022,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable circle button ────────────────────────────────────────────────────
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double rsw;
  final Color color;
  final Color bgColor;
  final double? size;

  const _CircleBtn({
    required this.icon,
    required this.onTap,
    required this.rsw,
    this.color   = Colors.white70,
    this.bgColor = const Color(0x1FFFFFFF),
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final s = size ?? rsw * 0.092;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  s,
        height: s,
        decoration: BoxDecoration(
          color:  bgColor,
          shape:  BoxShape.circle,
          border: Border.all(color: Colors.white12, width: 0.5),
        ),
        child: Icon(icon, color: color, size: s * 0.55),
      ),
    );
  }
}

// ── Page placeholder ──────────────────────────────────────────────────────────
class _PagePlaceholder extends StatelessWidget {
  final int page;
  final SurahModel surah;
  final double rsw;
  final bool isQuranPage;

  const _PagePlaceholder({
    required this.page,
    required this.surah,
    required this.rsw,
    this.isQuranPage = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isQuranPage) {
      return Container(
        color: const Color(0xFFF5F0E8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined,
                  color: const Color(0xFF2E6B40), size: rsw * 0.14),
              SizedBox(height: rsw * 0.03),
              Text(
                page < 3 ? 'Cover Page' : 'Appendix',
                style: TextStyle(
                    color: const Color(0xFF2E6B40),
                    fontSize: rsw * 0.040,
                    fontWeight: FontWeight.w700),
              ),
              Text(
                'Image $page of 619',
                style: TextStyle(
                    color: const Color(0xFF888888),
                    fontSize: rsw * 0.026),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF5F0E8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'بِسْمِ اللهِ الرَّحْمَٰنِ الرَّحِيْمِ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                color: const Color(0xFF2E6B40),
                fontSize: rsw * 0.046,
              ),
            ),
            SizedBox(height: rsw * 0.04),
            Text(
              surah.nameAr,
              style: TextStyle(
                fontFamily: 'Amiri',
                color: const Color(0xFF2E6B40),
                fontSize: rsw * 0.065,
              ),
            ),
            SizedBox(height: rsw * 0.015),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: rsw * 0.035, vertical: rsw * 0.012),
              decoration: BoxDecoration(
                color:        const Color(0xFF2E6B40).withOpacity(0.08),
                borderRadius: BorderRadius.circular(rsw * 0.025),
                border: Border.all(
                    color: const Color(0xFF2E6B40).withOpacity(0.25)),
              ),
              child: Text(
                'Quran page ${page - 2}  ·  Image ${page.toString().padLeft(3, '0')}.jpg',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: const Color(0xFF555555),
                    fontSize: rsw * 0.024),
              ),
            ),
          ],
        ),
      ),
    );
  }
}