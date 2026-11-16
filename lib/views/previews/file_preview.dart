import 'package:omnifile/omnifile.dart';
import 'package:material_ui/material_ui.dart';

class FsFilePreview extends StatefulWidget {
  const FsFilePreview({super.key, required this.file});

  final OmniFile file;

  @override
  State<FsFilePreview> createState() => _FsFilePreviewState();
}

class _FsFilePreviewState extends State<FsFilePreview> {
  @override
  Widget build(BuildContext context) {
    final extension = widget.file.extension;

    if (OmniFileUtils.isImage(extension)) {
      return _ImagePreview(image: widget.file);
    }

    return const Placeholder();
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({super.key, required this.image});

  final OmniFile image;

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
