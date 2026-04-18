import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:crypto/src/digest_sink.dart';

import 'hash_native_bindings.dart';

class HashUtils {
  static const int chunkSize = 1024 * 1024; // 1 MB

  /// Returns the MD5 hex digest of the first + last [chunkSize] bytes.
  /// On Windows delegates to the native FFI implementation.
  /// On non-Windows falls back to the Dart `crypto` package.
  static String partialHash(String path, {int chunkSize = 1048576}) {
    if (Platform.isWindows) {
      return nativeMd5Partial(path, chunkSize);
    }
    return _dartPartialHash(path, chunkSize: chunkSize);
  }

  /// Returns the MD5 hex digest of the entire file.
  /// On Windows delegates to the native FFI implementation.
  /// On non-Windows falls back to the Dart `crypto` package.
  static String fullHash(String path) {
    if (Platform.isWindows) {
      return nativeMd5Full(path);
    }
    return _dartFullHash(path);
  }

  // ---------------------------------------------------------------------------
  // Non-Windows fallbacks using the `crypto` package
  // ---------------------------------------------------------------------------

  static String _dartPartialHash(String path, {required int chunkSize}) {
    final file = File(path);
    final fileSize = file.statSync().size;

    final output = DigestSink();
    final input = md5.startChunkedConversion(output);

    final raf = file.openSync();
    try {
      // First window: [0, min(fileSize, chunkSize))
      final firstLen = fileSize < chunkSize ? fileSize : chunkSize;
      if (firstLen > 0) {
        raf.setPositionSync(0);
        input.add(raf.readSync(firstLen));
      }

      // Last window: [max(0, fileSize - chunkSize), fileSize)
      // Read independently even when the two windows overlap.
      final lastStart = (fileSize - chunkSize) < 0 ? 0 : (fileSize - chunkSize);
      final lastLen = fileSize < chunkSize ? fileSize : chunkSize;
      if (lastLen > 0) {
        raf.setPositionSync(lastStart);
        input.add(raf.readSync(lastLen));
      }
    } finally {
      raf.closeSync();
    }

    input.close();
    return output.value.toString();
  }

  static String _dartFullHash(String path) {
    final file = File(path);
    final output = DigestSink();
    final input = md5.startChunkedConversion(output);

    final raf = file.openSync();
    try {
      const bufSize = 65536;
      while (true) {
        final chunk = raf.readSync(bufSize);
        if (chunk.isEmpty) break;
        input.add(chunk);
      }
    } finally {
      raf.closeSync();
    }

    input.close();
    return output.value.toString();
  }
}
