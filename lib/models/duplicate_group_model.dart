import 'package:freezed_annotation/freezed_annotation.dart';

import 'file_meta_model.dart';

part 'duplicate_group_model.freezed.dart';

@freezed
abstract class DuplicateGroup with _$DuplicateGroup {
  const factory DuplicateGroup({
    required List<FileMeta> files,
    required int totalGroupSize,
  }) = _DuplicateGroup;
}