import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_page.dart';

const _bg         = Color(0xFF011A0E);
const _surface    = Color(0xFF0D2E1C);
const _card       = Color(0xFF122E1E);
const _accent     = Color(0xFF4CAF82);
const _accentSoft = Color(0xFF2E7D5A);
const _gold       = Color(0xFFD4AF37);
const _textHi     = Color(0xFFE8F5EC);
const _textLo     = Color(0xFF7BAF92);

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

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? _accentSoft : Colors.red[900],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: success ? 2 : 4),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final trimmed = _nameCtrl.text.trim();
    if (trimmed.isEmpty) return;
    final ok = await ref.read(authNotifierProvider.notifier).updateProfile(name: trimmed);
    if (!mounted) return;
    if (ok) {
      setState(() => _editing = false);
      _snack('Profile updated successfully', success: true);
    } else {
      _snack('Could not update profile. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth       = ref.watch(authNotifierProvider);
    final isLoggedIn = auth.isLoggedIn;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _accent),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Profile',
            style: TextStyle(color: _textHi, fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        actions: isLoggedIn && !_editing
            ? [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: _accent),
            onPressed: () => setState(() {
              _editing = true;
              _nameCtrl.text = auth.displayName;
            }),
          ),
        ]
            : null,
      ),
      body: isLoggedIn ? _loggedInView(auth) : _loggedOutView(),
    );
  }

  Widget _loggedInView(auth) {
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
                _profileHeader(auth, isWide, isTablet),
                SizedBox(height: isWide ? 32 : 24),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _infoSection(auth),
                      const SizedBox(height: 32),
                      _signOutBtn(),
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

  Widget _profileHeader(auth, bool isWide, bool isTablet) {
    final avatarSize = isTablet ? 120.0 : isWide ? 110.0 : 100.0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_surface, _bg],
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
                  border: Border.all(color: _gold, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                        color: _accent.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ],
                ),
                child: auth.photoUrl.isNotEmpty
                    ? ClipOval(
                  child: Image.network(
                    auth.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(auth.displayName),
                  ),
                )
                    : _avatarFallback(auth.displayName),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: _accentSoft),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            auth.displayName.isNotEmpty ? auth.displayName : 'Muslim User',
            style: TextStyle(
                color: _textHi,
                fontSize: isWide ? 26 : 22,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(auth.email,
              style: const TextStyle(color: _textLo, fontSize: 14)),
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
                color: _gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gold.withOpacity(0.3)),
              ),
              child: Text('🔗  Signed in via $label',
                  style: const TextStyle(
                      color: _gold, fontSize: 12, fontWeight: FontWeight.w600)),
            );
          }),
        ],
      ),
    );
  }

  Widget _avatarFallback(String displayName) {
    return CircleAvatar(
      backgroundColor: _accentSoft,
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M',
        style: const TextStyle(
            color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoSection(auth) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentSoft.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _infoTile(Icons.email_outlined, 'Email',
              auth.email.isNotEmpty ? auth.email : '—'),
          Divider(height: 1, color: _accentSoft.withOpacity(0.15)),
          _infoTile(Icons.shield_outlined, 'Account Type', 'Standard'),
          Divider(height: 1, color: _accentSoft.withOpacity(0.15)),
          _infoTile(Icons.language, 'Language', 'English'),
          Divider(height: 1, color: _accentSoft.withOpacity(0.15)),
          _securityTile(isUpdate: auth.hasPassword),
        ],
      ),
    );
  }

  Widget _securityTile({required bool isUpdate}) {
    return InkWell(
      onTap: _showSetPasswordSheet,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: _accent, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Security',
                      style: TextStyle(color: _textLo, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    isUpdate ? 'Update Password for Login' : 'Add Password for Login',
                    style: const TextStyle(color: _textHi, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _textLo, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: _accent, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: _textLo, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: _textHi, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _signOutBtn() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _confirmSignOut,
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

  void _showSetPasswordSheet() {
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
                    decoration: const BoxDecoration(
                      color: _card,
                      borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
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
                              color: _textLo.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isUpdate ? 'Update Password' : 'Add Password Login',
                          style: const TextStyle(
                              color: _textHi,
                              fontSize: 18,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isUpdate
                              ? 'Set a new password for your account.'
                              : 'After setting a password, you can sign in with either Google or your email & password.',
                          style: const TextStyle(
                              color: _textLo, fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        StatefulBuilder(builder: (_, ss) {
                          return Column(
                            children: [
                              TextFormField(
                                controller: passCtrl,
                                obscureText: obscure1,
                                style: const TextStyle(color: _textHi),
                                decoration: InputDecoration(
                                  labelText: 'New Password',
                                  labelStyle:
                                  const TextStyle(color: _textLo),
                                  prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: _accentSoft,
                                      size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        obscure1
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: _textLo,
                                        size: 20),
                                    onPressed: () =>
                                        ss(() => obscure1 = !obscure1),
                                  ),
                                  filled: true,
                                  fillColor: _surface,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                        color: _accentSoft.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: _accent, width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: confirmCtrl,
                                obscureText: obscure2,
                                style: const TextStyle(color: _textHi),
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  labelStyle:
                                  const TextStyle(color: _textLo),
                                  prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: _accentSoft,
                                      size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        obscure2
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: _textLo,
                                        size: 20),
                                    onPressed: () =>
                                        ss(() => obscure2 = !obscure2),
                                  ),
                                  filled: true,
                                  fillColor: _surface,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                        color: _accentSoft.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: _accent, width: 1.5),
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
                                _snack('Password must be at least 6 characters.');
                                return;
                              }
                              if (passCtrl.text != confirmCtrl.text) {
                                _snack('Passwords do not match.');
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
                                  success: true,
                                );
                              } else {
                                final err = ref
                                    .read(authNotifierProvider)
                                    .errorMessage;
                                _snack(err.isNotEmpty
                                    ? err
                                    : 'Failed. Please try again.');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentSoft,
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

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(color: _textHi, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: _textLo)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: _textLo)),
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
                  backgroundColor: _accentSoft,
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

  Widget _loggedOutView() {
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
                    color: _surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: _gold.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.person_outline,
                      color: _gold, size: isWide ? 80 : 60),
                ),
                const SizedBox(height: 24),
                const Text('بِسْمِ اللَّهِ',
                    style: TextStyle(
                        color: _gold, fontSize: 24, fontFamily: 'Amiri')),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to sync your progress,\nduas, and Quran bookmarks.',
                  textAlign: TextAlign.center,
                  style:
                  TextStyle(color: _textLo, fontSize: 15, height: 1.6),
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
                      backgroundColor: _accentSoft,
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