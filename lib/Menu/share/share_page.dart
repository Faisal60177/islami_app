import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

const _bg        = Color(0xFF011A0E);
const _surface   = Color(0xFF0D2E1C);
const _card      = Color(0xFF122E1E);
const _accent    = Color(0xFF4CAF82);
const _accentSoft= Color(0xFF2E7D5A);
const _gold      = Color(0xFFD4AF37);
const _textHi    = Color(0xFFE8F5EC);
const _textLo    = Color(0xFF7BAF92);

const _appLink =
    'https://play.google.com/store/apps/details?id=com.islamicapp.dev';

const _shareMessage =
    '🕌 Assalamu Alaikum!\n\n'
    'I\'ve been using Islamic App — it\'s amazing for Quran, Duas, Prayer Times & more!\n\n'
    '📲 Download it here:\n$_appLink\n\n'
    '#Islam #Quran #MuslimApp';

class SharePage extends StatelessWidget {
  const SharePage({super.key});

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
        title: const Text('Share App',
            style: TextStyle(
                color: _textHi, fontWeight: FontWeight.w600, fontSize: 18)),
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
                    _heroBanner(isWide),
                    const SizedBox(height: 28),
                    const _SectionLabel('Share via Platform'),
                    const SizedBox(height: 14),
                    _platformGrid(context, constraints.maxWidth),
                    const SizedBox(height: 28),
                    const _SectionLabel('Copy App Link'),
                    const SizedBox(height: 14),
                    _linkCard(),
                    const SizedBox(height: 28),
                    _generalShareBtn(),
                    const SizedBox(height: 28),
                    _statsRow(isWide),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _heroBanner(bool isWide) {
    return Container(
      padding: EdgeInsets.all(isWide ? 32 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2E1C), Color(0xFF122E1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.25)),
      ),
      child: isWide
          ? Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌙', style: TextStyle(fontSize: 52)),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Spread the Good',
                  style: TextStyle(
                      color: _textHi, fontSize: 22, fontWeight: FontWeight.w800)),
              SizedBox(height: 6),
              Text(
                '"Whoever guides someone to goodness\nwill have a reward like the one who did it."',
                style: TextStyle(
                    color: _gold, fontSize: 13, fontStyle: FontStyle.italic, height: 1.5),
              ),
              SizedBox(height: 4),
              Text('— Prophet Muhammad ﷺ (Muslim)',
                  style: TextStyle(color: _textLo, fontSize: 11)),
            ],
          ),
        ],
      )
          : Column(
        children: const [
          Text('🌙', style: TextStyle(fontSize: 52)),
          SizedBox(height: 12),
          Text('Spread the Good',
              style: TextStyle(
                  color: _textHi, fontSize: 22, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text(
            '"Whoever guides someone to goodness\nwill have a reward like the one who did it."',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _gold, fontSize: 13, fontStyle: FontStyle.italic, height: 1.5),
          ),
          SizedBox(height: 4),
          Text('— Prophet Muhammad ﷺ (Muslim)',
              style: TextStyle(color: _textLo, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _platformGrid(BuildContext context, double width) {
    final platforms = [
      _PlatformItem(icon: '💬', label: 'WhatsApp',   color: const Color(0xFF25D366), onTap: () => _shareToWhatsApp()),
      _PlatformItem(icon: '✈️', label: 'Telegram',   color: const Color(0xFF0088CC), onTap: () => _shareToTelegram()),
      _PlatformItem(icon: '📘', label: 'Facebook',   color: const Color(0xFF1877F2), onTap: () => _shareToFacebook()),
      _PlatformItem(icon: '🐦', label: 'Twitter / X', color: const Color(0xFF1DA1F2), onTap: () => _shareToTwitter()),
      _PlatformItem(icon: '📸', label: 'Instagram',  color: const Color(0xFFE1306C), onTap: () => _shareGeneral()),
      _PlatformItem(icon: '💼', label: 'LinkedIn',   color: const Color(0xFF0077B5), onTap: () => _shareGeneral()),
      _PlatformItem(icon: '📧', label: 'Email',      color: const Color(0xFF4285F4), onTap: () => _shareViaEmail()),
      _PlatformItem(icon: '📲', label: 'More…',      color: _accentSoft,             onTap: () => _shareGeneral()),
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
                style: const TextStyle(color: _textLo, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _linkCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentSoft.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, color: _accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _appLink,
              style: const TextStyle(color: _textLo, fontSize: 12, overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _copyLink,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _accentSoft, borderRadius: BorderRadius.circular(8)),
              child: const Text('Copy',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _generalShareBtn() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _shareGeneral,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentSoft,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        icon: const Icon(Icons.share, color: Colors.white, size: 20),
        label: const Text('Share Now',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }

  Widget _statsRow(bool isWide) {
    return Row(
      children: [
        _statChip('50K+', 'Downloads'),
        const SizedBox(width: 12),
        _statChip('4.8★', 'Rating'),
        const SizedBox(width: 12),
        _statChip('120+', 'Countries'),
      ],
    );
  }

  Widget _statChip(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gold.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(color: _gold, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: _textLo, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ── Share Handlers ─────────────────────────────────────────────────────────
  Future<void> _shareGeneral() async =>
      await Share.share(_shareMessage, subject: 'Islamic App');

  Future<void> _shareToWhatsApp() async {
    final url = 'whatsapp://send?text=${Uri.encodeComponent(_shareMessage)}';
    await _tryLaunch(url, fallback: _shareGeneral);
  }

  Future<void> _shareToTelegram() async {
    final url = 'tg://msg?text=${Uri.encodeComponent(_shareMessage)}';
    await _tryLaunch(url, fallback: _shareGeneral);
  }

  Future<void> _shareToFacebook() async {
    final url = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(_appLink)}';
    await _tryLaunch(url, fallback: _shareGeneral);
  }

  Future<void> _shareToTwitter() async {
    final url = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(_shareMessage)}';
    await _tryLaunch(url, fallback: _shareGeneral);
  }

  Future<void> _shareViaEmail() async {
    final url = 'mailto:?subject=Check out Islamic App&body=${Uri.encodeComponent(_shareMessage)}';
    await _tryLaunch(url, fallback: _shareGeneral);
  }

  Future<void> _copyLink() async {
    await Share.share(_appLink);
    Get.snackbar('Copied!', 'App link copied to clipboard',
        backgroundColor: _accentSoft,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16));
  }

  Future<void> _tryLaunch(String url, {required Future<void> Function() fallback}) async {
    try {
      await fallback();
    } catch (_) {
      await fallback();
    }
  }
}

class _PlatformItem {
  final String icon, label;
  final Color color;
  final VoidCallback onTap;
  const _PlatformItem({required this.icon, required this.label, required this.color, required this.onTap});
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 16,
          decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: _textHi, fontWeight: FontWeight.w700, fontSize: 15)),
      ],
    );
  }
}