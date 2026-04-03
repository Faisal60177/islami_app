import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

const _bg        = Color(0xFF011A0E);
const _surface   = Color(0xFF0D2E1C);
const _card      = Color(0xFF122E1E);
const _accent    = Color(0xFF4CAF82);
const _accentSoft= Color(0xFF2E7D5A);
const _gold      = Color(0xFFD4AF37);
const _textHi    = Color(0xFFE8F5EC);
const _textLo    = Color(0xFF7BAF92);

class RatePage extends StatefulWidget {
  const RatePage({super.key});

  @override
  State<RatePage> createState() => _RatePageState();
}

class _RatePageState extends State<RatePage>
    with SingleTickerProviderStateMixin {
  int _selectedStars = 0;
  bool _submitted = false;
  final _feedbackCtrl = TextEditingController();
  late AnimationController _bounce;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _bounceAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _bounce, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _bounce.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  void _selectStar(int star) {
    setState(() => _selectedStars = star);
    _bounce.forward(from: 0);
  }

  Future<void> _submit() async {
    if (_selectedStars == 0) {
      Get.snackbar('Oops!', 'Please select a star rating first',
          backgroundColor: Colors.orange[800],
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16));
      return;
    }

    if (_selectedStars >= 4) {
      // Trigger in-app review
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await launchUrl(
          Uri.parse(
              'https://play.google.com/store/apps/details?id=com.islamicapp.dev'),
        );
      }
    }
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _accent),
          onPressed: () => Get.back(),
        ),
        title: const Text('Rate Us',
            style: TextStyle(
                color: _textHi,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        centerTitle: true,
        elevation: 0,
      ),
      body: _submitted ? _thankYouView() : _ratingView(),
    );
  }

  Widget _ratingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _appIcon(),
          const SizedBox(height: 24),
          const Text(
            'Enjoying Islamic App?',
            style: TextStyle(
              color: _textHi,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your review helps us reach more\nMuslims around the world 🌍',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textLo, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 36),
          _starRow(),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selectedStars > 0
                ? Text(
              _ratingLabel(_selectedStars),
              key: ValueKey(_selectedStars),
              style: const TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
            )
                : const Text('Tap a star to rate',
                style: TextStyle(color: _textLo, fontSize: 14)),
          ),
          const SizedBox(height: 32),
          if (_selectedStars > 0 && _selectedStars < 4) ...[
            _feedbackBox(),
            const SizedBox(height: 24),
          ],
          _submitBtn(),
          const SizedBox(height: 24),
          _storeButtons(),
          const SizedBox(height: 32),
          _reviewStats(),
        ],
      ),
    );
  }

  Widget _appIcon() {
    return Container(
      width: 100, height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2E1C), Color(0xFF2E7D5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _gold.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
              color: _accent.withOpacity(0.3),
              blurRadius: 30, spreadRadius: 2)
        ],
      ),
      child: const Center(
        child: Text('🕌', style: TextStyle(fontSize: 48)),
      ),
    );
  }

  Widget _starRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < _selectedStars;
        return GestureDetector(
          onTap: () => _selectStar(i + 1),
          child: AnimatedBuilder(
            animation: _bounceAnim,
            builder: (_, __) {
              final scale =
              (i == _selectedStars - 1) ? _bounceAnim.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? _gold : _textLo,
                    size: 48,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _feedbackBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tell us what we can improve:',
            style: TextStyle(
                color: _textHi,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        const SizedBox(height: 10),
        TextFormField(
          controller: _feedbackCtrl,
          maxLines: 4,
          style: const TextStyle(color: _textHi, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Share your feedback here…',
            hintStyle: const TextStyle(color: _textLo, fontSize: 13),
            filled: true,
            fillColor: _card,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              BorderSide(color: _accentSoft.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _accent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _submitBtn() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedStars > 0 ? _accentSoft : _surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: _selectedStars > 0 ? 4 : 0,
        ),
        icon: const Icon(Icons.star, color: _gold, size: 20),
        label: Text(
          _selectedStars >= 4 ? 'Rate on Play Store' : 'Submit Feedback',
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15),
        ),
      ),
    );
  }

  Widget _storeButtons() {
    return Row(
      children: [
        Expanded(child: _storeBtn('Google Play', '▶', const Color(0xFF01875F))),
        const SizedBox(width: 12),
        Expanded(child: _storeBtn('App Store', '', const Color(0xFF0A84FF))),
      ],
    );
  }

  Widget _storeBtn(String label, String icon, Color color) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(_selectedStars >= 4
          ? 'https://play.google.com/store'
          : 'https://apps.apple.com')),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _reviewStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentSoft.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text('Community Reviews',
              style: TextStyle(
                  color: _textHi,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                children: [
                  const Text('4.8',
                      style: TextStyle(
                          color: _gold,
                          fontSize: 42,
                          fontWeight: FontWeight.w900)),
                  Row(
                    children: List.generate(
                        5,
                            (_) => const Icon(Icons.star_rounded,
                            color: _gold, size: 14)),
                  ),
                  const SizedBox(height: 4),
                  const Text('12,400+ reviews',
                      style: TextStyle(color: _textLo, fontSize: 11)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _ratingBar(5, 0.78),
                    _ratingBar(4, 0.14),
                    _ratingBar(3, 0.05),
                    _ratingBar(2, 0.02),
                    _ratingBar(1, 0.01),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ratingBar(int star, double fraction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$star',
              style: const TextStyle(color: _textLo, fontSize: 11)),
          const SizedBox(width: 6),
          const Icon(Icons.star_rounded, color: _gold, size: 11),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: _surface,
                valueColor:
                const AlwaysStoppedAnimation<Color>(_gold),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('${(fraction * 100).round()}%',
              style: const TextStyle(color: _textLo, fontSize: 10)),
        ],
      ),
    );
  }

  // ── Thank You ────────────────────────────────────────────────────────────
  Widget _thankYouView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⭐', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            const Text('JazakAllahu Khairan!',
                style: TextStyle(
                    color: _gold,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'May Allah reward you for\nsupporting Islamic App.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _textLo, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentSoft,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back to Menu',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int stars) {
    switch (stars) {
    case 1: return '😞 We are sorry to hear that...';
    case 2: return '😐 We will do better, InshaAllah';
    case 3: return '🙂 Thanks! We are improving!';
    case 4: return '😊 Great! You love it!';
    case 5: return '🌟 Alhamdulillah! You love it!';
    default: return '';
    }
  }
}