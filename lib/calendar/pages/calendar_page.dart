import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:islamic_app/home/cubit/prayer_times_cubit.dart';
import 'package:islamic_app/home/cubit/prayer_times_state.dart';
import 'package:islamic_app/home/model/prayer_times_models.dart';

class MonthlyCalendarPage extends StatefulWidget {
  const MonthlyCalendarPage({super.key});

  @override
  State<MonthlyCalendarPage> createState() => _MonthlyCalendarPageState();
}

class _MonthlyCalendarPageState extends State<MonthlyCalendarPage>
    with TickerProviderStateMixin {
  late DateTime _focusedMonth;
  late DateTime _selectedDay;
  PrayerTimesModel? _selectedDayTimes;
  bool _loadingDay = false;

  late AnimationController _fadeController;
  late AnimationController _panelController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _panelAnimation;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _panelController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _panelAnimation = CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic);

    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTimesForDay(_selectedDay));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _panelController.dispose();
    super.dispose();
  }

  // ── load prayer times for any tapped day ─────────────────────────────────

  Future<void> _loadTimesForDay(DateTime day) async {
    setState(() => _loadingDay = true);
    _panelController.reset();
    final times = await context.read<PrayerTimesCubit>().calculateForDate(day);
    if (mounted) {
      setState(() {
        _selectedDay = day;
        _selectedDayTimes = times;
        _loadingDay = false;
      });
      _panelController.forward();
    }
  }

  // ── calendar helpers ──────────────────────────────────────────────────────

  List<DateTime?> _daysInMonthGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final leadingBlanks = firstDay.weekday % 7;
    final List<DateTime?> grid = List.filled(leadingBlanks, null, growable: true);
    for (int d = 1; d <= lastDay.day; d++) {
      grid.add(DateTime(_focusedMonth.year, _focusedMonth.month, d));
    }
    while (grid.length % 7 != 0) grid.add(null);
    return grid;
  }

  bool _isToday(DateTime? d) {
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isSelected(DateTime? d) {
    if (d == null) return false;
    return d.year == _selectedDay.year &&
        d.month == _selectedDay.month &&
        d.day == _selectedDay.day;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return "$h:$m $ampm";
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF080F0A),
      body: Stack(
        children: [
          // ── Background glow orbs ──
          Positioned(
            top: -sh * 0.05,
            right: -sw * 0.3,
            child: Container(
              width: sw * 0.8,
              height: sw * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF00A86B).withOpacity(0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: sh * 0.1,
            left: -sw * 0.3,
            child: Container(
              width: sw * 0.7,
              height: sw * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF0077B6).withOpacity(0.09),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Main Content ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
                builder: (context, state) {
                  if (state is PrayerTimesLoading && _selectedDayTimes == null) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: const Color(0xFF00A86B),
                        backgroundColor: Colors.white.withOpacity(0.1),
                        strokeWidth: 3,
                      ),
                    );
                  }
                  if (state is PrayerTimesError && _selectedDayTimes == null) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  final displayTimes = _selectedDayTimes ??
                      (state is PrayerTimesLoaded ? state.prayerTimes : null);

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: sw * 0.05,
                            vertical: sw * 0.04,
                          ),
                          child: Column(
                            children: [
                              _buildHeader(sw),
                              SizedBox(height: sh * 0.028),
                              _buildCalendarCard(sw, sh),
                              SizedBox(height: sh * 0.025),
                              if (_loadingDay)
                                _buildPanelLoading(sw, sh)
                              else if (displayTimes != null)
                                FadeTransition(
                                  opacity: _panelAnimation,
                                  child: _buildPrayerPanel(sw, sh, displayTimes),
                                )
                              else
                                _buildNoLocation(sw),
                              SizedBox(height: sh * 0.04),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(double sw) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.all(sw * 0.025),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(sw * 0.03),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: sw * 0.05,
            ),
          ),
        ),
        SizedBox(width: sw * 0.04),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Prayer Calendar",
              style: TextStyle(
                color: Colors.white,
                fontSize: sw * 0.058,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            Text(
              "Monthly prayer times at a glance",
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: sw * 0.032,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── calendar card ─────────────────────────────────────────────────────────

  Widget _buildCalendarCard(double sw, double sh) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(sw * 0.055),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(sw * 0.05),
      child: Column(
        children: [
          _buildMonthHeader(sw),
          SizedBox(height: sh * 0.022),
          _buildWeekdayRow(sw),
          SizedBox(height: sh * 0.01),
          _buildCalendarGrid(sw),
        ],
      ),
    );
  }

  // ── month nav header ──────────────────────────────────────────────────────

  Widget _buildMonthHeader(double sw) {
    final label = DateFormat('MMMM yyyy').format(_focusedMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _navBtn(Icons.chevron_left_rounded, () {
          final prev = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
          final lastDay = DateTime(prev.year, prev.month + 1, 0).day;
          final newSelected = DateTime(
            prev.year, prev.month, _selectedDay.day.clamp(1, lastDay),
          );
          setState(() => _focusedMonth = prev);
          _loadTimesForDay(newSelected);
        }),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: sw * 0.048,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        _navBtn(Icons.chevron_right_rounded, () {
          final next = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
          final lastDay = DateTime(next.year, next.month + 1, 0).day;
          final newSelected = DateTime(
            next.year, next.month, _selectedDay.day.clamp(1, lastDay),
          );
          setState(() => _focusedMonth = next);
          _loadTimesForDay(newSelected);
        }),
      ],
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00A86B), Color(0xFF007A4D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00A86B).withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // ── weekday row ───────────────────────────────────────────────────────────

  Widget _buildWeekdayRow(double sw) {
    const dayNames = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return Row(
      children: dayNames
          .map((n) => Expanded(
        child: Text(
          n,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: n == 'Fr'
                ? const Color(0xFF4DFFA6)
                : Colors.white.withOpacity(0.35),
            fontSize: sw * 0.03,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ))
          .toList(),
    );
  }

  // ── calendar grid ─────────────────────────────────────────────────────────

  Widget _buildCalendarGrid(double sw) {
    final days = _daysInMonthGrid();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: days.length,
      itemBuilder: (_, i) => _buildDayCell(days[i], sw),
    );
  }

  Widget _buildDayCell(DateTime? day, double sw) {
    if (day == null) return const SizedBox();

    final today = _isToday(day);
    final selected = _isSelected(day);

    return GestureDetector(
      onTap: () => _loadTimesForDay(day),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: today && selected
              ? const LinearGradient(
            colors: [Color(0xFF00A86B), Color(0xFF007A4D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : selected
              ? LinearGradient(
            colors: [
              const Color(0xFF00A86B).withOpacity(0.55),
              const Color(0xFF005F3B).withOpacity(0.4),
            ],
          )
              : null,
          color: today && !selected
              ? const Color(0xFF00A86B).withOpacity(0.18)
              : (!today && !selected ? Colors.transparent : null),
          borderRadius: BorderRadius.circular(sw * 0.022),
          border: selected
              ? Border.all(color: const Color(0xFF4DFFA6).withOpacity(0.5), width: 1)
              : today
              ? Border.all(
              color: const Color(0xFF00A86B).withOpacity(0.5), width: 1)
              : null,
          boxShadow: selected || today
              ? [
            BoxShadow(
              color: const Color(0xFF00A86B).withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: selected || today ? Colors.white : Colors.white.withOpacity(0.55),
            fontSize: sw * 0.033,
            fontWeight: selected || today ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ── panel loading ─────────────────────────────────────────────────────────

  Widget _buildPanelLoading(double sw, double sh) {
    return SizedBox(
      height: sh * 0.2,
      child: Center(
        child: CircularProgressIndicator(
          color: const Color(0xFF00A86B),
          backgroundColor: Colors.white.withOpacity(0.08),
          strokeWidth: 3,
        ),
      ),
    );
  }

  // ── no location ───────────────────────────────────────────────────────────

  Widget _buildNoLocation(double sw) {
    return Container(
      padding: EdgeInsets.all(sw * 0.08),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(sw * 0.05),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off_rounded,
              color: Colors.white.withOpacity(0.3), size: sw * 0.12),
          SizedBox(height: sw * 0.03),
          Text(
            'Location not available',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: sw * 0.04,
            ),
          ),
        ],
      ),
    );
  }

  // ── prayer panel ──────────────────────────────────────────────────────────

  Widget _buildPrayerPanel(double sw, double sh, PrayerTimesModel t) {
    final now = DateTime.now();
    final isTodaySelected = _selectedDay.year == now.year &&
        _selectedDay.month == now.month &&
        _selectedDay.day == now.day;

    final dayLabel = DateFormat('EEEE, d MMMM yyyy').format(_selectedDay);

    final prayers = [
      _PrayerEntry(Icons.wb_twilight_rounded, 'Fajr', '${_formatTime(t.fajrStart)} – ${_formatTime(t.fajrEnd)}', const Color(0xFF6A5ACD)),
      _PrayerEntry(Icons.wb_sunny_rounded, 'Dhuhr', '${_formatTime(t.dhuhrStart)} – ${_formatTime(t.dhuhrEnd)}', const Color(0xFFF5A623)),
      _PrayerEntry(Icons.cloud_rounded, 'Asr', '${_formatTime(t.asrStart)} – ${_formatTime(t.asrEnd)}', const Color(0xFF4FC3F7)),
      _PrayerEntry(Icons.nightlight_round, 'Maghrib', '${_formatTime(t.maghribStart)} – ${_formatTime(t.maghribEnd)}', const Color(0xFFFF7043)),
      _PrayerEntry(Icons.dark_mode_rounded, 'Isha', '${_formatTime(t.ishaStart)} – ${_formatTime(t.ishaEnd)}', const Color(0xFF7E57C2)),
      _PrayerEntry(Icons.restaurant_rounded, 'Sahri End', _formatTime(t.sahriEnd), const Color(0xFF26C6DA)),
      _PrayerEntry(Icons.local_dining_rounded, 'Iftar', _formatTime(t.iftarTime), const Color(0xFF66BB6A)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(sw * 0.055),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Panel Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: sw * 0.05,
              vertical: sw * 0.045,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00A86B), Color(0xFF005F3B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(sw * 0.055),
                topRight: Radius.circular(sw * 0.055),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(sw * 0.025),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: sw * 0.05,
                  ),
                ),
                SizedBox(width: sw * 0.035),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: sw * 0.038,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        "Prayer Times",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: sw * 0.03,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isTodaySelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: sw * 0.028,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Prayer rows
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: sw * 0.045,
              vertical: sw * 0.02,
            ),
            child: Column(
              children: prayers.asMap().entries.map((entry) {
                final idx = entry.key;
                final p = entry.value;
                final isLast = idx == prayers.length - 1;
                return Column(
                  children: [
                    _buildPrayerRow(sw, p),
                    if (!isLast)
                      Divider(
                        color: Colors.white.withOpacity(0.06),
                        height: 1,
                        thickness: 1,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
          SizedBox(height: sw * 0.02),
        ],
      ),
    );
  }

  Widget _buildPrayerRow(double sw, _PrayerEntry p) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sw * 0.032),
      child: Row(
        children: [
          Container(
            width: sw * 0.1,
            height: sw * 0.1,
            decoration: BoxDecoration(
              color: p.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(p.icon, color: p.color, size: sw * 0.048),
          ),
          SizedBox(width: sw * 0.035),
          Expanded(
            child: Text(
              p.name,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: sw * 0.038,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            p.time,
            style: TextStyle(
              color: Colors.white,
              fontSize: sw * 0.036,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerEntry {
  final IconData icon;
  final String name;
  final String time;
  final Color color;
  const _PrayerEntry(this.icon, this.name, this.time, this.color);
}