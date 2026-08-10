// surah_list_view.dart
//
// PURPOSE: এটা Surah list দেখানোর "body content" — কোনো Scaffold/AppBar
// নেই এখানে ইচ্ছাকৃতভাবে। এটাকে বের করে আনা হয়েছে যাতে এই একই list
// দুই জায়গায় reuse করা যায়:
//   ১. standalone SurahListPage (নিজের Scaffold সহ) — direct navigation এ
//   ২. QuranTafsirPage এর TabBar এর ভিতরে (Scaffold সেখানে বাইরে থেকে আসে)
//
// এভাবে আলাদা করাটাই Clean Code এর "Don't Repeat Yourself (DRY)" নীতি —
// একই loading/error/data logic দুইবার লিখতে হচ্ছে না।

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chapter_list_provider.dart';
import '../pages/surah_detail_page.dart';

class SurahListView extends ConsumerWidget {
  const SurahListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(chapterListNotifierProvider);

    return chaptersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'কুরআন লোড করা যায়নি।\nইন্টারনেট সংযোগ চেক করুন।',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(chapterListNotifierProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        ),
      ),
      data: (chapters) => RefreshIndicator(
        onRefresh: () =>
            ref.read(chapterListNotifierProvider.notifier).refresh(),
        child: ListView.separated(
          itemCount: chapters.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            return ListTile(
              leading: CircleAvatar(child: Text('${chapter.id}')),
              title: Text(
                chapter.nameSimple,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${chapter.translatedName} · ${chapter.versesCount} Ayahs',
              ),
              trailing: Text(
                chapter.nameArabic,
                style: const TextStyle(fontSize: 18),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SurahDetailPage(
                      chapterNumber: chapter.id,
                      chapterName: chapter.nameSimple,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}