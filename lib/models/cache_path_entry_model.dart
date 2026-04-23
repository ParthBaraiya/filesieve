import 'package:freezed_annotation/freezed_annotation.dart';

part 'cache_path_entry_model.freezed.dart';

@freezed
abstract class CachePathEntry with _$CachePathEntry {
  const factory CachePathEntry({
    required String id,
    required String label,
    required String path,
    required String category,
    required bool exists,
  }) = _CachePathEntry;
}
