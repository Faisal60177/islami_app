import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import '../cubit/quran_cubit.dart';
import '../cubit/quran_state.dart';
import '../models/surah_model.dart';
import 'dart:io';
import '../services/quran_download_service.dart';

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

class _QuranReaderPageState extends State<QuranReaderPage>
    with SingleTickerProviderStateMixin {
  static const int _totalImages = 619;
  static const int _quranStart  = 2;
  static const int _quranEnd    = 619;

  late int _currentPage;
  late int _nextPage;
  bool _showOverlay  = true;
  bool _isBookmarked = false;
  bool _isAnimating  = false;

  late AnimationController _curlCtrl;
  late Animation<double> _curlAnim;
  bool _curlingForward = true;

  double _dragX = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, _totalImages);
    _nextPage    = _currentPage;

    _curlCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _curlAnim = CurvedAnimation(parent: _curlCtrl, curve: Curves.easeInOut);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBookmark());
  }

  @override
  void dispose() {
    _curlCtrl.dispose();
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

  String _imagePath(int page) {
    // Returns local file path — loaded after one-time download
    return ''; // placeholder — actual path built async below
  }

  Future<String> _getLocalPagePath(int page) =>
      QuranDownloadService.getPagePath(page);

  SurahModel _surahForPage(int page, List<SurahModel> surahs) {
    if (surahs.isEmpty) return widget.surah;
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

  // RTL Mushaf: next Quran page = lower image number
  //             prev Quran page = higher image number
  Future<void> _turnToPage(int targetPage, {bool forward = true}) async {
    if (_isAnimating) return;
    final clamped = targetPage.clamp(1, _totalImages);
    if (clamped == _currentPage) return;

    setState(() {
      _isAnimating    = true;
      _curlingForward = forward;
      _nextPage       = clamped;
    });

    _curlCtrl.reset();
    await _curlCtrl.forward();

    if (mounted) {
      setState(() {
        _currentPage  = clamped;
        _isAnimating  = false;
      });
      context.read<QuranCubit>().saveLastRead(clamped);
      _checkBookmark();
    }
  }

  // Right swipe / right arrow = next Quran page = lower image number
  void _goNext() => _turnToPage(_currentPage - 1, forward: true);
  // Left swipe / left arrow  = prev Quran page = higher image number
  void _goPrev() => _turnToPage(_currentPage + 1, forward: false);

  void _jumpToPage(int page) {
    final forward = page < _currentPage;
    _turnToPage(page, forward: forward);
  }

  void _onHorizontalDragStart(DragStartDetails d) {
    if (_isAnimating) return;
    _dragX      = 0;
    _isDragging = true;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    if (!_isDragging || _isAnimating) return;
    setState(() => _dragX += d.delta.dx);
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    if (!_isDragging) return;
    _isDragging = false;
    const threshold = 60.0;
    if (_dragX > threshold) {
      _goNext();
    } else if (_dragX < -threshold) {
      _goPrev();
    }
    setState(() => _dragX = 0);
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
                  // ── Page curl viewer ───────────────────────────────────
                  GestureDetector(
                    onTap: () => setState(() => _showOverlay = !_showOverlay),
                    onLongPress: () => _toggleBookmark(currentSurah),
                    onHorizontalDragStart: _onHorizontalDragStart,
                    onHorizontalDragUpdate: _onHorizontalDragUpdate,
                    onHorizontalDragEnd: _onHorizontalDragEnd,
                    child: SizedBox.expand(
                      child: AnimatedBuilder(
                        animation: _curlAnim,
                        builder: (_, __) => _PageCurlView(
                          currentPage: _currentPage,
                          nextPage: _nextPage,
                          progress: _isAnimating ? _curlAnim.value : 0.0,
                          forward: _curlingForward,
                          imagePath: _imagePath,
                          surahs: surahs,
                          fallbackSurah: widget.surah,
                          surahForPage: _surahForPage,
                          rsw: rsw,
                          quranStart: _quranStart,
                          quranEnd: _quranEnd,
                        ),
                      ),
                    ),
                  ),

                  // ── Top overlay ────────────────────────────────────────
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

                  // ── Bottom overlay ─────────────────────────────────────
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
                          onNext: _goNext,
                          onPrev: _goPrev,
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

// ── Page curl renderer ────────────────────────────────────────────────────────
class _PageCurlView extends StatelessWidget {
  final int currentPage;
  final int nextPage;
  final double progress;
  final bool forward;
  final String Function(int) imagePath;
  final List<SurahModel> surahs;
  final SurahModel fallbackSurah;
  final SurahModel Function(int, List<SurahModel>) surahForPage;
  final double rsw;
  final int quranStart;
  final int quranEnd;

  const _PageCurlView({
    required this.currentPage,
    required this.nextPage,
    required this.progress,
    required this.forward,
    required this.imagePath,
    required this.surahs,
    required this.fallbackSurah,
    required this.surahForPage,
    required this.rsw,
    required this.quranStart,
    required this.quranEnd,
  });

  Widget _buildPage(int page) {
    final isQP = page >= quranStart && page <= quranEnd;
    return FutureBuilder<String>(
      future: QuranDownloadService.getPagePath(page),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            color: const Color(0xFFF5F0E8),
            child: Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF2E6B40),
                strokeWidth: 2,
              ),
            ),
          );
        }
        final file = File(snapshot.data!);
        return InteractiveViewer(
          minScale: 0.85,
          maxScale: 5.0,
          child: file.existsSync()
              ? Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _PagePlaceholder(
              page: page,
              surah: isQP
                  ? surahForPage(page, surahs)
                  : fallbackSurah,
              rsw: rsw,
              isQuranPage: isQP,
            ),
          )
              : _PagePlaceholder(
            page: page,
            surah: isQP
                ? surahForPage(page, surahs)
                : fallbackSurah,
            rsw: rsw,
            isQuranPage: isQP,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final angle    = progress * math.pi;
    final showBack = angle > math.pi / 2;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: destination page (behind)
        _buildPage(nextPage),

        // Layer 2: shadow cast on destination while curling
        if (progress > 0 && progress < 1)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: (progress * (1 - progress) * 4).clamp(0.0, 0.40),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: forward
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      end: forward
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      colors: [Colors.black54, Colors.transparent],
                      stops: const [0.0, 0.55],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Layer 3: the page that's curling (3D flip)
        if (progress > 0 && progress < 1)
          Positioned.fill(
            child: IgnorePointer(
              child: Transform(
                alignment: forward
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0008)
                  ..rotateY(forward ? angle : -angle),
                child: showBack
                // Back of the curling page shows next page mirrored
                    ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildPage(nextPage),
                      // Subtle gloss on back face
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.white.withOpacity(0.10),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                // Front face: current page with right-edge curl shadow
                    : Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPage(currentPage),
                    Positioned(
                      right: 0, top: 0, bottom: 0,
                      child: Container(
                        width: (progress * rsw * 0.18).clamp(0, rsw * 0.14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black
                                  .withOpacity((progress * 0.55).clamp(0, 0.55)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
          _CircleBtn(icon: Icons.arrow_back_ios_rounded, onTap: onBack, rsw: rsw),
          SizedBox(width: rsw * 0.022),
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
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  isQuranPage
                      ? 'Page ${currentPage - 1} / 618 · Para ${surah.para}'
                      : currentPage == 1 ? 'Cover Page' : 'Appendix',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white54, fontSize: rsw * 0.024),
                ),
              ],
            ),
          ),
          SizedBox(width: rsw * 0.015),
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
                    fontWeight: FontWeight.bold),
              ),
            ),
          SizedBox(width: rsw * 0.018),
          _CircleBtn(
            icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            onTap: onBookmark,
            rsw: rsw,
            color: isBookmarked ? const Color(0xFFFFB74D) : Colors.white70,
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
  final VoidCallback onNext;
  final VoidCallback onPrev;
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
    if (currentPage == 1)  return 'Cover Page';
    if (currentPage > 612) return 'Appendix · ${currentPage - 612}';
    final quranPage = currentPage - 1;
    return 'Page $quranPage / 611';
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
          Text(_pageLabel,
              style: TextStyle(
                  color: Colors.white60,
                  fontSize: rsw * 0.026,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: rsw * 0.010),

          Row(
            children: [
              _CircleBtn(icon: Icons.chevron_left_rounded, onTap: onPrev, rsw: rsw, size: rsw * 0.090),
              SizedBox(width: rsw * 0.015),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: rsw * 0.020),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: rsw * 0.032),
                    activeTrackColor:   theme.accent,
                    inactiveTrackColor: Colors.white24,
                    thumbColor:         theme.accent,
                    overlayColor:       theme.accent.withOpacity(0.18),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Slider(
                      value: currentPage.toDouble().clamp(1.0, 619.0),
                      min: 1,
                      max: 619,
                      onChanged: (v) => onJump(619 - v.round() + 1),
                    ),
                  ),
                ),
              ),
              SizedBox(width: rsw * 0.015),
              _CircleBtn(icon: Icons.chevron_right_rounded, onTap: onNext, rsw: rsw, size: rsw * 0.090),
            ],
          ),

          SizedBox(height: rsw * 0.008),
          Container(
            padding: EdgeInsets.symmetric(horizontal: rsw * 0.030, vertical: rsw * 0.008),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(rsw * 0.025),
              border: Border.all(color: Colors.white24, width: 0.5),
            ),
            child: Text('Image $currentPage / 619',
                style: TextStyle(color: Colors.white38, fontSize: rsw * 0.022)),
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
        width: s, height: s,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
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
              Text(page < 3 ? 'Cover Page' : 'Appendix',
                  style: TextStyle(
                      color: const Color(0xFF2E6B40),
                      fontSize: rsw * 0.040,
                      fontWeight: FontWeight.w700)),
              Text('Image $page of 619',
                  style: TextStyle(color: const Color(0xFF888888), fontSize: rsw * 0.026)),
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
                  fontSize: rsw * 0.046),
            ),
            SizedBox(height: rsw * 0.04),
            Text(surah.nameAr,
                style: TextStyle(
                    fontFamily: 'Amiri',
                    color: const Color(0xFF2E6B40),
                    fontSize: rsw * 0.065)),
            SizedBox(height: rsw * 0.015),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: rsw * 0.035, vertical: rsw * 0.012),
              decoration: BoxDecoration(
                color: const Color(0xFF2E6B40).withOpacity(0.08),
                borderRadius: BorderRadius.circular(rsw * 0.025),
                border: Border.all(color: const Color(0xFF2E6B40).withOpacity(0.25)),
              ),
              child: Text(
                'Page $page  ·  Image ${page.toString().padLeft(3, '0')}.webp',
                textAlign: TextAlign.center,
                style: TextStyle(color: const Color(0xFF555555), fontSize: rsw * 0.024),
              ),
            ),
          ],
        ),
      ),
    );
  }
}