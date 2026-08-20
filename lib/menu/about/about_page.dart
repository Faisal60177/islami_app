import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import 'package:muslim_app/core/app_info.dart';


class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final thm = getThemeById(state.themeMode);

        return Scaffold(
          backgroundColor: thm.background,
          appBar: AppBar(
            backgroundColor: thm.surface,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: thm.accent),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text('About App',
                style: TextStyle(color: thm.textHigh, fontWeight: FontWeight.w600, fontSize: 18)),
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
                        _appHeader(thm, isWide, isTablet),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _featureGrid(thm, constraints.maxWidth),
                              const SizedBox(height: 28),
                              _sectionLabel(thm, 'About This App'),
                              const SizedBox(height: 12),
                              _aboutText(thm),
                              const SizedBox(height: 28),
                              _sectionLabel(thm, 'আমাদের আক্বিদা ও ফিকহ'),
                              const SizedBox(height: 12),
                              _aqeedahFiqhCard(thm),
                              const SizedBox(height: 12),
                              if (isWide) ...[
                                _infoCardWide(thm),
                                const SizedBox(height: 28),
                              ],

                              _missionCard(thm),
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
      },
    );
  }

  Widget _appHeader(AppThemeOption thm, bool isWide, bool isTablet) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [thm.surface, thm.background],
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
              gradient: LinearGradient(
                colors: [thm.accent, thm.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isWide ? 32 : 26),
              border: Border.all(color: thm.accent.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(color: thm.accent.withOpacity(0.4), blurRadius: 30, spreadRadius: 2)
              ],
            ),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isWide ? 24 : 20),
                child: Image.asset(
                  'assets/icons/AppIcon.png',
                  width: isWide ? 84 : 70,
                  height: isWide ? 84 : 70,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Muslim Life',
            style: TextStyle(
              color: thm.textHigh,
              fontSize: isWide ? 32 : 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text('Version ${AppInfo.version} (Build ${AppInfo.buildNumber})',
              style: TextStyle(color: thm.textLow, fontSize: 13)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: thm.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: thm.accent.withOpacity(0.3)),
            ),
            child: Text(
              '🌙  Your Complete Islamic Companion',
              style: TextStyle(color: thm.accent, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureGrid(AppThemeOption thm, double width) {
    final features = [
      _FeatureItem('🕐', 'Prayer Times', 'GPS-accurate Adhan'),
      _FeatureItem('📖', 'Holy Quran Tlawat', 'Tafsir and Audio'),
      _FeatureItem('🤲', 'Daily duas', '200+ authentic duas'),
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
            color: thm.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: thm.accent.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(f.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(f.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: thm.textHigh, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 2),
              Text(f.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: thm.textLow, fontSize: 10)),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(AppThemeOption thm, String text) {
    return Row(
      children: [
        Container(
          width: 4, height: 16,
          decoration: BoxDecoration(color: thm.accent, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(color: thm.textHigh, fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _aqeedahFiqhCard(AppThemeOption thm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: thm.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: thm.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BANGLA SECTION
          Text(
            'আমাদের আক্বিদা',
            style: TextStyle(color: thm.accent, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'আমরা আহলুস সুন্নাহ ওয়াল জামায়াতের আক্বিদা পোষণ করি। আমরা চেষ্টা করি নবীজির (সা) সুন্নাহ, সাহাবীগণ (রাঃ) এবং তাবেয়ী-তাবে তাবেয়ীগণের (রহ) আমল ও শিক্ষা অনুসরণ করার। যাবতীয় শিরক ও বিদআত থেকে আমরা দূরে থাকার চেষ্টা করি, যার প্রতিফলন এই অ্যাপে হয়ে থাকে।',
            style: TextStyle(color: thm.textLow, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 14),
          Text(
            'আমাদের ফিকহী মাযহাব',
            style: TextStyle(color: thm.accent, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'আমরা ফিকহে হানাফী (হানাফী মাযহাব) অনুসরণ করি। যেহেতু আমাদের অঞ্চলের বেশির ভাগ মানুষ হানাফী মাযহাব অনুসরণ করেন, তাই এই অ্যাপের সমস্ত ডিফল্ট সেটিংস, নামাজের সময়সূচী এবং ফিকহী মাসআলাসমূহ সম্পূর্ণরূপে হানাফী ফিকহ অনুযায়ী সাজানো হয়েছে।',
            style: TextStyle(color: thm.textLow, fontSize: 13, height: 1.6),
          ),

        ],
      ),
    );
  }

  Widget _aboutText(AppThemeOption thm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: thm.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: thm.accent.withOpacity(0.2)),
      ),
      child: Text(
        'Islamic App is a free, comprehensive Islamic companion designed to '
            'help Muslims around the world strengthen their faith and daily practice. '
            'Built with love by a team of dedicated Muslim developers, this app '
            'provides accurate prayer times based on your GPS location, complete '
            'quran_tilawat with translations and audio recitations, authentic duas & Adhkar, '
            'Qibla direction, and much more.\n\n'
            'Our mission is simple: to make Islamic knowledge accessible to every '
            'Muslim, wherever they are in the world — InshaAllah.',
        style: TextStyle(color: thm.textLow, fontSize: 13.5, height: 1.75),
      ),
    );
  }


  // Landscape/wide: 2-column grid
  Widget _infoCardWide(AppThemeOption thm) {
    final info = [
      ('Version', AppInfo.version),
      ('Build', AppInfo.buildNumber),
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
              Expanded(child: _infoCell(thm, left.$1, left.$2)),
              if (right != null) ...[
                VerticalDivider(width: 1, color: thm.accent.withOpacity(0.15)),
                Expanded(child: _infoCell(thm, right.$1, right.$2)),
              ],
            ],
          ),
        ),
      );
      if (i + 2 < info.length) {
        rows.add(Divider(height: 1, color: thm.accent.withOpacity(0.15)));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: thm.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: thm.accent.withOpacity(0.2)),
      ),
      child: Column(children: rows),
    );
  }

  Widget _infoCell(AppThemeOption thm, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: thm.textLow, fontSize: 13)),
          Text(value,
              style: TextStyle(color: thm.textHigh, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _missionCard(AppThemeOption thm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [thm.accent.withOpacity(0.15), thm.accent.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: thm.accent.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            'وَذَكِّرْ فَإِنَّ الذِّكْرَى تَنفَعُ الْمُؤْمِنِينَ',
            textAlign: TextAlign.center,
            style: TextStyle(color: thm.accent, fontSize: 18, fontFamily: 'Amiri'),
          ),
          const SizedBox(height: 8),
          Text(
            '"And remind, for indeed reminding benefits the believers."',
            textAlign: TextAlign.center,
            style: TextStyle(color: thm.textLow, fontSize: 12, fontStyle: FontStyle.italic),
          ),
          Text('— quran_tilawat 51:55', style: TextStyle(color: thm.textLow, fontSize: 11)),
          const SizedBox(height: 16),
          Divider(color: thm.accent.withOpacity(0.13)),
          const SizedBox(height: 12),
          Text(
            '© 2026 Muslim Life — All rights reserved.\nMade with ❤️ for the Ummah.',
            textAlign: TextAlign.center,
            style: TextStyle(color: thm.textLow, fontSize: 12, height: 1.6),
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