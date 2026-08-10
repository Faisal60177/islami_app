import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/translation_resource.dart';
import '../../domain/entities/reciter.dart';
import 'quran_providers.dart';

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