import 'package:flutter/material.dart';

import '../../../models/cache_path_entry_model.dart';
import '../../../values/app_strings.dart';

class CachePathEntryWidget extends StatelessWidget {
  const CachePathEntryWidget({
    super.key,
    required this.entry,
    required this.isCopied,
    this.onOpenFolder,
    this.onCopyPath,
  });

  final CachePathEntry entry;
  final bool isCopied;
  final VoidCallback? onOpenFolder;
  final VoidCallback? onCopyPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.label,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(entry.category, style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Tooltip(
                  message: entry.path,
                  child: Text(
                    entry.path,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (!entry.exists)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      AppStrings.settingsCacheEntryNotCreated,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: onOpenFolder,
                icon: const Icon(Icons.folder_open_outlined),
              ),
              IconButton(
                onPressed: onCopyPath,
                icon: Icon(isCopied ? Icons.check : Icons.copy_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
