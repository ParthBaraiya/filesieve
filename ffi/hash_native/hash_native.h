#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#ifdef _WIN32
#define HASH_NATIVE_EXPORT __declspec(dllexport)
#else
#define HASH_NATIVE_EXPORT
#endif

#include <stdint.h>

/// Compute the MD5 of the first and last chunkSize bytes of the file.
/// Result is written as a 33-byte null-terminated lowercase hex string into outHex.
/// The two windows are fed independently into a single MD5 context (they may overlap
/// when fileSize is between chunkSize and 2*chunkSize — both ranges are still read).
HASH_NATIVE_EXPORT void md5_partial(const wchar_t* path, int64_t chunkSize, char* outHex);

/// Compute the MD5 of the entire file.
/// Result is written as a 33-byte null-terminated lowercase hex string into outHex.
HASH_NATIVE_EXPORT void md5_full(const wchar_t* path, char* outHex);

/// Compare two files byte-by-byte.
/// Returns 1 if the files are identical, 0 otherwise (including on I/O error).
HASH_NATIVE_EXPORT int byte_compare(const wchar_t* pathA, const wchar_t* pathB);

#ifdef __cplusplus
}
#endif
