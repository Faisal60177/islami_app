// juz_list_view.dart
//
// PURPOSE: Juz tab এর content। এখন শুধু ৩০টা Juz এর তালিকা দেখাচ্ছে
// (verse count, range সহ)। এখনই "tap করলে ওই Juz এর আয়াত দেখাও" পুরোপুরি
// implement করিনি — কারণ সেটার জন্য /verses/by_juz endpoint টা
// datasource/repository তে আলাদা করে যোগ করা লাগবে, যেটা এই ধাপে
// অন্তর্ভুক্ত করলে অসম্পূর্ণ/অপরীক্ষিত কোড দেওয়া হতো।
//
// TODO (পরের ধাপ): getVersesByJuz() যোগ করে tap করলে SurahDetailPage
// এর মতো একটা VerseListPage(byJuz: juzNumber) এ navigate করানো।

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/juz_list_provider.dart';

class JuzListView extends ConsumerWidget {
  const JuzListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final juzsAsync = ref.watch(juzListProvider);

    return juzsAsync.when(
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
                'Juz লোড করা যায়নি।\nইন্টারনেট সংযোগ চেক করুন।',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(juzListProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        ),
      ),
      data: (juzs) => ListView.separated(
        itemCount: juzs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final juz = juzs[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${juz.juzNumber}')),
            title: Text('Juz ${juz.juzNumber}'),
            subtitle: Text(
              '${juz.firstVerseKey} — ${juz.lastVerseKey} · ${juz.versesCount} Ayahs',
            ),
            onTap: () {
              // TODO: getVersesByJuz() যোগ হলে এখানে navigate করানো হবে
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Juz অনুযায়ী verse reading শীঘ্রই আসছে।'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}