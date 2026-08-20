import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_page.dart';

class SignOutPage extends ConsumerWidget {
  const SignOutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);

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
            title: Text('Sign Out',
                style: TextStyle(color: thm.textHigh, fontWeight: FontWeight.w600, fontSize: 18)),
            centerTitle: true,
            elevation: 0,
          ),
          body: auth.isLoggedIn
              ? _signOutView(context, ref, auth, thm)
              : _notLoggedInView(context, thm),
        );
      },
    );
  }

  Widget _signOutView(BuildContext context, WidgetRef ref, authState, AppThemeOption thm) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide     = constraints.maxWidth > 600;
      final isTablet   = constraints.maxWidth > 800;
      final maxW       = isTablet ? 520.0 : isWide ? 480.0 : double.infinity;
      final hPad       = isTablet ? 80.0   : isWide ? 64.0  : 32.0;
      final avatarSize = isTablet ? 130.0  : isWide ? 120.0 : 110.0;

      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Avatar ──────────────────────────────────────────
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: thm.surface,
                      border: Border.all(color: thm.accent.withOpacity(0.4), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                            color: thm.accent.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 2)
                      ],
                    ),
                    child: authState.photoUrl.isNotEmpty
                        ? ClipOval(
                      child: Image.network(
                        authState.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarFallback(authState.displayName, thm),
                      ),
                    )
                        : _avatarFallback(authState.displayName, thm),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    authState.displayName.isNotEmpty ? authState.displayName : 'Muslim User',
                    style: TextStyle(
                        color: thm.textHigh,
                        fontSize: isWide ? 26 : 22,
                        fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    authState.email,
                    style: TextStyle(color: thm.textLow, fontSize: 14),
                  ),

                  SizedBox(height: isWide ? 48 : 40),

                  // ── Confirmation card ────────────────────────────────
                  Container(
                    padding: EdgeInsets.all(isWide ? 28 : 20),
                    decoration: BoxDecoration(
                      color: thm.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.25)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.logout_rounded,
                            color: Colors.redAccent, size: isWide ? 52 : 40),
                        const SizedBox(height: 14),
                        Text(
                          'Are you sure you want to sign out?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: thm.textHigh,
                              fontSize: isWide ? 20 : 17,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your bookmarks, progress and data\nwill be saved to your account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: thm.textLow, fontSize: 13.5, height: 1.6),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Sign Out button ──────────────────────────────────
                  Consumer(builder: (_, ref, __) {
                    final loading = ref.watch(authNotifierProvider).isLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: loading
                            ? null
                            : () async {
                          await ref
                              .read(authNotifierProvider.notifier)
                              .signOut();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'You have been signed out. See you soon! 🌙'),
                              backgroundColor: thm.accent,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[800],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                        icon: loading
                            ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                            : const Icon(Icons.logout, color: Colors.white, size: 20),
                        label: const Text(
                          'Yes, Sign Me Out',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 14),

                  // ── Cancel button ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: thm.accent.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Cancel',
                          style: TextStyle(
                              color: thm.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _avatarFallback(String displayName, AppThemeOption thm) {
    return Center(
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M',
        style: const TextStyle(
            color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _notLoggedInView(BuildContext context, AppThemeOption thm) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 600;
      final maxW   = isWide ? 480.0 : double.infinity;
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 80 : 32,
              vertical: 32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isWide ? 36 : 28),
                  decoration: BoxDecoration(
                    color: thm.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: thm.textLow.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.person_off_outlined,
                      color: thm.textLow, size: isWide ? 64 : 52),
                ),
                const SizedBox(height: 24),
                Text("You're not signed in",
                    style: TextStyle(
                        color: thm.textHigh, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'Sign in to access your profile\nand personalized features.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: thm.textLow, fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuthPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: thm.accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Sign In',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}