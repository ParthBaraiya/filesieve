import 'package:freezed_annotation/freezed_annotation.dart';

part 'scan_duplicate_entry_model.freezed.dart';

@freezed
abstract class ScanDuplicateEntryModel with _$ScanDuplicateEntryModel {
  const factory ScanDuplicateEntryModel({
    required String path,
    required String fileName,
    required String parentPath,
    required int sizeBytes,
    required int matchPercent,
  }) = _ScanDuplicateEntryModel;
}
