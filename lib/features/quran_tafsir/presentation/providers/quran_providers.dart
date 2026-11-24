import 'package:muslim_app/features/quran_tafsir/data/network/quran_api_client.dart';
import 'package:muslim_app/features/quran_tafsir/data/network/quran_auth_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:muslim_app/features/quran_tafsir/data/datasources/quran_remote_datasource.dart';
import 'package:muslim_app/features/quran_tafsir/data/repositories/quran_repository_impl.dart';
import 'package:muslim_app/features/quran_tafsir/domain/repositories/quran_repository.dart';

part 'quran_providers.g.dart';

@Riverpod(keepAlive: true)
QuranAuthService quranAuthService(QuranAuthServiceRef ref) {
  return QuranAuthService();
}

@Riverpod(keepAlive: true)
QuranApiClient quranApiClient(QuranApiClientRef ref) {
  final authService = ref.watch(quranAuthServiceProvider);
  return QuranApiClient(authService: authService);
}

@Riverpod(keepAlive: true)
QuranRemoteDataSource quranRemoteDataSource(QuranRemoteDataSourceRef ref) {
  final apiClient = ref.watch(quranApiClientProvider);
  return QuranRemoteDataSource(apiClient: apiClient);
}

@Riverpod(keepAlive: true)
QuranRepository quranRepository(QuranRepositoryRef ref) {
  final remoteDataSource = ref.watch(quranRemoteDataSourceProvider);
  return QuranRepositoryImpl(remoteDataSource: remoteDataSource);
}
