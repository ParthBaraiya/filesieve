import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// ---------------------------------------------------------------------------
// Native function typedefs
// ---------------------------------------------------------------------------

typedef _Md5PartialNative = Void Function(Pointer<Utf16>, Int64, Pointer<Utf8>);
typedef _Md5PartialDart = void Function(Pointer<Utf16>, int, Pointer<Utf8>);

typedef _Md5FullNative = Void Function(Pointer<Utf16>, Pointer<Utf8>);
typedef _Md5FullDart = void Function(Pointer<Utf16>, Pointer<Utf8>);

typedef _ByteCompareNative = Int32 Function(Pointer<Utf16>, Pointer<Utf16>);
typedef _ByteCompareDart = int Function(Pointer<Utf16>, Pointer<Utf16>);

/// Singleton wrapper around the native `hash_native.dll` functions.
///
/// The native library is loaded lazily on first use. Note that each Dart
/// Isolate has its own instance (statics are isolate-local), so the library is
/// loaded once per isolate. Must only be used on Windows.
class HashNativeBindings {
  HashNativeBindings._();

  static final HashNativeBindings instance = HashNativeBindings._();

  /// Convenience alias for [instance].
  factory HashNativeBindings() => instance;

  late final DynamicLibrary _lib = DynamicLibrary.open('hash_native.dll');

  late final _Md5PartialDart _md5Partial =
      _lib.lookupFunction<_Md5PartialNative, _Md5PartialDart>('md5_partial');

  late final _Md5FullDart _md5Full =
      _lib.lookupFunction<_Md5FullNative, _Md5FullDart>('md5_full');

  late final _ByteCompareDart _byteCompare =
      _lib.lookupFunction<_ByteCompareNative, _ByteCompareDart>('byte_compare');

  /// Calls the native md5_partial function.
  String md5Partial(String path, int chunkSize) {
    assert(Platform.isWindows, 'md5Partial is Windows-only');

    final pathPtr = path.toNativeUtf16(allocator: calloc);
    final outBuf = calloc<Uint8>(33);
    try {
      _md5Partial(pathPtr, chunkSize, outBuf.cast<Utf8>());
      return outBuf.cast<Utf8>().toDartString();
    } finally {
      calloc.free(pathPtr);
      calloc.free(outBuf);
    }
  }

  /// Calls the native md5_full function.
  String md5Full(String path) {
    assert(Platform.isWindows, 'md5Full is Windows-only');

    final pathPtr = path.toNativeUtf16(allocator: calloc);
    final outBuf = calloc<Uint8>(33);
    try {
      _md5Full(pathPtr, outBuf.cast<Utf8>());
      return outBuf.cast<Utf8>().toDartString();
    } finally {
      calloc.free(pathPtr);
      calloc.free(outBuf);
    }
  }

  /// Calls the native byte_compare function.
  /// Returns true when the two files are byte-for-byte identical.
  bool byteCompare(String pathA, String pathB) {
    assert(Platform.isWindows, 'byteCompare is Windows-only');

    final ptrA = pathA.toNativeUtf16(allocator: calloc);
    final ptrB = pathB.toNativeUtf16(allocator: calloc);
    try {
      return _byteCompare(ptrA, ptrB) == 1;
    } finally {
      calloc.free(ptrA);
      calloc.free(ptrB);
    }
  }
}
