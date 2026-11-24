import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:muslim_app/features/quran_tafsir/domain/entities/chapter.dart';
import 'package:muslim_app/features/quran_tafsir/presentation/providers/quran_providers.dart';

part 'chapter_list_provider.g.dart';

@Riverpod(keepAlive: true)
class ChapterListNotifier extends _$ChapterListNotifier {
  @override
  Future<List<Chapter>> build() async {
    final repository = ref.watch(quranRepositoryProvider);
    return repository.getChapters();
  }


  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
