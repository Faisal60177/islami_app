
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:muslim_app/features/quran_tafsir/domain/entities/juz.dart';
import 'package:muslim_app/features/quran_tafsir/presentation/providers/quran_providers.dart';

part 'juz_list_provider.g.dart';

@Riverpod(keepAlive: true)
Future<List<Juz>> juzList(JuzListRef ref) async {
  final repository = ref.watch(quranRepositoryProvider);
  return repository.getJuzs();
}