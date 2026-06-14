import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranDownloadService {
  static const int totalPages = 619;
  static const String _downloadCompleteKey = 'quran_pages_downloaded';

  // ── Replace with your actual GitHub URL ──────────────────────────
  static const String _zipUrl =
      'https://github.com/Faisal60177/quran-pages/releases/download/v2.0/quran_pages_webp.zip';

  final Dio _dio = Dio();

  // ── Check if already downloaded ──────────────────────────────────
  static Future<bool> isDownloadComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_downloadCompleteKey) ?? false;
  }

  // ── Get local quran pages directory ──────────────────────────────
  static Future<Directory> getQuranDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final quranDir = Directory('${appDir.path}/quran_pages');
    if (!await quranDir.exists()) {
      await quranDir.create(recursive: true);
    }
    return quranDir;
  }

  // ── Get path for a single page ────────────────────────────────────
  static Future<String> getPagePath(int page) async {
    final dir = await getQuranDir();
    final fileName = '${page.toString().padLeft(3, '0')}.webp';
    return '${dir.path}/$fileName';
  }

  // ── Main download function ────────────────────────────────────────
  Future<void> downloadAllPages({
    required void Function(int downloaded, int total, String status) onProgress,
    required void Function(String error) onError,
    required void Function() onComplete,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final zipPath = '${appDir.path}/quran_pages_webp.zip';
      final zipFile = File(zipPath);

      // ── Phase 1: Download zip ─────────────────────────────────────
      onProgress(0, 100, 'Downloading Quran pages...');

      await _dio.download(
        _zipUrl,
        zipPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final percent = ((received / total) * 70).toInt(); // 0-70%
            final mb = (received / 1024 / 1024).toStringAsFixed(1);
            final totalMb = (total / 1024 / 1024).toStringAsFixed(1);
            onProgress(percent, 100, 'Downloading... $mb MB / $totalMb MB');
          }
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 2),
        ),
      );

      // ── Phase 2: Extract zip ──────────────────────────────────────
      onProgress(70, 100, 'Extracting pages...');

      final quranDir = await getQuranDir();

      // Extract using archive package
      await _extractZip(zipFile, quranDir, onProgress);

      // ── Phase 3: Verify ───────────────────────────────────────────
      onProgress(95, 100, 'Verifying pages...');

      final count = await _countExtractedPages(quranDir);

      if (count >= totalPages) {
        // Delete zip to save space
        if (await zipFile.exists()) await zipFile.delete();

        // Mark complete
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_downloadCompleteKey, true);

        onProgress(100, 100, 'Complete!');
        onComplete();
      } else {
        // Delete incomplete zip
        if (await zipFile.exists()) await zipFile.delete();
        onError(
            'Only $count of $totalPages pages extracted. Please retry.');
      }
    } catch (e) {
      onError('Download failed: ${e.toString()}');
    }
  }

  // ── Extract zip file ──────────────────────────────────────────────
  Future<void> _extractZip(
      File zipFile,
      Directory targetDir,
      void Function(int, int, String) onProgress,
      ) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    int extracted = 0;
    final imageFiles =
    archive.files.where((f) => f.name.endsWith('.webp')).toList();
    final total = imageFiles.length;

    for (final file in imageFiles) {
      if (file.isFile) {
        // Get just the filename (strip any folder prefix in zip)
        final fileName = file.name.split('/').last;
        final outFile = File('${targetDir.path}/$fileName');

        if (!await outFile.exists()) {
          await outFile.writeAsBytes(file.content as List<int>);
        }

        extracted++;
        final percent = 70 + ((extracted / total) * 25).toInt(); // 70-95%
        onProgress(percent, 100, 'Extracting page $extracted of $total...');
      }
    }
  }

  // ── Count extracted pages ─────────────────────────────────────────
  Future<int> _countExtractedPages(Directory dir) async {
    int count = 0;
    for (int i = 1; i <= totalPages; i++) {
      final fileName = '${i.toString().padLeft(3, '0')}.webp';
      final file = File('${dir.path}/$fileName');
      if (await file.exists()) count++;
    }
    return count;
  }

  // ── Clear download (reset) ────────────────────────────────────────
  static Future<void> clearDownload() async {
    final dir = await getQuranDir();
    if (await dir.exists()) await dir.delete(recursive: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_downloadCompleteKey, false);
  }
}