import 'package:flutter/material.dart';

import '../../cubit/settings_cubit.dart';
import '../../cubit/settings_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_themes.dart';
import '../../../Menu/auth/sign_out_page.dart';
import '../../../Menu/auth/auth_controller.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as gets;

class SessionSettingsSection extends StatelessWidget {
  final AppThemeOption theme;
  final AppLocalizations l10n;
  const SessionSettingsSection(
      {super.key, required this.theme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final cubit = context.read<SettingsCubit>();
        final thm   = getThemeById(state.themeMode);

        return Column(
          children: [
            // Reset settings
            _ActionTile(
              thm: thm,
              icon: Icons.refresh_rounded,
              iconColor: const Color(0xFFFFB74D),
              title: 'Reset All Settings',
              subtitle: 'Restore defaults (keeps account)',
              onTap: () => _showResetDialog(context, cubit, thm),
            ),
            const SizedBox(height: 10),

            // Privacy policy
            _ActionTile(
              thm: thm,
              icon: Icons.privacy_tip_outlined,
              iconColor: const Color(0xFF26C6DA),
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              onTap: () {/* Open web view */},
              showArrow: true,
            ),
            const SizedBox(height: 10),

            // Clear cache
            _ActionTile(
              thm: thm,
              icon: Icons.delete_sweep_rounded,
              iconColor: const Color(0xFF9E9E9E),
              title: 'Clear Cache',
              subtitle: 'Free up storage space',
              onTap: () => _showClearCacheDialog(context, thm),
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
                  onTap: () => gets.Get.to(() => const SignOutPage(),
                      transition: gets.Transition.rightToLeft),
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

  void _showResetDialog(
      BuildContext context, SettingsCubit cubit, AppThemeOption thm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: thm.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'Reset Settings',
              style: TextStyle(
                  color: thm.textHigh, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'All settings will return to defaults. Your account and data will not be affected.',
          style: TextStyle(color: thm.textLow, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: thm.textLow)),
          ),
          ElevatedButton(
            onPressed: () {
              cubit.resetAllSettings();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Settings reset to defaults'),
                  backgroundColor: thm.accent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB74D),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w700),),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, AppThemeOption thm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: thm.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🗑️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'Clear Cache',
              style: TextStyle(
                  color: thm.textHigh, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'This will clear temporary files. The app may load slightly slower until data is re-cached.',
          style: TextStyle(color: thm.textLow, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: thm.textLow)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Cache cleared successfully'),
                  backgroundColor: const Color(0xFF9E9E9E),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9E9E9E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Clear', style: TextStyle(fontWeight: FontWeight.w700),),
          ),
        ],
      ),
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