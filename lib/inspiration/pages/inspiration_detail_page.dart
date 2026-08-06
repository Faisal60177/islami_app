import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/inspiration_cubit.dart';
import '../model/inspiration_model.dart';
import 'inspiration_page.dart' show gradientForIndex;
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// ── Detail Page — Full screen PageView ─────────────────────────
class InspirationDetailPage extends StatefulWidget {
  final List<InspirationModel> inspirations;
  final int initialIndex;

  const InspirationDetailPage({
    super.key,
    required this.inspirations,
    required this.initialIndex,
  });

  @override
  State<InspirationDetailPage> createState() =>
      _InspirationDetailPageState();
}

class _InspirationDetailPageState extends State<InspirationDetailPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  InspirationModel get _current => widget.inspirations[_currentIndex];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    final theme = getThemeById(settings.themeMode);

    // Scaffold background is the plain outer background — shows around
    // the card (top-bar area, edges).
    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          // ── Full screen PageView ────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: widget.inspirations.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return _InspirationFullCard(
                inspiration: widget.inspirations[index],
                gradientColors: gradientForIndex(index),
                theme: theme,
              );
            },
          ),

          // ── Top Bar overlay ─────────────────────────────
          // Theme-aware: back/more circle buttons and the page indicator
          // adapt their colors for light vs dark themes.
          SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    theme: theme,
                    onTap: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.isDark
                          ? Colors.black26
                          : theme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.inspirations.length}',
                      style: TextStyle(
                        color:
                        theme.isDark ? Colors.white70 : theme.textHigh,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  _CircleButton(
                    icon: Icons.more_horiz_rounded,
                    theme: theme,
                    onTap: () {},
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

// ── Full Card Widget ────────────────────────────────────────────
// Renders TWO things:
//  1) the visible on-screen card (flexible height, no watermark)
//  2) a hidden, fixed-size (360x640) card used only to generate the
//     Full HD (1080x1920) share image — includes the watermark bar.
// Both reuse the same _QuoteCardContent widget so their layout
// (category/title/quote/reference) never drifts out of sync.
class _InspirationFullCard extends StatefulWidget {
  final InspirationModel inspiration;
  final List<Color> gradientColors;
  final AppThemeOption theme;

  const _InspirationFullCard({
    required this.inspiration,
    required this.gradientColors,
    required this.theme,
  });

  @override
  State<_InspirationFullCard> createState() => _InspirationFullCardState();
}

class _InspirationFullCardState extends State<_InspirationFullCard> {
  final GlobalKey _shareCardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final inspiration = widget.inspiration;
    final gradientColors = widget.gradientColors;

    return Stack(
      children: [
        // ── ON-SCREEN CARD ────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    // Shared layout widget — no watermark on-screen.
                    child: _QuoteCardContent(inspiration: inspiration),
                  ),
                ),

                const SizedBox(height: 20),
                _buildActionRow(context),
                const SizedBox(height: 8),

                Text(
                  'Swipe for next',
                  style: TextStyle(
                    color: widget.theme.isDark
                        ? Colors.white24
                        : widget.theme.textLow.withOpacity(0.6),
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          left: -9999,
          top: 0,
          child: RepaintBoundary(
            key: _shareCardKey,
            child: SizedBox(
              width: 360,
              height: 640,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _QuoteCardContent(
                  inspiration: inspiration,
                  watermark: const _WatermarkBar(
                    appName: 'Muslim Life',
                    appIconAsset:
                    'assets/icons/AppIcon.png',
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context) {
    final inspiration = widget.inspiration;
    final theme = widget.theme;
    final accent = theme.accent;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: inspiration.isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          color: inspiration.isFavorite
              ? Colors.redAccent
              : (theme.isDark ? Colors.white60 : theme.textLow),
          label: 'Like',
          theme: theme,
          onTap: () {
            setState(() => inspiration.isFavorite = !inspiration.isFavorite);
            context.read<InspirationCubit>().toggleFavorite(inspiration);
          },
        ),
        const SizedBox(width: 24),
        _ActionButton(
          icon: Icons.ios_share_rounded,
          color: theme.isDark ? Colors.white60 : theme.textLow,
          label: 'Share',
          theme: theme,
          onTap: () => _shareCard(context),
        ),
        const SizedBox(width: 24),
        _ActionButton(
          icon: inspiration.isBookmarked
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          color: inspiration.isBookmarked
              ? accent
              : (theme.isDark ? Colors.white60 : theme.textLow),
          label: 'Save',
          theme: theme,
          onTap: () {
            setState(
                    () => inspiration.isBookmarked = !inspiration.isBookmarked);
            context.read<InspirationCubit>().toggleBookmark(inspiration);
          },
        ),
      ],
    );
  }

  Future<void> _shareCard(BuildContext context) async {
    try {
      // Give the hidden share-card widget one frame to paint before capture.
      await Future.delayed(const Duration(milliseconds: 50));

      final boundary = _shareCardKey.currentContext!.findRenderObject()
      as RenderRepaintBoundary;

      // 360x640 logical size × pixelRatio 3.0 = 1080x1920 → Full HD.
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes =
      (await image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();

      final dir = await getTemporaryDirectory();
      final file = await File('${dir.path}/inspiration_share.png')
          .writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: widget.inspiration.quoteText,
      );
    } catch (e) {
      debugPrint('Share failed: $e');
    }
  }
}

// ── Shared quote-card content ───────────────────────────────────
// Used by BOTH the on-screen card and the share-image card so the
// layout (category top-left, title mid, quote centered, reference
// bottom-right) always stays identical between the two.
class _QuoteCardContent extends StatelessWidget {
  final InspirationModel inspiration;
  final Widget? watermark; // null = on-screen card, set = share card

  const _QuoteCardContent({
    required this.inspiration,
    this.watermark,
  });

  bool get _hasReference {
    final r = inspiration.reference;
    final a = inspiration.author;
    return (r != null && r.isNotEmpty) || (a != null && a.isNotEmpty);
  }

  String get _referenceText {
    final r = inspiration.reference;
    final a = inspiration.author;
    final hasR = r != null && r.isNotEmpty;
    final hasA = a != null && a.isNotEmpty;
    if (hasR && hasA) return '$r — $a';
    if (hasR) return r!;
    return a!;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 28, 26, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Category — top-left corner ──
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    inspiration.categoryTitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Title — centered, upper-middle ──
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    inspiration.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                // ── Quote — fills remaining space, centered, auto-sized ──
                Expanded(
                  child: Center(
                    child: AutoSizeText(
                      inspiration.quoteText,
                      textAlign: TextAlign.center,
                      maxLines: 10,
                      minFontSize: 14,
                      maxFontSize: 24,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                // ── Reference — bottom-right corner ──
                if (_hasReference)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _referenceText,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Watermark — only present on the share card ──
        if (watermark != null) watermark!,
      ],
    );
  }
}

// ── Watermark bar (share card only) ─────────────────────────────
// Bottom, full-width bar with app icon + name, bottom-left aligned —
// gives the shared image clear branding/attribution.
class _WatermarkBar extends StatelessWidget {
  final String appName;
  final String appIconAsset;

  const _WatermarkBar({
    required this.appName,
    required this.appIconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
      color: Colors.black.withOpacity(0.28),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(appIconAsset, width: 26, height: 26),
          ),
          const SizedBox(width: 10),
          Text(
            appName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Button ───────────────────────────────────────────────
// Theme-aware: circle fill / border / label color adapt to light vs
// dark themes so it stays visible on any background.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final AppThemeOption theme;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.theme,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.isDark ? Colors.white10 : theme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.isDark
                    ? Colors.white12
                    : theme.textLow.withOpacity(0.25),
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.isDark
                  ? Colors.white38
                  : theme.textLow.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Circle Button (top bar) ─────────────────────────────────────
// Theme-aware: fill/icon color adapt to light vs dark themes.
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final AppThemeOption theme;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.isDark
              ? Colors.black26
              : theme.surface.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.isDark
                ? Colors.white12
                : theme.textLow.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          color: theme.isDark ? Colors.white : theme.textHigh,
          size: 18,
        ),
      ),
    );
  }
}