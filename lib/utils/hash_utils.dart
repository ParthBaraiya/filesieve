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
      return HashNativeBindings.instance.md5Partial(path, chunkSize);
    }
    return _dartPartialHash(path, chunkSize: chunkSize);
  }

  /// Returns the MD5 hex digest of the entire file.
  /// On Windows delegates to the native FFI implementation.
  /// On non-Windows falls back to the Dart `crypto` package.
  static String fullHash(String path) {
    if (Platform.isWindows) {
      return HashNativeBindings.instance.md5Full(path);
    }
    return _dartFullHash(path);
  }

  /// Returns `true` when [pathA] and [pathB] are byte-for-byte identical.
  ///
  /// On Windows delegates to the native FFI implementation.
  /// On non-Windows opens both files and compares content block by block using
  /// pure Dart — no temporary buffers are allocated beyond the read buffer.
  static bool byteCompare(String pathA, String pathB) {
    if (Platform.isWindows) {
      return HashNativeBindings.instance.byteCompare(pathA, pathB);
    }
    return _dartByteCompare(pathA, pathB);
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

  static bool _dartByteCompare(String pathA, String pathB) {
    // Quick size check avoids opening files that are obviously different.
    if (File(pathA).statSync().size != File(pathB).statSync().size) {
      return false;
    }

    final rafA = File(pathA).openSync();
    final rafB = File(pathB).openSync();
    try {
      const bufSize = 65536;
      while (true) {
        final chunkA = rafA.readSync(bufSize);
        final chunkB = rafB.readSync(bufSize);
        if (chunkA.length != chunkB.length) return false;
        if (chunkA.isEmpty) return true; // both exhausted simultaneously
        for (var i = 0; i < chunkA.length; i++) {
          if (chunkA[i] != chunkB[i]) return false;
        }
      }
    } finally {
      rafA.closeSync();
      rafB.closeSync();
    }
  }
}
