import 'package:filesieve/utils/fs_file/fs_file.dart';
import 'package:filesieve/utils/fs_file/fs_file_utils.dart';
import 'package:flutter/material.dart';

class FsFilePreview extends StatefulWidget {
  const FsFilePreview({super.key, required this.file});

  final FsFile file;

  @override
  State<FsFilePreview> createState() => _FsFilePreviewState();
}

class _FsFilePreviewState extends State<FsFilePreview> {
  @override
  Widget build(BuildContext context) {
    final extension = widget.file.extension;

    if (FsFileUtils.isImage(extension)) {
      return _ImagePreview(image: widget.file);
    }

    return const Placeholder();
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({super.key, required this.image});

  final FsFile image;

  @override
  Widget build(BuildContext context) {
    final provider = image.imageProvider;
    if (provider == null) return SizedBox.shrink();

    return Image(
      image: provider,
      height: .maxFinite,
      width: .maxFinite,
      fit: .cover,
    );
  }
}
