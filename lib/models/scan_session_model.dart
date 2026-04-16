import 'package:freezed_annotation/freezed_annotation.dart';
import '../values/enums.dart';
import 'scan_folder_model.dart';

part 'scan_session_model.freezed.dart';
part 'scan_session_model.g.dart';

@freezed
abstract class ScanSessionModel with _$ScanSessionModel {
  const factory ScanSessionModel({
    required String id,
    required DateTime createdAt,
    required List<ScanFolderModel> folders,
    @Default(ScanSessionStatus.pending) ScanSessionStatus status,
  }) = _ScanSessionModel;

  factory ScanSessionModel.fromJson(Map<String, dynamic> json) =>
      _$ScanSessionModelFromJson(json);
}
