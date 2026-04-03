import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/duas_model.dart';
import '../repository/duas_repository.dart';

// ─── Palette (matches ToolsPage) ────────────────────────────────────────────
const _bg        = Color(0xFF021A10);
const _surface   = Color(0xFF0D2E1C);
const _card      = Color(0xFF143324);
const _accent    = Color(0xFF4CAF82);
const _accentSoft= Color(0xFF2E7D5A);
const _gold      = Color(0xFFD4A847);
const _textHi    = Color(0xFFE8F5EE);
const _textMid   = Color(0xFFB0CFBC);
const _textLo    = Color(0xFF7BAF92);

class DuasDetailPage extends StatefulWidget {
  final DuasModel dua;
  const DuasDetailPage({super.key, required this.dua});

  @override
  State<DuasDetailPage> createState() => _DuasDetailPageState();
}

class _DuasDetailPageState extends State<DuasDetailPage>
    with SingleTickerProviderStateMixin {
  late DuasModel dua;
  bool _isPlaying = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    dua = widget.dua;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _toggleFavorite() async {
    await DuasRepository().toggleFavorite(dua);
    setState(() => dua.isFavorite = !dua.isFavorite);
    _showSnack(
      dua.isFavorite ? 'Added to Favorites' : 'Removed from Favorites',
      dua.isFavorite ? Icons.favorite : Icons.favorite_border,
    );
  }

  Future<void> _toggleBookmark() async {
    await DuasRepository().toggleBookmark(dua);
    setState(() => dua.isBookmarked = !dua.isBookmarked);
    _showSnack(
      dua.isBookmarked ? 'Bookmarked' : 'Bookmark Removed',
      dua.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
    );
  }

  void _copyToClipboard() {
    final text = '''${dua.arabic}

${dua.transliteration}

${dua.translation['en'] ?? ''}

${dua.reference}''';
    Clipboard.setData(ClipboardData(text: text));
    _showSnack('Copied to clipboard', Icons.copy_rounded);
  }

  void _shareDua() {
    final text = '''${dua.arabic}

${dua.transliteration}

Translation: ${dua.translation['en'] ?? ''}

Reference: ${dua.reference}''';
    // Replace with share_plus: Share.share(text);
    _showSnack('Share opened', Icons.share_rounded);
  }

  void _toggleAudio() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _pulseCtrl.repeat();
      // Replace with just_audio or audioplayers playback
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  void _showSnack(String msg, IconData icon) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(icon, color: _accent, size: 18),
            const SizedBox(width: 10),
            Text(msg, style: const TextStyle(color: _textHi, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(sw),
      body: Stack(
        children: [
          // Decorative top glow
          Positioned(
            top: -60, right: -40,
            child: Container(
              width: sw * 0.6, height: sw * 0.6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Color(0x202E7D5A), Color(0x00000000),
                ]),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  sw * 0.04, sw * 0.03, sw * 0.04, sh * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Quick Actions Row ──────────────────────────────────
                  _ActionRow(
                    isFavorite: dua.isFavorite,
                    isBookmarked: dua.isBookmarked,
                    onFavorite: _toggleFavorite,
                    onBookmark: _toggleBookmark,
                    onCopy: _copyToClipboard,
                    onShare: _shareDua,
                    sw: sw,
                  ),

                  SizedBox(height: sw * 0.05),

                  // ── Arabic Card ────────────────────────────────────────
                  _ContentCard(
                    label: 'Arabic',
                    labelColor: _gold,
                    child: Text(
                      dua.arabic,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: sw * 0.065,
                        color: _textHi,
                        height: 1.9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Transliteration Card ───────────────────────────────
                  _ContentCard(
                    label: 'Transliteration',
                    labelColor: _accent,
                    child: Text(
                      dua.transliteration,
                      style: TextStyle(
                        fontSize: sw * 0.04,
                        color: _textMid,
                        height: 1.7,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Translation English ────────────────────────────────
                  _ContentCard(
                    label: 'Translation — English',
                    labelColor: _accent,
                    child: Text(
                      dua.translation['en'] ?? '',
                      style: TextStyle(
                        fontSize: sw * 0.038,
                        color: _textMid,
                        height: 1.7,
                      ),
                    ),
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Translation Bangla ─────────────────────────────────
                  _ContentCard(
                    label: 'অনুবাদ — বাংলা',
                    labelColor: _accent,
                    child: Text(
                      dua.translation['bn'] ?? '',
                      style: TextStyle(
                        fontSize: sw * 0.038,
                        color: _textMid,
                        height: 1.8,
                      ),
                    ),
                  ),

                  // ── Reference ─────────────────────────────────────────
                  if (dua.reference.isNotEmpty) ...[
                    SizedBox(height: sw * 0.04),
                    _ReferenceChip(reference: dua.reference, sw: sw),
                  ],

                  // ── Audio Player ───────────────────────────────────────
                  if (dua.audioUrl != null && dua.audioUrl!.isNotEmpty) ...[
                    SizedBox(height: sw * 0.06),
                    _AudioPlayer(
                      isPlaying: _isPlaying,
                      pulseCtrl: _pulseCtrl,
                      onToggle: _toggleAudio,
                      sw: sw,
                    ),
                  ],

                  SizedBox(height: sw * 0.06),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(double sw) => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accentSoft.withOpacity(0.3)),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _textHi, size: 16),
      ),
    ),
    title: Column(
      children: [
        Text('Dua Detail',
            style: TextStyle(
              fontSize: sw * 0.045,
              fontWeight: FontWeight.w700,
              color: _textHi,
              letterSpacing: 0.5,
            )),
        Text('اللهم آمين',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: sw * 0.032,
              color: _gold.withOpacity(0.75),
            )),
      ],
    ),
    centerTitle: true,
    flexibleSpace: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_surface, _bg.withOpacity(0)],
        ),
      ),
    ),
  );
}

// ─── Action Row ──────────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final bool isFavorite;
  final bool isBookmarked;
  final VoidCallback onFavorite;
  final VoidCallback onBookmark;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final double sw;

  const _ActionRow({
    required this.isFavorite,
    required this.isBookmarked,
    required this.onFavorite,
    required this.onBookmark,
    required this.onCopy,
    required this.onShare,
    required this.sw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentSoft.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionBtn(
            icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            label: 'Favorite',
            color: isFavorite ? const Color(0xFFE57373) : _textLo,
            filled: isFavorite,
            fillColor: const Color(0x22E57373),
            onTap: onFavorite,
            sw: sw,
          ),
          _ActionBtn(
            icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
            label: 'Bookmark',
            color: isBookmarked ? const Color(0xFF64B5F6) : _textLo,
            filled: isBookmarked,
            fillColor: const Color(0x2264B5F6),
            onTap: onBookmark,
            sw: sw,
          ),
          _ActionBtn(
            icon: Icons.copy_rounded,
            label: 'Copy',
            color: _textLo,
            filled: false,
            fillColor: Colors.transparent,
            onTap: onCopy,
            sw: sw,
          ),
          _ActionBtn(
            icon: Icons.share_rounded,
            label: 'Share',
            color: _textLo,
            filled: false,
            fillColor: Colors.transparent,
            onTap: onShare,
            sw: sw,
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final Color fillColor;
  final VoidCallback onTap;
  final double sw;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.filled,
    required this.fillColor,
    required this.onTap,
    required this.sw,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween(begin: 1.0, end: 0.82).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: widget.sw * 0.12,
              height: widget.sw * 0.12,
              decoration: BoxDecoration(
                color: widget.filled ? widget.fillColor : _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.filled
                      ? widget.color.withOpacity(0.4)
                      : _accentSoft.withOpacity(0.2),
                ),
              ),
              child: Icon(widget.icon, color: widget.color, size: widget.sw * 0.055),
            ),
            const SizedBox(height: 5),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.sw * 0.028,
                color: widget.filled ? widget.color : _textLo,
                fontWeight:
                widget.filled ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Content Card ────────────────────────────────────────────────────────────
class _ContentCard extends StatelessWidget {
  final String label;
  final Color labelColor;
  final Widget child;

  const _ContentCard({
    required this.label,
    required this.labelColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentSoft.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label header
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                bottom: BorderSide(
                    color: _accentSoft.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 3, height: 14,
                  decoration: BoxDecoration(
                    color: labelColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Text(label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                      letterSpacing: 0.6,
                    )),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─── Reference Chip ──────────────────────────────────────────────────────────
class _ReferenceChip extends StatelessWidget {
  final String reference;
  final double sw;

  const _ReferenceChip({required this.reference, required this.sw});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _gold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.menu_book_rounded, color: _gold, size: sw * 0.045),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reference',
                    style: TextStyle(
                      fontSize: sw * 0.03,
                      fontWeight: FontWeight.w700,
                      color: _gold,
                      letterSpacing: 0.5,
                    )),
                const SizedBox(height: 3),
                Text(reference,
                    style: TextStyle(
                      fontSize: sw * 0.034,
                      color: _textLo,
                      height: 1.5,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Audio Player ─────────────────────────────────────────────────────────────
class _AudioPlayer extends StatelessWidget {
  final bool isPlaying;
  final AnimationController pulseCtrl;
  final VoidCallback onToggle;
  final double sw;

  const _AudioPlayer({
    required this.isPlaying,
    required this.pulseCtrl,
    required this.onToggle,
    required this.sw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.05, vertical: sw * 0.045),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPlaying
              ? _accent.withOpacity(0.5)
              : _accentSoft.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: sw * 0.14,
              height: sw * 0.14,
              decoration: BoxDecoration(
                color: isPlaying ? _accent : _accentSoft,
                shape: BoxShape.circle,
                boxShadow: isPlaying
                    ? [
                  BoxShadow(
                      color: _accent.withOpacity(0.35),
                      blurRadius: 14,
                      spreadRadius: 2)
                ]
                    : [],
              ),
              child: Icon(
                isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: sw * 0.07,
              ),
            ),
          ),

          SizedBox(width: sw * 0.04),

          // Waveform + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Audio Recitation',
                    style: TextStyle(
                      fontSize: sw * 0.038,
                      fontWeight: FontWeight.w600,
                      color: _textHi,
                    )),
                const SizedBox(height: 6),
                // Animated bars
                _WaveformBars(isPlaying: isPlaying, pulseCtrl: pulseCtrl),
              ],
            ),
          ),

          // Duration badge
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _accentSoft.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '0:00',
              style: TextStyle(
                  fontSize: sw * 0.032,
                  color: _accent,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Waveform Bars ───────────────────────────────────────────────────────────
class _WaveformBars extends StatelessWidget {
  final bool isPlaying;
  final AnimationController pulseCtrl;

  const _WaveformBars(
      {required this.isPlaying, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    final heights = [10.0, 16.0, 8.0, 20.0, 12.0, 18.0, 10.0, 14.0];

    return SizedBox(
      height: 22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: heights.asMap().entries.map((e) {
          final delay = e.key * 0.12;
          if (!isPlaying) {
            return Container(
              width: 3,
              height: e.value * 0.5,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _textLo.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }
          return AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, __) {
              final t = (pulseCtrl.value + delay) % 1.0;
              final h = e.value * (0.5 + 0.5 * (t < 0.5 ? t * 2 : (1 - t) * 2));
              return Container(
                width: 3,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}