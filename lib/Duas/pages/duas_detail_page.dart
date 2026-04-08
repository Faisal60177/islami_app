import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/duas_model.dart';
import '../repository/duas_repository.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const _bg         = Color(0xFF021A10);
const _surface    = Color(0xFF0D2E1C);
const _card       = Color(0xFF0F2A1A);
const _accent     = Color(0xFF4CAF82);
const _accentSoft = Color(0xFF2E7D5A);
const _gold       = Color(0xFFD4A847);
const _textHi     = Color(0xFFE8F5EE);
const _textMid    = Color(0xFFB0CFBC);
const _textLo     = Color(0xFF7BAF92);
const _divider    = Color(0x1A4CAF82);

class DuasDetailPage extends StatefulWidget {
  final DuasModel dua;
  const DuasDetailPage({super.key, required this.dua});

  @override
  State<DuasDetailPage> createState() => _DuasDetailPageState();
}

class _DuasDetailPageState extends State<DuasDetailPage>
    with TickerProviderStateMixin {

  late DuasModel _dua;
  bool _isPlaying = false;
  late AnimationController _waveCtrl;
  late AnimationController _favCtrl;
  late AnimationController _bkmCtrl;
  late Animation<double> _favBounce;
  late Animation<double> _bkmBounce;

  @override
  void initState() {
    super.initState();
    _dua = widget.dua;

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _favCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _favBounce = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 0.88), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _favCtrl, curve: Curves.easeOut));

    _bkmCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _bkmBounce = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 0.88), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _bkmCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _favCtrl.dispose();
    _bkmCtrl.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _toggleFavorite() async {
    HapticFeedback.lightImpact();
    // ✅ Update UI instantly before async call
    setState(() => _dua.isFavorite = !_dua.isFavorite);
    _favCtrl.forward(from: 0);
    _toast(
      _dua.isFavorite ? 'Added to Favorites' : 'Removed from Favorites',
      _dua.isFavorite ? const Color(0xFFE57373) : _textLo,
    );
    // Persist in background
    await DuasRepository().toggleFavorite(_dua);
  }

  Future<void> _toggleBookmark() async {
    HapticFeedback.lightImpact();
    // ✅ Update UI instantly before async call
    setState(() => _dua.isBookmarked = !_dua.isBookmarked);
    _bkmCtrl.forward(from: 0);
    _toast(
      _dua.isBookmarked ? 'Bookmarked' : 'Bookmark Removed',
      _dua.isBookmarked ? const Color(0xFF64B5F6) : _textLo,
    );
    // Persist in background
    await DuasRepository().toggleBookmark(_dua);
  }

  void _copyDua() {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(
      text: '${_dua.arabic}\n\n'
          '${_dua.transliteration}\n\n'
          '${_dua.translation['en'] ?? ''}\n\n'
          'Reference: ${_dua.reference}',
    ));
    _toast('Copied to clipboard', _accent);
  }

  void _shareDua() {
    HapticFeedback.selectionClick();
    // Replace with: Share.share(text) from share_plus package
    _toast('Sharing…', _accent);
  }

  void _toggleAudio() {
    HapticFeedback.lightImpact();
    setState(() => _isPlaying = !_isPlaying);
    _isPlaying ? _waveCtrl.repeat() : (_waveCtrl..stop()..reset());
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      duration: const Duration(seconds: 2),
      elevation: 0,
      content: Row(children: [
        Container(
          width: 4, height: 32,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 12),
        Text(msg,
            style: const TextStyle(
                color: _textHi, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _textHi, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dua.tags ?? 'Dua Detail',
              style: TextStyle(
                  color: _textHi,
                  fontSize: sw * 0.042,
                  fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(_dua.category ?? 'Daily Dua',
                style: TextStyle(color: _textLo, fontSize: sw * 0.028)),
          ],
        ),
        // ── Action icons in AppBar ─────────────────────────────────────
        actions: [
          // Favorite
          ScaleTransition(
            scale: _favBounce,
            child: IconButton(
              tooltip: _dua.isFavorite ? 'Unfavorite' : 'Favorite',
              onPressed: _toggleFavorite,
              icon: Icon(
                _dua.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_outline_rounded,
                color: _dua.isFavorite
                    ? const Color(0xFFE57373)
                    : _textLo,
                size: sw * 0.058,
              ),
            ),
          ),
          // Bookmark
          ScaleTransition(
            scale: _bkmBounce,
            child: IconButton(
              tooltip: _dua.isBookmarked ? 'Remove Bookmark' : 'Bookmark',
              onPressed: _toggleBookmark,
              icon: Icon(
                _dua.isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                color: _dua.isBookmarked
                    ? const Color(0xFF64B5F6)
                    : _textLo,
                size: sw * 0.058,
              ),
            ),
          ),
          // More menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded,
                color: _textLo, size: sw * 0.058),
            color: _card,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            onSelected: (val) {
              if (val == 'copy') _copyDua();
              if (val == 'share') _shareDua();
            },
            itemBuilder: (_) => [
              _menuItem('copy', Icons.copy_rounded, 'Copy Dua'),
              _menuItem('share', Icons.share_rounded, 'Share Dua'),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _divider),
        ),
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Arabic hero block ────────────────────────────────────────
            _ArabicHero(arabic: _dua.arabic, sw: sw),

            // ── Continuous text flow ─────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.055, vertical: sw * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  _SectionLabel('Transliteration', sw),
                  SizedBox(height: sw * 0.025),
                  Text(
                    _dua.transliteration,
                    style: TextStyle(
                      fontSize: sw * 0.04,
                      color: _textMid,
                      height: 1.8,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  _Divider(sw),

                  _SectionLabel('Translation', sw),
                  SizedBox(height: sw * 0.03),
                  _TranslationBlock(dua: _dua, sw: sw),

                  if (_dua.reference.isNotEmpty) ...[
                    _Divider(sw),
                    _ReferenceBlock(reference: _dua.reference, sw: sw),
                  ],

                  if (_dua.audioUrl != null &&
                      _dua.audioUrl!.isNotEmpty) ...[
                    _Divider(sw),
                    _AudioBar(
                      isPlaying: _isPlaying,
                      waveCtrl: _waveCtrl,
                      onToggle: _toggleAudio,
                      sw: sw,
                    ),
                  ],

                  SizedBox(height: sw * 0.1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      String val, IconData icon, String label) =>
      PopupMenuItem(
        value: val,
        child: Row(children: [
          Icon(icon, color: _textLo, size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: _textHi, fontSize: 14)),
        ]),
      );
}

// ─── Arabic Hero ─────────────────────────────────────────────────────────────
class _ArabicHero extends StatelessWidget {
  final String arabic;
  final double sw;
  const _ArabicHero({required this.arabic, required this.sw});

  Widget _ornament() => Row(children: [
    Expanded(child: Container(height: 1,
        color: _gold.withOpacity(0.22))),
    Container(
        margin: EdgeInsets.symmetric(horizontal: sw * 0.04),
        width: 5, height: 5,
        decoration: BoxDecoration(
            color: _gold.withOpacity(0.45), shape: BoxShape.circle)),
    Expanded(child: Container(height: 1,
        color: _gold.withOpacity(0.22))),
  ]);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _card,
      padding: EdgeInsets.fromLTRB(
          sw * 0.06, sw * 0.09, sw * 0.06, sw * 0.09),
      child: Column(children: [
        _ornament(),
        SizedBox(height: sw * 0.08),
        Text(
          arabic,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: sw * 0.075,
            color: _textHi,
            height: 2.1,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: sw * 0.08),
        _ornament(),
      ]),
    );
  }
}

// ─── Section Label ───────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final double sw;
  const _SectionLabel(this.text, this.sw);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: sw * 0.027,
      fontWeight: FontWeight.w800,
      color: _accent,
      letterSpacing: 1.5,
    ),
  );
}

// ─── Divider ─────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  final double sw;
  const _Divider(this.sw);

  @override
  Widget build(BuildContext context) =>
      Container(margin: EdgeInsets.symmetric(vertical: sw * 0.06),
          height: 1, color: _divider);
}

// ─── Translation Block with Language Toggle ───────────────────────────────
class _TranslationBlock extends StatefulWidget {
  final DuasModel dua;
  final double sw;
  const _TranslationBlock({required this.dua, required this.sw});

  @override
  State<_TranslationBlock> createState() => _TranslationBlockState();
}

class _TranslationBlockState extends State<_TranslationBlock> {
  String _lang = 'en';

  @override
  Widget build(BuildContext context) {
    final langs = {'en': 'English', 'bn': 'বাংলা'};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: langs.entries.map((e) {
            final active = _lang == e.key;
            return GestureDetector(
              onTap: () => setState(() => _lang = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: active
                      ? _accentSoft.withOpacity(0.22)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? _accent.withOpacity(0.5)
                        : _textLo.withOpacity(0.18),
                  ),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: widget.sw * 0.033,
                    fontWeight:
                    active ? FontWeight.w700 : FontWeight.w400,
                    color: active ? _accent : _textLo,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: widget.sw * 0.045),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Text(
            widget.dua.translation[_lang] ?? '',
            key: ValueKey(_lang),
            style: TextStyle(
              fontSize: widget.sw * 0.04,
              color: _textMid,
              height: 1.85,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Reference Block ─────────────────────────────────────────────────────────
class _ReferenceBlock extends StatelessWidget {
  final String reference;
  final double sw;
  const _ReferenceBlock({required this.reference, required this.sw});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.menu_book_rounded,
          color: _gold.withOpacity(0.65), size: sw * 0.042),
      SizedBox(width: sw * 0.03),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('REFERENCE',
                style: TextStyle(
                  fontSize: sw * 0.027,
                  fontWeight: FontWeight.w800,
                  color: _gold,
                  letterSpacing: 1.4,
                )),
            SizedBox(height: sw * 0.015),
            Text(reference,
                style: TextStyle(
                  fontSize: sw * 0.036,
                  color: _textLo,
                  height: 1.6,
                )),
          ],
        ),
      ),
    ],
  );
}

// ─── Audio Bar ───────────────────────────────────────────────────────────────
class _AudioBar extends StatelessWidget {
  final bool isPlaying;
  final AnimationController waveCtrl;
  final VoidCallback onToggle;
  final double sw;
  const _AudioBar({
    required this.isPlaying,
    required this.waveCtrl,
    required this.onToggle,
    required this.sw,
  });

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: EdgeInsets.symmetric(
        horizontal: sw * 0.045, vertical: sw * 0.04),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isPlaying ? _accent.withOpacity(0.4) : _divider,
        width: isPlaying ? 1.5 : 1,
      ),
    ),
    child: Row(children: [
      GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: sw * 0.13,
          height: sw * 0.13,
          decoration: BoxDecoration(
            color: isPlaying ? _accent : _accentSoft.withOpacity(0.28),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: isPlaying ? Colors.white : _accent,
            size: sw * 0.065,
          ),
        ),
      ),
      SizedBox(width: sw * 0.04),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            isPlaying ? 'Playing recitation…' : 'Listen to recitation',
            style: TextStyle(
              fontSize: sw * 0.035,
              color: isPlaying ? _textHi : _textLo,
              fontWeight:
              isPlaying ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          _Waveform(isPlaying: isPlaying, ctrl: waveCtrl),
        ]),
      ),
    ]),
  );
}

// ─── Waveform ────────────────────────────────────────────────────────────────
class _Waveform extends StatelessWidget {
  final bool isPlaying;
  final AnimationController ctrl;
  const _Waveform({required this.isPlaying, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    const hs = [8.0, 14.0, 6.0, 18.0, 10.0, 16.0, 8.0, 12.0, 5.0, 17.0];
    return SizedBox(
      height: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: hs.asMap().entries.map((e) {
          if (!isPlaying) {
            return Container(
              width: 3,
              height: e.value * 0.38,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: _textLo.withOpacity(0.22),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }
          final offset = e.key * 0.1;
          return AnimatedBuilder(
            animation: ctrl,
            builder: (_, __) {
              final t = (ctrl.value + offset) % 1.0;
              final h =
                  e.value * (0.35 + 0.65 * (t < 0.5 ? t * 2 : (1 - t) * 2));
              return Container(
                width: 3, height: h,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
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