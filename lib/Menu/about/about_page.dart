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
            style: TextStyle(
                color: _textHi,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _appHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _featureGrid(),
                  const SizedBox(height: 28),
                  _sectionLabel('About This App'),
                  const SizedBox(height: 12),
                  _aboutText(),
                  const SizedBox(height: 28),
                  _sectionLabel('Whatis New — v2.5.0'),
                  const SizedBox(height: 12),
                  _changelogCard(),
                  const SizedBox(height: 28),
                  _sectionLabel('App Information'),
                  const SizedBox(height: 12),
                  _infoCard(),
                  const SizedBox(height: 28),
                  _sectionLabel('Legal'),
                  const SizedBox(height: 12),
                  _legalCard(),
                  const SizedBox(height: 28),
                  _missionCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2E1C), Color(0xFF011A0E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D5A), Color(0xFF0D2E1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _gold.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                    color: _accent.withOpacity(0.4),
                    blurRadius: 30, spreadRadius: 2)
              ],
            ),
            child: const Center(
              child: Text('🕌', style: TextStyle(fontSize: 50)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Islamic App',
            style: TextStyle(
              color: _textHi,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Version 2.5.0 (Build 250)',
              style: TextStyle(color: _textLo, fontSize: 13)),
          const SizedBox(height: 10),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gold.withOpacity(0.3)),
            ),
            child: const Text(
              '🌙  Your Complete Islamic Companion',
              style: TextStyle(
                  color: _gold, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureGrid() {
    final features = [
      _FeatureItem('🕐', 'Prayer Times', 'GPS-accurate Adhan'),
      _FeatureItem('📖', 'Holy Quran', '114 Surah + Audio'),
      _FeatureItem('🤲', 'Daily Duas', '200+ authentic Duas'),
      _FeatureItem('🧭', 'Qibla', 'Real-time compass'),
      _FeatureItem('📿', 'Tasbeeh', 'Digital counter'),
      _FeatureItem('📅', 'Hijri Cal', 'Islamic dates'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
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
                      color: _textHi,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
              const SizedBox(height: 2),
              Text(f.subtitle,
                  textAlign: TextAlign.center,
                  style:
                  const TextStyle(color: _textLo, fontSize: 10)),
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
          decoration: BoxDecoration(
              color: _gold, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(
                color: _textHi,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
      ],
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
          child: Text(c,
              style: const TextStyle(
                  color: _textLo, fontSize: 13, height: 1.5)),
        ))
            .toList(),
      ),
    );
  }

  Widget _infoCard() {
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

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentSoft.withOpacity(0.2)),
      ),
      child: Column(
        children: info.asMap().entries.map((e) {
          final isLast = e.key == info.length - 1;
          final item = e.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.$1,
                        style: const TextStyle(
                            color: _textLo, fontSize: 13)),
                    Text(item.$2,
                        style: const TextStyle(
                            color: _textHi,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                    height: 1,
                    color: _accentSoft.withOpacity(0.15)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _legalCard() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentSoft.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _legalTile(Icons.privacy_tip_outlined, 'Privacy Policy',
              'https://islamicapp.dev/privacy'),
          Divider(height: 1, color: _accentSoft.withOpacity(0.15)),
          _legalTile(Icons.gavel_outlined, 'Terms of Service',
              'https://islamicapp.dev/terms'),
          Divider(height: 1, color: _accentSoft.withOpacity(0.15)),
          _legalTile(Icons.source, 'Open Source Licenses',
              null),
        ],
      ),
    );
  }

  Widget _legalTile(IconData icon, String title, String? url) {
    return GestureDetector(
      onTap: url != null
          ? () => launchUrl(Uri.parse(url))
          : null,
      child: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: _accent, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: _textHi, fontSize: 14)),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: _textLo, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _missionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accentSoft.withOpacity(0.15),
            _gold.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          const Text('وَذَكِّرْ فَإِنَّ الذِّكْرَى تَنفَعُ الْمُؤْمِنِينَ',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _gold,
                  fontSize: 18,
                  fontFamily: 'Amiri')),
          const SizedBox(height: 8),
          const Text(
            '"And remind, for indeed reminding benefits the believers."',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _textLo,
                fontSize: 12,
                fontStyle: FontStyle.italic),
          ),
          const Text('— Quran 51:55',
              style: TextStyle(color: _textLo, fontSize: 11)),
          const SizedBox(height: 16),
          const Divider(color: Color(0x22D4AF37)),
          const SizedBox(height: 12),
          const Text(
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