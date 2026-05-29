import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/inspiration_cubit.dart';
import '../model/inspiration_model.dart';
import 'inspiration_page.dart' show gradientForIndex;

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

  InspirationModel get _current =>
      widget.inspirations[_currentIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071A15),
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
              );
            },
          ),

          // ── Top Bar overlay ─────────────────────────────
          SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  _CircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),

                  // Page indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.inspirations.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Options button
                  _CircleButton(
                    icon: Icons.more_horiz_rounded,
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
class _InspirationFullCard extends StatelessWidget {
  final InspirationModel inspiration;
  final List<Color> gradientColors;

  const _InspirationFullCard({
    required this.inspiration,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 70, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Category Chip ───────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  inspiration.categoryTitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Title ───────────────────────────────────
              Text(
                inspiration.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 24),

              // ── Divider line ────────────────────────────
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),

              const SizedBox(height: 24),

              // ── Quote Text — AutoSizeText ────────────────
              Expanded(
                child: Center(
                  child: AutoSizeText(
                    inspiration.quoteText,
                    textAlign: TextAlign.center,
                    maxLines: 14,
                    minFontSize: 14,
                    maxFontSize: 22,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Reference & Author ──────────────────────
              _buildReferenceAuthor(),

              const SizedBox(height: 28),

              // ── Action Row ──────────────────────────────
              _buildActionRow(context),

              const SizedBox(height: 8),

              // ── Swipe hint ──────────────────────────────
              const Text(
                'Swipe for next',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceAuthor() {
    final hasReference =
        inspiration.reference != null && inspiration.reference!.isNotEmpty;
    final hasAuthor =
        inspiration.author != null && inspiration.author!.isNotEmpty;

    if (!hasReference && !hasAuthor) return const SizedBox.shrink();

    String displayText = '';
    if (hasReference && hasAuthor) {
      displayText = '${inspiration.reference!} — ${inspiration.author!}';
    } else if (hasReference) {
      displayText = inspiration.reference!;
    } else {
      displayText = inspiration.author!;
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        displayText,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Favorite ──────────────────────────────────────
        _ActionButton(
          icon: inspiration.isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          color: inspiration.isFavorite
              ? Colors.redAccent
              : Colors.white60,
          label: 'Like',
          onTap: () {
            context
                .read<InspirationCubit>()
                .toggleFavorite(inspiration);
          },
        ),

        const SizedBox(width: 24),

        // ── Share ─────────────────────────────────────────
        _ActionButton(
          icon: Icons.ios_share_rounded,
          color: Colors.white60,
          label: 'Share',
          onTap: () {
            // Share.share(inspiration.quoteText);
          },
        ),

        const SizedBox(width: 24),

        // ── Bookmark ──────────────────────────────────────
        _ActionButton(
          icon: inspiration.isBookmarked
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          color: inspiration.isBookmarked
              ? const Color(0xFF2ECC71)
              : Colors.white60,
          label: 'Save',
          onTap: () {
            context
                .read<InspirationCubit>()
                .toggleBookmark(inspiration);
          },
        ),
      ],
    );
  }
}

// ── Action Button ───────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
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
              color: Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
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
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black26,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}