import 'package:flutter/material.dart';

import '../../../models/cache_path_entry_model.dart';
import 'cache_path_entry_widget.dart';

class StorageCacheSectionWidget extends StatelessWidget {
  const StorageCacheSectionWidget({
    super.key,
    required this.entries,
    this.copiedEntryId,
    this.onOpenFolder,
    this.onCopyPath,
  });

  final List<CachePathEntry> entries;
  final String? copiedEntryId;
  final ValueChanged<CachePathEntry>? onOpenFolder;
  final ValueChanged<CachePathEntry>? onCopyPath;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...entries.map((entry) {
          return CachePathEntryWidget(
            entry: entry,
            isCopied: copiedEntryId == entry.id,
            onOpenFolder:
                onOpenFolder == null ? null : () => onOpenFolder!(entry),
            onCopyPath: onCopyPath == null ? null : () => onCopyPath!(entry),
          );
        }),
      ],
    );
  }
}
