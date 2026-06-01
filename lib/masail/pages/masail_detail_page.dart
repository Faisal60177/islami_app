import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/masail_cubit.dart';
import '../model/masail_model.dart';
import 'package:muslim_app/utils/language_utils.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';

// ── Palette ────────────────────────────────────────────────────────────────────
const Color _bg        = Color(0xFFFAF6EF);
const Color _primary   = Color(0xFF6B1E2E);
const Color _primaryDk = Color(0xFF4A1220);
const Color _primaryLt = Color(0xFF8B2E42);
const Color _gold      = Color(0xFFD4AF37);
const Color _goldDk    = Color(0xFFB8860B);
const Color _surface   = Color(0xFFF2EBE0);
const Color _card      = Color(0xFFF7F1E8);
const Color _textHi    = Color(0xFF1C0A0F);
const Color _textMid   = Color(0xFF5C3D44);
const Color _textLo    = Color(0xFF9C7A82);
const Color _divider   = Color(0x1A6B1E2E);

class MasailDetailPage extends StatefulWidget {
  final MasailModel masail;
  const MasailDetailPage({super.key, required this.masail});

  @override
  State<MasailDetailPage> createState() => _MasailDetailPageState();
}

class _MasailDetailPageState extends State<MasailDetailPage>
    with TickerProviderStateMixin {

  late MasailModel _masail;
  late bool _isRtl;
  bool _interactionLoaded = false;
  bool _answerExpanded    = true; // answer open by default

  late AnimationController _bkmCtrl;
  late Animation<double>   _bkmBounce;

  @override
  void initState() {
    super.initState();
    _masail = widget.masail;

    final cubit = context.read<MasailCubit>();
    _isRtl = LanguageUtils.isRtl(cubit.currentLanguageCode);

    _bkmCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _bkmBounce = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 0.88), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _bkmCtrl, curve: Curves.easeOut));

    _loadInteraction();
  }

  Future<void> _loadInteraction() async {
    final cubit  = context.read<MasailCubit>();
    final result = await cubit.repository
        .getUserBookmarkForMasail(cubit.userId, _masail.id);
    if (result != null && mounted) {
      setState(() {
        _masail.isBookmarked = result['is_bookmarked'] == 1;
      });
    }
    if (mounted) setState(() => _interactionLoaded = true);
  }

  @override
  void dispose() {
    _bkmCtrl.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  void _toggleBookmark() {
    HapticFeedback.lightImpact();
    setState(() => _masail.isBookmarked = !_masail.isBookmarked);
    _bkmCtrl.forward(from: 0);
    final l10n = AppLocalizations(
        context.read<SettingsCubit>().state.languageCode);
    _toast(
      _masail.isBookmarked
          ? l10n.addedToBookmarked
          : l10n.removedFromBookmark,
      _masail.isBookmarked ? _primary : _textLo,
    );
    context.read<MasailCubit>().toggleBookmark(_masail);
  }

  void _copyMasail() {
    HapticFeedback.selectionClick();
    final buf = StringBuffer();
    // Arabic — only if present
    if (_masail.arabic != null && _masail.arabic!.isNotEmpty) {
      buf.writeln(_masail.arabic);
      buf.writeln();
    }
    buf.writeln('Q: ${_masail.question}');
    buf.writeln();
    buf.writeln('A: ${_masail.answer}');
    buf.writeln();
    buf.writeln('Reference: ${_masail.reference}');
    // Madhab — only if present
    if (_masail.madhab != null && _masail.madhab!.isNotEmpty) {
      buf.writeln('Madhab: ${_masail.madhab}');
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    final l10n = AppLocalizations(
        context.read<SettingsCubit>().state.languageCode);
    _toast(l10n.copiedToClipboard, _primary);
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        behavior:        SnackBarBehavior.floating,
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        duration: const Duration(seconds: 2),
        elevation: 0,
        content: Row(children: [
          Container(
            width: 4, height: 30,
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
    final l10n = AppLocalizations(
        context.read<SettingsCubit>().state.languageCode);

    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _primaryDk,
          elevation:       0,
          leading: IconButton(
            icon: Icon(
              _isRtl
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size:  17,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: _isRtl
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                _masail.categoryTitle,
                style: TextStyle(
                  color:      Colors.white,
                  fontSize:   sw * 0.042,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Mas\'ala #${_masail.id}',
                style: TextStyle(
                    color: _gold, fontSize: sw * 0.028),
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
                        color: Colors.white54, strokeWidth: 2),
                  ),
                ),
              )
            else
              ScaleTransition(
                scale: _bkmBounce,
                child: IconButton(
                  tooltip:   _masail.isBookmarked ? 'Remove' : 'Bookmark',
                  onPressed: _toggleBookmark,
                  icon: Icon(
                    _masail.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    color: _masail.isBookmarked ? _gold : Colors.white54,
                    size:  sw * 0.058,
                  ),
                ),
              ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  color: Colors.white54, size: sw * 0.055),
              color: _card,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onSelected: (v) {
                if (v == 'copy') _copyMasail();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'copy',
                  child: Row(children: [
                    const Icon(Icons.copy_rounded, color: _textLo, size: 18),
                    const SizedBox(width: 12),
                    Text(l10n.copy,
                        style: const TextStyle(color: _textHi, fontSize: 14)),
                  ]),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _gold.withOpacity(0.2)),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Arabic block — shown ONLY if arabic is not null/empty ──────
              if (_masail.arabic != null && _masail.arabic!.isNotEmpty)
                _ArabicHero(arabic: _masail.arabic!, sw: sw),

              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.05, vertical: sw * 0.04),
                child: Column(
                  crossAxisAlignment: _isRtl
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [

                    // ── Madhab badge — shown ONLY if madhab is not null/empty
                    if (_masail.madhab != null && _masail.madhab!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: sw * 0.04),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF5E6C0), Color(0xFFEDD898)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _goldDk.withOpacity(0.4), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.school_rounded,
                                  size: sw * 0.035, color: _goldDk),
                              SizedBox(width: sw * 0.015),
                              Text(
                                _masail.madhab!,
                                style: TextStyle(
                                  fontSize:   sw * 0.032,
                                  color:      _goldDk,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Question section ────────────────────────────────────
                    _SectionHeader(
                        label: 'Question', // l10n.question
                        icon: Icons.help_outline_rounded,
                        color: _primary,
                        sw: sw,
                        isRtl: _isRtl),
                    SizedBox(height: sw * 0.03),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(sw * 0.045),
                      decoration: BoxDecoration(
                        color:         _card,
                        borderRadius:  BorderRadius.circular(16),
                        border: Border.all(color: _divider, width: 1),
                      ),
                      child: Text(
                        _masail.question,
                        textAlign: _isRtl ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          fontSize:   sw * 0.038,
                          color:      _textHi,
                          height:     1.75,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    SizedBox(height: sw * 0.05),

                    // ── Answer section (collapsible) ────────────────────────
                    GestureDetector(
                      onTap: () =>
                          setState(() => _answerExpanded = !_answerExpanded),
                      child: Row(
                        textDirection: _isRtl
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionHeader(
                            label: 'Answer', // l10n.answer
                            icon:  Icons.lightbulb_outline_rounded,
                            color: const Color(0xFF1E6B2A),
                            sw:    sw,
                            isRtl: _isRtl,
                          ),
                          AnimatedRotation(
                            turns: _answerExpanded ? 0 : -0.25,
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _textLo,
                              size:  sw * 0.055,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 280),
                      crossFadeState: _answerExpanded
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: Padding(
                        padding: EdgeInsets.only(top: sw * 0.03),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(sw * 0.045),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF7EE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF2D6B1E).withOpacity(0.18),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _masail.answer,
                            textAlign: _isRtl
                                ? TextAlign.right
                                : TextAlign.left,
                            style: TextStyle(
                              fontSize:   sw * 0.038,
                              color:      const Color(0xFF1C3A1E),
                              height:     1.8,
                            ),
                          ),
                        ),
                      ),
                      secondChild: const SizedBox.shrink(),
                    ),

                    SizedBox(height: sw * 0.05),

                    // ── Reference ───────────────────────────────────────────
                    _DividerLine(sw: sw),
                    SizedBox(height: sw * 0.04),
                    _ReferenceBlock(
                      reference: _masail.reference,
                      sw:        sw,
                      isRtl:     _isRtl,
                    ),

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
}


// ── Arabic Hero ───────────────────────────────────────────────────────────────
class _ArabicHero extends StatelessWidget {
  final String arabic;
  final double sw;
  const _ArabicHero({required this.arabic, required this.sw});

  Widget _ornament() => Row(children: [
    Expanded(child: Container(height: 1, color: _gold.withOpacity(0.3))),
    Container(
      margin: EdgeInsets.symmetric(horizontal: sw * 0.04),
      width: 6, height: 6,
      decoration: BoxDecoration(
          color: _gold.withOpacity(0.55), shape: BoxShape.circle),
    ),
    Container(
      margin: EdgeInsets.symmetric(horizontal: sw * 0.01),
      width: 4, height: 4,
      decoration: BoxDecoration(
          color: _gold.withOpacity(0.35), shape: BoxShape.circle),
    ),
    Container(
      margin: EdgeInsets.symmetric(horizontal: sw * 0.04),
      width: 6, height: 6,
      decoration: BoxDecoration(
          color: _gold.withOpacity(0.55), shape: BoxShape.circle),
    ),
    Expanded(child: Container(height: 1, color: _gold.withOpacity(0.3))),
  ]);

  @override
  Widget build(BuildContext context) => Container(
    width:   double.infinity,
    color:   const Color(0xFFF7F1E8),
    padding: EdgeInsets.fromLTRB(
        sw * 0.06, sw * 0.085, sw * 0.06, sw * 0.085),
    child: Column(children: [
      _ornament(),
      SizedBox(height: sw * 0.07),
      Text(
        arabic,
        textAlign:     TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize:   sw * 0.072,
          color:      _textHi,
          height:     2.0,
        ),
      ),
      SizedBox(height: sw * 0.07),
      _ornament(),
    ]),
  );
}


// ── Section Header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String   label;
  final IconData icon;
  final Color    color;
  final double   sw;
  final bool     isRtl;
  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.color,
    required this.sw,
    required this.isRtl,
  });

  @override
  Widget build(BuildContext context) => Row(
    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
    mainAxisSize:  MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color:         color.withOpacity(0.1),
          borderRadius:  BorderRadius.circular(8),
        ),
        child: Icon(icon, size: sw * 0.038, color: color),
      ),
      SizedBox(width: sw * 0.02),
      Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize:      sw * 0.028,
          fontWeight:    FontWeight.w800,
          color:         color,
          letterSpacing: 1.4,
        ),
      ),
    ],
  );
}


// ── Divider ───────────────────────────────────────────────────────────────────
class _DividerLine extends StatelessWidget {
  final double sw;
  const _DividerLine({required this.sw});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Container(height: 1, color: _divider)),
    Container(
      margin: EdgeInsets.symmetric(horizontal: sw * 0.03),
      width: 4, height: 4,
      decoration: BoxDecoration(
          color: _gold.withOpacity(0.4), shape: BoxShape.circle),
    ),
    Expanded(child: Container(height: 1, color: _divider)),
  ]);
}


// ── Reference Block ───────────────────────────────────────────────────────────
class _ReferenceBlock extends StatelessWidget {
  final String reference;
  final double sw;
  final bool   isRtl;
  const _ReferenceBlock({
    required this.reference,
    required this.sw,
    required this.isRtl,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
    children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color:         _goldDk.withOpacity(0.1),
          borderRadius:  BorderRadius.circular(10),
        ),
        child: Icon(Icons.import_contacts_rounded,
            color: _goldDk, size: sw * 0.04),
      ),
      SizedBox(width: sw * 0.03),
      Expanded(
        child: Column(
          crossAxisAlignment: isRtl
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              'REFERENCE',
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                fontSize:      sw * 0.026,
                fontWeight:    FontWeight.w800,
                color:         _goldDk,
                letterSpacing: 1.4,
              ),
            ),
            SizedBox(height: sw * 0.015),
            Text(
              reference,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                fontSize: sw * 0.036,
                color:    _textLo,
                height:   1.6,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}