import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_app/settings/cubit/settings_cubit.dart';
import 'package:muslim_app/settings/cubit/settings_state.dart';
import 'package:muslim_app/settings/theme/app_themes.dart';
import 'package:muslim_app/quran/cubit/quran_cubit.dart';
import 'package:muslim_app/quran/repository/quran_repository.dart';
import '../services/quran_download_service.dart';

class QuranDownloadScreen extends StatefulWidget {
  const QuranDownloadScreen({super.key});

  @override
  State<QuranDownloadScreen> createState() =>
      _QuranDownloadScreenState();
}

class _QuranDownloadScreenState extends State<QuranDownloadScreen>
    with SingleTickerProviderStateMixin {
  final _service = QuranDownloadService();

  int _progress = 0;
  String _statusText = 'Preparing...';
  bool _isDownloading = false;
  bool _hasError = false;
  String _errorMsg = '';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _startDownload();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startDownload() {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
      _hasError = false;
      _errorMsg = '';
    });

    _service.downloadAllPages(
      onProgress: (downloaded, total, status) {
        if (mounted) {
          setState(() {
            _progress = downloaded;
            _statusText = status;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _hasError = true;
            _errorMsg = error;
          });
        }
      },
      onComplete: () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => QuranCubit(QuranRepository())..init(),
                child: const _QuranReadyPage(),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final rsw = sw.clamp(320.0, 420.0);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (_, settings) {
        final theme = getThemeById(settings.themeMode);

        return Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: Padding(
              padding:
              EdgeInsets.symmetric(horizontal: rsw * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // ── Icon ─────────────────────────────────────────
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      width: rsw * 0.32,
                      height: rsw * 0.32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.accent.withOpacity(0.10),
                        border: Border.all(
                            color: theme.accent.withOpacity(0.30),
                            width: 1.5),
                      ),
                      child: Center(
                        child: Text('📖',
                            style:
                            TextStyle(fontSize: rsw * 0.13)),
                      ),
                    ),
                  ),

                  SizedBox(height: rsw * 0.05),

                  // ── Title ────────────────────────────────────────
                  Text(
                    'القرآن الكريم',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      color: theme.accent,
                      fontSize: rsw * 0.065,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: rsw * 0.010),
                  Text(
                    'The Holy Quran · 15-line Mushaf',
                    style: TextStyle(
                        color: theme.textLow,
                        fontSize: rsw * 0.028),
                  ),

                  SizedBox(height: rsw * 0.05),

                  // ── One-time notice box ──────────────────────────
                  Container(
                    padding: EdgeInsets.all(rsw * 0.04),
                    decoration: BoxDecoration(
                      color: theme.accent.withOpacity(0.06),
                      borderRadius:
                      BorderRadius.circular(rsw * 0.04),
                      border: Border.all(
                          color: theme.accent.withOpacity(0.20),
                          width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.download_rounded,
                            color: theme.accent,
                            size: rsw * 0.055),
                        SizedBox(width: rsw * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'One-Time Setup',
                                style: TextStyle(
                                  color: theme.accent,
                                  fontSize: rsw * 0.030,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: rsw * 0.008),
                              Text(
                                'Downloading 619 pages once.\nWorks fully offline forever after.',
                                style: TextStyle(
                                  color: theme.textLow,
                                  fontSize: rsw * 0.024,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: rsw * 0.05),

                  // ── Progress / Error ──────────────────────────────
                  if (!_hasError) ...[
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _statusText,
                            style: TextStyle(
                                color: theme.textLow,
                                fontSize: rsw * 0.024),
                          ),
                        ),
                        Text(
                          '$_progress%',
                          style: TextStyle(
                            color: theme.accent,
                            fontSize: rsw * 0.030,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: rsw * 0.018),
                    ClipRRect(
                      borderRadius:
                      BorderRadius.circular(rsw * 0.012),
                      child: LinearProgressIndicator(
                        value: _progress / 100,
                        minHeight: rsw * 0.024,
                        backgroundColor:
                        theme.accent.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            theme.accent),
                      ),
                    ),
                    SizedBox(height: rsw * 0.018),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: theme.textLow,
                            size: rsw * 0.030),
                        SizedBox(width: rsw * 0.012),
                        Text(
                          'Please keep the app open',
                          style: TextStyle(
                              color: theme.textLow,
                              fontSize: rsw * 0.024),
                        ),
                      ],
                    ),
                  ],

                  if (_hasError) ...[
                    Container(
                      padding: EdgeInsets.all(rsw * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius:
                        BorderRadius.circular(rsw * 0.03),
                        border: Border.all(
                            color: Colors.red.withOpacity(0.30),
                            width: 0.8),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              color: Colors.red[300],
                              size: rsw * 0.06),
                          SizedBox(height: rsw * 0.02),
                          Text(
                            'Connection Error',
                            style: TextStyle(
                              color: Colors.red[300],
                              fontSize: rsw * 0.032,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: rsw * 0.01),
                          Text(
                            _errorMsg,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: theme.textLow,
                                fontSize: rsw * 0.022),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: rsw * 0.04),
                    GestureDetector(
                      onTap: _startDownload,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            vertical: rsw * 0.035),
                        decoration: BoxDecoration(
                          color: theme.accent,
                          borderRadius:
                          BorderRadius.circular(rsw * 0.035),
                        ),
                        child: Center(
                          child: Text(
                            'Retry Download',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: rsw * 0.032,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Simple ready page that rebuilds QuranPage ─────────────────────────────────
class _QuranReadyPage extends StatelessWidget {
  const _QuranReadyPage();

  @override
  Widget build(BuildContext context) {
    // Import and return QuranPage body directly
    return const Center(child: CircularProgressIndicator());
  }
}