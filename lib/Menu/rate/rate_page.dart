import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';

class RatePage extends StatefulWidget {
  const RatePage({super.key});

  @override
  State<RatePage> createState() => _RatePageState();
}

class _RatePageState extends State<RatePage> with SingleTickerProviderStateMixin {
  int _selectedStars = 0;
  bool _submitted = false;
  final _feedbackCtrl = TextEditingController();
  late AnimationController _bounce;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Oops!', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Please select a star rating first'),
            ],
          ),
          backgroundColor: Colors.orange[800],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    if (_selectedStars >= 4) {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await launchUrl(Uri.parse(
            'https://play.google.com/store/apps/details?id=com.siratalmustaqeem.muslimlife'));
      }
    }
    setState(() => _submitted = true);
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
            title: Text('Rate Us',
                style: TextStyle(color: thm.textHigh, fontWeight: FontWeight.w600, fontSize: 18)),
            centerTitle: true,
            elevation: 0,
          ),
          body: _submitted ? _thankYouView(thm) : _ratingView(thm),
        );
      },
    );
  }

  Widget _ratingView(AppThemeOption thm) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide   = constraints.maxWidth > 600;
        final isTablet = constraints.maxWidth > 800;
        final hPad = isTablet ? 80.0 : isWide ? 48.0 : 24.0;
        final maxW = isTablet ? 640.0 : double.infinity;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _appIcon(thm, isWide),
                  const SizedBox(height: 24),
                  Text(
                    'Enjoying Muslim Life App?',
                    style: TextStyle(
                        color: thm.textHigh,
                        fontSize: isWide ? 28 : 24,
                        fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your review helps us reach more\nMuslims around the world 🌍',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: thm.textLow, fontSize: 14, height: 1.6),
                  ),
                  const SizedBox(height: 36),
                  _starRow(thm, isWide),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedStars > 0
                        ? Text(
                      _ratingLabel(_selectedStars),
                      key: ValueKey(_selectedStars),
                      style: TextStyle(
                          color: thm.accent, fontWeight: FontWeight.w700, fontSize: 16),
                    )
                        : Text('Tap a star to rate',
                        style: TextStyle(color: thm.textLow, fontSize: 14)),
                  ),
                  const SizedBox(height: 32),
                  if (_selectedStars > 0 && _selectedStars < 4) ...[
                    _feedbackBox(thm),
                    const SizedBox(height: 24),
                  ],
                  _submitBtn(thm),
                  const SizedBox(height: 24),
                  _storeButtons(thm),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _appIcon(AppThemeOption thm, bool isWide) {
    final size = isWide ? 120.0 : 100.0;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [thm.surface, thm.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isWide ? 30 : 24),
        border: Border.all(color: thm.accent.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(color: thm.accent.withOpacity(0.3), blurRadius: 30, spreadRadius: 2)
        ],
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isWide ? 22 : 18),
          child: Image.asset(
            'assets/icons/AppIcon.png',
            width: isWide ? 78 : 66,
            height: isWide ? 78 : 66,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _starRow(AppThemeOption thm, bool isWide) {
    final starSize = isWide ? 56.0 : 48.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < _selectedStars;
        return GestureDetector(
          onTap: () => _selectStar(i + 1),
          child: AnimatedBuilder(
            animation: _bounceAnim,
            builder: (_, __) {
              final scale = (i == _selectedStars - 1) ? _bounceAnim.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? thm.accent : thm.textLow,
                    size: starSize,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _feedbackBox(AppThemeOption thm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tell us what we can improve:',
            style: TextStyle(color: thm.textHigh, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 10),
        TextFormField(
          controller: _feedbackCtrl,
          maxLines: 4,
          style: TextStyle(color: thm.textHigh, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Share your feedback here…',
            hintStyle: TextStyle(color: thm.textLow, fontSize: 13),
            filled: true,
            fillColor: thm.cardColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: thm.accent.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: thm.accent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _submitBtn(AppThemeOption thm) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedStars > 0 ? thm.accent : thm.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: _selectedStars > 0 ? 4 : 0,
        ),
        icon: Icon(Icons.star, color: thm.accent, size: 20),
        label: Text(
          _selectedStars >= 4 ? 'Rate on Play Store' : 'Submit Feedback',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  Widget _storeButtons(AppThemeOption thm) {
    // Cleaner, layout-safe implementation for a single button
    return SizedBox(
      width: double.infinity,
      child: _storeBtn('Google Play', '▶', const Color(0xFF01875F)),
    );
  }

  Widget _storeBtn(String label, String icon, Color color) {
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.parse('https://play.google.com/store/apps/details?id=com.siratalmustaqeem.muslimlife'),
        mode: LaunchMode.externalApplication,
      ),
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
            Flexible(
              child: Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }


  Widget _ratingBar(AppThemeOption thm, int star, double fraction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$star', style: TextStyle(color: thm.textLow, fontSize: 11)),
          const SizedBox(width: 6),
          Icon(Icons.star_rounded, color: thm.accent, size: 11),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: thm.surface,
                valueColor: AlwaysStoppedAnimation<Color>(thm.accent),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('${(fraction * 100).round()}%',
              style: TextStyle(color: thm.textLow, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _thankYouView(AppThemeOption thm) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final maxW = isWide ? 480.0 : double.infinity;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Padding(
              padding: EdgeInsets.all(isWide ? 48 : 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('⭐', style: TextStyle(fontSize: isWide ? 100 : 80)),
                  const SizedBox(height: 24),
                  Text('JazakAllahu Khairan!',
                      style: TextStyle(color: thm.accent, fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    'May Allah reward you for\nsupporting Islamic App.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: thm.textLow, fontSize: 15, height: 1.6),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: thm.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Back to Menu',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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