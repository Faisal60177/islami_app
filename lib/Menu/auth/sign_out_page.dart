import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_page.dart';

const _bg        = Color(0xFF011A0E);
const _surface   = Color(0xFF0D2E1C);
const _card      = Color(0xFF122E1E);
const _accent    = Color(0xFF4CAF82);
const _accentSoft= Color(0xFF2E7D5A);
const _gold      = Color(0xFFD4AF37);
const _textHi    = Color(0xFFE8F5EC);
const _textLo    = Color(0xFF7BAF92);

class SignOutPage extends StatelessWidget {
  const SignOutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _accent),
          onPressed: () => Get.back(),
        ),
        title: const Text('Sign Out',
            style: TextStyle(color: _textHi, fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(() {
        if (!auth.isLoggedIn) return _notLoggedInView();
        return _signOutView(auth);
      }),
    );
  }

  Widget _signOutView(AuthController auth) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide   = constraints.maxWidth > 600;
      final isTablet = constraints.maxWidth > 800;
      final maxW  = isTablet ? 520.0 : isWide ? 480.0 : double.infinity;
      final hPad  = isTablet ? 80.0 : isWide ? 64.0 : 32.0;
      final avatarSize = isTablet ? 130.0 : isWide ? 120.0 : 110.0;

      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar
                  Obx(() => Container(
                    width: avatarSize, height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _surface,
                      border: Border.all(color: _gold.withOpacity(0.4), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                            color: _accent.withOpacity(0.2),
                            blurRadius: 30, spreadRadius: 2)
                      ],
                    ),
                    child: auth.photoUrl.value.isNotEmpty
                        ? ClipOval(
                        child: Image.network(auth.photoUrl.value,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _avatarFallback(auth)))
                        : _avatarFallback(auth),
                  )),
                  const SizedBox(height: 20),
                  Obx(() => Text(
                    auth.displayName.value.isNotEmpty
                        ? auth.displayName.value
                        : 'Muslim User',
                    style: TextStyle(
                        color: _textHi,
                        fontSize: isWide ? 26 : 22,
                        fontWeight: FontWeight.w700),
                  )),
                  const SizedBox(height: 4),
                  Obx(() => Text(auth.email.value,
                      style: const TextStyle(color: _textLo, fontSize: 14))),
                  SizedBox(height: isWide ? 48 : 40),

                  // Confirmation card
                  Container(
                    padding: EdgeInsets.all(isWide ? 28 : 20),
                    decoration: BoxDecoration(
                      color: _card,
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
                              color: _textHi,
                              fontSize: isWide ? 20 : 17,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your bookmarks, progress and data\nwill be saved to your account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _textLo, fontSize: 13.5, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Sign out button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Obx(() => ElevatedButton.icon(
                      onPressed: auth.isLoading.value
                          ? null
                          : () async {
                        await auth.signOut();
                        Get.back();
                        Get.snackbar(
                          'Signed Out',
                          'You have been signed out. See you soon! 🌙',
                          backgroundColor: _accentSoft,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[800],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      icon: auth.isLoading.value
                          ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                          : const Icon(Icons.logout, color: Colors.white, size: 20),
                      label: const Text('Yes, Sign Me Out',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    )),
                  ),
                  const SizedBox(height: 14),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _accentSoft.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              color: _accent, fontWeight: FontWeight.w600, fontSize: 15)),
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

  Widget _avatarFallback(AuthController auth) {
    return Obx(() => Center(
      child: Text(
        auth.displayName.value.isNotEmpty
            ? auth.displayName.value[0].toUpperCase()
            : 'M',
        style: const TextStyle(
            color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
      ),
    ));
  }

  Widget _notLoggedInView() {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 600;
      final maxW = isWide ? 480.0 : double.infinity;
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
                    color: _surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: _textLo.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.person_off_outlined,
                      color: _textLo, size: isWide ? 64 : 52),
                ),
                const SizedBox(height: 24),
                const Text('You\'re not signed in',
                    style: TextStyle(
                        color: _textHi, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to access your profile\nand personalized features.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textLo, fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      Get.to(() => const AuthPage());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentSoft,
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