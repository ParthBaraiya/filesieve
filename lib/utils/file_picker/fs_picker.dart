import 'package:file_selector/file_selector.dart' as fs;

import 'fs_picker_base.dart';

class FsPicker extends FsPickerBase {
  @override
  Future<List<String>> getDirectoryPaths() {
    return fs.getDirectoryPaths().then((e) => e.nonNulls.toList());
  }

  @override
  Future<String?> getDirectoryPath() {
    return fs.getDirectoryPath();
  }
}
