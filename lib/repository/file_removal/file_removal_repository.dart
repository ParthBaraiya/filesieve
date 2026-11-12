import 'dart:io';

import '../../values/enums.dart';
import 'file_removal_repository_base.dart';

/// Removes files using the platform's own tools, so no extra package is
/// needed. Paths are passed through environment variables or arguments, never
/// interpolated into scripts.
class FileRemovalRepository implements FileRemovalRepositoryBase {
  const FileRemovalRepository();

  static const _pathVar = 'FILESIEVE_PATH';

  @override
  bool get canRestore => Platform.isWindows;

  @override
  Future<void> remove(String path, RemovalMode mode) async {
    if (!await File(path).exists()) {
      throw FileRemovalException(path, 'File no longer exists.');
    }
    try {
      switch (mode) {
        case RemovalMode.permanent:
          await File(path).delete();
        case RemovalMode.trash:
          await _moveToTrash(path);
      }
    } on FileSystemException catch (e) {
      throw FileRemovalException(path, e.message);
    }
  }

  Future<void> _moveToTrash(String path) async {
    final ProcessResult result;
    if (Platform.isWindows) {
      result = await _powershell(
        r'''
Add-Type -AssemblyName Microsoft.VisualBasic
[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($env:FILESIEVE_PATH, 'OnlyErrorDialogs', 'SendToRecycleBin')
''',
        path,
      );
    } else if (Platform.isMacOS) {
      result = await Process.run('osascript', [
        '-e', 'on run argv',
        '-e', 'tell application "Finder" to delete (POSIX file (item 1 of argv))',
        '-e', 'end run',
        path,
      ]);
    } else {
      result = await Process.run('gio', ['trash', path]);
    }
    if (result.exitCode != 0 || await File(path).exists()) {
      throw FileRemovalException(path, '${result.stderr}'.trim());
    }
  }

  @override
  Future<bool> restore(String path) async {
    if (!Platform.isWindows) return false;
    final result = await _powershell(
      r'''
$p = $env:FILESIEVE_PATH
$dir = Split-Path $p
$leaf = Split-Path $p -Leaf
$bare = [IO.Path]::GetFileNameWithoutExtension($p)
$bin = (New-Object -ComObject Shell.Application).NameSpace(10)
foreach ($i in $bin.Items()) {
  if ($bin.GetDetailsOf($i, 1) -eq $dir -and ($i.Name -eq $leaf -or $i.Name -eq $bare)) {
    $i.InvokeVerb('undelete')
    exit 0
  }
}
exit 3
''',
      path,
    );
    return result.exitCode == 0 && await File(path).exists();
  }

  @override
  Future<void> revealInFolder(String path) async {
    if (Platform.isWindows) {
      await Process.run('explorer.exe', ['/select,', path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', ['-R', path]);
    } else {
      await Process.run('xdg-open', [File(path).parent.path]);
    }
  }

  Future<ProcessResult> _powershell(String script, String path) {
    return Process.run(
      'powershell',
      ['-NoProfile', '-NonInteractive', '-Command', script],
      environment: {_pathVar: path},
    );
  }
}
