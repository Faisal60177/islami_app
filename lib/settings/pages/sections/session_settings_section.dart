import 'package:flutter/material.dart';
import '../../cubit/settings_cubit.dart';
import '../../cubit/settings_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_themes.dart';
import '../../../Menu/auth/sign_out_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _launchPrivacyPolicy() async {
  final Uri url = Uri.parse('https://faisal60177.github.io/muslim-life/privacy.html');
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}

class SessionSettingsSection extends StatelessWidget {
  final AppThemeOption theme;
  final AppLocalizations l10n;
  const SessionSettingsSection(
      {super.key, required this.theme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final thm   = getThemeById(state.themeMode);

        return Column(
          children: [
            // Privacy policy
            _ActionTile(
              thm: thm,
              icon: Icons.privacy_tip_outlined,
              iconColor: const Color(0xFF26C6DA),
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              onTap: _launchPrivacyPolicy,
              showArrow: true,
            ),
            const SizedBox(height: 10),

            // Sign out (red)
            Container(
              decoration: BoxDecoration(
                color: thm.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.red.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.06),
                    blurRadius: 12, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const SignOutPage(),
                      transitionDuration: const Duration(milliseconds: 300),
                      reverseTransitionDuration: const Duration(milliseconds: 300),
                      transitionsBuilder: (_, animation, __, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        );
                      },
                    ),
                  ),
                  splashColor: Colors.red.withOpacity(0.08),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.logout_rounded,
                              color: Colors.redAccent, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sign Out',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'End your current session',
                                style: TextStyle(
                                    color: thm.textLow, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.redAccent, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

}

class _ActionTile extends StatelessWidget {
  final AppThemeOption thm;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showArrow;

  const _ActionTile({
    required this.thm,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: thm.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: thm.accent.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(thm.isDark ? 0.25 : 0.05),
            blurRadius: 10, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          splashColor: iconColor.withOpacity(0.07),
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: thm.textHigh,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              color: thm.textLow, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(
                  showArrow
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.chevron_right_rounded,
                  color: thm.textLow,
                  size: showArrow ? 13 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}