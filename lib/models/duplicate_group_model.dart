import 'package:freezed_annotation/freezed_annotation.dart';

part 'duplicate_group_model.freezed.dart';

@freezed
abstract class DuplicateGroup with _$DuplicateGroup {
  const factory DuplicateGroup({
    required List<String> paths,
  }) = _DuplicateGroup;
}
