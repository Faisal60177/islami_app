import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

const _bg         = Color(0xFF011A0E);
const _surface    = Color(0xFF0D2E1C);
const _card       = Color(0xFF122E1E);
const _accent     = Color(0xFF4CAF82);
const _accentSoft = Color(0xFF2E7D5A);
const _gold       = Color(0xFFD4AF37);
const _textHi     = Color(0xFFE8F5EC);
const _textLo     = Color(0xFF7BAF92);

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  final AuthController _auth = Get.find<AuthController>();

  late TabController _tab;
  final _signInForm = GlobalKey<FormState>();
  final _signUpForm = GlobalKey<FormState>();

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

    // Clear errors when switching tabs so stale messages don't show
    _tab.addListener(() {
      if (_tab.indexIsChanging) {
        _auth.errorMessage.value = '';
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _auth.errorMessage.value = '';
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

  // ── Sign In ──────────────────────────────────────────────────────────────

  Future<void> _doSignIn() async {
    if (!_signInForm.currentState!.validate()) return;

    final ok = await _auth.signInWithEmail(
      email:    _emailInCtrl.text,
      password: _passInCtrl.text,
    );

    if (!mounted) return;

    if (ok) {
      _popAuthPage();
      _snack('Welcome back! 🌙', success: true);
    } else {
      _snack(_auth.errorMessage.value.isNotEmpty
          ? _auth.errorMessage.value
          : 'Sign in failed. Please try again.');
    }
  }

  // ── Sign Up ──────────────────────────────────────────────────────────────

  Future<void> _doSignUp() async {
    if (!_signUpForm.currentState!.validate()) return;

    final ok = await _auth.signUpWithEmail(
      name:     _nameCtrl.text,
      email:    _emailUpCtrl.text,
      password: _passUpCtrl.text,
    );

    if (!mounted) return;

    if (ok) {
      _popAuthPage();
      _snack('Account created! Assalamu Alaikum 🌙', success: true);
    } else {
      _snack(_auth.errorMessage.value.isNotEmpty
          ? _auth.errorMessage.value
          : 'Sign up failed. Please try again.');
    }
  }

  // ── Google ───────────────────────────────────────────────────────────────

  Future<void> _doGoogle() async {
    final ok = await _auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      _popAuthPage();
      _snack('Signed in with Google 🌙', success: true);
    } else if (_auth.errorMessage.value.isNotEmpty) {
      _snack(_auth.errorMessage.value);
    }
  }

  void _popAuthPage() {
    final nav = Navigator.of(Get.context!);
    if (nav.canPop()) nav.pop();
  }

  void _snack(String msg, {bool success = false}) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.snackbar(
      success ? 'Success' : 'Error',
      msg,
      backgroundColor: success ? _accentSoft : Colors.red[900],
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: Duration(seconds: success ? 2 : 4),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

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
        title: const Text(
          'My Account',
          style: TextStyle(color: _textHi, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tab,
              indicator: BoxDecoration(
                color: _accentSoft,
                borderRadius: BorderRadius.circular(30),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: _textLo,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              tabs: const [Tab(text: 'Sign In'), Tab(text: 'Sign Up')],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_signInView(), _signUpView()],
      ),
    );
  }

  // ── Sign In View ─────────────────────────────────────────────────────────

  Widget _signInView() {
    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth > 600 ? 500.0 : double.infinity;
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: constraints.maxWidth > 600 ? 48 : 24,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _arabicDecor(),
                const SizedBox(height: 32),
                Form(
                  key: _signInForm,
                  child: Column(
                    children: [
                      _field(
                        controller: _emailInCtrl,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      _field(
                        controller: _passInCtrl,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        obscure: !_showPassIn,
                        suffix: IconButton(
                          icon: Icon(
                            _showPassIn ? Icons.visibility_off : Icons.visibility,
                            color: _textLo,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _showPassIn = !_showPassIn),
                        ),
                        validator: (v) =>
                        (v == null || v.length < 6) ? 'Min 6 characters' : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgot,
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(color: _gold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(() => _primaryBtn(
                        label: 'Sign In',
                        loading: _auth.isLoading.value,
                        onTap: _doSignIn,
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _divider(),
                const SizedBox(height: 24),
                _googleBtn(),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _tab.animateTo(1),
                  child: RichText(
                    text: const TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: _textLo),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(color: _accent, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ── Sign Up View ─────────────────────────────────────────────────────────

  Widget _signUpView() {
    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth > 600 ? 500.0 : double.infinity;
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: constraints.maxWidth > 600 ? 48 : 24,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _arabicDecor(),
                const SizedBox(height: 32),
                // Info banner explaining that same email works with both methods
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _accentSoft.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accentSoft.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: _accent, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You can use the same email for both Google and email/password sign-in. They will be linked to one account.',
                          style: TextStyle(color: _textLo, fontSize: 12, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Form(
                  key: _signUpForm,
                  child: Column(
                    children: [
                      _field(
                        controller: _nameCtrl,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Name required' : null,
                      ),
                      const SizedBox(height: 16),
                      _field(
                        controller: _emailUpCtrl,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      _field(
                        controller: _passUpCtrl,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        obscure: !_showPassUp,
                        suffix: IconButton(
                          icon: Icon(
                            _showPassUp ? Icons.visibility_off : Icons.visibility,
                            color: _textLo,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _showPassUp = !_showPassUp),
                        ),
                        validator: (v) =>
                        (v == null || v.length < 6) ? 'Min 6 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      _field(
                        controller: _confirmCtrl,
                        label: 'Confirm Password',
                        icon: Icons.lock_outline,
                        obscure: !_showConfirm,
                        suffix: IconButton(
                          icon: Icon(
                            _showConfirm ? Icons.visibility_off : Icons.visibility,
                            color: _textLo,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _showConfirm = !_showConfirm),
                        ),
                        validator: (v) =>
                        v != _passUpCtrl.text ? 'Passwords do not match' : null,
                      ),
                      const SizedBox(height: 24),
                      Obx(() => _primaryBtn(
                        label: 'Create Account',
                        loading: _auth.isLoading.value,
                        onTap: _doSignUp,
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _divider(),
                const SizedBox(height: 24),
                _googleBtn(),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _tab.animateTo(0),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: _textLo),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(color: _accent, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ── Forgot Password Dialog ───────────────────────────────────────────────

  void _showForgot() {
    final ctrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset Password',
          style: TextStyle(color: _textHi, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email and we will send a reset link.',
              style: TextStyle(color: _textLo, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _field(
              controller: ctrl,
              label: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: _textLo)),
          ),
          Obx(() => ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accentSoft),
            onPressed: _auth.isLoading.value
                ? null
                : () async {
              if (ctrl.text.trim().isEmpty) return;
              final ok = await _auth.sendPasswordReset(ctrl.text);
              Get.back();
              _snack(
                ok
                    ? 'Reset email sent! Check your inbox.'
                    : _auth.errorMessage.value,
                success: ok,
              );
            },
            child: _auth.isLoading.value
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('Send Link', style: TextStyle(color: Colors.white)),
          )),
        ],
      ),
    );
  }

  // ── Shared Widgets ───────────────────────────────────────────────────────

  Widget _arabicDecor() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold.withOpacity(0.3)),
          ),
          child: const Text(
            'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
            style: TextStyle(color: _gold, fontSize: 20, fontFamily: 'Amiri'),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'In the name of Allah, the Most Gracious',
          style: TextStyle(color: _textLo, fontSize: 12),
        ),
      ],
    );
  }

  Widget _field({
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
      style: const TextStyle(color: _textHi),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textLo, fontSize: 14),
        prefixIcon: Icon(icon, color: _accentSoft, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: _surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _accentSoft.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.5),
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
    required String label,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentSoft,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: loading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
        )
            : Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Row(
      children: [
        Expanded(child: Divider(color: _textLo.withOpacity(0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: TextStyle(color: _textLo.withOpacity(0.7), fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: _textLo.withOpacity(0.3))),
      ],
    );
  }

  Widget _googleBtn() {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: _auth.isLoading.value ? null : _doGoogle,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: _textLo.withOpacity(0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: _surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Image.network(
                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                width: 22,
                height: 22,
                errorBuilder: (_, __, ___) => Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(color: _textHi, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ));
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email required';
    final regex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!regex.hasMatch(v.trim())) return 'Invalid email address';
    return null;
  }
}