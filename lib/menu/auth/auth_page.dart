import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import 'auth_notifier.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  final _signInForm  = GlobalKey<FormState>();
  final _signUpForm  = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailInCtrl = TextEditingController();
  final _passInCtrl  = TextEditingController();
  final _emailUpCtrl = TextEditingController();
  final _passUpCtrl  = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showPassIn  = false;
  bool _showPassUp  = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (_tab.indexIsChanging) {
        ref.read(authNotifierProvider.notifier)
            .state = ref.read(authNotifierProvider).copyWith(errorMessage: '');
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameCtrl.dispose();
    _emailInCtrl.dispose();
    _passInCtrl.dispose();
    _emailUpCtrl.dispose();
    _passUpCtrl.dispose();
    _confirmCtrl.dispose();
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

  Future<void> _doSignIn(AppThemeOption thm) async {
    if (!_signInForm.currentState!.validate()) return;
    final ok = await ref.read(authNotifierProvider.notifier).signInWithEmail(
      email:    _emailInCtrl.text,
      password: _passInCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      _snack('Welcome back! 🌙', thm, success: true);
    } else {
      final err = ref.read(authNotifierProvider).errorMessage;
      _snack(err.isNotEmpty ? err : 'Sign in failed. Please try again.', thm);
    }
  }

  Future<void> _doSignUp(AppThemeOption thm) async {
    if (!_signUpForm.currentState!.validate()) return;
    final ok = await ref.read(authNotifierProvider.notifier).signUpWithEmail(
      name:     _nameCtrl.text,
      email:    _emailUpCtrl.text,
      password: _passUpCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      _snack('Account created! Assalamu Alaikum 🌙', thm, success: true);
    } else {
      final err = ref.read(authNotifierProvider).errorMessage;
      _snack(err.isNotEmpty ? err : 'Sign up failed. Please try again.', thm);
    }
  }

  Future<void> _doGoogle(AppThemeOption thm) async {
    final ok = await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      _snack('Signed in with Google 🌙', thm, success: true);
    } else {
      final err = ref.read(authNotifierProvider).errorMessage;
      if (err.isNotEmpty) _snack(err, thm);
    }
  }

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
            title: Text('My Account',
                style: TextStyle(color: thm.textHigh, fontSize: 18, fontWeight: FontWeight.w600)),
            centerTitle: true,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                decoration: BoxDecoration(
                  color: thm.surface,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(color: thm.accent, borderRadius: BorderRadius.circular(30)),
                  labelColor: Colors.white,
                  unselectedLabelColor: thm.textLow,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(fontSize: 14),
                  tabs: const [Tab(text: 'Sign In'), Tab(text: 'Sign Up')],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: [_signInView(thm), _signUpView(thm)],
          ),
        );
      },
    );
  }

  Widget _signInView(AppThemeOption thm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _arabicDecor(thm),
          const SizedBox(height: 32),
          Form(
            key: _signInForm,
            child: Column(
              children: [
                _field(thm: thm, controller: _emailInCtrl, label: 'Email Address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail),
                const SizedBox(height: 16),
                _field(
                  thm: thm,
                  controller: _passInCtrl, label: 'Password',
                  icon: Icons.lock_outline, obscure: !_showPassIn,
                  suffix: IconButton(
                    icon: Icon(_showPassIn ? Icons.visibility_off : Icons.visibility,
                        color: thm.textLow, size: 20),
                    onPressed: () => setState(() => _showPassIn = !_showPassIn),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showForgot(thm),
                    child: Text('Forgot password?',
                        style: TextStyle(color: thm.accent, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 8),
                Consumer(builder: (_, ref, __) {
                  final loading = ref.watch(authNotifierProvider).isLoading;
                  return _primaryBtn(thm: thm, label: 'Sign In', loading: loading, onTap: () => _doSignIn(thm));
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _divider(thm),
          const SizedBox(height: 24),
          _googleBtn(thm),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _tab.animateTo(1),
            child: RichText(
              text: TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(color: thm.textLow),
                children: [TextSpan(text: 'Sign Up',
                    style: TextStyle(color: thm.accent, fontWeight: FontWeight.w700))],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signUpView(AppThemeOption thm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _arabicDecor(thm),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: thm.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: thm.accent.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: thm.accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You can use the same email for both Google and email/password. They will be linked to one account.',
                    style: TextStyle(color: thm.textLow, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          Form(
            key: _signUpForm,
            child: Column(
              children: [
                _field(thm: thm, controller: _nameCtrl, label: 'Full Name',
                    icon: Icons.person_outline,
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name required' : null),
                const SizedBox(height: 16),
                _field(thm: thm, controller: _emailUpCtrl, label: 'Email Address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail),
                const SizedBox(height: 16),
                _field(
                  thm: thm,
                  controller: _passUpCtrl, label: 'Password',
                  icon: Icons.lock_outline, obscure: !_showPassUp,
                  suffix: IconButton(
                    icon: Icon(_showPassUp ? Icons.visibility_off : Icons.visibility,
                        color: thm.textLow, size: 20),
                    onPressed: () => setState(() => _showPassUp = !_showPassUp),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 16),
                _field(
                  thm: thm,
                  controller: _confirmCtrl, label: 'Confirm Password',
                  icon: Icons.lock_outline, obscure: !_showConfirm,
                  suffix: IconButton(
                    icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility,
                        color: thm.textLow, size: 20),
                    onPressed: () => setState(() => _showConfirm = !_showConfirm),
                  ),
                  validator: (v) => v != _passUpCtrl.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 24),
                Consumer(builder: (_, ref, __) {
                  final loading = ref.watch(authNotifierProvider).isLoading;
                  return _primaryBtn(thm: thm, label: 'Create Account', loading: loading, onTap: () => _doSignUp(thm));
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _divider(thm),
          const SizedBox(height: 24),
          _googleBtn(thm),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _tab.animateTo(0),
            child: RichText(
              text: TextSpan(
                text: 'Already have an account? ',
                style: TextStyle(color: thm.textLow),
                children: [TextSpan(text: 'Sign In',
                    style: TextStyle(color: thm.accent, fontWeight: FontWeight.w700))],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgot(AppThemeOption thm) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: thm.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset Password',
            style: TextStyle(color: thm.textHigh, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your email and we will send a reset link.',
                style: TextStyle(color: thm.textLow, fontSize: 13)),
            const SizedBox(height: 16),
            _field(thm: thm, controller: ctrl, label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Cancel', style: TextStyle(color: thm.textLow)),
          ),
          Consumer(builder: (_, ref, __) {
            final loading = ref.watch(authNotifierProvider).isLoading;
            return ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: thm.accent),
              onPressed: loading ? null : () async {
                if (ctrl.text.trim().isEmpty) return;
                final ok = await ref.read(authNotifierProvider.notifier)
                    .sendPasswordReset(ctrl.text);
                if (!dialogCtx.mounted) return;
                Navigator.of(dialogCtx).pop();
                _snack(
                  ok ? 'Reset email sent! Check your inbox.'
                      : ref.read(authNotifierProvider).errorMessage,
                  thm,
                  success: ok,
                );
              },
              child: loading
                  ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Send Link', style: TextStyle(color: Colors.white)),
            );
          }),
        ],
      ),
    );
  }

  Widget _arabicDecor(AppThemeOption thm) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: thm.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: thm.accent.withOpacity(0.3)),
          ),
          child: Text('بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
              style: TextStyle(color: thm.accent, fontSize: 20, fontFamily: 'Amiri'),
              textAlign: TextAlign.center),
        ),
        const SizedBox(height: 8),
        Text('In the name of Allah, the Most Gracious',
            style: TextStyle(color: thm.textLow, fontSize: 12)),
      ],
    );
  }

  Widget _field({
    required AppThemeOption thm,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: TextStyle(color: thm.textHigh),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: thm.textLow, fontSize: 14),
        prefixIcon: Icon(icon, color: thm.accent, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: thm.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: thm.accent.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: thm.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _primaryBtn({
    required AppThemeOption thm,
    required String label,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: thm.accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Text(label, style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }

  Widget _divider(AppThemeOption thm) {
    return Row(
      children: [
        Expanded(child: Divider(color: thm.textLow.withOpacity(0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or continue with',
              style: TextStyle(color: thm.textLow.withOpacity(0.7), fontSize: 12)),
        ),
        Expanded(child: Divider(color: thm.textLow.withOpacity(0.3))),
      ],
    );
  }

  Widget _googleBtn(AppThemeOption thm) {
    return Consumer(builder: (_, ref, __) {
      final loading = ref.watch(authNotifierProvider).isLoading;
      return SizedBox(
        width: double.infinity, height: 54,
        child: OutlinedButton(
          onPressed: loading ? null : () => _doGoogle(thm),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: thm.textLow.withOpacity(0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: thm.surface,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                width: 22, height: 22,
                errorBuilder: (_, __, ___) => const CircleAvatar(
                  backgroundColor: Colors.white, radius: 11,
                  child: Text('G', style: TextStyle(color: Color(0xFF4285F4),
                      fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Text('Continue with Google',
                  style: TextStyle(color: thm.textHigh, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    });
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email required';
    final regex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!regex.hasMatch(v.trim())) return 'Invalid email address';
    return null;
  }
}