import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

const _bg        = Color(0xFF011A0E);
const _surface   = Color(0xFF0D2E1C);
const _card      = Color(0xFF122E1E);
const _accent    = Color(0xFF4CAF82);
const _accentSoft= Color(0xFF2E7D5A);
const _gold      = Color(0xFFD4AF37);
const _textHi    = Color(0xFFE8F5EC);
const _textLo    = Color(0xFF7BAF92);

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _accent),
          onPressed: () => Get.back(),
        ),
        title: const Text('About App',
            style: TextStyle(color: _textHi, fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide   = constraints.maxWidth > 600;
          final isTablet = constraints.maxWidth > 800;
          final hPad = isTablet ? 48.0 : isWide ? 32.0 : 20.0;
          final maxW = isTablet ? 800.0 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _appHeader(isWide, isTablet),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _featureGrid(constraints.maxWidth),
                          const SizedBox(height: 28),
                          _sectionLabel('About This App'),
                          const SizedBox(height: 12),
                          _aboutText(),
                          const SizedBox(height: 28),
                          _sectionLabel('Our Aqeedah & Fiqh / আমাদের আক্বিদা ও ফিকহ'),
                          const SizedBox(height: 12),
                          _aqeedahFiqhCard(),
                          const SizedBox(height: 28),
                          _sectionLabel('What\'s New — v2.5.0'),
                          const SizedBox(height: 12),
                          _changelogCard(),
                          const SizedBox(height: 12),
                          if (isWide) ...[
                            _infoCardWide(),
                            const SizedBox(height: 28),
                          ],

                          _missionCard(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _appHeader(bool isWide, bool isTablet) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2E1C), Color(0xFF011A0E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: isTablet ? 56 : isWide ? 48 : 40),
      child: Column(
        children: [
          Container(
            width: isWide ? 120 : 100,
            height: isWide ? 120 : 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D5A), Color(0xFF0D2E1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isWide ? 32 : 26),
              border: Border.all(color: _gold.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(color: _accent.withOpacity(0.4), blurRadius: 30, spreadRadius: 2)
              ],
            ),
            child: Center(
              child: Text('🕌', style: TextStyle(fontSize: isWide ? 60 : 50)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Islamic App',
            style: TextStyle(
              color: _textHi,
              fontSize: isWide ? 32 : 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Version 2.5.0 (Build 250)',
              style: TextStyle(color: _textLo, fontSize: 13)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gold.withOpacity(0.3)),
            ),
            child: const Text(
              '🌙  Your Complete Islamic Companion',
              style: TextStyle(color: _gold, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureGrid(double width) {
    final features = [
      _FeatureItem('🕐', 'Prayer Times', 'GPS-accurate Adhan'),
      _FeatureItem('📖', 'Holy Quran', '114 Surah + Audio'),
      _FeatureItem('🤲', 'Daily Duas', '200+ authentic Duas'),
      _FeatureItem('🧭', 'Qibla', 'Real-time compass'),
      _FeatureItem('📿', 'Tasbeeh', 'Digital counter'),
      _FeatureItem('📅', 'Hijri Cal', 'Islamic dates'),
    ];

    // Responsive cross-axis count
    int crossCount = 3;
    if (width > 800) crossCount = 6;
    else if (width > 600) crossCount = 4;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: features.length,
      itemBuilder: (_, i) {
        final f = features[i];
        return Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _accentSoft.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(f.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(f.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: _textHi, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 2),
              Text(f.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _textLo, fontSize: 10)),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4, height: 16,
          decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: _textHi, fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _aqeedahFiqhCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentSoft.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BANGLA SECTION
          const Text(
            'আমাদের আক্বিদা',
            style: TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Text(
            'আমরা আহলুস সুন্নাহ ওয়াল জামায়াতের আক্বিদা পোষণ করি। আমরা চেষ্টা করি নবীজির (সা) সুন্নাহ, সাহাবীগণ (রাঃ) এবং তাবেয়ী-তাবে তাবেয়ীগণের (রহ) আমল ও শিক্ষা অনুসরণ করার। যাবতীয় শিরক ও বিদআত থেকে আমরা দূরে থাকার চেষ্টা করি, যার প্রতিফলন এই অ্যাপে হয়ে থাকে।',
            style: TextStyle(color: _textLo, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 14),
          const Text(
            'আমাদের ফিকহী মাযহাব',
            style: TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Text(
            'আমরা ফিকহে হানাফী (হানাফী মাযহাব) অনুসরণ করি। যেহেতু আমাদের অঞ্চলের বেশির ভাগ মানুষ হানাফী মাযহাব অনুসরণ করেন, তাই এই অ্যাপের সমস্ত ডিফল্ট সেটিংস, নামাজের সময়সূচী এবং ফিকহী মাসআলাসমূহ সম্পূর্ণরূপে হানাফী ফিকহ অনুযায়ী সাজানো হয়েছে।',
            style: TextStyle(color: _textLo, fontSize: 13, height: 1.6),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0x1A7BAF92), height: 1),
          ),

          // ENGLISH SECTION
          const Text(
            'Our Aqeedah',
            style: TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Text(
            'We hold the Aqeedah (creed) of Ahlus Sunnah wal Jama\'ah. We strive to follow the Sunnah of the Prophet (ﷺ), and the practices and teachings of the Companions (Sahabah), the Tabi\'un, and the Atba\' al-Tabi\'un. We sincerely endeavor to stay away from all forms of Shirk (polytheism) and Bid\'ah (innovation), which is strictly reflected throughout this app.',
            style: TextStyle(color: _textLo, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 14),
          const Text(
            'Fiqh School of Thought',
            style: TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Text(
            'We strictly follow the Hanafi Fiqh (Hanafi Madhhab). Since the vast majority of Muslims in our region follow the Hanafi school of thought, all the default settings, prayer time calculations, and Islamic rulings (Mas\'alah) provided in this app are completely based on the Hanafi Fiqh.',
            style: TextStyle(color: _textLo, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _aboutText() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentSoft.withOpacity(0.2)),
      ),
      child: const Text(
        'Islamic App is a free, comprehensive Islamic companion designed to '
            'help Muslims around the world strengthen their faith and daily practice. '
            'Built with love by a team of dedicated Muslim developers, this app '
            'provides accurate prayer times based on your GPS location, complete '
            'Quran with translations and audio recitations, authentic Duas & Adhkar, '
            'Qibla direction, and much more.\n\n'
            'Our mission is simple: to make Islamic knowledge accessible to every '
            'Muslim, wherever they are in the world — InshaAllah.',
        style: TextStyle(color: _textLo, fontSize: 13.5, height: 1.75),
      ),
    );
  }

  Widget _changelogCard() {
    final changes = [
      '✨ New: Enhanced Quran audio player with repeat mode',
      '🐛 Fixed: Prayer time calculation for high-latitude cities',
      '🎨 Improved: Beautiful new Ramadan theme',
      '⚡ Faster: App launch speed improved by 40%',
      '🌍 Added: 15 new UI languages including Bangla',
      '🔔 Fixed: Adhan notification reliability',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentSoft.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: changes
            .map((c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text(c, style: const TextStyle(color: _textLo, fontSize: 13, height: 1.5)),
        ))
            .toList(),
      ),
    );
  }

  // Landscape/wide: 2-column grid
  Widget _infoCardWide() {
    final info = [
      ('Version', '2.5.0'),
      ('Build', '250'),
      ('Released', 'April 2026'),
      ('Platform', 'iOS & Android'),
      ('Developer', 'Islamic App Team'),
      ('Country', '🇧🇩 Bangladesh'),
      ('Size', '~32 MB'),
      ('Requires', 'Android 6.0+ / iOS 13+'),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < info.length; i += 2) {
      final left  = info[i];
      final right = i + 1 < info.length ? info[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _infoCell(left.$1, left.$2)),
              if (right != null) ...[
                VerticalDivider(width: 1, color: _accentSoft.withOpacity(0.15)),
                Expanded(child: _infoCell(right.$1, right.$2)),
              ],
            ],
          ),
        ),
      );
      if (i + 2 < info.length) {
        rows.add(Divider(height: 1, color: _accentSoft.withOpacity(0.15)));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentSoft.withOpacity(0.2)),
      ),
      child: Column(children: rows),
    );
  }

  Widget _infoCell(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _textLo, fontSize: 13)),
          Text(value,
              style: const TextStyle(color: _textHi, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _missionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accentSoft.withOpacity(0.15), _gold.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.25)),
      ),
      child: const Column(
        children: [
          Text(
            'وَذَكِّرْ فَإِنَّ الذِّكْرَى تَنفَعُ الْمُؤْمِنِينَ',
            textAlign: TextAlign.center,
            style: TextStyle(color: _gold, fontSize: 18, fontFamily: 'Amiri'),
          ),
          SizedBox(height: 8),
          Text(
            '"And remind, for indeed reminding benefits the believers."',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textLo, fontSize: 12, fontStyle: FontStyle.italic),
          ),
          Text('— Quran 51:55', style: TextStyle(color: _textLo, fontSize: 11)),
          SizedBox(height: 16),
          Divider(color: Color(0x22D4AF37)),
          SizedBox(height: 12),
          Text(
            '© 2026 Islamic App — All rights reserved.\nMade with ❤️ for the Ummah.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textLo, fontSize: 12, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final String emoji, title, subtitle;
  const _FeatureItem(this.emoji, this.title, this.subtitle);
}
