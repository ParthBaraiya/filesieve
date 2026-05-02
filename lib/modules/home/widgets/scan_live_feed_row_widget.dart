import 'package:filesieve/models/duplicate_group_model.dart';
import 'package:filesieve/utils/extensions.dart';
import 'package:filesieve/utils/fs_file/fs_file.dart';
import 'package:filesieve/utils/fs_file/fs_file_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ScanLiveFeedGridWidget extends StatefulWidget {
  const ScanLiveFeedGridWidget({
    super.key,
    required this.group,
    required this.onPreview,
  });

  final DuplicateGroup group;
  final VoidCallback onPreview;

  @override
  State<ScanLiveFeedGridWidget> createState() => _ScanLiveFeedGridWidgetState();
}

class _ScanLiveFeedGridWidgetState extends State<ScanLiveFeedGridWidget> {
  final hover = ValueNotifier(false);
  final isChecked = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    final file = widget.group.files.first;
    final hasMoreThanOneDuplicate = widget.group.files.length > 2;
    return MouseRegion(
      onHover: (event) => hover.value = true,

      onExit: (_) => hover.value = false,
      child: GestureDetector(
        onTap: () => isChecked.value = !isChecked.value,
        child: Padding(
          padding: .all(10.sp),
          child: ValueListenableBuilder(
            valueListenable: isChecked,
            builder: (_, value, child) {
              return AnimatedScale(
                scale: value ? 0.95 : 1,
                duration: Duration(microseconds: 300),
                curve: Curves.easeOut,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: value
                        ? Border.all(
                            color: context.theme.colorScheme.primaryContainer,
                            width: 4.sp,
                          )
                        : null,
                    borderRadius: .circular(10.r),
                  ),
                  position: .foreground,
                  child: child,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: .circular(10.r),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.theme.colorScheme.surfaceBright,
                  border: Border.all(
                    color: context.theme.colorScheme.outlineVariant.withAlpha(
                      80,
                    ),
                  ),
                  borderRadius: .circular(10.r),
                ),
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.4,
                      child: ClipRect(
                        child: ValueListenableBuilder(
                          valueListenable: hover,
                          builder: (_, value, child) {
                            return AnimatedScale(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              scale: value ? 1.1 : 1,
                              child: child,
                            );
                          },
                          child: Center(
                            child: _widgetForExtension(file, context),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: .all(10.sp),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: .end,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: .min,
                                    crossAxisAlignment: .start,
                                    children: [
                                      Text(
                                        file.name ?? 'unknown',
                                        maxLines: 1,
                                        style: context
                                            .theme
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: context
                                                  .theme
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                      ),
                                      SizedBox(height: 4.sp),
                                      Row(
                                        children: [
                                          FutureBuilder(
                                            future: file.formattedSize,
                                            builder: (_, snapshot) {
                                              if (!snapshot.hasData &&
                                                  !snapshot.hasError) {
                                                return SizedBox.shrink();
                                              }

                                              final size =
                                                  snapshot.hasData &&
                                                      snapshot.data != null
                                                  ? snapshot.data!
                                                  : 'N/A';

                                              return Padding(
                                                padding: .only(right: 8.sp),
                                                child: Text(
                                                  size,
                                                  maxLines: 1,
                                                  style: context
                                                      .theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: context
                                                            .theme
                                                            .colorScheme
                                                            .onSurface,
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                          Text(
                                            "${widget.group.files.length - 1} "
                                            "duplicate${hasMoreThanOneDuplicate ? 's' : ''}",
                                            maxLines: 1,
                                            style: context
                                                .theme
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: context
                                                      .theme
                                                      .colorScheme
                                                      .primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                _previewIconWidget(Icons.visibility_outlined),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _previewIconWidget(IconData icon) {
    return IconButton(
      onPressed: widget.onPreview,
      padding: .all(12.sp),
      icon: Icon(icon, color: context.theme.colorScheme.onSurface),
    );
  }

  Widget _widgetForExtension(FsFile file, BuildContext context) {
    if (FsFileUtils.isImage(file.extension) && file.imageProvider != null) {
      return Image(
        image: file.imageProvider!,
        fit: .cover,
        height: .maxFinite,
        width: .maxFinite,
      );
    }

    IconData icon;

    if (FsFileUtils.isPlayableVideo(file.extension)) {
      icon = Icons.video_file;
    } else if (FsFileUtils.isArchive(file.extension)) {
      icon = Icons.folder_zip;
    } else {
      icon = Icons.description;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.theme.colorScheme.secondaryContainer,
        borderRadius: .vertical(top: .circular(10.r)),
      ),
      child: SizedBox.expand(
        child: Icon(
          icon,
          size: 70,
          color: context.theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
