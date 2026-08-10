import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';

const _appLink =
    'https://play.google.com/store/apps/details?id=com.siratalmustaqeem.muslimlife';

const _shareMessage =
    '🕌 Assalamu Alaikum!\n\n'
    'I\'ve been using Muslim Life App — it\'s amazing for Quran, duas, Prayer Times & more!\n\n'
    '📲 Download it here:\n$_appLink\n\n'
    '#Islam #Quran #MuslimApp';

class SharePage extends StatelessWidget {
  const SharePage({super.key});

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
            title: Text('Share App',
                style: TextStyle(
                    color: thm.textHigh, fontWeight: FontWeight.w600, fontSize: 18)),
            centerTitle: true,
            elevation: 0,
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide   = constraints.maxWidth > 600;
              final isTablet = constraints.maxWidth > 800;
              final hPad = isTablet ? 48.0 : isWide ? 32.0 : 20.0;
              final maxW = isTablet ? 720.0 : double.infinity;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxW),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _heroBanner(thm, isWide),
                        const SizedBox(height: 28),
                        _SectionLabel('Share via Platform', thm),
                        const SizedBox(height: 14),
                        _platformGrid(context, constraints.maxWidth, thm),
                        const SizedBox(height: 28),
                        _SectionLabel('Copy App Link', thm),
                        const SizedBox(height: 14),
                        _linkCard(context, thm),
                        const SizedBox(height: 28),
                        _generalShareBtn(thm),
                        const SizedBox(height: 20)
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

  Widget _heroBanner(AppThemeOption thm, bool isWide) {
    return Container(
      padding: EdgeInsets.all(isWide ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [thm.surface, thm.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: thm.accent.withOpacity(0.25)),
      ),
      child: isWide
          ? Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌙', style: TextStyle(fontSize: 52)),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Spread the Good',
                  style: TextStyle(
                      color: thm.textHigh, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                '"Whoever guides someone to goodness\nwill have a reward like the one who did it."',
                style: TextStyle(
                    color: thm.accent, fontSize: 13, fontStyle: FontStyle.italic, height: 1.5),
              ),
              const SizedBox(height: 4),
              Text('— Prophet Muhammad ﷺ (Muslim)',
                  style: TextStyle(color: thm.textLow, fontSize: 11)),
            ],
          ),
        ],
      )
          : Column(
        children: [
          const Text('🌙', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text('Spread the Good',
              style: TextStyle(
                  color: thm.textHigh, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            '"Whoever guides someone to goodness\nwill have a reward like the one who did it."',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: thm.accent, fontSize: 13, fontStyle: FontStyle.italic, height: 1.5),
          ),
          const SizedBox(height: 4),
          Text('— Prophet Muhammad ﷺ (Muslim)',
              style: TextStyle(color: thm.textLow, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _platformGrid(BuildContext context, double width, AppThemeOption thm) {
    final platforms = [
      _PlatformItem(icon: '💬', label: 'WhatsApp',   color: const Color(0xFF25D366), onTap: () => _shareToWhatsApp()),
      _PlatformItem(icon: '✈️', label: 'Telegram',   color: const Color(0xFF0088CC), onTap: () => _shareToTelegram()),
      _PlatformItem(icon: '📘', label: 'Facebook',   color: const Color(0xFF1877F2), onTap: () => _shareToFacebook()),
      _PlatformItem(icon: '🐦', label: 'Twitter / X', color: const Color(0xFF1DA1F2), onTap: () => _shareToTwitter()),
      _PlatformItem(icon: '📸', label: 'Instagram',  color: const Color(0xFFE1306C), onTap: () => _shareGeneral()),
      _PlatformItem(icon: '💼', label: 'LinkedIn',   color: const Color(0xFF0077B5), onTap: () => _shareGeneral()),
      _PlatformItem(icon: '📧', label: 'Email',      color: const Color(0xFF4285F4), onTap: () => _shareViaEmail()),
      _PlatformItem(icon: '📲', label: 'More…',      color: thm.accent,              onTap: () => _shareGeneral()),
    ];

    // Responsive cross-axis count
    int crossCount = 4;
    if (width > 800) crossCount = 8;
    else if (width > 600) crossCount = 6;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.9,
      ),
      itemCount: platforms.length,
      itemBuilder: (_, i) {
        final p = platforms[i];
        final iconSize = width > 600 ? 60.0 : 52.0;
        return GestureDetector(
          onTap: p.onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: iconSize, height: iconSize,
                decoration: BoxDecoration(
                  color: p.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.color.withOpacity(0.3)),
                ),
                child: Center(child: Text(p.icon, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(height: 5),
              Text(
                p.label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(color: thm.textLow, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _linkCard(BuildContext context, AppThemeOption thm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: thm.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: thm.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.link, color: thm.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _appLink,
              style: TextStyle(color: thm.textLow, fontSize: 12, overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _copyLink(context, thm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: thm.accent, borderRadius: BorderRadius.circular(8)),
              child: const Text('Copy',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _generalShareBtn(AppThemeOption thm) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _shareGeneral,
        style: ElevatedButton.styleFrom(
          backgroundColor: thm.accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        icon: const Icon(Icons.share, color: Colors.white, size: 20),
        label: const Text('Share Now',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }


  Widget _statChip(AppThemeOption thm, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: thm.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: thm.accent.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(color: thm.accent, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: thm.textLow, fontSize: 11)),
          ],
        ),
      ),
    );
  }

// ── Share Handlers ─────────────────────────────────────────────────────────
  Future<void> _shareGeneral() async =>
      await Share.share(_shareMessage, subject: 'Muslim Life');

  Future<void> _shareToWhatsApp() async {
// Modern universal HTTPS formats reliably wake up the installed application
    final url = 'https://wa.me/?text=${Uri.encodeComponent(_shareMessage)}';
    await _tryLaunch(url);
  }

  Future<void> _shareToTelegram() async {
    final url = 'https://t.me/share/url?url=${Uri.encodeComponent(_appLink)}&text=${Uri.encodeComponent(_shareMessage.replaceAll(_appLink, ''))}';
    await _tryLaunch(url);
  }

  Future<void> _shareToFacebook() async {
    final url = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(_appLink)}';
    await _tryLaunch(url);
  }

  Future<void> _shareToTwitter() async {
    final url = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(_shareMessage)}';
    await _tryLaunch(url);
  }

  Future<void> _shareViaEmail() async {
    final url = 'mailto:?subject=${Uri.encodeComponent('Check out Islamic App')}&body=${Uri.encodeComponent(_shareMessage)}';
    await _tryLaunch(url);
  }

  Future<void> _copyLink(BuildContext context, AppThemeOption thm) async {
    await Clipboard.setData(const ClipboardData(text: _appLink));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'App link copied to clipboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: thm.accent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

// Fixed: Engine now attempts a real platform application launch before resorting to generic share sheets
  Future<void> _tryLaunch(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await _shareGeneral(); // Fallback if the specific app isn't installed
      }
    } catch (_) {
      await _shareGeneral(); // Safe generic backup plan
    }
  }
} // <── THIS CLOSING BRACKET WAS MISSING TO CLOSE THE SharePage CLASS

class _PlatformItem {
  final String icon, label;
  final Color color;
  final VoidCallback onTap;
  const _PlatformItem({required this.icon, required this.label, required this.color, required this.onTap});
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final AppThemeOption thm;
  const _SectionLabel(this.text, this.thm);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 16,
          decoration: BoxDecoration(color: thm.accent, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: thm.textHigh, fontWeight: FontWeight.w700, fontSize: 15)),
      ],
    );
  }
}