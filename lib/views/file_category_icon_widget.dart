import 'package:filesieve/utils/extensions.dart';
import 'package:flutter/material.dart';

import '../values/enums.dart';

/// FileCategoryIconWidget — the icon for a file type, tinted from the palette.
class FileCategoryIconWidget extends StatelessWidget {
  const FileCategoryIconWidget({
    super.key,
    required this.category,
    required this.size,
  });

  final FileCategory category;
  final double size;

  static IconData iconOf(FileCategory category) => switch (category) {
    FileCategory.image => Icons.image_outlined,
    FileCategory.video => Icons.videocam_outlined,
    FileCategory.document => Icons.description_outlined,
    FileCategory.audio => Icons.music_note_outlined,
    FileCategory.archive => Icons.folder_zip_outlined,
    FileCategory.other => Icons.insert_drive_file_outlined,
  };

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Icon(
      iconOf(category),
      size: size,
      color: context.palette.tintOf(category),
    ),
  );
}
