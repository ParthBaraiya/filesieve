import 'dart:io';

import 'package:filesieve/models/duplicate_group_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/scan_duplicate_entry_model.dart';
import '../../../utils/format_utils.dart';

import 'package:path/path.dart' as p;

class ScanLiveFeedRowWidget extends StatelessWidget {
  const ScanLiveFeedRowWidget({super.key, required this.group});

  final DuplicateGroup group;

  IconData _iconForExtension(String fileName) {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    const imageExts = {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
      'heic',
      'svg',
    };
    const videoExts = {'mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv', 'webm'};
    const docExts = {
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'txt',
      'odt',
    };
    const archiveExts = {'zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz'};

    if (imageExts.contains(ext)) return Icons.image;
    if (videoExts.contains(ext)) return Icons.video_file;
    if (docExts.contains(ext)) return Icons.description;
    if (archiveExts.contains(ext)) return Icons.folder_zip;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final file = File(group.files.first.path);
    final entry = ScanDuplicateEntryModel(
      path: file.path,
      fileName: p.basename(file.path),
      parentPath: p.dirname(file.path),
      sizeBytes: group.totalGroupSize,
      matchPercent: 100,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Icon(
            _iconForExtension(entry.fileName),
            color: colorScheme.onSurfaceVariant,
            size: 20.r,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.fileName,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  entry.parentPath,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            formatBytes(entry.sizeBytes),
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              'MATCH: ${entry.matchPercent}%',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
