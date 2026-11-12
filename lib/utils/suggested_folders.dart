import 'dart:io';

import 'package:path/path.dart' as p;

/// Common user folders that exist on this machine, for the "Suggested" chips.
List<({String name, String path})> suggestedFolders() {
  final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
  if (home == null || home.isEmpty) return const [];

  return [
    for (final name in const ['Documents', 'Downloads', 'Pictures', 'Desktop'])
      if (Directory(p.join(home, name)).existsSync())
        (name: name, path: p.join(home, name)),
  ];
}
