import 'dart:io';

import '../../models/duplicate_group_model.dart';
import '../../models/scan_progress_model.dart';
import '../../utils/cancel_token.dart';

abstract class DuplicateFinderRepositoryBase {
  Future<List<DuplicateGroup>> find({
    required List<File> files,
    required void Function(ScanProgress) onProgress,
    required CancelToken cancelToken,
    bool byteByByteCompare = false,
    void Function(DuplicateGroup, List<int> sizes)? onGroupFound,
  });
}
