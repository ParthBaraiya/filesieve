import 'package:freezed_annotation/freezed_annotation.dart';

part 'fs_exception.freezed.dart';

@freezed
abstract class FsException with _$FsException {
  const factory FsException({
    required String title,
    required String description,
    required String code,
    StackTrace? stackTrace,
    dynamic metadata,
  }) = FsExceptionImpl;

  static FsException unknown({
    required String title,
    required String description,
    StackTrace? stackTrace,
    dynamic metadata,
  }) => FsException(
    title: title,
    description: description,
    stackTrace: stackTrace,
    metadata: metadata,
    code: FsExceptionCodes.unknown,
  );

  static const scanningCancelled = FsException(
    title: 'Scanning Cancelled',
    description: 'Scanning has been cancelled.',
    code: FsExceptionCodes.scanCancelled,
  );
}

abstract class FsExceptionCodes {
  static const scanCancelled = 'SCAN_CANCELLED';
  static const unknown = 'UNKNOWN';
}
