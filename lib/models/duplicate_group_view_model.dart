import 'dart:io' show Platform;

import 'package:path/path.dart' as p;

import 'package:omnifile/omnifile.dart';
import '../values/enums.dart';
import 'duplicate_group_model.dart';

/// One copy of a file inside a [DuplicateGroupView].
class DuplicateVersionView {
  const DuplicateVersionView({
    required this.file,
    required this.path,
    required this.folderName,
    required this.modified,
    required this.removedAs,
  });

  final OmniFile file;
  final String path;

  /// Name of the folder that holds this copy.
  final String folderName;
  final DateTime? modified;

  /// How this copy was removed this session, or null while it is on disk.
  final RemovalMode? removedAs;

  bool get isRemoved => removedAs != null;

  /// Full path of the directory that holds this copy.
  String get folderPath => p.normalize(p.dirname(path));
}

/// Whether two directory paths are the same folder (case-insensitive on
/// Windows).
bool isSameFolder(String a, String b) => Platform.isWindows
    ? p.normalize(a).toLowerCase() == p.normalize(b).toLowerCase()
    : p.normalize(a) == p.normalize(b);

/// FolderCombo — every duplicate group whose remaining copies sit in exactly
/// the same set of folders. A group belongs to exactly one combo, so a file
/// found in f1, f2 and f3 is never also counted under f1 + f3.
class FolderCombo {
  const FolderCombo({required this.key, required this.folders, required this.groups});

  /// Stable id: the sorted folder paths joined together.
  final String key;

  /// The distinct folders, sorted by path.
  final List<String> folders;
  final List<DuplicateGroupView> groups;

  /// Number of files (duplicate groups) in this combination.
  int get fileCount => groups.length;

  /// More than one folder means the user has to choose which one to keep.
  bool get needsChoice => folders.length > 1;

  /// Combos for [groups] (active ones only), largest first.
  static List<FolderCombo> fromGroups(Iterable<DuplicateGroupView> groups) {
    final folderSets = <String, List<String>>{};
    final byKey = <String, List<DuplicateGroupView>>{};
    for (final g in groups) {
      if (!g.isActive) continue;
      final folders = <String>[];
      for (final v in g.remaining) {
        if (!folders.any((f) => isSameFolder(f, v.folderPath))) {
          folders.add(v.folderPath);
        }
      }
      folders.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final key = folders
          .map((f) => Platform.isWindows ? f.toLowerCase() : f)
          .join('|');
      folderSets.putIfAbsent(key, () => folders);
      byKey.putIfAbsent(key, () => []).add(g);
    }
    final combos = [
      for (final e in byKey.entries)
        FolderCombo(key: e.key, folders: folderSets[e.key]!, groups: e.value),
    ]..sort((a, b) {
        final c = b.fileCount.compareTo(a.fileCount);
        return c != 0 ? c : a.key.compareTo(b.key);
      });
    return combos;
  }

  /// Paths to remove when [keepFolder] is the chosen folder: in every group
  /// the oldest copy inside that folder is kept and all other copies go.
  List<String> pathsToRemove(String keepFolder) => [
        for (final g in groups) ...g.pathsToRemoveKeepingIn(keepFolder),
      ];
}

/// DuplicateGroupView — a [DuplicateGroup] seen through this session's
/// removals: which copies are left, and the figures shown in the lists.
class DuplicateGroupView {
  DuplicateGroupView._({
    required this.key,
    required this.name,
    required this.category,
    required this.bytesEach,
    required this.versions,
  });

  /// Builds the view; [removed] maps a path to how it was removed.
  factory DuplicateGroupView.from(
    DuplicateGroup group,
    Map<String, RemovalMode> removed,
  ) {
    final files = group.files;
    final first = files.first;
    final name = first.name ?? p.basename(first.path ?? '');
    return DuplicateGroupView._(
      key: first.path ?? name,
      name: name,
      category: categoryOf(first.extension),
      bytesEach: files.isEmpty ? 0 : group.totalGroupSize ~/ files.length,
      versions: [
        for (final f in files)
          DuplicateVersionView(
            file: f,
            path: f.path ?? '',
            folderName: p.basename(p.dirname(f.path ?? '')),
            modified: f.lastModified,
            removedAs: removed[f.path],
          ),
      ],
    );
  }

  /// Stable id: the path of the group's first copy.
  final String key;
  final String name;
  final FileCategory category;

  /// Size of one copy in bytes (all copies are identical).
  final int bytesEach;
  final List<DuplicateVersionView> versions;

  List<DuplicateVersionView> get remaining =>
      versions.where((v) => !v.isRemoved).toList();

  /// Still needs a decision: two or more copies remain.
  bool get isActive => remaining.length >= 2;

  bool get isResolved => remaining.length <= 1;

  /// Bytes freed if all but one remaining copy were removed.
  int get reclaimableBytes => (remaining.length - 1).clamp(0, 1 << 30) * bytesEach;

  /// The oldest copy by modification time (the original), among all copies.
  DuplicateVersionView get oldest => _byModified(versions, newest: false);

  /// Copy kept unless the user picked another: the oldest remaining one.
  DuplicateVersionView? defaultKeep() {
    final rem = remaining;
    return rem.isEmpty ? null : _byModified(rem, newest: false);
  }

  /// The copy to keep given an optional user choice [selectedPath].
  DuplicateVersionView? keepFor(String? selectedPath) {
    final rem = remaining;
    for (final v in rem) {
      if (v.path == selectedPath) return v;
    }
    return defaultKeep();
  }

  /// Paths to remove so only the oldest remaining copy inside [folder] stays.
  /// Falls back to the oldest remaining copy if none sits in [folder].
  List<String> pathsToRemoveKeepingIn(String folder) {
    final rem = remaining;
    final inFolder = rem.where((v) => isSameFolder(v.folderPath, folder)).toList();
    final keep = _byModified(inFolder.isEmpty ? rem : inFolder, newest: false);
    return [
      for (final v in rem)
        if (v.path != keep.path) v.path,
    ];
  }

  /// Folders holding the remaining copies, e.g. "Downloads · Desktop · 2 more".
  String get whereLabel {
    final dirs = remaining.map((v) => v.folderName).toList();
    final shown = dirs.take(3).join(' · ');
    return dirs.length > 3 ? '$shown · ${dirs.length - 3} more' : shown;
  }

  static DuplicateVersionView _byModified(
    List<DuplicateVersionView> list, {
    required bool newest,
  }) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final sorted = [...list]
      ..sort((a, b) {
        final c = (a.modified ?? epoch).compareTo(b.modified ?? epoch);
        return newest ? -c : c;
      });
    return sorted.first;
  }

  static FileCategory categoryOf(String? extension) {
    final ext = extension?.toLowerCase();
    if (OmniFileUtils.isImage(ext)) return FileCategory.image;
    if (OmniFileUtils.isVideo(ext)) return FileCategory.video;
    if (OmniFileUtils.isAudio(ext)) return FileCategory.audio;
    if (OmniFileUtils.isArchive(ext)) return FileCategory.archive;
    if (_documentExtensions.contains(ext)) return FileCategory.document;
    return FileCategory.other;
  }

  static const _documentExtensions = {
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'md', 'rtf',
    'odt', 'ods', 'odp', 'csv', 'epub', 'pages', 'numbers', 'key',
  };
}
