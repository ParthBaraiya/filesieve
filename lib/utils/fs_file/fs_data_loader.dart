import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'fs_file.dart';

abstract class FsBytesLoader {
  final FsFile file;

  const FsBytesLoader(this.file);

  /// Loads the file bytes from its respective source.
  Future<List<int>> load();
  Future<Stream<List<int>>> stream();

  Future<int?> get size => file.size;

  static FsBytesLoader fromFile(FsFile file) {
    return switch (file.source) {
      FsFileSource.network => FsNetworkBytesLoader(file),
      FsFileSource.memory => FsMemoryBytesLoader(file),
      FsFileSource.asset => FsAssetBytesLoader(file),
      FsFileSource.local => FsLocalFileBytesLoader(file),
    };
  }
}

class FsNetworkBytesLoader extends FsBytesLoader {
  const FsNetworkBytesLoader(super.file);

  @override
  Future<List<int>> load() async {
    if (file.source != FsFileSource.network) {
      throw Exception("File source is not network");
    }

    final uri = Uri.parse(file.path!);

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load network file (${file.name}): '
        '${response.statusCode}',
      );
    }

    return response.bodyBytes;
  }

  @override
  Future<Stream<List<int>>> stream() async {
    if (file.source != FsFileSource.network) {
      throw Exception("File source is not network");
    }

    final uri = Uri.parse(file.path!);
    final request = http.Request('GET', uri);
    final client = http.Client();

    final response = await client.send(request);
    if (response.statusCode != 200) {
      client.close();
      throw Exception(
        'Failed to load network file (${file.name}): '
        '${response.statusCode}',
      );
    }

    return response.stream;
  }
}

class FsLocalFileBytesLoader extends FsBytesLoader {
  const FsLocalFileBytesLoader(super.file);

  @override
  Future<List<int>> load() async {
    if (file.source != FsFileSource.local) {
      throw Exception("File source is not local");
    }

    final fileRef = File(file.path!);

    if (!await fileRef.exists()) {
      throw FileSystemException('Local file not found', file.path!);
    }

    return await fileRef.readAsBytes();
  }

  @override
  Future<Stream<List<int>>> stream() async {
    return load().asStream();
  }
}

class FsMemoryBytesLoader extends FsBytesLoader {
  FsMemoryBytesLoader(super.file);

  @override
  Future<List<int>> load() {
    if (file.source != FsFileSource.memory) {
      throw Exception("File source is not memory");
    }

    return Future.value(file.bytes!);
  }

  @override
  Future<Stream<List<int>>> stream() async {
    return load().asStream();
  }
}

class FsAssetBytesLoader extends FsBytesLoader {
  const FsAssetBytesLoader(super.file);

  @override
  Future<List<int>> load() async {
    if (file.source != FsFileSource.asset) {
      throw Exception("File source is not asset");
    }

    final data = await rootBundle.load(file.path!);
    return data.buffer.asUint8List();
  }

  @override
  Future<Stream<List<int>>> stream() async {
    return load().asStream();
  }
}
