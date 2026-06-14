import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

const _bg        = Color(0xFF011A0E);
const _surface   = Color(0xFF0D2E1C);
const _card      = Color(0xFF122E1E);
const _accent    = Color(0xFF4CAF82);
const _accentSoft= Color(0xFF2E7D5A);
const _gold      = Color(0xFFD4AF37);
const _textHi    = Color(0xFFE8F5EC);
const _textLo    = Color(0xFF7BAF92);

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _accent),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Contact Us',
            style: TextStyle(
                color: _textHi,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        centerTitle: true,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
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
                    _headerBanner(isWide),
                    const SizedBox(height: 28),
                    _sectionLabel('Get In Touch'),
                    const SizedBox(height: 12),
                    if (isWide)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: isTablet ? 3.2 : 2.8,
                        children: [
                          _contactCard(
                            icon: Icons.email_outlined,
                            color: const Color(0xFF4285F4),
                            title: 'Email Support',
                            subtitle: 'siratalmustaqeem60177@gmail.com',
                            hint: 'Response within 24–48 hours',
                            onTap: () => _launchUrl('mailto:siratalmustaqeem60177@gmail.com'),
                            onCopy: () => _copy(context,'siratalmustaqeem60177@gmail.com', 'Email copied'),
                          ),
                          _contactCard(
                            icon: Icons.chat_bubble_outline,
                            color: const Color(0xFF25D366),
                            title: 'WhatsApp Support',
                            subtitle: '+880 1700-000000',
                            hint: 'Mon – Fri, 9 AM – 6 PM',
                            onTap: () => _launchUrl('https://wa.me/8801700000000'),
                            onCopy: () => _copy(context, '+8801700000000', 'Number copied'),
                          ),
                          /* _contactCard(
                            icon: Icons.telegram,
                            color: const Color(0xFF0088CC),
                            title: 'Telegram Channel',
                            subtitle: '@IslamicAppOfficial',
                            hint: 'Updates & announcements',
                            onTap: () => _launchUrl('https://t.me/IslamicAppOfficial'),
                            onCopy: null,
                          ),
                          _contactCard(
                            icon: Icons.language,
                            color: _accentSoft,
                            title: 'Website',
                            subtitle: 'www.islamicapp.dev',
                            hint: 'Blog, FAQs & documentation',
                            onTap: () => _launchUrl('https://www.islamicapp.dev'),
                            onCopy: null,
                          ),

                           */
                        ],
                      )
                    else ...[
                      _contactCard(
                        icon: Icons.email_outlined,
                        color: const Color(0xFF4285F4),
                        title: 'Email Support',
                        subtitle: 'siratalmustaqeem60177@gmail.com',
                        hint: 'Response within 24–48 hours',
                        onTap: () => _launchUrl('mailto:siratalmustaqeem60177@gmail.com'),
                        onCopy: () => _copy(context, 'siratalmustaqeem60177@gmail.com', 'Email copied'),
                      ),
                      const SizedBox(height: 12),
                      _contactCard(
                        icon: Icons.chat_bubble_outline,
                        color: const Color(0xFF25D366),
                        title: 'WhatsApp Support',
                        subtitle: '+8801334543168',
                        hint: 'Every Day, 8 AM – 8 PM',
                        onTap: () => _launchUrl('https://wa.me/8801334543168'),
                        onCopy: () => _copy(context, '+8801334543168', 'Number copied'),
                      ),
                      /* HIDING TELEGRAM & WEBSITE FOR NOW
                      const SizedBox(height: 12),
                      _contactCard(
                        icon: Icons.telegram,
                        color: const Color(0xFF0088CC),
                        title: 'Telegram Channel',
                        subtitle: '@IslamicAppOfficial',
                        hint: 'Updates & announcements',
                        onTap: () => _launchUrl('https://t.me/IslamicAppOfficial'),
                        onCopy: null,
                      ),
                      const SizedBox(height: 12),
                      _contactCard(
                        icon: Icons.language,
                        color: _accentSoft,
                        title: 'Website',
                        subtitle: 'www.islamicapp.dev',
                        hint: 'Blog, FAQs & documentation',
                        onTap: () => _launchUrl('https://www.islamicapp.dev'),
                        onCopy: null,
                      ),

                       */
                    ],
                    const SizedBox(height: 28),
                    _sectionLabel('Report a Bug'),
                    const SizedBox(height: 12),
                    _bugReportCard(),
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

  Widget _headerBanner(bool isWide) {
    return Container(
      width: double.infinity,
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentSoft.withOpacity(0.2),
            ),
            child: const Icon(Icons.support_agent, color: _accent, size: 42),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const[
                 Text(
                  'We\'re Here to Help',
                  style: TextStyle(color: _textHi, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                 SizedBox(height: 6),
                 Text(
                  'Have a question, suggestion, or encountered a bug?\nOur team is ready to assist you — always.',
                  style: TextStyle(color: _textLo, fontSize: 13.5, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      )
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentSoft.withOpacity(0.2),
            ),
            child: const Icon(Icons.support_agent, color: _accent, size: 42),
          ),
          const SizedBox(height: 16),
          const Text(
            'We\'re Here to Help',
            style: TextStyle(color: _textHi, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Have a question, suggestion, or encountered a bug?\nOur team is ready to assist you — always.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textLo, fontSize: 13.5, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 4, height: 16,
          decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                color: _textHi, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3)),
      ],
    );
  }

  Widget _contactCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String hint,
    required VoidCallback onTap,
    VoidCallback? onCopy,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accentSoft.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: _textHi, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: color, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(hint, style: const TextStyle(color: _textLo, fontSize: 11)),
                ],
              ),
            ),
            if (onCopy != null)
              IconButton(
                icon: const Icon(Icons.copy, color: _textLo, size: 18),
                onPressed: onCopy,
              ),
            const Icon(Icons.arrow_forward_ios, color: _textLo, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _bugReportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report_outlined, color: Colors.orange, size: 22),
              const SizedBox(width: 10),
              const Text('Found a bug?',
                  style: TextStyle(color: _textHi, fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Please send a detailed report including:\n'
                '• Your device model & OS version\n'
                '• Steps to reproduce the issue\n'
                '• A screenshot if possible',
            style: TextStyle(color: _textLo, fontSize: 13, height: 1.7),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchUrl('mailto:siratalmustaqeem60177@gmail.com?subject=Bug Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.withOpacity(0.15),
                side: BorderSide(color: Colors.orange.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.send_outlined, color: Colors.orange, size: 18),
              label: const Text('Send Bug Report',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _copy(BuildContext context, String text, String msg) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: _accentSoft,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}