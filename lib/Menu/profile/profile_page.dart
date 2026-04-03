import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthController _auth = Get.find<AuthController>();
  final _nameCtrl = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = _auth.displayName.value;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final ok = await _auth.updateProfile(name: _nameCtrl.text);
    if (ok) {
      setState(() => _editing = false);
      Get.snackbar('Saved', 'Profile updated successfully',
          backgroundColor: _accentSoft,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoggedIn = _auth.isLoggedIn;

      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: _accent),
            onPressed: () => Get.back(),
          ),
          title: const Text('Profile',
              style: TextStyle(
                  color: _textHi,
                  fontWeight: FontWeight.w600,
                  fontSize: 18)),
          centerTitle: true,
          elevation: 0,
          actions: isLoggedIn && !_editing
              ? [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: _accent),
              onPressed: () => setState(() {
                _editing = true;
                _nameCtrl.text = _auth.displayName.value;
              }),
            ),
          ]
              : null,
        ),
        body: isLoggedIn ? _loggedInView() : _loggedOutView(),
      );
    });
  }

  // ── Logged In ────────────────────────────────────────────────────────────
  Widget _loggedInView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _profileHeader(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                if (_editing) _editForm() else _statsRow(),
                const SizedBox(height: 24),
                _infoSection(),
                const SizedBox(height: 32),
                _signOutBtn(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_surface, _bg],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Obx(() => Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _gold, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                        color: _accent.withOpacity(0.3),
                        blurRadius: 20, spreadRadius: 2)
                  ],
                ),
                child: _auth.photoUrl.value.isNotEmpty
                    ? ClipOval(
                  child: Image.network(
                    _auth.photoUrl.value,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(),
                  ),
                )
                    : _avatarFallback(),
              )),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentSoft,
                ),
                child: const Icon(Icons.camera_alt,
                    color: Colors.white, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() => Text(
            _auth.displayName.value.isNotEmpty
                ? _auth.displayName.value
                : 'Muslim User',
            style: const TextStyle(
              color: _textHi,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          )),
          const SizedBox(height: 4),
          Obx(() => Text(
            _auth.email.value,
            style: const TextStyle(color: _textLo, fontSize: 14),
          )),
          const SizedBox(height: 8),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gold.withOpacity(0.3)),
            ),
            child: const Text(
              '🕌  Verified Muslim',
              style: TextStyle(
                  color: _gold, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return CircleAvatar(
      backgroundColor: _accentSoft,
      child: Obx(() => Text(
        _auth.displayName.value.isNotEmpty
            ? _auth.displayName.value[0].toUpperCase()
            : 'M',
        style: const TextStyle(
            color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
      )),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        _statCard('0', 'Days\nStreak', Icons.local_fire_department_outlined),
        const SizedBox(width: 12),
        _statCard('0', 'Duas\nRead', Icons.book_outlined),
        const SizedBox(width: 12),
        _statCard('0', 'Quran\nPages', Icons.auto_stories_outlined),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accentSoft.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _accent, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: _textHi,
                    fontWeight: FontWeight.w800,
                    fontSize: 20)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textLo, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _editForm() {
    return Column(
      children: [
        TextFormField(
          controller: _nameCtrl,
          style: const TextStyle(color: _textHi),
          decoration: InputDecoration(
            labelText: 'Full Name',
            labelStyle: const TextStyle(color: _textLo),
            prefixIcon:
            const Icon(Icons.person_outline, color: _accentSoft, size: 20),
            filled: true,
            fillColor: _surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              BorderSide(color: _accentSoft.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: _accent, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _editing = false),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _textLo.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cancel',
                    style: TextStyle(color: _textLo)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() => ElevatedButton(
                onPressed: _auth.isLoading.value ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentSoft,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _auth.isLoading.value
                    ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Text('Save',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              )),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoSection() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentSoft.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _infoTile(Icons.email_outlined, 'Email', _auth.email.value),
          Divider(height: 1, color: _accentSoft.withOpacity(0.15)),
          _infoTile(Icons.shield_outlined, 'Account Type', 'Standard'),
          Divider(height: 1, color: _accentSoft.withOpacity(0.15)),
          _infoTile(Icons.language, 'Language', 'English'),
        ],
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
                Text(label,
                    style: const TextStyle(
                        color: _textLo, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: _textHi, fontSize: 14)),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
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

  void _confirmSignOut() {
    Get.dialog(
      AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(color: _textHi, fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: _textLo),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: _textLo)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
            onPressed: () async {
              Get.back();
              await _auth.signOut();
            },
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Logged Out ───────────────────────────────────────────────────────────
  Widget _loggedOutView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _gold.withOpacity(0.3)),
              ),
              child: const Icon(Icons.person_outline,
                  color: _gold, size: 60),
            ),
            const SizedBox(height: 24),
            const Text(
              'بِسْمِ اللَّهِ',
              style: TextStyle(
                  color: _gold, fontSize: 24, fontFamily: 'Amiri'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to sync your progress,\nduas, and Quran bookmarks.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textLo, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Get.to(() => const AuthPage()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentSoft,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Sign In / Create Account',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}