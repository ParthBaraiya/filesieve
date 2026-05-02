import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../helper.dart';
import 'fs_file_utils.dart';

enum FsFileSource {
  network,
  memory,
  asset,
  local;

  bool get isNetwork => this == FsFileSource.network;
  bool get isMemory => this == FsFileSource.memory;
  bool get isAsset => this == FsFileSource.asset;
  bool get isLocal => this == FsFileSource.local;
}

class FsFile {
  final FsFileSource source;
  final String? path;
  final Uint8List? bytes;
  final String mimeType;
  final String? name;

  /// Only available for [FsFileSource.local] files.
  final DateTime? lastModified;

  int? _size;

  FsFile({
    this.path,
    required this.source,
    this.bytes,
    String? name,
    int? size,
    this.lastModified,
  }) : assert(
         bytes != null || (path != null),
         'bytes and path parameters can not be null at the same time.',
       ),
       assert(
         !kIsWeb || source != FsFileSource.local,
         'local files are not supported on web platform.',
       ),
       _size = size,
       name = name ?? _getName(source, path),
       mimeType = FsFileUtils.getMimeFromExtension(
         path?.split('.').lastOrNull ?? '',
       );

  FsFile rename(String newName) {
    return FsFile(
      source: source,
      name: newName,
      path: path,
      bytes: bytes,
      size: _size,
    );
  }

  bool get isValid =>
      ((source.isAsset || source.isLocal || source.isNetwork) &&
          (path?.isNotEmpty ?? false)) ||
      bytes != null;

  String? get extension => name?.split('.').lastOrNull;

  String? get nameWithoutExtension {
    return name?.split('.').firstOrNull;
  }

  Future<int?> get size async {
    if (_size != null) return _size;

    switch (source) {
      case FsFileSource.memory:
        if (bytes == null) return null;

        return _size = bytes!.lengthInBytes;
      case FsFileSource.asset:
        try {
          if (path == null) return null;
          final data = await rootBundle.load(path!);
          return _size = data.lengthInBytes;
        } catch (e) {
          return null;
        }
      case FsFileSource.network:
        try {
          if (path == null) return null;

          // Send a HEAD request to the server to get file metadata
          final response = await http.head(Uri.parse(path!));

          // Check if the response is successful
          if (response.statusCode == 200) {
            // Extract the file size from the Content-Length header
            final contentLength = response.headers['content-length'];

            if (contentLength != null) {
              return _size = int.parse(contentLength);
            } else {
              return null;
            }
          } else {
            return null;
          }
        } catch (e) {
          return null;
        }

      case FsFileSource.local:
        if (kIsWeb) {
          return null;
        }

        if (path?.isEmpty ?? true) return null;
        final file = File(path!);

        return _size = await file.length();
    }
  }

  Future<String?> get formattedSize {
    return size.then((size) {
      return size == null ? null : formatFileSize(size);
    });
  }
}

extension FsFilePathStringExt on String {
  FsFile? get asNetworkFile => FsFile(source: FsFileSource.network, path: this);

  FsFile? get asLocalFile => FsFile(source: FsFileSource.local, path: this);

  FsFile? get asAssetFile => FsFile(source: FsFileSource.asset, path: this);
}

extension FsFileBytesExt on Uint8List {
  FsFile? get asMemoryFile => FsFile(source: FsFileSource.memory, bytes: this);
}

extension FsFileImageProviderExt on FsFile {
  ImageProvider<Object>? get imageProvider {
    if (!FsFileUtils.canPreviewImageByDefault(extension)) {
      return null;
    }

    if (source.isMemory) {
      return MemoryImage(bytes!);
    } else if (source.isAsset) {
      return AssetImage(path!);
    } else if (source.isNetwork) {
      return NetworkImage(path!);
    } else if (source.isLocal) {
      return FileImage(File(path!));
    } else {
      return null;
    }
  }
}

String? _getName(FsFileSource source, String? path) {
  if (path == null) return null;
  switch (source) {
    case FsFileSource.network:
      final uri = Uri.tryParse(path);
      if (uri == null) return null;
      return uri.path.split('/').lastOrNull;
    case FsFileSource.asset:
    case FsFileSource.local:
      return p.basename(path);
    case FsFileSource.memory:
      return null;
  }
}
