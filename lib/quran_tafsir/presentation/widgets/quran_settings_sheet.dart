import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/resources_provider.dart';
import '../providers/user_preference_provider.dart';
import '../../domain/entities/translation_resource.dart';
import '../../domain/entities/reciter.dart';

const int _kTransliterationResourceId = 57;

class QuranSettingsSheet extends StatelessWidget {
  const QuranSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          // ── এখানেই background fix — theme এর surface color ব্যবহার
          // করা হচ্ছে যাতে light/dark mode দুটোতেই সঠিক দেখায় ──
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const TabBar(
                  tabs: [
                    Tab(text: 'Reciter'),
                    Tab(text: 'Translation'),
                    Tab(text: 'Arabic'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ReciterTab(scrollController: scrollController),
                      _TranslationTab(scrollController: scrollController),
                      _ArabicTab(scrollController: scrollController),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Reciter Tab
// ─────────────────────────────────────────────────────────────────
class _ReciterTab extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const _ReciterTab({required this.scrollController});

  @override
  ConsumerState<_ReciterTab> createState() => _ReciterTabState();
}

class _ReciterTabState extends ConsumerState<_ReciterTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final recitersAsync = ref.watch(availableRecitersProvider);
    final preferencesAsync = ref.watch(quranPreferencesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search reciter...',
              prefixIcon: Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: recitersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => const Center(child: Text('Failed to load reciters')),
            data: (reciters) {
              final filtered = reciters
                  .where((r) => r.reciterName.toLowerCase().contains(_query))
                  .toList();

              return preferencesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => const Center(child: Text('—')),
                data: (preferences) {
                  return ListView.builder(
                    controller: widget.scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final Reciter reciter = filtered[index];
                      return RadioListTile<int>(
                        value: reciter.id,
                        groupValue: preferences.reciterId,
                        title: Text(reciter.reciterName),
                        subtitle:
                        reciter.style != null ? Text(reciter.style!) : null,
                        onChanged: (id) {
                          if (id == null) return;
                          ref
                              .read(quranPreferencesProvider.notifier)
                              .updateReciterId(id);
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Translation Tab
// ─────────────────────────────────────────────────────────────────
class _TranslationTab extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const _TranslationTab({required this.scrollController});

  @override
  ConsumerState<_TranslationTab> createState() => _TranslationTabState();
}

class _TranslationTabState extends ConsumerState<_TranslationTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final translationsAsync = ref.watch(availableTranslationsProvider);
    final preferencesAsync = ref.watch(quranPreferencesProvider);

    return preferencesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('—')),
      data: (preferences) {
        final hasTransliteration =
        preferences.translationIds.contains(_kTransliterationResourceId);

        return Column(
          children: [
            SwitchListTile(
              title: const Text('Show Transliteration'),
              subtitle: const Text('Arabic pronunciation (In English)'),
              value: hasTransliteration,
              onChanged: (enabled) {
                final current = List<int>.from(preferences.translationIds);
                if (enabled) {
                  if (!current.contains(_kTransliterationResourceId)) {
                    current.add(_kTransliterationResourceId);
                  }
                } else {
                  current.remove(_kTransliterationResourceId);
                }
                ref
                    .read(quranPreferencesProvider.notifier)
                    .updateTranslationIds(current);
              },
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search language or translator...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ),
            Expanded(
              child: translationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) =>
                const Center(child: Text('Failed to load translations')),
                data: (translations) {
                  final filtered = translations
                      .where((t) => t.id != _kTransliterationResourceId)
                      .where((t) =>
                  t.name.toLowerCase().contains(_query) ||
                      t.languageName.toLowerCase().contains(_query))
                      .toList();

                  return ListView.builder(
                    controller: widget.scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final TranslationResource t = filtered[index];
                      final isSelected =
                      preferences.translationIds.contains(t.id);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(t.name),
                        subtitle: Text(
                          '${t.languageName[0].toUpperCase()}${t.languageName.substring(1)}'
                              '${t.authorName.isNotEmpty ? " · ${t.authorName}" : ""}',
                        ),
                        onChanged: (checked) {
                          final current =
                          List<int>.from(preferences.translationIds);
                          if (checked == true) {
                            if (!current.contains(t.id)) current.add(t.id);
                          } else {
                            current.remove(t.id);
                          }
                          ref
                              .read(quranPreferencesProvider.notifier)
                              .updateTranslationIds(current);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Arabic Tab (নতুন) — শুধু font size, script selection future
// ─────────────────────────────────────────────────────────────────
class _ArabicTab extends ConsumerWidget {
  final ScrollController scrollController;
  const _ArabicTab({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(quranPreferencesProvider);

    return preferencesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('—')),
      data: (preferences) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            // ── Preview ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Uthmanic',
                  fontSize: preferences.arabicFontSize,
                  height: 1.8,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Font size control ──
            const Text(
              'Font size',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: preferences.arabicFontSize <= 18
                      ? null
                      : () => ref
                      .read(quranPreferencesProvider.notifier)
                      .updateArabicFontSize(preferences.arabicFontSize - 2),
                ),
                Text(
                  preferences.arabicFontSize.toInt().toString(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: preferences.arabicFontSize >= 40
                      ? null
                      : () => ref
                      .read(quranPreferencesProvider.notifier)
                      .updateArabicFontSize(preferences.arabicFontSize + 2),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── সততার সাথে জানানো: script selection future ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'IndoPak ও Tajweed script শীঘ্রই আসছে।',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}