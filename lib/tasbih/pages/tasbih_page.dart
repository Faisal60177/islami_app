import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';

import '../cubit/tasbih_cubit.dart';
import '../cubit/tasbih_state.dart';
import '../models/click_mode.dart';
import '../widgets/ring_painter.dart';

class TasbihPage extends StatelessWidget {
  const TasbihPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TasbihCubit()..load(),
      child: const _TasbihView(), // The private widget that does all the rendering.
    );
  }
}

class _TasbihView extends StatefulWidget {
  const _TasbihView();

  @override
  State<_TasbihView> createState() => _TasbihViewState();
}

class _TasbihViewState extends State<_TasbihView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _red = Color(0xFFE24B4A);
  static const Color _gold = Color(0xFFFFD700);

  late final AnimationController _ctrl;
  late Animation<double> _anim;
  late AppThemeOption _theme;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _ctrl = AnimationController(
      vsync: this, // `this` works because of SingleTickerProviderStateMixin above.
      duration: const Duration(milliseconds: 600), // How long one ring animation takes.
    );
    // Start with a "do nothing" animation (0 to 0) — it gets replaced by
    // `_animateTo()` the first time real progress data arrives.
    _anim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  // Re-targets the animation to end at a new progress value, then plays it
  // from the CURRENT visual position (`_anim.value`) — this avoids the
  // ring visually "jumping" if a new animation starts mid-flight.
  void _animateTo(double end) {
    _anim = Tween<double>(begin: _anim.value, end: end)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl
      ..reset() // Rewind the controller to the start (t=0).
      ..forward(); // Play forward from 0 to 1, driving the Tween above.
  }

  // Called by Flutter whenever the app's lifecycle state changes.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // App is going to background or closing — force-save immediately.
      // `context.read<TasbihCubit>()` grabs the Cubit WITHOUT subscribing
      // to rebuilds (unlike `context.watch`), which is correct here since
      // this callback doesn't rebuild any widget — it just calls a method.
      context.read<TasbihCubit>().persistNow();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Stop listening to lifecycle events.
    context.read<TasbihCubit>().persistNow(); // Final safety-net save on page close.
    _ctrl.dispose(); // Release animation resources.
    super.dispose(); // Always call super.dispose() last.
  }

  @override
  Widget build(BuildContext context) {
    // Outer BlocBuilder: rebuilds this whole subtree whenever the APP-WIDE
    // theme changes (this Cubit belongs to a different feature — Settings
    // — and already existed before this refactor).
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        _theme = getThemeById(settings.themeMode); // Resolve the active color palette.
        final sw = MediaQuery.of(context).size.width; // Screen width, used for responsive sizing.
        final sh = MediaQuery.of(context).size.height; // Screen height, same purpose.

        // MultiBlocListener lets us react to TasbihCubit state CHANGES with
        // side effects (things that are NOT "just render different pixels"
        // — like playing an animation or opening a dialog) without mixing
        // that logic into the widget-building code below.
        return MultiBlocListener(
          listeners: [
            // Listener #1: whenever `current` or `target` changes, animate
            // the ring to the new progress value.
            BlocListener<TasbihCubit, TasbihState>(
              // `listenWhen` is a filter — without it, this listener would
              // fire on EVERY state change (even unrelated ones like mode
              // changes), re-triggering the animation unnecessarily.
              listenWhen: (prev, curr) => prev.current != curr.current || prev.target != curr.target,
              listener: (context, state) => _animateTo(state.progress),
            ),
            // Listener #2: whenever `justCompleted` flips from false to
            // true (i.e. a round was JUST finished, not "is still true
            // from before"), show the celebration dialog exactly once.
            BlocListener<TasbihCubit, TasbihState>(
              listenWhen: (prev, curr) => !prev.justCompleted && curr.justCompleted,
              listener: (context, state) => _showCompletionFlash(context, state),
            ),
          ],
          // BlocBuilder: rebuilds ONLY the widgets returned here, and ONLY
          // when TasbihState actually changes (thanks to Equatable). This
          // is the direct replacement for every `setState(() {...})` call
          // in the original file.
          child: BlocBuilder<TasbihCubit, TasbihState>(
            builder: (context, state) {
              // While `load()` hasn't finished yet, show a spinner instead
              // of a half-populated screen.
              if (!state.isLoaded) {
                return Scaffold(
                  backgroundColor: _theme.background,
                  body: const Center(child: CircularProgressIndicator()),
                );
              }
              // Normal UI, built entirely from `state` (never from local
              // mutable fields).
              return Scaffold(
                backgroundColor: _theme.background,
                appBar: _buildAppBar(context, state, sw),
                body: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: sw * 0.05, vertical: sw * 0.03),
                  child: Column(
                    children: [
                      _buildDhikrSelector(context, state, sw),
                      SizedBox(height: sh * 0.014),
                      _buildActiveDhikrBanner(state, sw),
                      SizedBox(height: sh * 0.02), // Vertical spacer, sized relative to screen height.
                      _buildProgressRing(context, state, sw),
                      SizedBox(height: sh * 0.02),
                      _buildStatsRow(state, sw),
                      SizedBox(height: sh * 0.018),
                      _buildTargetRow(context, state, sw),
                      SizedBox(height: sh * 0.018),
                      _buildButtons(context, state, sw),
                      SizedBox(height: sh * 0.022),
                      // Only render the history card if there's something to show.
                      if (state.history.isNotEmpty) _buildHistory(context, state, sw),
                      SizedBox(height: sh * 0.02),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }


  PreferredSizeWidget _buildAppBar(BuildContext context, TasbihState state, double sw) {
    // `switch` expression (Dart 3 syntax) picks a value based on the enum
    // — cleaner than a chain of if/else or a classic switch statement.
    final modeColor = switch (state.mode) {
      ClickMode.sound => _theme.accent,
      ClickMode.vibrate => _gold,
      ClickMode.mute => _red,
    };
    final modeIcon = switch (state.mode) {
      ClickMode.sound => Icons.volume_up_rounded,
      ClickMode.vibrate => Icons.vibration_rounded,
      ClickMode.mute => Icons.volume_off_rounded,
    };
    final modeLabel = switch (state.mode) {
      ClickMode.sound => 'Sound',
      ClickMode.vibrate => 'Vibrate',
      ClickMode.mute => 'Muted',
    };

    return AppBar(
      backgroundColor: _theme.background, // Match the page background (no visual seam).
      elevation: 0, // No drop shadow under the app bar.
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: _theme.textHigh),
        onPressed: () {
          context.read<TasbihCubit>().persistNow(); // Save before leaving the page.
          Navigator.pop(context); // Go back to the previous screen.
        },
      ),
      title: Text('Tasbih Counter', style: TextStyle(color: _theme.textHigh, fontWeight: FontWeight.w600)),
      actions: [
        // Tappable pill showing the current feedback mode; opens the mode sheet.
        GestureDetector(
          onTap: () => _showModeSheet(context, state),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: modeColor.withOpacity(0.12), // Faint tinted background.
              borderRadius: BorderRadius.circular(20), // Fully rounded "pill" shape.
              border: Border.all(color: modeColor.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Row only as wide as its children need.
              children: [
                Icon(modeIcon, color: modeColor, size: 15),
                const SizedBox(width: 5), // Small horizontal gap.
                Text(modeLabel, style: TextStyle(color: modeColor, fontSize: sw * 0.028, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        // Read-only chip showing the lifetime total tap count.
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: _theme.cardColor, borderRadius: BorderRadius.circular(20)),
          child: Text('Total: ${state.totalEver}', // Directly reads from Cubit state — always in sync.
              style: TextStyle(color: _theme.textLow, fontSize: sw * 0.028, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildDhikrSelector(BuildContext context, TasbihState state, double sw) {

    final chipMaxWidth = sw * 0.42;
    return SizedBox(
      height: sw * 0.12,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.dhikrOptions.length,
        separatorBuilder: (_, __) => SizedBox(width: sw * 0.025),
        itemBuilder: (context, i) {
          final active = i == state.dhikrIndex;
          return GestureDetector(
            onTap: () => context.read<TasbihCubit>().selectDhikr(i),
            child: Container(
              constraints: BoxConstraints(maxWidth: chipMaxWidth, minWidth: sw * 0.24),
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: sw * 0.035, vertical: sw * 0.02),
              decoration: BoxDecoration(
                color: active ? _theme.accent : _theme.surface,
                border: Border.all(color: active ? _theme.accent : _theme.cardColor, width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                state.dhikrOptions[i],
                textAlign: TextAlign.center,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? _theme.background : _theme.textLow,
                  fontSize: sw * 0.03,
                  fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                  height: 1.25,
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildActiveDhikrBanner(TasbihState state, double sw) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: sw * 0.05, vertical: sw * 0.03),
      decoration: BoxDecoration(
        color: _theme.accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(sw * 0.03),
        border: Border.all(color: _theme.accent.withOpacity(0.35)),
      ),
      child: Text(
        state.activeDhikr,
        textAlign: TextAlign.center,
        maxLines: 2,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _theme.accent,
          fontSize: sw * 0.045,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildProgressRing(BuildContext context, TasbihState state, double sw) {
    final size = sw * 0.65; // Ring diameter as a fraction of screen width (responsive).
    final stroke = size * 0.065; // Ring thickness scales with the ring size.

    return GestureDetector(
      // Tapping ANYWHERE on the ring counts as one tap — calls the Cubit.
      onTap: () => context.read<TasbihCubit>().Increament(),
      child: Stack(
        alignment: Alignment.center, // All children centered on top of each other.
        children: [
          // Decorative outer ring (always fully visible, never animated).
          Container(
            width: size + 16,
            height: size + 16,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _theme.cardColor, width: 1)),
          ),

          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: RingPainter(
                  progress: _anim.value, // Current animated value (0.0–1.0), NOT state.progress directly.
                  trackColor: _theme.cardColor,
                  progressColor: state.justCompleted ? _gold : _theme.accent, // Gold flash right after completion.
                  strokeWidth: stroke,
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${state.current}',
                  style: TextStyle(color: _theme.textHigh, fontSize: size * 0.26, fontWeight: FontWeight.w800, height: 1)),
              Text('of ${state.target}', style: TextStyle(color: _theme.textLow, fontSize: size * 0.08)),
              // Only show the "rounds completed" badge once at least 1 round is done.
              if (state.rounds > 0) ...[
                SizedBox(height: size * 0.03),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(20)),
                  child: Text('${state.rounds}× completed',
                      style: TextStyle(color: _theme.background, fontSize: size * 0.065, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
          // Small "Tap ring to count" hint pinned to the bottom of the stack.
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: _theme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _theme.cardColor),
              ),
              child: Text('Tap ring to count', style: TextStyle(color: _theme.textLow, fontSize: sw * 0.028)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(TasbihState state, double sw) {
    final items = [
      ('Current', '${state.current}'),
      ('This session', '${state.sessionTotal}'),
      ('Rounds', '${state.rounds}'),
    ];
    return Row(
      children: items
          .map((item) => Expanded( // Each chip takes equal width (1/3 of the row).
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: sw * 0.012),
          padding: EdgeInsets.symmetric(vertical: sw * 0.01, horizontal: sw * 0.01),
          decoration: BoxDecoration(color: _theme.accent, borderRadius: BorderRadius.circular(sw * 0.03)),
          child: Column(
            children: [
              Text(item.$2, // `.$2` accesses the 2nd positional field of the record.
                  style: TextStyle(color: Colors.white, fontSize: sw * 0.05, fontWeight: FontWeight.w700)),
              Text(item.$1, // `.$1` accesses the 1st positional field (the label).
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: sw * 0.026)),
            ],
          ),
        ),
      ))
          .toList(),
    );
  }

  Widget _buildTargetRow(BuildContext context, TasbihState state, double sw) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.03),
      decoration: BoxDecoration(color: _theme.surface, borderRadius: BorderRadius.circular(sw * 0.03)),
      child: Row(
        children: [
          Text('Target', style: TextStyle(color: _theme.textLow, fontSize: sw * 0.038)),
          SizedBox(width: sw * 0.02),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true, // Keeps content right-aligned by default, like the old Spacer() look.
              child: Row(
                mainAxisSize: MainAxisSize.min, // Row is only as wide as its children need — scroll view handles overflow.
                children: [
                  ...state.presets.map((p) { // Spread a mapped list of widgets directly into `children`.
                    final active = state.target == p;
                    return GestureDetector(
                      onTap: () => context.read<TasbihCubit>().setTarget(p), // Directly sets the new target via the Cubit.
                      child: Container(
                        margin: EdgeInsets.only(left: sw * 0.02),
                        padding: EdgeInsets.symmetric(horizontal: sw * 0.035, vertical: sw * 0.015),
                        decoration: BoxDecoration(
                          color: active ? _theme.accent : _theme.cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$p',
                            style: TextStyle(
                              color: active ? _theme.background : _theme.textLow,
                              fontSize: sw * 0.032,
                              fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                            )),
                      ),
                    );
                  }),
                  // Edit icon opens a dialog for a custom (non-preset) target value.
                  GestureDetector(
                    onTap: () => _showCustomTargetDialog(context, state),
                    child: Container(
                      margin: EdgeInsets.only(left: sw * 0.02),
                      padding: EdgeInsets.symmetric(horizontal: sw * 0.035, vertical: sw * 0.015),
                      decoration: BoxDecoration(
                        color: _theme.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _theme.accent.withOpacity(0.4)),
                      ),
                      child: Icon(Icons.edit, color: _theme.textLow, size: sw * 0.04),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog with a text field for entering a custom target count.
  void _showCustomTargetDialog(BuildContext context, TasbihState state) {
    final cubit = context.read<TasbihCubit>();
    final ctrl = TextEditingController(text: '${state.target}'); // Pre-fill with the current target.
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Set custom target', style: TextStyle(color: _theme.textHigh)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number, // Shows the numeric keyboard.
          style: TextStyle(color: _theme.textHigh),
          decoration: InputDecoration(
            labelText: 'Count',
            labelStyle: TextStyle(color: _theme.textLow),
            enabledBorder:
            OutlineInputBorder(borderSide: BorderSide(color: _theme.cardColor), borderRadius: BorderRadius.circular(8)),
            focusedBorder:
            OutlineInputBorder(borderSide: BorderSide(color: _theme.accent), borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // Close without applying.
            child: Text('Cancel', style: TextStyle(color: _theme.textLow)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _theme.accent),
            onPressed: () {
              final v = int.tryParse(ctrl.text); // Returns null if the text isn't a valid integer.
              if (v != null && v > 0) cubit.setTarget(v); // Only apply valid, positive values.
              Navigator.pop(dialogContext);
            },
            child: Text('Set', style: TextStyle(color: _theme.background)),
          ),
        ],
      ),
    );
  }


  Widget _buildButtons(BuildContext context, TasbihState state, double sw) {
    final cubit = context.read<TasbihCubit>(); // Cached once, reused by both buttons below.
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (state.rounds > 0) cubit.saveToHistory(); // Save progress before wiping it.
              cubit.resetFull();
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: sw * 0.038),
              decoration: BoxDecoration(border: Border.all(color: _red, width: 1.5), borderRadius: BorderRadius.circular(sw * 0.03)),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, color: _red, size: sw * 0.05),
                  const SizedBox(width: 6),
                  Text('Reset', style: TextStyle(color: _red, fontSize: sw * 0.038, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: sw * 0.03), // Horizontal gap between the two buttons.
        Expanded(
          flex: 2, // Twice as wide as the Reset button — this is the primary action.
          child: GestureDetector(
            onTap: () => cubit.Increament(), // Same action as tapping the ring.
            child: Container(
              padding: EdgeInsets.symmetric(vertical: sw * 0.038),
              decoration: BoxDecoration(color: _theme.accent, borderRadius: BorderRadius.circular(sw * 0.03)),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: _theme.background, size: sw * 0.06),
                  const SizedBox(width: 6),
                  Text('Count', style: TextStyle(color: _theme.background, fontSize: sw * 0.042, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildHistory(BuildContext context, TasbihState state, double sw) {
    return Container(
      padding: EdgeInsets.all(sw * 0.04),
      decoration: BoxDecoration(color: _theme.surface, borderRadius: BorderRadius.circular(sw * 0.03)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Left-align text inside this column.
        children: [
          Row(
            children: [
              Text('Session history', style: TextStyle(color: _theme.textLow, fontSize: sw * 0.035, fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.read<TasbihCubit>().clearHistory(),
                child: Text('Clear', style: TextStyle(color: _red, fontSize: sw * 0.03)),
              ),
            ],
          ),
          SizedBox(height: sw * 0.02),
          ...state.history.take(8).map((e) => Padding(
            padding: EdgeInsets.symmetric(vertical: sw * 0.015),
            child: Row(
              children: [
                Container(width: sw * 0.02, height: sw * 0.02, decoration: BoxDecoration(color: _theme.accent, shape: BoxShape.circle)),
                SizedBox(width: sw * 0.025),
                Expanded(child: Text(e.dhikr, style: TextStyle(color: _theme.textHigh, fontSize: sw * 0.033))),
                Text('${e.target} × ${e.rounds} = ${e.total}', // `e.total` is the computed getter on HistoryEntry.
                    style: TextStyle(color: _theme.textLow, fontSize: sw * 0.03, fontWeight: FontWeight.w600)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showCompletionFlash(BuildContext context, TasbihState state) {
    final cubit = context.read<TasbihCubit>();
    showDialog(
      context: context,
      barrierColor: Colors.black54, // Dims the background behind the dialog.
      builder: (dialogContext) => Dialog(
        backgroundColor: _theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Only take as much vertical space as content needs.
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Round Complete!', style: TextStyle(color: _theme.textHigh, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('${state.target} × ${state.rounds} = ${state.target * state.rounds} ${state.activeDhikr}',
                  textAlign: TextAlign.center, style: TextStyle(color: _theme.textLow, fontSize: 14)),
              const SizedBox(height: 20),
              Row(
                children: [
                  // "Continue": keep the rounds tally, just reset the current tap count.
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(dialogContext);
                        cubit.resetCurrent();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(border: Border.all(color: _theme.accent), borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.center,
                        child: Text('Continue', style: TextStyle(color: _theme.accent, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // "Finish": save this session to history, then wipe everything.
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(dialogContext);
                        cubit.saveToHistory();
                        cubit.resetFull();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: _theme.accent, borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.center,
                        child: Text('Finish', style: TextStyle(color: _theme.background, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showModeSheet(BuildContext context, TasbihState state) {
    final cubit = context.read<TasbihCubit>();
    // A list of records (tuples): (mode, icon, label, description) — one
    // per selectable row, avoids repeating similar Container code 3 times.
    final modes = [
      (ClickMode.sound, Icons.volume_up_rounded, 'Sound', 'Play a click sound'),
      (ClickMode.vibrate, Icons.vibration_rounded, 'Vibrate', 'Haptic feedback'),
      (ClickMode.mute, Icons.volume_off_rounded, 'Muted', 'No feedback'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: _theme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Small grey "handle" bar, a common visual convention for bottom sheets.
            Center(
              child: Container(width: 36, height: 4, decoration: BoxDecoration(color: _theme.cardColor, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text('Feedback Mode', style: TextStyle(color: _theme.textHigh, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Choose how the counter responds when you tap', style: TextStyle(color: _theme.textLow, fontSize: 12)),
            const SizedBox(height: 16),
            // Build one selectable row per mode.
            ...modes.map((m) {
              final active = state.mode == m.$1; // `.$1` = the ClickMode field of the record.
              return GestureDetector(
                onTap: () {
                  cubit.setMode(m.$1); // Tell the Cubit to switch modes.
                  Navigator.pop(sheetContext); // Close the sheet.
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: active ? _theme.cardColor : _theme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: active ? _theme.accent : _theme.cardColor, width: active ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: active ? _theme.accent.withOpacity(0.2) : _theme.cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(m.$2, color: active ? _theme.accent : _theme.textLow, size: 20), // `.$2` = the IconData field.
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.$3, // `.$3` = the label field.
                                style: TextStyle(
                                    color: active ? _theme.textHigh : _theme.textLow,
                                    fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                                    fontSize: 14)),
                            Text(m.$4, style: TextStyle(color: _theme.textLow, fontSize: 11)), // `.$4` = the description field.
                          ],
                        ),
                      ),
                      // Checkmark shown only on the currently active mode.
                      if (active) Icon(Icons.check_circle_rounded, color: _theme.accent, size: 20),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}