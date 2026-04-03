import 'package:flutter/material.dart';
import 'package:islamic_app/Menu/menu_page.dart';
import 'package:islamic_app/Quran/quran_page.dart';
import 'package:islamic_app/home/home_page.dart';
import 'package:islamic_app/Duas/pages/duas_page.dart';
import 'package:islamic_app/tasbih/tasbih_page.dart';
import 'package:islamic_app/inspiration/inspiration_page.dart';
import 'package:islamic_app/notification/page/notification_page.dart';
import 'package:islamic_app/calendar/pages/calendar_page.dart';
import 'package:islamic_app/qibla/pages/qibla_page.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const _bg        = Color(0xFF021A10);   // near-black deep forest
const _surface   = Color(0xFF0D2E1C);   // card base
const _card      = Color(0xFF143324);   // elevated card
const _accent    = Color(0xFF4CAF82);   // vibrant jade
const _accentSoft= Color(0xFF2E7D5A);   // muted jade
const _gold      = Color(0xFFD4A847);   // warm gold highlight
const _textHi    = Color(0xFFE8F5EE);   // near-white
const _textLo    = Color(0xFF7BAF92);   // muted sage

// ─── Section model ──────────────────────────────────────────────────────────
class _Section {
  final String title;
  final String subtitle;
  final Color accentColor;
  final List<_Tool> tools;
  const _Section(this.title, this.subtitle, this.accentColor, this.tools);
}

class _Tool {
  final String label;
  final String asset;
  final VoidCallback onTap;
  const _Tool(this.label, this.asset, this.onTap);
}

// ─── Page ───────────────────────────────────────────────────────────────────
class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  final List<Widget> _pages = const [
    PrayerTimesPage(),
    ToolsPage(),
    QuranPage(),
    DuasPage(),
    MenuPage(),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;

    // Responsive grid columns
    final cols = sw > 900 ? 5 : sw > 600 ? 4 : 3;

    // Sections data (lambdas capture context lazily – safe)
    final sections = [
      _Section('Knowledge', 'Learn & Explore', _accent, [
        _Tool('Quran',       'assets/icons/quran.png',
                () => _push(QuranPage())),
        _Tool('Duas',        'assets/icons/duas.png',
                () => _push(DuasPage())),
        _Tool('Masail',      'assets/icons/masail.png',
                () {}),
      ]),
      _Section('Amal', 'Worship & Reflect', _gold, [
        _Tool('Tasbih',      'assets/icons/tasbih.png',
                () => _push(TasbihPage())),
        _Tool('Prayer Times','assets/icons/prayer_time.png',
                () => _push(PrayerTimesPage())),
        _Tool('Inspiration', 'assets/icons/inspiration.png',
                () => _push(InspirationPage())),
      ]),
      _Section('Tools', 'Utilities & More', const Color(0xFF64B5F6), [
        _Tool('Qibla',       'assets/icons/qibla.png',
                () => _push(QiblaPage())),
        _Tool('Calendar',    'assets/icons/calendar.png',
                () => _push(MonthlyCalendarPage())),
        _Tool('Notification','assets/icons/notification.png',
                () => _push(NotificationPage())),
        _Tool('Menu',        'assets/icons/menu.png',
                () => _push(MenuPage())),
      ]),
    ];

    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // ── Decorative top radial glow ──
          Positioned(
            top: -80, left: -60,
            child: Container(
              width: sw * 0.7, height: sw * 0.7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Color(0x25388E3C), Color(0x00000000),
                ]),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header greeting ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(sw * 0.05, 20, sw * 0.05, 4),
                    child: _FadeSlide(
                      delay: 0,
                      controller: _ctrl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('بِسْمِ اللهِ الرَّحْمَٰنِ الرَّحِيْمِ',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: sw * 0.07,
                                color: _gold.withOpacity(0.85),
                                letterSpacing: 1.5,
                              )),
                          const SizedBox(height: 2),
                          Text('Your Islamic Toolkit',
                              style: TextStyle(
                                fontSize: sw * 0.038,
                                color: _textLo,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.4,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),

                // Thin gold divider
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: sw * 0.05, vertical: 14),
                    child: _FadeSlide(
                      delay: 0.05,
                      controller: _ctrl,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.transparent,
                            _gold.withOpacity(0.4),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Sections ──
                ...sections.asMap().entries.map((e) {
                  final idx = e.key;
                  final sec = e.value;
                  return SliverToBoxAdapter(
                    child: _FadeSlide(
                      delay: 0.1 + idx * 0.15,
                      controller: _ctrl,
                      child: _SectionBlock(
                        section: sec,
                        cols: cols,
                        sw: sw,
                      ),
                    ),
                  );
                }),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNav(),
    );
  }

  void _push(Widget page) =>
      Navigator.push(context, _fadeRoute(page));

  Route _fadeRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, a, __) => page,
    transitionsBuilder: (_, a, __, child) =>
        FadeTransition(opacity: a, child: child),
    transitionDuration: const Duration(milliseconds: 260),
  );

  // ── AppBar ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    automaticallyImplyLeading: false,
    flexibleSpace: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_surface, _bg.withOpacity(0)],
        ),
      ),
    ),
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color: _gold, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _gold.withOpacity(0.5), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textHi,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color: _gold, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _gold.withOpacity(0.5), blurRadius: 6)],
          ),
        ),
      ],
    ),
  );

  // ── Bottom Nav ──────────────────────────────────────────────────────────
  Widget _buildNav() {
    final items = [
      ('Today',  'assets/icons/today.png'),
      ('Tools',  'assets/icons/tools.png'),
      ('Quran',  'assets/icons/quran.png'),
      ('Duas',   'assets/icons/duas.png'),
      ('Menu',   'assets/icons/menu.png'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _accentSoft.withOpacity(0.25), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final label = e.value.$1;
              final asset = e.value.$2;
              final active = i == 1;

              return GestureDetector(
                onTap: () {
                  if (!active) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => _pages[i]));
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? _accentSoft.withOpacity(0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(asset,
                          width: 24, height: 24,
                          ),
                      const SizedBox(height: 4),
                      Text(label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: active ? _accent : _textLo,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Section Block ───────────────────────────────────────────────────────────
class _SectionBlock extends StatelessWidget {
  final _Section section;
  final int cols;
  final double sw;

  const _SectionBlock({
    required this.section,
    required this.cols,
    required this.sw,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.04, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 3, height: 22,
                decoration: BoxDecoration(
                  color: section.accentColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: section.accentColor.withOpacity(0.5),
                      blurRadius: 6,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.title,
                      style: TextStyle(
                        fontSize: sw * 0.045,
                        fontWeight: FontWeight.w700,
                        color: _textHi,
                        letterSpacing: 0.5,
                      )),
                  Text(section.subtitle,
                      style: TextStyle(
                        fontSize: sw * 0.03,
                        color: _textLo,
                      )),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Grid
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.88,
            ),
            itemCount: section.tools.length,
            itemBuilder: (_, i) => _ToolCard(
              tool: section.tools[i],
              accent: section.accentColor,
              sw: sw,
            ),
          ),

          SizedBox(height: sw * 0.04),
        ],
      ),
    );
  }
}

// ─── Tool Card ───────────────────────────────────────────────────────────────
class _ToolCard extends StatefulWidget {
  final _Tool tool;
  final Color accent;
  final double sw;

  const _ToolCard({
    required this.tool,
    required this.accent,
    required this.sw,
  });

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp:   (_) { setState(() => _pressed = false); widget.tool.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          decoration: BoxDecoration(
            color: _pressed ? _card.withOpacity(0.7) : _card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _pressed
                  ? widget.accent.withOpacity(0.55)
                  : widget.accent.withOpacity(0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_pressed ? 0.45 : 0.30),
                blurRadius: _pressed ? 4 : 10,
                offset: Offset(0, _pressed ? 2 : 5),
              ),
              if (!_pressed)
                BoxShadow(
                  color: widget.accent.withOpacity(0.06),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon container
                Expanded(
                  flex: 4,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: widget.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Image.asset(
                        widget.tool.asset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Label
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      widget.tool.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.sw * 0.031,
                        fontWeight: FontWeight.w600,
                        color: _textHi,
                        height: 1.2,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Fade + Slide animation helper ──────────────────────────────────────────
class _FadeSlide extends StatelessWidget {
  final double delay;     // 0.0 – 1.0
  final AnimationController controller;
  final Widget child;

  const _FadeSlide({
    required this.delay,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = delay.clamp(0.0, 0.85);
    final end   = (delay + 0.4).clamp(0.0, 1.0);

    final curve = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: curve,
      builder: (_, __) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - curve.value)),
          child: child,
        ),
      ),
    );
  }
}