import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:islamic_app/home/cubit/prayer_times_cubit.dart';
import 'package:islamic_app/home/state/prayer_times_state.dart';
import 'package:islamic_app/home/model/prayer_times_models.dart';

class MonthlyCalendarPage extends StatefulWidget {
  const MonthlyCalendarPage({super.key});

  @override
  State<MonthlyCalendarPage> createState() => _MonthlyCalendarPageState();
}

class _MonthlyCalendarPageState extends State<MonthlyCalendarPage> {
  late DateTime _focusedMonth;
  late DateTime _selectedDay;
  PrayerTimesModel? _selectedDayTimes;
  bool _loadingDay = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay  = DateTime(now.year, now.month, now.day);
    // Load today's times on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTimesForDay(_selectedDay));
  }

  // ── load prayer times for any tapped day ─────────────────────────────────

  Future<void> _loadTimesForDay(DateTime day) async {
    setState(() => _loadingDay = true);
    final times = await context.read<PrayerTimesCubit>().calculateForDate(day);
    if (mounted) {
      setState(() {
        _selectedDay      = day;
        _selectedDayTimes = times;
        _loadingDay       = false;
      });
    }
  }

  // ── calendar helpers ──────────────────────────────────────────────────────

  List<DateTime?> _daysInMonthGrid() {
    final firstDay     = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay      = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final leadingBlanks = firstDay.weekday % 7; // Sunday = 0
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
    final h    = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m    = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return "$h:$m $ampm";
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF013220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF013220),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Monthly Prayer Calendar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
        builder: (context, state) {
          if (state is PrayerTimesLoading && _selectedDayTimes == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            );
          }
          if (state is PrayerTimesError && _selectedDayTimes == null) {
            return Center(
              child: Text(state.message, style: const TextStyle(color: Colors.white)),
            );
          }

          // Use freshly calculated day times; fall back to cubit's today times
          final displayTimes = _selectedDayTimes ??
              (state is PrayerTimesLoaded ? state.prayerTimes : null);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.03),
            child: Column(
              children: [
                _buildMonthHeader(sw),
                SizedBox(height: sh * 0.018),
                _buildCalendarGrid(sw),
                SizedBox(height: sh * 0.022),
                if (_loadingDay)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                    ),
                  )
                else if (displayTimes != null)
                  _buildPrayerPanel(sw, displayTimes)
                else
                  const Center(
                    child: Text(
                      'Location not available',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── month nav header ──────────────────────────────────────────────────────

  Widget _buildMonthHeader(double sw) {
    final label = DateFormat('MMMM yyyy').format(_focusedMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _navBtn(Icons.chevron_left, () {
          final prev = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
          final lastDay = DateTime(prev.year, prev.month + 1, 0).day;
          final newSelected = DateTime(
            prev.year, prev.month,
            _selectedDay.day.clamp(1, lastDay),
          );
          setState(() => _focusedMonth = prev);
          _loadTimesForDay(newSelected);
        }),
        Text(label,
            style: TextStyle(
                color: Colors.white,
                fontSize: sw * 0.045,
                fontWeight: FontWeight.w600)),
        _navBtn(Icons.chevron_right, () {
          final next = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
          final lastDay = DateTime(next.year, next.month + 1, 0).day;
          final newSelected = DateTime(
            next.year, next.month,
            _selectedDay.day.clamp(1, lastDay),
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
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF74C365),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // ── calendar grid ─────────────────────────────────────────────────────────

  Widget _buildCalendarGrid(double sw) {
    final days    = _daysInMonthGrid();
    const dayNames = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    final cellSize = (sw - sw * 0.08) / 7;

    return Column(
      children: [
        Row(
          children: dayNames
              .map((n) => SizedBox(
            width: cellSize,
            child: Text(n,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF9FE1CB),
                  fontSize: sw * 0.030,
                  fontWeight: FontWeight.w500,
                )),
          ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: days.length,
          itemBuilder: (_, i) => _buildDayCell(days[i], sw),
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime? day, double sw) {
    if (day == null) return const SizedBox();

    final today    = _isToday(day);
    final selected = _isSelected(day);

    Color bg        = Colors.transparent;
    Color textColor = Colors.grey[400]!;

    if (today && selected) {
      bg        = const Color(0xFF4CAF50);
      textColor = Colors.white;
    } else if (selected) {
      bg        = const Color(0xFF74C365);
      textColor = Colors.white;
    } else if (today) {
      bg        = const Color(0xFF4CAF50).withOpacity(0.35);
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: () => _loadTimesForDay(day), // ✅ always re-fetches real times
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontSize: sw * 0.032,
            fontWeight: selected || today ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ── prayer panel ──────────────────────────────────────────────────────────

  Widget _buildPrayerPanel(double sw, PrayerTimesModel t) {
    final now = DateTime.now();
    final isTodaySelected = _selectedDay.year == now.year &&
        _selectedDay.month == now.month &&
        _selectedDay.day == now.day;

    final dayLabel = DateFormat('EEEE, d MMMM yyyy').format(_selectedDay);

    final prayers = [
      _PrayerEntry(Icons.wb_twilight,      'Fajr',     '${_formatTime(t.fajrStart)} – ${_formatTime(t.fajrEnd)}'),
      _PrayerEntry(Icons.wb_sunny,         'Dhuhr',    '${_formatTime(t.dhuhrStart)} – ${_formatTime(t.dhuhrEnd)}'),
      _PrayerEntry(Icons.cloud,            'Asr',      '${_formatTime(t.asrStart)} – ${_formatTime(t.asrEnd)}'),
      _PrayerEntry(Icons.nightlight_round, 'Maghrib',  '${_formatTime(t.maghribStart)} – ${_formatTime(t.maghribEnd)}'),
      _PrayerEntry(Icons.dark_mode,        'Isha',     '${_formatTime(t.ishaStart)} – ${_formatTime(t.ishaEnd)}'),
      _PrayerEntry(Icons.restaurant,       'Sahri End','${_formatTime(t.sahriEnd)}'),
      _PrayerEntry(Icons.local_dining,     'Iftar',    '${_formatTime(t.iftarTime)}'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF74C365),
        borderRadius: BorderRadius.circular(sw * 0.04),
      ),
      padding: EdgeInsets.all(sw * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dayLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: sw * 0.038,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isTodaySelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      color: const Color(0xFF013220),
                      fontSize: sw * 0.028,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: sw * 0.03),
          ...prayers.map((p) => _buildPrayerRow(sw, p)).toList(),
        ],
      ),
    );
  }

  Widget _buildPrayerRow(double sw, _PrayerEntry p) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sw * 0.018),
      child: Row(
        children: [
          Icon(p.icon, color: Colors.white70, size: sw * 0.055),
          SizedBox(width: sw * 0.03),
          Expanded(
            child: Text(p.name,
                style: TextStyle(color: Colors.white, fontSize: sw * 0.038)),
          ),
          Text(p.time,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: sw * 0.036,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PrayerEntry {
  final IconData icon;
  final String name;
  final String time;
  const _PrayerEntry(this.icon, this.name, this.time);
}