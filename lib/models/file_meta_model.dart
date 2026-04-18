import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_meta_model.freezed.dart';

@freezed
abstract class FileMeta with _$FileMeta {
  const factory FileMeta({
    required String path,
    required int size,
    required int lastModified,
  }) = _FileMeta;
}
