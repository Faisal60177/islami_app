import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:muslim_app/features/quran_tafsir/domain/entities/translation_resource.dart';
import 'package:muslim_app/features/quran_tafsir/domain/entities/reciter.dart';
import 'package:muslim_app/features/quran_tafsir/presentation/providers/quran_providers.dart';

part 'resources_provider.g.dart';

@Riverpod(keepAlive: true)
Future<List<TranslationResource>> availableTranslations(
    AvailableTranslationsRef ref,
    ) async {
  final repository = ref.watch(quranRepositoryProvider);
  return repository.getAvailableTranslations();
}

@Riverpod(keepAlive: true)
Future<List<Reciter>> availableReciters(AvailableRecitersRef ref) async {
  final repository = ref.watch(quranRepositoryProvider);
  return repository.getAvailableReciters();
}