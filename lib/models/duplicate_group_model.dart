import 'package:omnifile/omnifile.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'duplicate_group_model.freezed.dart';

@freezed
abstract class DuplicateGroup with _$DuplicateGroup {
  const factory DuplicateGroup({
    required List<OmniFile> files,
    required int totalGroupSize,
  }) = _DuplicateGroup;
}

extension DuplicateGroupModelExtension on DuplicateGroup {
  bool get hasFiles => files.isNotEmpty;

  Future<OmniFile?> get largestFile async {
    if (files.isEmpty) return null;

    OmniFile file = files.first;
    int lastSize = (await file.size) ?? 0;

    for (final item in files) {
      final newSize = (await file.size) ?? 0;

      if (newSize > lastSize) {
        file = item;
        lastSize = newSize;
      }
    }

    return file;
  }
}
