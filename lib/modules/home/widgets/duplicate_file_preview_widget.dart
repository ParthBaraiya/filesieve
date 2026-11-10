import 'dart:io';

import 'package:filesieve/modules/home/duplicate_group_cubit.dart';
import 'package:filesieve/modules/home/home_screen_cubit.dart';
import 'package:filesieve/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/duplicate_group_model.dart';
import '../../../utils/fs_file/fs_file.dart';
import '../../../utils/fs_file/fs_file_utils.dart';
import '../../../views/previews/file_preview.dart';
import '../home_screen_state.dart';
import 'duplicate_file_preview_body/duplicate_file_preview_body_cubit.dart';

class DuplicateFilePreviewWidget extends StatefulWidget {
  const DuplicateFilePreviewWidget({super.key, required this.state});

  final HomeScreenFilePreview state;

  @override
  State<DuplicateFilePreviewWidget> createState() =>
      _DuplicateFilePreviewWidgetState();
}

class _DuplicateFilePreviewWidgetState
    extends State<DuplicateFilePreviewWidget> {
  DuplicateFilePreviewBodyCubit? cubit;

  @override
  void initState() {
    super.initState();

    _initCubit();
  }

  @override
  void didUpdateWidget(covariant DuplicateFilePreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.state != widget.state) {
      _initCubit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = this.cubit;
    if (cubit == null) return SizedBox.shrink();

    return BlocBuilder(
      bloc: cubit.state.group,
      builder: (_, state) {
        final group = cubit.state.group.state.group;
        return Column(
          crossAxisAlignment: .start,
          children: [
            TextButton(
              onPressed: () => context.read<HomeScreenCubit>().backToPreview(),
              child: Row(
                mainAxisSize: .min,
                children: [
                  Icon(Icons.chevron_left),
                  Text('Back to Duplicates'),
                ],
              ),
            ),
            FutureBuilder(
              future: group.largestFile,
              builder: (_, snapshot) {
                return Padding(
                  padding: .symmetric(vertical: 20.sp, horizontal: 30.sp),
                  child: Text(
                    snapshot.data?.name ?? 'unknown',
                    style: context.theme.textTheme.titleMedium,
                  ),
                );
              },
            ),
            Padding(
              padding: .only(left: 20.sp),
              child: Text('${group.files.length - 1} duplicates found!'),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child:
                        BlocBuilder<
                          DuplicateFilePreviewBodyCubit,
                          DuplicateFilePreviewBodyState
                        >(
                          bloc: cubit,
                          builder: (_, state) {
                            return Padding(
                              padding: .all(20.sp),
                              child: ClipRRect(
                                borderRadius: .circular(10.r),

                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: FsFilePreview(
                                    file: state.selectedFile,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Center(child: Text('Meta will come here')),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200.sp,
              child: BlocBuilder<DuplicateGroupCubit, DuplicateGroupState>(
                bloc: cubit.state.group,
                buildWhen: (old, updated) =>
                    old.group.files.length != updated.group.files.length,
                builder: (_, state) {
                  final group = state.group;

                  return ListView.separated(
                    separatorBuilder: (_, _) => SizedBox(width: 20),
                    scrollDirection: .horizontal,
                    padding: .symmetric(vertical: 20.sp, horizontal: 20.sp),
                    itemBuilder: (_, index) {
                      final file = group.files[index];

                      return BlocBuilder<
                        DuplicateFilePreviewBodyCubit,
                        DuplicateFilePreviewBodyState
                      >(
                        bloc: cubit,
                        buildWhen: (old, updated) =>
                            (old.selectedFile == file ||
                                updated.selectedFile == file) &&
                            old.selectedFile != updated.selectedFile,
                        builder: (_, state) {
                          final isSelected = state.selectedFile == file;

                          return InkWell(
                            onTap: () => cubit.selectFile(file),
                            child: AspectRatio(
                              aspectRatio: 1.3,
                              child: Tooltip(
                                message: file.path ?? '',
                                enableTapToDismiss: true,
                                triggerMode: .longPress,
                                child: ClipRRect(
                                  borderRadius: .circular(10.r),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected
                                            ? context.theme.colorScheme.primary
                                            : context
                                                  .theme
                                                  .colorScheme
                                                  .outlineVariant
                                                  .withAlpha(80),
                                        width: isSelected ? 4 : 1,
                                      ),
                                      borderRadius: .circular(10.r),
                                    ),
                                    position: .foreground,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: context
                                            .theme
                                            .colorScheme
                                            .surfaceBright,
                                      ),
                                      child: Column(
                                        children: [
                                          AspectRatio(
                                            aspectRatio: 1.9,
                                            child: ClipRect(
                                              child: Stack(
                                                children: [
                                                  Center(
                                                    child: _widgetForExtension(
                                                      file,
                                                      context,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: .all(10.sp),
                                                    child: SizedBox.expand(
                                                      child: Row(
                                                        mainAxisSize: .max,
                                                        mainAxisAlignment: .end,
                                                        crossAxisAlignment:
                                                            .start,
                                                        children: [
                                                          DecoratedBox(
                                                            decoration: BoxDecoration(
                                                              color: context
                                                                  .theme
                                                                  .colorScheme
                                                                  .surface,
                                                              borderRadius:
                                                                  .circular(
                                                                    6.sp,
                                                                  ),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: context
                                                                      .theme
                                                                      .colorScheme
                                                                      .shadow
                                                                      .withAlpha(
                                                                        100,
                                                                      ),
                                                                  blurRadius:
                                                                      10,
                                                                  spreadRadius:
                                                                      -5,
                                                                  offset:
                                                                      Offset(
                                                                        4,
                                                                        4,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                            child: InkWell(
                                                              onTap: () => cubit
                                                                  .deleteFile(
                                                                    file,
                                                                  ),
                                                              borderRadius:
                                                                  .circular(
                                                                    6.sp,
                                                                  ),
                                                              child: Padding(
                                                                padding: .all(
                                                                  8.sp,
                                                                ),
                                                                child: Icon(
                                                                  Icons
                                                                      .delete_outline_rounded,
                                                                  size: 16.sp,
                                                                  color: context
                                                                      .theme
                                                                      .colorScheme
                                                                      .error,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: 8.sp),
                                                          DecoratedBox(
                                                            decoration: BoxDecoration(
                                                              color: context
                                                                  .theme
                                                                  .colorScheme
                                                                  .surface,
                                                              borderRadius:
                                                                  .circular(
                                                                    6.sp,
                                                                  ),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: context
                                                                      .theme
                                                                      .colorScheme
                                                                      .shadow
                                                                      .withAlpha(
                                                                        100,
                                                                      ),
                                                                  blurRadius:
                                                                      10,
                                                                  spreadRadius:
                                                                      -5,
                                                                  offset:
                                                                      Offset(
                                                                        4,
                                                                        4,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                            child: InkWell(
                                                              onTap: () async {
                                                                await Process.run(
                                                                  'explorer.exe',
                                                                  [file.path!],
                                                                );
                                                              },
                                                              borderRadius:
                                                                  .circular(
                                                                    6.sp,
                                                                  ),
                                                              child: Padding(
                                                                padding: .all(
                                                                  8.sp,
                                                                ),
                                                                child: Icon(
                                                                  Icons
                                                                      .open_in_new_rounded,
                                                                  size: 16.sp,
                                                                  color: context
                                                                      .theme
                                                                      .colorScheme
                                                                      .primary,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: .all(6.sp),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: .end,
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          mainAxisSize: .min,
                                                          crossAxisAlignment:
                                                              .start,
                                                          children: [
                                                            Text(
                                                              file.name ??
                                                                  'unknown',
                                                              maxLines: 1,
                                                              style: context
                                                                  .theme
                                                                  .textTheme
                                                                  .labelMedium
                                                                  ?.copyWith(
                                                                    color: context
                                                                        .theme
                                                                        .colorScheme
                                                                        .onSurface,
                                                                  ),
                                                            ),
                                                            SizedBox(
                                                              height: 2.sp,
                                                            ),
                                                            Row(
                                                              children: [
                                                                FutureBuilder(
                                                                  future: file
                                                                      .formattedSize,
                                                                  builder: (_, snapshot) {
                                                                    if (!snapshot
                                                                            .hasData &&
                                                                        !snapshot
                                                                            .hasError) {
                                                                      return SizedBox.shrink();
                                                                    }

                                                                    final size =
                                                                        snapshot.hasData &&
                                                                            snapshot.data !=
                                                                                null
                                                                        ? snapshot
                                                                              .data!
                                                                        : 'N/A';

                                                                    return Padding(
                                                                      padding: .only(
                                                                        right: 8
                                                                            .sp,
                                                                      ),
                                                                      child: Text(
                                                                        size,
                                                                        maxLines:
                                                                            1,
                                                                        style: context
                                                                            .theme
                                                                            .textTheme
                                                                            .labelSmall
                                                                            ?.copyWith(
                                                                              color: context.theme.colorScheme.onSurface,
                                                                            ),
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
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
                        },
                      );
                    },
                    itemCount: group.files.length,
                  );
                },
              ),
            ),
          ],
        );
      },
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

  Future<void> _initCubit() async {
    if (cubit != null) {
      final old = cubit!;
      cubit = null;

      // Close old cubit.
      // We are adding delay so, we can make sure that all the widgets that
      // listens to the old widget are either disposed or updated to use new one
      //
      Future.delayed(Duration(seconds: 1), () {
        old.close();
      });
    }

    final firstFile = await widget.state.currentGroup.state.group.largestFile;

    cubit = DuplicateFilePreviewBodyCubit(
      group: widget.state.currentGroup,
      file: firstFile!,
    );

    if (mounted) {
      setState(() {});
    }
  }
}
