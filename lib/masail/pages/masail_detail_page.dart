import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/masail_cubit.dart';
import '../model/masail_model.dart';
import 'package:muslim_app/utils/language_utils.dart';
import 'package:muslim_app/settings/l10n/app_localizations.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';

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
    final theme = getThemeById(context.read<SettingsCubit>().state.themeMode);
    final l10n = AppLocalizations(
        context.read<SettingsCubit>().state.languageCode);
    _toast(
      _masail.isBookmarked
          ? l10n.addedToBookmarked
          : l10n.removedFromBookmark,
      _masail.isBookmarked ? theme.accent : theme.textLow,
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
    final theme = getThemeById(context.read<SettingsCubit>().state.themeMode);
    final l10n = AppLocalizations(
        context.read<SettingsCubit>().state.languageCode);
    _toast(l10n.copiedToClipboard, theme.accent);
  }

  void _toast(String msg, Color color) {
    final theme = getThemeById(context.read<SettingsCubit>().state.themeMode);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        behavior:        SnackBarBehavior.floating,
        backgroundColor: theme.cardColor,
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
              style: TextStyle(
                  color: theme.textHigh, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = getThemeById(context.watch<SettingsCubit>().state.themeMode);
    final sw = MediaQuery.of(context).size.width;
    final l10n = AppLocalizations(
        context.read<SettingsCubit>().state.languageCode);

    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          backgroundColor: theme.surface,
          elevation:       0,
          leading: IconButton(
            icon: Icon(
              _isRtl
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_new_rounded,
              color: theme.accent,
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
                  color:      theme.textHigh,
                  fontSize:   sw * 0.042,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Mas\'ala #${_masail.id}',
                style: TextStyle(
                    color: theme.accent, fontSize: sw * 0.028),
              ),
            ],
          ),
          actions: [
            if (!_interactionLoaded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: theme.textLow, strokeWidth: 2),
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
                    color: _masail.isBookmarked ? theme.accent : theme.textLow,
                    size:  sw * 0.058,
                  ),
                ),
              ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  color: theme.textLow, size: sw * 0.055),
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onSelected: (v) {
                if (v == 'copy') _copyMasail();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'copy',
                  child: Row(children: [
                    Icon(Icons.copy_rounded, color: theme.textLow, size: 18),
                    const SizedBox(width: 12),
                    Text(l10n.copy,
                        style: TextStyle(color: theme.textHigh, fontSize: 14)),
                  ]),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: theme.accent.withOpacity(0.2)),
          ),
        ),
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
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
                            color: theme.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: theme.accent.withOpacity(0.4), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.school_rounded,
                                  size: sw * 0.035, color: theme.accent),
                              SizedBox(width: sw * 0.015),
                              Text(
                                _masail.madhab!,
                                style: TextStyle(
                                  fontSize:   sw * 0.032,
                                  color:      theme.accent,
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
                        color: theme.accent,
                        sw: sw,
                        isRtl: _isRtl),
                    SizedBox(height: sw * 0.03),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(sw * 0.045),
                      decoration: BoxDecoration(
                        color:         theme.cardColor,
                        borderRadius:  BorderRadius.circular(16),
                        border: Border.all(
                            color: theme.textLow.withOpacity(0.12), width: 1),
                      ),
                      child: Text(
                        _masail.question,
                        textAlign: _isRtl ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          fontSize:   sw * 0.038,
                          color:      theme.textHigh,
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
                            color: theme.accent,
                            sw:    sw,
                            isRtl: _isRtl,
                          ),
                          AnimatedRotation(
                            turns: _answerExpanded ? 0 : -0.25,
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: theme.textLow,
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
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.accent.withOpacity(0.18),
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
                              color:      theme.textHigh,
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

  Widget _ornament(AppThemeOption theme) => Row(children: [
    Expanded(child: Container(height: 1, color: theme.accent.withOpacity(0.3))),
    Container(
      margin: EdgeInsets.symmetric(horizontal: sw * 0.04),
      width: 6, height: 6,
      decoration: BoxDecoration(
          color: theme.accent.withOpacity(0.55), shape: BoxShape.circle),
    ),
    Container(
      margin: EdgeInsets.symmetric(horizontal: sw * 0.01),
      width: 4, height: 4,
      decoration: BoxDecoration(
          color: theme.accent.withOpacity(0.35), shape: BoxShape.circle),
    ),
    Container(
      margin: EdgeInsets.symmetric(horizontal: sw * 0.04),
      width: 6, height: 6,
      decoration: BoxDecoration(
          color: theme.accent.withOpacity(0.55), shape: BoxShape.circle),
    ),
    Expanded(child: Container(height: 1, color: theme.accent.withOpacity(0.3))),
  ]);

  @override
  Widget build(BuildContext context) {
    final theme = getThemeById(context.watch<SettingsCubit>().state.themeMode);
    return Container(
      width:   double.infinity,
      color:   theme.cardColor,
      padding: EdgeInsets.fromLTRB(
          sw * 0.06, sw * 0.085, sw * 0.06, sw * 0.085),
      child: Column(children: [
        _ornament(theme),
        SizedBox(height: sw * 0.07),
        Text(
          arabic,
          textAlign:     TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize:   sw * 0.072,
            color:      theme.textHigh,
            height:     2.0,
          ),
        ),
        SizedBox(height: sw * 0.07),
        _ornament(theme),
      ]),
    );
  }
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
  Widget build(BuildContext context) {
    final theme = getThemeById(context.watch<SettingsCubit>().state.themeMode);
    return Row(children: [
      Expanded(child: Container(height: 1, color: theme.textLow.withOpacity(0.12))),
      Container(
        margin: EdgeInsets.symmetric(horizontal: sw * 0.03),
        width: 4, height: 4,
        decoration: BoxDecoration(
            color: theme.accent.withOpacity(0.4), shape: BoxShape.circle),
      ),
      Expanded(child: Container(height: 1, color: theme.textLow.withOpacity(0.12))),
    ]);
  }
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
  Widget build(BuildContext context) {
    final theme = getThemeById(context.watch<SettingsCubit>().state.themeMode);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color:         theme.accent.withOpacity(0.1),
            borderRadius:  BorderRadius.circular(10),
          ),
          child: Icon(Icons.import_contacts_rounded,
              color: theme.accent, size: sw * 0.04),
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
                  color:         theme.accent,
                  letterSpacing: 1.4,
                ),
              ),
              SizedBox(height: sw * 0.015),
              Text(
                reference,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  fontSize: sw * 0.036,
                  color:    theme.textLow,
                  height:   1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}