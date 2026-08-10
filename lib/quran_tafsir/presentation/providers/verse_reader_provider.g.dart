// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verse_reader_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$verseReaderNotifierHash() =>
    r'ee663cc12a6146fb3926383621b96239cff7b76a';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$VerseReaderNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Verse>> {
  late final VerseReaderParams params;

  FutureOr<List<Verse>> build(VerseReaderParams params);
}

/// See also [VerseReaderNotifier].
@ProviderFor(VerseReaderNotifier)
const verseReaderNotifierProvider = VerseReaderNotifierFamily();

/// See also [VerseReaderNotifier].
class VerseReaderNotifierFamily extends Family<AsyncValue<List<Verse>>> {
  /// See also [VerseReaderNotifier].
  const VerseReaderNotifierFamily();

  /// See also [VerseReaderNotifier].
  VerseReaderNotifierProvider call(VerseReaderParams params) {
    return VerseReaderNotifierProvider(params);
  }

  @override
  VerseReaderNotifierProvider getProviderOverride(
    covariant VerseReaderNotifierProvider provider,
  ) {
    return call(provider.params);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'verseReaderNotifierProvider';
}

/// See also [VerseReaderNotifier].
class VerseReaderNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<VerseReaderNotifier, List<Verse>> {
  /// See also [VerseReaderNotifier].
  VerseReaderNotifierProvider(VerseReaderParams params)
    : this._internal(
        () => VerseReaderNotifier()..params = params,
        from: verseReaderNotifierProvider,
        name: r'verseReaderNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$verseReaderNotifierHash,
        dependencies: VerseReaderNotifierFamily._dependencies,
        allTransitiveDependencies:
            VerseReaderNotifierFamily._allTransitiveDependencies,
        params: params,
      );

  VerseReaderNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final VerseReaderParams params;

  @override
  FutureOr<List<Verse>> runNotifierBuild(
    covariant VerseReaderNotifier notifier,
  ) {
    return notifier.build(params);
  }

  @override
  Override overrideWith(VerseReaderNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: VerseReaderNotifierProvider._internal(
        () => create()..params = params,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<VerseReaderNotifier, List<Verse>>
  createElement() {
    return _VerseReaderNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VerseReaderNotifierProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VerseReaderNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<Verse>> {
  /// The parameter `params` of this provider.
  VerseReaderParams get params;
}

class _VerseReaderNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          VerseReaderNotifier,
          List<Verse>
        >
    with VerseReaderNotifierRef {
  _VerseReaderNotifierProviderElement(super.provider);

  @override
  VerseReaderParams get params =>
      (origin as VerseReaderNotifierProvider).params;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
