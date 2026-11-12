import 'dart:io';

import 'package:filesieve/repository/file_removal/file_removal_repository.dart';
import 'package:filesieve/repository/file_removal/file_removal_repository_base.dart';
import 'package:filesieve/values/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  const repo = FileRemovalRepository();
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('fs_removal_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('permanent removal deletes the file', () async {
    final file = File(p.join(dir.path, 'perm.txt'))..writeAsStringSync('x');
    await repo.remove(file.path, RemovalMode.permanent);
    expect(file.existsSync(), isFalse);
  });

  test('removing a missing file throws', () async {
    expect(
      repo.remove(p.join(dir.path, 'nope.txt'), RemovalMode.permanent),
      throwsA(isA<FileRemovalException>()),
    );
  });

  test(
    'trash removal can be restored (Windows Recycle Bin)',
    () async {
      final file = File(p.join(dir.path, 'sample file.txt'))
        ..writeAsStringSync('hello');
      await repo.remove(file.path, RemovalMode.trash);
      expect(file.existsSync(), isFalse);

      expect(await repo.restore(file.path), isTrue);
      expect(file.readAsStringSync(), 'hello');
    },
    skip: Platform.isWindows ? false : 'Restore is only supported on Windows',
  );
}
