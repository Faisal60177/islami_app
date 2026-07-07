import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';

// ── Models ────────────────────────────────────────────────────────────────────

enum ClickMode { sound, vibrate, mute }

class _HistoryEntry {
  final String dhikr;
  final int rounds;
  final int target;
  final DateTime time;

  _HistoryEntry({
    required this.dhikr,
    required this.rounds,
    required this.target,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
    'dhikr': dhikr,
    'rounds': rounds,
    'target': target,
    'time': time.toIso8601String(),
  };

  factory _HistoryEntry.fromJson(Map<String, dynamic> j) => _HistoryEntry(
    dhikr: j['dhikr'],
    rounds: j['rounds'],
    target: j['target'],
    time: DateTime.parse(j['time']),
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────

class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key});

  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {

  // ── dhikr options ──────────────────────────────────────────────────────────
  final List<String> _dhikrOptions = [
    'SubhanAllah',
    'Alhamdulillah',
    'Allahu Akbar',
    'Astaghfirullah',
    'La ilaha illAllah',
    'Salawat',
  ];
  int _dhikrIndex = 0;

  // ── counter state ──────────────────────────────────────────────────────────
  int _current   = 0;
  int _rounds    = 0;
  int _totalEver = 0;
  int _target    = 33;

  // ── preset targets ─────────────────────────────────────────────────────────
  final List<int> _presets = [11, 33, 99, 100];

  // ── mode ───────────────────────────────────────────────────────────────────
  ClickMode _mode = ClickMode.sound;

  // ── animation ─────────────────────────────────────────────────────────────
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  // ── misc ───────────────────────────────────────────────────────────────────
  final AudioPlayer _audio = AudioPlayer();
  List<_HistoryEntry> _history = [];
  bool _justCompleted = false;

  // ── theme (updated every build) ─────────────────────────────────────────────
  // Semantic colors kept independent of app theme:
  static const Color _red  = Color(0xFFE24B4A);
  static const Color _gold = Color(0xFFFFD700);
  late AppThemeOption _theme;

  // ── init ───────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // ← observe lifecycle

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    )..addListener(() => setState(() {}));

    _loadPersisted();
  }

  // ── lifecycle: save on pause (app goes to background / closed) ────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _persistCurrentSession();
    }
  }

  // ── persist helpers ────────────────────────────────────────────────────────

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final histJson = prefs.getStringList('tasbih_history') ?? [];

    setState(() {
      _totalEver  = prefs.getInt('tasbih_total')       ?? 0;
      _dhikrIndex = prefs.getInt('tasbih_dhikr_index') ?? 0;
      _target     = prefs.getInt('tasbih_target')      ?? 33;
      _rounds     = prefs.getInt('tasbih_rounds')      ?? 0;
      _current    = prefs.getInt('tasbih_current')     ?? 0;
      _mode       = ClickMode.values[prefs.getInt('tasbih_mode') ?? 0];

      _history = histJson
          .map((s) => _HistoryEntry.fromJson(jsonDecode(s)))
          .toList()
          .reversed
          .take(10)
          .toList();
    });

    // Restore ring progress after state is set
    if (_current > 0 || _rounds > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateTo(_target > 0 ? _current / _target : 0);
      });
    }
  }

  /// Saves everything including current in-progress round
  Future<void> _persistCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbih_total',       _totalEver);
    await prefs.setInt('tasbih_dhikr_index', _dhikrIndex);
    await prefs.setInt('tasbih_target',      _target);
    await prefs.setInt('tasbih_rounds',      _rounds);
    await prefs.setInt('tasbih_current',     _current);  // ← NEW: save current
    await prefs.setInt('tasbih_mode',        _mode.index);
    await prefs.setStringList(
      'tasbih_history',
      _history.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  /// Saves completed history entries only (called after finish)
  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbih_total', _totalEver);
    await prefs.setStringList(
      'tasbih_history',
      _history.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _persistCurrentSession(); // save on widget dispose too
    _ctrl.dispose();
    _audio.dispose();
    super.dispose();
  }

  // ── counter logic ──────────────────────────────────────────────────────────

  void _increment() {
    if (_current >= _target) return;

    setState(() {
      _current++;
      _totalEver++;
      _justCompleted = false;
    });

    _animateTo(_current / _target);
    _playEffect(long: false);

    if (_current == _target) {
      _onRoundComplete();
    }
  }

  void _onRoundComplete() {
    setState(() {
      _rounds++;
      _justCompleted = true;
    });

    if (_mode == ClickMode.vibrate) {
      Vibration.hasVibrator().then((has) {
        if (has ?? false) Vibration.vibrate(duration: 600);
      });
    } else if (_mode == ClickMode.sound) {
      Future.delayed(const Duration(milliseconds: 300), () => _audio.resume());
    }

    _showCompletionFlash();
  }

  void _showCompletionFlash() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: _theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'Round Complete!',
                style: TextStyle(
                    color: _theme.textHigh,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '$_target × $_rounds = ${_target * _rounds} ${_dhikrOptions[_dhikrIndex]}',
                textAlign: TextAlign.center,
                style: TextStyle(color: _theme.textLow, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _resetCurrent();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: _theme.accent),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text('Continue',
                            style: TextStyle(
                                color: _theme.accent, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _saveToHistory();
                        _resetFull();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _theme.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text('Finish',
                            style: TextStyle(
                                color: _theme.background, fontWeight: FontWeight.w700)),
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

  void _resetCurrent() {
    setState(() {
      _current = 0;
      _justCompleted = false;
    });
    _animateTo(0);
    _persistCurrentSession();
  }

  void _resetFull() {
    setState(() {
      _current = 0;
      _rounds  = 0;
      _justCompleted = false;
    });
    _animateTo(0);
    _persistCurrentSession();
  }

  void _saveToHistory() {
    if (_rounds == 0) return;
    final entry = _HistoryEntry(
      dhikr: _dhikrOptions[_dhikrIndex],
      rounds: _rounds,
      target: _target,
      time: DateTime.now(),
    );
    setState(() {
      _history.insert(0, entry);
      if (_history.length > 20) _history.removeLast();
    });
    _persistHistory();
  }

  // ── animation helper ───────────────────────────────────────────────────────

  void _animateTo(double end) {
    _anim = Tween<double>(begin: _anim.value, end: end).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    )..addListener(() => setState(() {}));
    _ctrl
      ..reset()
      ..forward();
  }

  // ── audio / haptic ─────────────────────────────────────────────────────────

  void _playEffect({required bool long}) {
    switch (_mode) {
      case ClickMode.sound:
        _audio.play(AssetSource('sounds/tasbih_click.mp3'));
        break;
      case ClickMode.vibrate:
        Vibration.hasVibrator().then((has) {
          if (has ?? false) Vibration.vibrate(duration: long ? 500 : 40);
        });
        break;
      case ClickMode.mute:
        break;
    }
  }

  // ── mode icon helper ───────────────────────────────────────────────────────

  IconData get _modeIcon {
    switch (_mode) {
      case ClickMode.sound:   return Icons.volume_up_rounded;
      case ClickMode.vibrate: return Icons.vibration_rounded;
      case ClickMode.mute:    return Icons.volume_off_rounded;
    }
  }

  String get _modeLabel {
    switch (_mode) {
      case ClickMode.sound:   return 'Sound';
      case ClickMode.vibrate: return 'Vibrate';
      case ClickMode.mute:    return 'Muted';
    }
  }

  Color get _modeColor {
    switch (_mode) {
      case ClickMode.sound:   return _theme.accent;
      case ClickMode.vibrate: return _gold;
      case ClickMode.mute:    return _red;
    }
  }

  // ── show mode bottom sheet ─────────────────────────────────────────────────

  void _showModeSheet() {
    final modes = [
      (ClickMode.sound,   Icons.volume_up_rounded,  'Sound',   'Play a click sound'),
      (ClickMode.vibrate, Icons.vibration_rounded,  'Vibrate', 'Haptic feedback'),
      (ClickMode.mute,    Icons.volume_off_rounded, 'Muted',   'No feedback'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: _theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: _theme.cardColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Feedback Mode',
              style: TextStyle(
                  color: _theme.textHigh,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose how the counter responds when you tap',
              style: TextStyle(color: _theme.textLow, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ...modes.map((m) {
              final active = _mode == m.$1;
              return GestureDetector(
                onTap: () {
                  setState(() => _mode = m.$1);
                  _persistCurrentSession();
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: active ? _theme.cardColor : _theme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active ? _theme.accent : _theme.cardColor,
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: active
                              ? _theme.accent.withOpacity(0.2)
                              : _theme.cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(m.$2,
                            color: active ? _theme.accent : _theme.textLow, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.$3,
                                style: TextStyle(
                                    color: active ? _theme.textHigh : _theme.textLow,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    fontSize: 14)),
                            Text(m.$4,
                                style: TextStyle(
                                    color: _theme.textLow, fontSize: 11)),
                          ],
                        ),
                      ),
                      if (active)
                        Icon(Icons.check_circle_rounded,
                            color: _theme.accent, size: 20),
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

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        _theme = getThemeById(settings.themeMode);
        final sw = MediaQuery.of(context).size.width;
        final sh = MediaQuery.of(context).size.height;

        return Scaffold(
          backgroundColor: _theme.background,
          appBar: AppBar(
            backgroundColor: _theme.background,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: _theme.textHigh),
              onPressed: () {
                _persistCurrentSession();
                Navigator.pop(context);
              },
            ),
            title: Text(
              'Tasbih Counter',
              style: TextStyle(color: _theme.textHigh, fontWeight: FontWeight.w600),
            ),
            actions: [
              // ── Feedback mode pill (tappable) ────────────────────────────────
              GestureDetector(
                onTap: _showModeSheet,
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _modeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _modeColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_modeIcon, color: _modeColor, size: 15),
                      const SizedBox(width: 5),
                      Text(
                        _modeLabel,
                        style: TextStyle(
                          color: _modeColor,
                          fontSize: sw * 0.028,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Grand total chip ─────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Total: $_totalEver',
                  style: TextStyle(
                      color: _theme.textLow,
                      fontSize: sw * 0.028,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.05, vertical: sw * 0.03),
            child: Column(
              children: [
                // ── Dhikr selector ─────────────────────────────────────────────
                _buildDhikrSelector(sw),
                SizedBox(height: sh * 0.025),

                // ── Progress ring ───────────────────────────────────────────────
                _buildProgressRing(sw),
                SizedBox(height: sh * 0.02),

                // ── Stats row ───────────────────────────────────────────────────
                _buildStatsRow(sw),
                SizedBox(height: sh * 0.018),

                // ── Target presets ──────────────────────────────────────────────
                _buildTargetRow(sw),
                SizedBox(height: sh * 0.018),

                // ── Buttons ─────────────────────────────────────────────────────
                _buildButtons(sw),
                SizedBox(height: sh * 0.022),

                // ── History ─────────────────────────────────────────────────────
                if (_history.isNotEmpty) _buildHistory(sw),

                SizedBox(height: sh * 0.02),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Dhikr selector ─────────────────────────────────────────────────────────

  Widget _buildDhikrSelector(double sw) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_dhikrOptions.length, (i) {
          final active = i == _dhikrIndex;
          return GestureDetector(
            onTap: () {
              if (_current > 0 || _rounds > 0) {
                _saveToHistory();
              }
              setState(() {
                _dhikrIndex = i;
                _current = 0;
                _rounds  = 0;
              });
              _animateTo(0);
              _persistCurrentSession();
            },
            child: Container(
              margin: EdgeInsets.only(right: sw * 0.025),
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.04, vertical: sw * 0.018),
              decoration: BoxDecoration(
                color: active ? _theme.accent : _theme.surface,
                border: Border.all(
                    color: active ? _theme.accent : _theme.cardColor, width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _dhikrOptions[i],
                style: TextStyle(
                  color: active ? _theme.background : _theme.textLow,
                  fontSize: sw * 0.032,
                  fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Progress ring ──────────────────────────────────────────────────────────

  Widget _buildProgressRing(double sw) {
    final size   = sw * 0.65;
    final stroke = size * 0.065;

    return GestureDetector(
      onTap: _increment,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer decorative ring
          Container(
            width: size + 16,
            height: size + 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _theme.cardColor, width: 1),
            ),
          ),

          // Progress ring
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RingPainter(
                progress: _anim.value,
                trackColor: _theme.cardColor,
                progressColor: _justCompleted ? _gold : _theme.accent,
                strokeWidth: stroke,
              ),
            ),
          ),

          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_current',
                style: TextStyle(
                  color: _theme.textHigh,
                  fontSize: size * 0.26,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Text(
                'of $_target',
                style: TextStyle(color: _theme.textLow, fontSize: size * 0.08),
              ),
              SizedBox(height: size * 0.02),
              Text(
                _dhikrOptions[_dhikrIndex],
                style: TextStyle(
                    color: _theme.accent,
                    fontSize: size * 0.07,
                    fontWeight: FontWeight.w500),
              ),
              if (_rounds > 0) ...[
                SizedBox(height: size * 0.03),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(
                    color: _gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_rounds× completed',
                    style: TextStyle(
                        color: _theme.background,
                        fontSize: size * 0.065,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),

          // Tap hint
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: _theme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _theme.cardColor),
              ),
              child: Text(
                'Tap ring to count',
                style: TextStyle(color: _theme.textLow, fontSize: sw * 0.028),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────

  Widget _buildStatsRow(double sw) {
    final totalSession = _rounds * _target + _current;
    final items = [
      ('Current', '$_current'),
      ('This session', '$totalSession'),
      ('Rounds', '$_rounds'),
    ];
    return Row(
      children: items
          .map((item) => Expanded(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: sw * 0.012),
          padding: EdgeInsets.symmetric(
              vertical: sw * 0.03, horizontal: sw * 0.02),
          decoration: BoxDecoration(
            color: _theme.accent,
            borderRadius: BorderRadius.circular(sw * 0.03),
          ),
          child: Column(
            children: [
              Text(
                item.$2,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 0, // overridden below
                ).copyWith(fontSize: sw * 0.05, fontWeight: FontWeight.w700),
              ),
              Text(
                item.$1,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: sw * 0.026),
              ),
            ],
          ),
        ),
      ))
          .toList(),
    );
  }

  // ── Target presets ─────────────────────────────────────────────────────────

  Widget _buildTargetRow(double sw) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.04, vertical: sw * 0.03),
      decoration: BoxDecoration(
        color: _theme.surface,
        borderRadius: BorderRadius.circular(sw * 0.03),
      ),
      child: Row(
        children: [
          Text('Target',
              style: TextStyle(color: _theme.textLow, fontSize: sw * 0.038)),
          const Spacer(),
          ..._presets.map((p) {
            final active = _target == p;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _target  = p;
                  _current = 0;
                  _rounds  = 0;
                });
                _animateTo(0);
                _persistCurrentSession();
              },
              child: Container(
                margin: EdgeInsets.only(left: sw * 0.02),
                padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.035, vertical: sw * 0.015),
                decoration: BoxDecoration(
                  color: active ? _theme.accent : _theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$p',
                  style: TextStyle(
                    color: active ? _theme.background : _theme.textLow,
                    fontSize: sw * 0.032,
                    fontWeight:
                    active ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
          // Custom target input
          GestureDetector(
            onTap: _showCustomTargetDialog,
            child: Container(
              margin: EdgeInsets.only(left: sw * 0.02),
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.035, vertical: sw * 0.015),
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
    );
  }

  void _showCustomTargetDialog() {
    final ctrl = TextEditingController(text: '$_target');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _theme.surface,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Set custom target',
            style: TextStyle(color: _theme.textHigh)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: TextStyle(color: _theme.textHigh),
          decoration: InputDecoration(
            labelText: 'Count',
            labelStyle: TextStyle(color: _theme.textLow),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _theme.cardColor),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _theme.accent),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _theme.textLow)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _theme.accent),
            onPressed: () {
              final v = int.tryParse(ctrl.text);
              if (v != null && v > 0) {
                setState(() {
                  _target  = v;
                  _current = 0;
                  _rounds  = 0;
                });
                _animateTo(0);
                _persistCurrentSession();
              }
              Navigator.pop(context);
            },
            child: Text('Set', style: TextStyle(color: _theme.background)),
          ),
        ],
      ),
    );
  }

  // ── Buttons ────────────────────────────────────────────────────────────────

  Widget _buildButtons(double sw) {
    return Row(
      children: [
        // Reset button
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_rounds > 0) _saveToHistory();
              _resetFull();
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: sw * 0.038),
              decoration: BoxDecoration(
                border: Border.all(color: _red, width: 1.5),
                borderRadius: BorderRadius.circular(sw * 0.03),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, color: _red, size: sw * 0.05),
                  const SizedBox(width: 6),
                  Text('Reset',
                      style: TextStyle(
                          color: _red,
                          fontSize: sw * 0.038,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: sw * 0.03),
        // Count button
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _increment,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: sw * 0.038),
              decoration: BoxDecoration(
                color: _theme.accent,
                borderRadius: BorderRadius.circular(sw * 0.03),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: _theme.background, size: sw * 0.06),
                  const SizedBox(width: 6),
                  Text('Count',
                      style: TextStyle(
                          color: _theme.background,
                          fontSize: sw * 0.042,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── History ────────────────────────────────────────────────────────────────

  Widget _buildHistory(double sw) {
    return Container(
      padding: EdgeInsets.all(sw * 0.04),
      decoration: BoxDecoration(
        color: _theme.surface,
        borderRadius: BorderRadius.circular(sw * 0.03),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Session history',
                  style: TextStyle(
                      color: _theme.textLow,
                      fontSize: sw * 0.035,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  setState(() => _history.clear());
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('tasbih_history');
                },
                child: Text('Clear',
                    style: TextStyle(color: _red, fontSize: sw * 0.03)),
              ),
            ],
          ),
          SizedBox(height: sw * 0.02),
          ..._history.take(8).map((e) {
            final total = e.rounds * e.target;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: sw * 0.015),
              child: Row(
                children: [
                  Container(
                    width: sw * 0.02,
                    height: sw * 0.02,
                    decoration: BoxDecoration(
                        color: _theme.accent, shape: BoxShape.circle),
                  ),
                  SizedBox(width: sw * 0.025),
                  Expanded(
                    child: Text(e.dhikr,
                        style: TextStyle(
                            color: _theme.textHigh, fontSize: sw * 0.033)),
                  ),
                  Text(
                    '${e.target} × ${e.rounds} = $total',
                    style: TextStyle(
                        color: _theme.textLow,
                        fontSize: sw * 0.03,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Ring Painter ──────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = (size.width - strokeWidth) / 2;
    const start = -1.5707963; // -90° = 12 o'clock

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), r, trackPaint);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start,
        2 * 3.14159265 * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
          old.progressColor != progressColor ||
          old.trackColor != trackColor;
}