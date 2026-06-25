import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/duas_cubit.dart';
import '../model/duas_model.dart';
import 'package:muslim_app/utils/language_utils.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';

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
  late String _userId;
  late bool _isRtl;         // ✅ NEW
  late bool _isArabicUser;  // ✅ NEW
  bool _isPlaying = false;
  bool _interactionLoaded = false;

  late AnimationController _waveCtrl;
  late AnimationController _favCtrl;
  late AnimationController _bkmCtrl;
  late Animation<double> _favBounce;
  late Animation<double> _bkmBounce;

  @override
  void initState() {
    super.initState();
    _dua = widget.dua;

    final cubit = context.read<DuasCubit>();
    _userId = cubit.userId;

    // ✅ resolve RTL and Arabic flags once — from cubit language
    _isRtl        = LanguageUtils.isRtl(cubit.currentLanguageCode);
    _isArabicUser = LanguageUtils.isArabicUser(cubit.currentLanguageCode);

    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

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

    _loadUserInteraction();
  }

  Future<void> _loadUserInteraction() async {
    final interaction = await context.read<DuasCubit>()
        .repository.getUserInteractionForDua(_userId, _dua.id);
    if (interaction != null && mounted) {
      setState(() {
        _dua.isFavorite   = interaction['is_favorite']   == 1;
        _dua.isBookmarked = interaction['is_bookmarked'] == 1;
        _interactionLoaded = true;
      });
    } else {
      setState(() => _interactionLoaded = true);
    }
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _favCtrl.dispose();
    _bkmCtrl.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────

  Future<void> _toggleFavorite() async {
    HapticFeedback.lightImpact();
    setState(() => _dua.isFavorite = !_dua.isFavorite);
    _favCtrl.forward(from: 0);
    final l10n = AppLocalizations(context.read<SettingsCubit>().state.languageCode);
    _toast(
      _dua.isFavorite ? l10n.addedToFavorites : l10n.removedFromFavorites,
      _dua.isFavorite ? const Color(0xFFE57373) : _textLo,
    );
    context.read<DuasCubit>().toggleFavorite(_dua);
  }

  Future<void> _toggleBookmark() async {
    HapticFeedback.lightImpact();
    setState(() => _dua.isBookmarked = !_dua.isBookmarked);
    _bkmCtrl.forward(from: 0);
    final l10n = AppLocalizations(context.read<SettingsCubit>().state.languageCode);
    _toast(
      _dua.isBookmarked ? l10n.addedToBookmarked : l10n.removedFromBookmark,
      _dua.isBookmarked ? const Color(0xFF64B5F6) : _textLo,
    );
    context.read<DuasCubit>().toggleBookmark(_dua);
  }

  void _copyDua() {
    HapticFeedback.selectionClick();
    // ✅ translationText — single resolved string, no map needed
    final copyText = StringBuffer();
    copyText.writeln(_dua.arabic);
    copyText.writeln();
    // ✅ skip transliteration in copy for Arabic users
    if (!_isArabicUser && _dua.transliteration.isNotEmpty) {
      copyText.writeln(_dua.transliteration);
      copyText.writeln();
    }
    // ✅ skip translation in copy for Arabic users
    if (!_isArabicUser && _dua.translationText.isNotEmpty) {
      copyText.writeln(_dua.translationText);
      copyText.writeln();
    }
    if (_dua.reference.isNotEmpty) {
      copyText.write('Reference: ${_dua.reference}');
    }
    final l10n = AppLocalizations(context.read<SettingsCubit>().state.languageCode);
    Clipboard.setData(ClipboardData(text: copyText.toString()));
    _toast(l10n.copiedToClipboard, _accent);
  }

  void _shareDua() {
    HapticFeedback.selectionClick();
    final l10n = AppLocalizations(context.read<SettingsCubit>().state.languageCode);
    _toast(l10n.sharing, _accent);
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

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    final langCode = context.read<SettingsCubit>().state.languageCode;
    final l10n = AppLocalizations(langCode);

    // ✅ Directionality wraps entire page — RTL for Arabic/Urdu
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _surface,
          elevation: 0,
          leading: IconButton(
            // ✅ flip back arrow for RTL
            icon: Icon(
              _isRtl
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.arrow_back_ios_new_rounded,
              color: _textHi,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: Column(
            // ✅ title alignment respects RTL
            crossAxisAlignment: _isRtl
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                _dua.title, // ✅ was _dua.tags — now uses resolved title
                style: TextStyle(
                    color: _textHi,
                    fontSize: sw * 0.042,
                    fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _dua.categoryTitle,
                style: TextStyle(color: _textLo, fontSize: sw * 0.028),
              ),
            ],
          ),
          actions: [
            if (!_interactionLoaded)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: _textLo, strokeWidth: 2),
                  ),
                ),
              )
            else ...[
              ScaleTransition(
                scale: _favBounce,
                child: IconButton(
                  tooltip: _dua.isFavorite ? l10n.unfavorite : l10n.favorite,
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
              ScaleTransition(
                scale: _bkmBounce,
                child: IconButton(
                  tooltip: _dua.isBookmarked
                      ? l10n.removeBookmark
                      : l10n.bookmark,
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
            ],
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  color: _textLo, size: sw * 0.058),
              color: _card,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onSelected: (val) {
                if (val == l10n.copy) _copyDua();
                if (val == l10n.share) _shareDua();
              },
              itemBuilder: (_) => [
                _menuItem(l10n.copy, Icons.copy_rounded, l10n.copyDua),
                _menuItem(l10n.share, Icons.share_rounded, l10n.shareDua),
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
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Arabic hero — always RTL inside, no change needed
              _ArabicHero(arabic: _dua.arabic, sw: sw),

              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.055, vertical: sw * 0.03),
                child: Column(
                  crossAxisAlignment: _isRtl
                      ? CrossAxisAlignment.end   // ✅ RTL alignment
                      : CrossAxisAlignment.start,
                  children: [

                    // ✅ Transliteration — hidden for Arabic users
                    if (!_isArabicUser && _dua.transliteration.isNotEmpty) ...[
                      _SectionLabel(l10n.transliteration, sw, _isRtl),
                      SizedBox(height: sw * 0.025),
                      Text(
                        _dua.transliteration,
                        textAlign: _isRtl ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          fontSize: sw * 0.04,
                          color: _textMid,
                          height: 1.8,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      _Divider(sw),
                    ],

                    // ✅ Translation — hidden for Arabic users
                    // Single resolved string — no language toggle needed
                    if (!_isArabicUser && _dua.translationText.isNotEmpty) ...[
                      _SectionLabel(l10n.translation, sw, _isRtl),
                      SizedBox(height: sw * 0.03),
                      Text(
                        _dua.translationText,
                        textAlign:
                        _isRtl ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          fontSize: sw * 0.04,
                          color: _textMid,
                          height: 1.85,
                        ),
                      ),
                      _Divider(sw),
                    ],

                    // ✅ Reference — always shown, respects RTL
                    if (_dua.reference.isNotEmpty) ...[
                      _ReferenceBlock(
                        reference: _dua.reference,
                        sw: sw,
                        isRtl: _isRtl,
                        referenceLabel: l10n.referenceLabel,
                      ),
                    ],

                    // ✅ Description — optional, hidden if null or empty
                    if (_dua.description != null &&
                        _dua.description!.isNotEmpty) ...[
                      _Divider(sw),
                      _SectionLabel(l10n.description, sw, _isRtl),
                      SizedBox(height: sw * 0.025),
                      Text(
                        _dua.description!,
                        textAlign:
                        _isRtl ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          fontSize: sw * 0.038,
                          color: _textMid,
                          height: 1.8,
                        ),
                      ),
                    ],

                    // ✅ Audio — optional, hidden if audioUrl is null
                    if (_dua.audioUrl != null &&
                        _dua.audioUrl!.isNotEmpty) ...[
                      _Divider(sw),
                      _AudioBar(
                        isPlaying: _isPlaying,
                        waveCtrl: _waveCtrl,
                        onToggle: _toggleAudio,
                        sw: sw,
                        playingText: l10n.playingRecitation,   // ← add
                        listenText: l10n.listenToRecitation,
                      ),
                    ],

                    SizedBox(height: sw * 0.1),
                  ],
                ),
              ),
            ],
          ),
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

// ─── Arabic Hero ──────────────────────────────────────────────────────────────
// ✅ No change needed — already uses TextDirection.rtl for arabic text
class _ArabicHero extends StatelessWidget {
  final String arabic;
  final double sw;
  const _ArabicHero({required this.arabic, required this.sw});

  Widget _ornament() => Row(children: [
    Expanded(
        child: Container(height: 1, color: _gold.withOpacity(0.22))),
    Container(
        margin: EdgeInsets.symmetric(horizontal: sw * 0.04),
        width: 5,
        height: 5,
        decoration: BoxDecoration(
            color: _gold.withOpacity(0.45), shape: BoxShape.circle)),
    Expanded(
        child: Container(height: 1, color: _gold.withOpacity(0.22))),
  ]);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _card,
      padding:
      EdgeInsets.fromLTRB(sw * 0.06, sw * 0.09, sw * 0.06, sw * 0.09),
      child: Column(children: [
        _ornament(),
        SizedBox(height: sw * 0.08),
        Text(
          arabic,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl, // ✅ always RTL — Arabic text
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

// ─── Section Label ────────────────────────────────────────────────────────────
// ✅ isRtl added for text alignment
class _SectionLabel extends StatelessWidget {
  final String text;
  final double sw;
  final bool isRtl; // ✅ NEW
  const _SectionLabel(this.text, this.sw, this.isRtl);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    textAlign: isRtl ? TextAlign.right : TextAlign.left,
    style: TextStyle(
      fontSize: sw * 0.027,
      fontWeight: FontWeight.w800,
      color: _accent,
      letterSpacing: 1.5,
    ),
  );
}

// ─── Divider ─────────────────────────────────────────────────────────────────
// ✅ No change needed
class _Divider extends StatelessWidget {
  final double sw;
  const _Divider(this.sw);

  @override
  Widget build(BuildContext context) => Container(
      margin: EdgeInsets.symmetric(vertical: sw * 0.06),
      height: 1,
      color: _divider);
}

// ─── Reference Block ─────────────────────────────────────────────────────────
// ✅ isRtl added — flips icon and text alignment
class _ReferenceBlock extends StatelessWidget {
  final String reference;
  final double sw;
  final bool isRtl;
  final String referenceLabel;
  const _ReferenceBlock({
    required this.reference,
    required this.sw,
    required this.isRtl,
    required this.referenceLabel,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.menu_book_rounded,
          color: _gold.withOpacity(0.65), size: sw * 0.042),
      SizedBox(width: sw * 0.03),
      Expanded(
        child: Column(
          // ✅ align to right for RTL
          crossAxisAlignment: isRtl
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              referenceLabel,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                fontSize: sw * 0.027,
                fontWeight: FontWeight.w800,
                color: _gold,
                letterSpacing: 1.4,
              ),
            ),
            SizedBox(height: sw * 0.015),
            Text(
              reference,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                fontSize: sw * 0.036,
                color: _textLo,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ─── Audio Bar ────────────────────────────────────────────────────────────────
// ✅ No change needed — audio player layout is universal
class _AudioBar extends StatelessWidget {
  final bool isPlaying;
  final AnimationController waveCtrl;
  final VoidCallback onToggle;
  final double sw;
  final String playingText; // ← add
  final String listenText;  // ← add
  const _AudioBar({
    required this.isPlaying,
    required this.waveCtrl,
    required this.onToggle,
    required this.sw,
    required this.playingText, // ← add
    required this.listenText,
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
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPlaying
                    ? playingText
                    : listenText,
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

// ─── Waveform ─────────────────────────────────────────────────────────────────
// ✅ No change needed
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
              final h = e.value *
                  (0.35 + 0.65 * (t < 0.5 ? t * 2 : (1 - t) * 2));
              return Container(
                width: 3,
                height: h,
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