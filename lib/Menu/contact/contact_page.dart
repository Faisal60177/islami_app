import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

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
            title: Text('Contact Us',
                style: TextStyle(
                    color: thm.textHigh,
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
                        _headerBanner(thm, isWide),
                        const SizedBox(height: 28),
                        _sectionLabel(thm, 'Get In Touch'),
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
                                thm: thm,
                                icon: Icons.email_outlined,
                                color: const Color(0xFF4285F4),
                                title: 'Email Support',
                                subtitle: 'siratalmustaqeem60177@gmail.com',
                                hint: 'Response within 24–48 hours',
                                onTap: () => _launchUrl('mailto:siratalmustaqeem60177@gmail.com'),
                                onCopy: () => _copy(context, thm, 'siratalmustaqeem60177@gmail.com', 'Email copied'),
                              ),
                              _contactCard(
                                thm: thm,
                                icon: Icons.chat_bubble_outline,
                                color: const Color(0xFF25D366),
                                title: 'WhatsApp Support',
                                subtitle: '+880 1700-000000',
                                hint: 'Mon – Fri, 9 AM – 6 PM',
                                onTap: () => _launchUrl('https://wa.me/8801700000000'),
                                onCopy: () => _copy(context, thm, '+8801700000000', 'Number copied'),
                              ),
                            ],
                          )
                        else ...[
                          _contactCard(
                            thm: thm,
                            icon: Icons.email_outlined,
                            color: const Color(0xFF4285F4),
                            title: 'Email Support',
                            subtitle: 'siratalmustaqeem60177@gmail.com',
                            hint: 'Response within 24–48 hours',
                            onTap: () => _launchUrl('mailto:siratalmustaqeem60177@gmail.com'),
                            onCopy: () => _copy(context, thm, 'siratalmustaqeem60177@gmail.com', 'Email copied'),
                          ),
                          const SizedBox(height: 12),
                          _contactCard(
                            thm: thm,
                            icon: Icons.chat_bubble_outline,
                            color: const Color(0xFF25D366),
                            title: 'WhatsApp Support',
                            subtitle: '+8801334543168',
                            hint: 'Every Day, 8 AM – 8 PM',
                            onTap: () => _launchUrl('https://wa.me/8801334543168'),
                            onCopy: () => _copy(context, thm, '+8801334543168', 'Number copied'),
                          ),
                        ],
                        const SizedBox(height: 28),
                        _sectionLabel(thm, 'Report a Bug'),
                        const SizedBox(height: 12),
                        _bugReportCard(thm),
                        const SizedBox(height: 32),
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

  Widget _headerBanner(AppThemeOption thm, bool isWide) {
    return Container(
      width: double.infinity,
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: thm.accent.withOpacity(0.2),
            ),
            child: Icon(Icons.support_agent, color: thm.accent, size: 42),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We\'re Here to Help',
                  style: TextStyle(color: thm.textHigh, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Have a question, suggestion, or encountered a bug?\nOur team is ready to assist you — always.',
                  style: TextStyle(color: thm.textLow, fontSize: 13.5, height: 1.6),
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
              color: thm.accent.withOpacity(0.2),
            ),
            child: Icon(Icons.support_agent, color: thm.accent, size: 42),
          ),
          const SizedBox(height: 16),
          Text(
            'We\'re Here to Help',
            style: TextStyle(color: thm.textHigh, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Have a question, suggestion, or encountered a bug?\nOur team is ready to assist you — always.',
            textAlign: TextAlign.center,
            style: TextStyle(color: thm.textLow, fontSize: 13.5, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(AppThemeOption thm, String label) {
    return Row(
      children: [
        Container(
          width: 4, height: 16,
          decoration: BoxDecoration(color: thm.accent, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                color: thm.textHigh, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3)),
      ],
    );
  }

  Widget _contactCard({
    required AppThemeOption thm,
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
          color: thm.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: thm.accent.withOpacity(0.2)),
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
                      style: TextStyle(
                          color: thm.textHigh, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: color, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(hint, style: TextStyle(color: thm.textLow, fontSize: 11)),
                ],
              ),
            ),
            if (onCopy != null)
              IconButton(
                icon: Icon(Icons.copy, color: thm.textLow, size: 18),
                onPressed: onCopy,
              ),
            Icon(Icons.arrow_forward_ios, color: thm.textLow, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _bugReportCard(AppThemeOption thm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: thm.cardColor,
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
              Text('Found a bug?',
                  style: TextStyle(color: thm.textHigh, fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Please send a detailed report including:\n'
                '• Your device model & OS version\n'
                '• Steps to reproduce the issue\n'
                '• A screenshot if possible',
            style: TextStyle(color: thm.textLow, fontSize: 13, height: 1.7),
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

  void _copy(BuildContext context, AppThemeOption thm, String text, String msg) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: thm.accent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}