import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameCtrl = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = ref.read(authNotifierProvider).displayName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, AppThemeOption thm, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? thm.accent : Colors.red[900],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: success ? 2 : 4),
      ),
    );
  }

  Future<void> _saveProfile(AppThemeOption thm) async {
    final trimmed = _nameCtrl.text.trim();
    if (trimmed.isEmpty) return;
    final ok = await ref.read(authNotifierProvider.notifier).updateProfile(name: trimmed);
    if (!mounted) return;
    if (ok) {
      setState(() => _editing = false);
      _snack('Profile updated successfully', thm, success: true);
    } else {
      _snack('Could not update profile. Please try again.', thm);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth       = ref.watch(authNotifierProvider);
    final isLoggedIn = auth.isLoggedIn;

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
            title: Text('Profile',
                style: TextStyle(color: thm.textHigh, fontWeight: FontWeight.w600, fontSize: 18)),
            centerTitle: true,
            elevation: 0,
            actions: isLoggedIn && !_editing
                ? [
              IconButton(
                icon: Icon(Icons.edit_outlined, color: thm.accent),
                onPressed: () => setState(() {
                  _editing = true;
                  _nameCtrl.text = auth.displayName;
                }),
              ),
            ]
                : null,
          ),
          body: isLoggedIn ? _loggedInView(auth, thm) : _loggedOutView(thm),
        );
      },
    );
  }

  Widget _loggedInView(auth, AppThemeOption thm) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide   = constraints.maxWidth > 600;
      final isTablet = constraints.maxWidth > 800;
      final hPad = isTablet ? 64.0 : isWide ? 40.0 : 20.0;
      final maxW = isTablet ? 720.0 : double.infinity;

      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _profileHeader(auth, isWide, isTablet, thm),
                SizedBox(height: isWide ? 32 : 24),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _infoSection(auth, thm),
                      const SizedBox(height: 32),
                      _signOutBtn(thm),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _profileHeader(auth, bool isWide, bool isTablet, AppThemeOption thm) {
    final avatarSize = isTablet ? 120.0 : isWide ? 110.0 : 100.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [thm.surface, thm.background],
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: isWide ? 48 : 36),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: thm.accent, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                        color: thm.accent.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ],
                ),
                child: auth.photoUrl.isNotEmpty
                    ? ClipOval(
                  child: Image.network(
                    auth.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(auth.displayName, thm),
                  ),
                )
                    : _avatarFallback(auth.displayName, thm),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: thm.accent),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            auth.displayName.isNotEmpty ? auth.displayName : 'Muslim User',
            style: TextStyle(
                color: thm.textHigh,
                fontSize: isWide ? 26 : 22,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(auth.email,
              style: TextStyle(color: thm.textLow, fontSize: 14)),
          const SizedBox(height: 8),
          Builder(builder: (_) {
            final parts = <String>[];
            if (auth.hasGoogle)   parts.add('Google');
            if (auth.hasPassword) parts.add('Email');
            final label = parts.join(' + ');
            if (label.isEmpty) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: thm.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: thm.accent.withOpacity(0.3)),
              ),
              child: Text('🔗  Signed in via $label',
                  style: TextStyle(
                      color: thm.accent, fontSize: 12, fontWeight: FontWeight.w600)),
            );
          }),
        ],
      ),
    );
  }

  Widget _avatarFallback(String displayName, AppThemeOption thm) {
    return CircleAvatar(
      backgroundColor: thm.accent,
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M',
        style: const TextStyle(
            color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoSection(auth, AppThemeOption thm) {
    return Container(
      decoration: BoxDecoration(
        color: thm.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: thm.accent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _infoTile(thm, Icons.email_outlined, 'Email',
              auth.email.isNotEmpty ? auth.email : '—'),
          Divider(height: 1, color: thm.accent.withOpacity(0.15)),
          _infoTile(thm, Icons.shield_outlined, 'Account Type', 'Standard'),
          Divider(height: 1, color: thm.accent.withOpacity(0.15)),
          _infoTile(thm, Icons.language, 'Language', 'English'),
          Divider(height: 1, color: thm.accent.withOpacity(0.15)),
          _securityTile(thm, isUpdate: auth.hasPassword),
        ],
      ),
    );
  }

  Widget _securityTile(AppThemeOption thm, {required bool isUpdate}) {
    return InkWell(
      onTap: () => _showSetPasswordSheet(thm),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: thm.accent, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Security',
                      style: TextStyle(color: thm.textLow, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    isUpdate ? 'Update Password for Login' : 'Add Password for Login',
                    style: TextStyle(color: thm.textHigh, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: thm.textLow, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(AppThemeOption thm, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: thm.accent, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: thm.textLow, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: thm.textHigh, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _signOutBtn(AppThemeOption thm) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmSignOut(thm),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
        label: const Text('Sign Out',
            style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
      ),
    );
  }

  void _showSetPasswordSheet(AppThemeOption thm) {
    final passCtrl    = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Consumer(
        builder: (_, ref, __) {
          final auth     = ref.watch(authNotifierProvider);
          final isUpdate = auth.hasPassword;
          final loading  = auth.isLoading;

          return StatefulBuilder(
            builder: (_, setSheetState) {
              bool obscure1 = true;
              bool obscure2 = true;

              return Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    decoration: BoxDecoration(
                      color: thm.cardColor,
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: thm.textLow.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isUpdate ? 'Update Password' : 'Add Password Login',
                          style: TextStyle(
                              color: thm.textHigh,
                              fontSize: 18,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isUpdate
                              ? 'Set a new password for your account.'
                              : 'After setting a password, you can sign in with either Google or your email & password.',
                          style: TextStyle(
                              color: thm.textLow, fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        StatefulBuilder(builder: (_, ss) {
                          return Column(
                            children: [
                              TextFormField(
                                controller: passCtrl,
                                obscureText: obscure1,
                                style: TextStyle(color: thm.textHigh),
                                decoration: InputDecoration(
                                  labelText: 'New Password',
                                  labelStyle:
                                  TextStyle(color: thm.textLow),
                                  prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: thm.accent,
                                      size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        obscure1
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: thm.textLow,
                                        size: 20),
                                    onPressed: () =>
                                        ss(() => obscure1 = !obscure1),
                                  ),
                                  filled: true,
                                  fillColor: thm.surface,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                        color: thm.accent.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                        color: thm.accent, width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: confirmCtrl,
                                obscureText: obscure2,
                                style: TextStyle(color: thm.textHigh),
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  labelStyle:
                                  TextStyle(color: thm.textLow),
                                  prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: thm.accent,
                                      size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        obscure2
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: thm.textLow,
                                        size: 20),
                                    onPressed: () =>
                                        ss(() => obscure2 = !obscure2),
                                  ),
                                  filled: true,
                                  fillColor: thm.surface,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                        color: thm.accent.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                        color: thm.accent, width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: loading
                                ? null
                                : () async {
                              if (passCtrl.text.length < 6) {
                                _snack('Password must be at least 6 characters.', thm);
                                return;
                              }
                              if (passCtrl.text != confirmCtrl.text) {
                                _snack('Passwords do not match.', thm);
                                return;
                              }
                              final ok = await ref
                                  .read(authNotifierProvider.notifier)
                                  .addPasswordToAccount(
                                  password: passCtrl.text);
                              if (!sheetCtx.mounted) return;
                              Navigator.of(sheetCtx).pop();
                              if (ok) {
                                _snack(
                                  isUpdate
                                      ? 'Your password has been updated.'
                                      : 'You can now sign in with email & password too.',
                                  thm,
                                  success: true,
                                );
                              } else {
                                final err = ref
                                    .read(authNotifierProvider)
                                    .errorMessage;
                                _snack(err.isNotEmpty
                                    ? err
                                    : 'Failed. Please try again.', thm);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: thm.accent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: loading
                                ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                                : Text(
                                isUpdate
                                    ? 'Update Password'
                                    : 'Set Password',
                                style: const TextStyle(
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
            },
          );
        },
      ),
    );
  }

  void _confirmSignOut(AppThemeOption thm) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: thm.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out',
            style: TextStyle(color: thm.textHigh, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?',
            style: TextStyle(color: thm.textLow)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Cancel', style: TextStyle(color: thm.textLow)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref.read(authNotifierProvider.notifier).signOut();
              if (!mounted) return;
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
            },
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _loggedOutView(AppThemeOption thm) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 600;
      final maxW   = isWide ? 480.0 : double.infinity;
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Padding(
            padding: EdgeInsets.all(isWide ? 48 : 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isWide ? 36 : 28),
                  decoration: BoxDecoration(
                    color: thm.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: thm.accent.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.person_outline,
                      color: thm.accent, size: isWide ? 80 : 60),
                ),
                const SizedBox(height: 24),
                Text('بِسْمِ اللَّهِ',
                    style: TextStyle(
                        color: thm.accent, fontSize: 24, fontFamily: 'Amiri')),
                const SizedBox(height: 8),
                Text(
                  'Sign in to sync your progress,\nduas, and quran_tilawat bookmarks.',
                  textAlign: TextAlign.center,
                  style:
                  TextStyle(color: thm.textLow, fontSize: 15, height: 1.6),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuthPage()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: thm.accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Sign In / Create Account',
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