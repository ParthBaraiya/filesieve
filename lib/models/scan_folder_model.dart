import 'package:freezed_annotation/freezed_annotation.dart';

part 'scan_folder_model.freezed.dart';
part 'scan_folder_model.g.dart';

@freezed
abstract class ScanFolderModel with _$ScanFolderModel {
  const factory ScanFolderModel({
    required String path,
    required String displayName,
    required bool hasReadAccess,
  }) = _ScanFolderModel;

  factory ScanFolderModel.fromJson(Map<String, dynamic> json) =>
      _$ScanFolderModelFromJson(json);
}
