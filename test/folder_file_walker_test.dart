import 'dart:io';

import 'package:filesieve/utils/folder_file_walker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('walker_test');
    File(p.join(root.path, 'a.txt')).createSync();
    File(p.join(root.path, '.hidden.txt')).createSync();
    Directory(p.join(root.path, 'sub')).createSync();
    File(p.join(root.path, 'sub', 'b.txt')).createSync();
    Directory(p.join(root.path, '.git')).createSync();
    File(p.join(root.path, '.git', 'c.txt')).createSync();
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('counts nested files and skips hidden when asked', () async {
    expect(
      await countFiles(root.path, recursive: true, skipHidden: true),
      2,
    );
  });

  test('includes hidden files when not skipping', () async {
    expect(
      await countFiles(root.path, recursive: true, skipHidden: false),
      4,
    );
  });

  test('top level only without subfolders', () async {
    expect(
      await countFiles(root.path, recursive: false, skipHidden: true),
      1,
    );
  });

  test('missing folder yields zero instead of throwing', () async {
    expect(
      await countFiles(p.join(root.path, 'nope'), recursive: true, skipHidden: true),
      0,
    );
  });
}
