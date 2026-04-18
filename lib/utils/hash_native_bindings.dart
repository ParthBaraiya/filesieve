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

// ---------------------------------------------------------------------------
// Lazy initialisation
// ---------------------------------------------------------------------------

late final _Md5PartialDart _md5Partial;
late final _Md5FullDart _md5Full;
late final _ByteCompareDart _byteCompare;

bool _initialized = false;

void _ensureInitialized() {
  if (_initialized) return;
  final lib = DynamicLibrary.open('hash_native.dll');
  _md5Partial =
      lib.lookupFunction<_Md5PartialNative, _Md5PartialDart>('md5_partial');
  _md5Full = lib.lookupFunction<_Md5FullNative, _Md5FullDart>('md5_full');
  _byteCompare =
      lib.lookupFunction<_ByteCompareNative, _ByteCompareDart>('byte_compare');
  _initialized = true;
}

// ---------------------------------------------------------------------------
// Public Dart wrappers
// ---------------------------------------------------------------------------

/// Calls the native md5_partial function.
/// Must only be invoked on Windows inside a spawned Dart Isolate.
String nativeMd5Partial(String path, int chunkSize) {
  assert(Platform.isWindows, 'nativeMd5Partial is Windows-only');
  _ensureInitialized();

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
/// Must only be invoked on Windows inside a spawned Dart Isolate.
String nativeMd5Full(String path) {
  assert(Platform.isWindows, 'nativeMd5Full is Windows-only');
  _ensureInitialized();

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
/// Must only be invoked on Windows inside a spawned Dart Isolate.
bool nativeByteCompare(String pathA, String pathB) {
  assert(Platform.isWindows, 'nativeByteCompare is Windows-only');
  _ensureInitialized();

  final ptrA = pathA.toNativeUtf16(allocator: calloc);
  final ptrB = pathB.toNativeUtf16(allocator: calloc);
  try {
    return _byteCompare(ptrA, ptrB) == 1;
  } finally {
    calloc.free(ptrA);
    calloc.free(ptrB);
  }
}
