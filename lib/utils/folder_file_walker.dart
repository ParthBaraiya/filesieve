import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

/// True for dot-prefixed names and well-known Windows system folders.
/// (Windows "hidden" file attributes are not readable from Dart without
/// native code, so they are not checked.)
bool isHiddenOrSystemName(String name) {
  if (name.startsWith('.')) return true;
  final lower = name.toLowerCase();
  return lower == r'$recycle.bin' || lower == 'system volume information';
}

/// Calls [onFile] for every file under [root].
///
/// Walks one directory at a time, so an unreadable folder is skipped on its own
/// instead of aborting the whole listing (which `listSync(recursive: true)`
/// does). Hidden folders are pruned without being entered. Blocking: run it in
/// a worker isolate for large trees.
void walkFiles(
  String root, {
  required bool recursive,
  required bool skipHidden,
  required void Function(File file) onFile,
}) {
  final pending = <String>[root];
  while (pending.isNotEmpty) {
    final dir = pending.removeLast();
    final List<FileSystemEntity> entries;
    try {
      entries = Directory(dir).listSync(followLinks: false);
    } on FileSystemException {
      continue; // unreadable folder: skip it, keep going
    }
    for (final entry in entries) {
      if (skipHidden && isHiddenOrSystemName(p.basename(entry.path))) continue;
      if (entry is File) {
        onFile(entry);
      } else if (entry is Directory && recursive) {
        pending.add(entry.path);
      }
    }
  }
}

/// Number of files under [root], counted off the main isolate.
Future<int> countFiles(
  String root, {
  required bool recursive,
  required bool skipHidden,
}) {
  return Isolate.run(() {
    var count = 0;
    walkFiles(
      root,
      recursive: recursive,
      skipHidden: skipHidden,
      onFile: (_) => count++,
    );
    return count;
  });
}
