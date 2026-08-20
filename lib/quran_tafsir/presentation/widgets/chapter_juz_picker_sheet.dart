import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chapter_list_provider.dart';
import '../providers/juz_list_provider.dart';
import '../pages/surah_detail_page.dart';
import '../pages/juz_detail_page.dart';

enum PickerType { surah, juz }

class ChapterJuzPickerSheet extends StatefulWidget {
  final PickerType initialType;
  final int? currentChapterNumber;
  final int? currentJuzNumber;

  const ChapterJuzPickerSheet({
    super.key,
    required this.initialType,
    this.currentChapterNumber,
    this.currentJuzNumber,
  });

  static Future<void> show(
      BuildContext context, {
        required PickerType initialType,
        int? currentChapterNumber,
        int? currentJuzNumber,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChapterJuzPickerSheet(
        initialType: initialType,
        currentChapterNumber: currentChapterNumber,
        currentJuzNumber: currentJuzNumber,
      ),
    );
  }

  @override
  State<ChapterJuzPickerSheet> createState() => _ChapterJuzPickerSheetState();
}

class _ChapterJuzPickerSheetState extends State<ChapterJuzPickerSheet>
    with SingleTickerProviderStateMixin {
  static const double _itemExtent = 72.0;

  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _surahScrollController = ScrollController();
  final ScrollController _juzScrollController = ScrollController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialType == PickerType.surah ? 0 : 1,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) _scrollToCurrent();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _surahScrollController.dispose();
    _juzScrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrent() {
    if (_query.isNotEmpty) return; // filter করা লিস্টে index আর match করবে না
    if (_tabController.index == 0 && widget.currentChapterNumber != null) {
      _jumpTo(_surahScrollController, (widget.currentChapterNumber! - 1) * _itemExtent);
    } else if (_tabController.index == 1 && widget.currentJuzNumber != null) {
      _jumpTo(_juzScrollController, (widget.currentJuzNumber! - 1) * _itemExtent);
    }
  }

  void _jumpTo(ScrollController controller, double target) {
    if (!controller.hasClients) return;
    controller.jumpTo(target.clamp(0, controller.position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, _) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [Tab(text: 'Surah'), Tab(text: 'Juz')],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or number',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SurahTab(
                    query: _query,
                    currentChapterNumber: widget.currentChapterNumber,
                    scrollController: _surahScrollController,
                    itemExtent: _itemExtent,
                  ),
                  _JuzTab(
                    query: _query,
                    currentJuzNumber: widget.currentJuzNumber,
                    scrollController: _juzScrollController,
                    itemExtent: _itemExtent,
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

class _SurahTab extends ConsumerWidget {
  final String query;
  final int? currentChapterNumber;
  final ScrollController scrollController;
  final double itemExtent;

  const _SurahTab({
    required this.query,
    required this.currentChapterNumber,
    required this.scrollController,
    required this.itemExtent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(chapterListNotifierProvider);

    return chaptersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Failed to load surah list')),
      data: (chapters) {
        final filtered = query.isEmpty
            ? chapters
            : chapters.where((c) {
          return c.nameSimple.toLowerCase().contains(query) ||
              c.translatedName.toLowerCase().contains(query) ||
              c.id.toString() == query;
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No Surah found'));
        }

        return ListView.builder(
          controller: scrollController,
          itemExtent: itemExtent,
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final chapter = filtered[index];
            final isSelected = chapter.id == currentChapterNumber;
            return ListTile(
              selected: isSelected,
              leading: CircleAvatar(child: Text('${chapter.id}')),
              title: Text(
                chapter.nameSimple,
                style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
              ),
              subtitle: Text('${chapter.translatedName} · ${chapter.versesCount} Ayahs'),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : Text(chapter.nameArabic, style: const TextStyle(fontSize: 18)),
              onTap: () {
                Navigator.of(context).pop();
                if (!isSelected) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => SurahDetailPage(
                        chapterNumber: chapter.id,
                        chapterName: chapter.nameSimple,
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

class _JuzTab extends ConsumerWidget {
  final String query;
  final int? currentJuzNumber;
  final ScrollController scrollController;
  final double itemExtent;

  const _JuzTab({
    required this.query,
    required this.currentJuzNumber,
    required this.scrollController,
    required this.itemExtent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final juzsAsync = ref.watch(juzListProvider);

    return juzsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Failed to load juz list')),
      data: (juzs) {
        final filtered = query.isEmpty
            ? juzs
            : juzs.where((j) => j.juzNumber.toString() == query).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No Juz found'));
        }

        return ListView.builder(
          controller: scrollController,
          itemExtent: itemExtent,
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final juz = filtered[index];
            final isSelected = juz.juzNumber == currentJuzNumber;
            return ListTile(
              selected: isSelected,
              leading: CircleAvatar(child: Text('${juz.juzNumber}')),
              title: Text(
                'Juz ${juz.juzNumber}',
                style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
              ),
              subtitle: Text('${juz.firstVerseKey} — ${juz.lastVerseKey} · ${juz.versesCount} Ayahs'),
              trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () {
                Navigator.of(context).pop();
                if (!isSelected) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => JuzDetailPage(
                        juzNumber: juz.juzNumber,
                        juzName: 'Juz ${juz.juzNumber}',
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}