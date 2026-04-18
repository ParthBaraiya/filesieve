/**
 * @file hash_native.cpp
 * @brief Native Windows DLL for fast file hashing and byte-level comparison.
 *
 * Exposes three functions via extern "C" for consumption by Dart FFI:
 *   - md5_partial  : MD5 of first + last N bytes (cheap fingerprint pass)
 *   - md5_full     : MD5 of entire file (definitive identity check)
 *   - byte_compare : Block-by-block binary equality check (no hashing)
 *
 * All file I/O uses _wfopen(path, L"rb") (wide path, binary mode) so that
 * Windows locale settings and newline translation never corrupt binary reads.
 *
 * The MD5 implementation is self-contained (no external crypto library) and
 * is adapted from RFC 1321 / public domain sources.
 *
 * NOTE: md5_partial and md5_full are synchronous and block the calling thread
 * until I/O and computation finish. Always call them from a spawned Dart
 * Isolate, never from the main (UI) isolate.
 */

#include "hash_native.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>

// ---------------------------------------------------------------------------
// Self-contained MD5 implementation (adapted from RFC 1321 / public domain)
// ---------------------------------------------------------------------------

/**
 * @brief Internal state for an in-progress MD5 computation.
 *
 * Treat this as an opaque handle — always initialise with md5_init(),
 * feed data with md5_update(), and finalise with md5_final().
 */
struct Md5Context {
  uint32_t state[4];   ///< Four 32-bit hash registers: A, B, C, D.
  uint32_t count[2];   ///< Total number of bits processed (lo word, hi word).
                       ///< Using two 32-bit words lets us handle inputs > 4 GB.
  uint8_t  buffer[64]; ///< Partial 64-byte block accumulator between update calls.
};

/**
 * @brief Standard MD5 padding block (RFC 1321 §3.1).
 *
 * After the last data byte, MD5 appends a 0x80 byte followed by enough
 * zero bytes so the total message length ≡ 56 (mod 64). This array covers
 * the maximum padding needed (up to 64 bytes).
 */
static const uint8_t kPadding[64] = {
  0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0,    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0,    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0,    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
};

// ---------------------------------------------------------------------------
// MD5 auxiliary functions (RFC 1321 §3.4) — one non-linear function per round.
// Each operates on three 32-bit words and returns a 32-bit word.
// ---------------------------------------------------------------------------
#define F(x, y, z) (((x) & (y)) | (~(x) & (z))) ///< Round 1: if x then y else z
#define G(x, y, z) (((x) & (z)) | ((y) & ~(z))) ///< Round 2: if z then x else y
#define H(x, y, z) ((x) ^ (y) ^ (z))             ///< Round 3: parity
#define I(x, y, z) ((y) ^ ((x) | ~(z)))          ///< Round 4

/// 32-bit left circular rotate: shifts bits left by n, wraps the overflow back on the right.
#define ROTATE_LEFT(x, n) (((x) << (n)) | ((x) >> (32 - (n))))

// Per-step macros for each round. Each macro:
//   1. Adds the round function result + message word (x) + round constant (ac) into register a.
//   2. Left-rotates a by s bits.
//   3. Adds register b into a.
// The four variants (FF/GG/HH/II) differ only in which auxiliary function they call.
#define FF(a, b, c, d, x, s, ac) { \
  (a) += F((b),(c),(d)) + (x) + (uint32_t)(ac); \
  (a) = ROTATE_LEFT((a),(s)); \
  (a) += (b); }

#define GG(a, b, c, d, x, s, ac) { \
  (a) += G((b),(c),(d)) + (x) + (uint32_t)(ac); \
  (a) = ROTATE_LEFT((a),(s)); \
  (a) += (b); }

#define HH(a, b, c, d, x, s, ac) { \
  (a) += H((b),(c),(d)) + (x) + (uint32_t)(ac); \
  (a) = ROTATE_LEFT((a),(s)); \
  (a) += (b); }

#define II(a, b, c, d, x, s, ac) { \
  (a) += I((b),(c),(d)) + (x) + (uint32_t)(ac); \
  (a) = ROTATE_LEFT((a),(s)); \
  (a) += (b); }

/**
 * @brief Core MD5 compression function — processes one 64-byte block.
 *
 * Unpacks the block into 16 little-endian 32-bit words, then runs 64 steps
 * across 4 rounds of 16 steps each (FF → GG → HH → II). Each step mixes
 * one message word with the four state registers using the round's auxiliary
 * function and a precomputed constant derived from sin (RFC 1321 §3.4).
 * The results are accumulated back into state[]. The message word array is
 * zeroed on exit to avoid leaving sensitive data on the stack.
 *
 * @param state  Four 32-bit registers (A, B, C, D); updated in place.
 * @param block  64-byte input block to process.
 */
static void md5_transform(uint32_t state[4], const uint8_t block[64]) {
  uint32_t a = state[0], b = state[1], c = state[2], d = state[3], x[16];

  for (int i = 0, j = 0; i < 16; ++i, j += 4) {
    x[i] = ((uint32_t)block[j])
          | ((uint32_t)block[j + 1] << 8)
          | ((uint32_t)block[j + 2] << 16)
          | ((uint32_t)block[j + 3] << 24);
  }

  // Round 1
  FF(a, b, c, d, x[ 0],  7, 0xd76aa478); FF(d, a, b, c, x[ 1], 12, 0xe8c7b756);
  FF(c, d, a, b, x[ 2], 17, 0x242070db); FF(b, c, d, a, x[ 3], 22, 0xc1bdceee);
  FF(a, b, c, d, x[ 4],  7, 0xf57c0faf); FF(d, a, b, c, x[ 5], 12, 0x4787c62a);
  FF(c, d, a, b, x[ 6], 17, 0xa8304613); FF(b, c, d, a, x[ 7], 22, 0xfd469501);
  FF(a, b, c, d, x[ 8],  7, 0x698098d8); FF(d, a, b, c, x[ 9], 12, 0x8b44f7af);
  FF(c, d, a, b, x[10], 17, 0xffff5bb1); FF(b, c, d, a, x[11], 22, 0x895cd7be);
  FF(a, b, c, d, x[12],  7, 0x6b901122); FF(d, a, b, c, x[13], 12, 0xfd987193);
  FF(c, d, a, b, x[14], 17, 0xa679438e); FF(b, c, d, a, x[15], 22, 0x49b40821);

  // Round 2
  GG(a, b, c, d, x[ 1],  5, 0xf61e2562); GG(d, a, b, c, x[ 6],  9, 0xc040b340);
  GG(c, d, a, b, x[11], 14, 0x265e5a51); GG(b, c, d, a, x[ 0], 20, 0xe9b6c7aa);
  GG(a, b, c, d, x[ 5],  5, 0xd62f105d); GG(d, a, b, c, x[10],  9,  0x2441453);
  GG(c, d, a, b, x[15], 14, 0xd8a1e681); GG(b, c, d, a, x[ 4], 20, 0xe7d3fbc8);
  GG(a, b, c, d, x[ 9],  5, 0x21e1cde6); GG(d, a, b, c, x[14],  9, 0xc33707d6);
  GG(c, d, a, b, x[ 3], 14, 0xf4d50d87); GG(b, c, d, a, x[ 8], 20, 0x455a14ed);
  GG(a, b, c, d, x[13],  5, 0xa9e3e905); GG(d, a, b, c, x[ 2],  9, 0xfcefa3f8);
  GG(c, d, a, b, x[ 7], 14, 0x676f02d9); GG(b, c, d, a, x[12], 20, 0x8d2a4c8a);

  // Round 3
  HH(a, b, c, d, x[ 5],  4, 0xfffa3942); HH(d, a, b, c, x[ 8], 11, 0x8771f681);
  HH(c, d, a, b, x[11], 16, 0x6d9d6122); HH(b, c, d, a, x[14], 23, 0xfde5380c);
  HH(a, b, c, d, x[ 1],  4, 0xa4beea44); HH(d, a, b, c, x[ 4], 11, 0x4bdecfa9);
  HH(c, d, a, b, x[ 7], 16, 0xf6bb4b60); HH(b, c, d, a, x[10], 23, 0xbebfbc70);
  HH(a, b, c, d, x[13],  4, 0x289b7ec6); HH(d, a, b, c, x[ 0], 11, 0xeaa127fa);
  HH(c, d, a, b, x[ 3], 16, 0xd4ef3085); HH(b, c, d, a, x[ 6], 23,  0x4881d05);
  HH(a, b, c, d, x[ 9],  4, 0xd9d4d039); HH(d, a, b, c, x[12], 11, 0xe6db99e5);
  HH(c, d, a, b, x[15], 16, 0x1fa27cf8); HH(b, c, d, a, x[ 2], 23, 0xc4ac5665);

  // Round 4
  II(a, b, c, d, x[ 0],  6, 0xf4292244); II(d, a, b, c, x[ 7], 10, 0x432aff97);
  II(c, d, a, b, x[14], 15, 0xab9423a7); II(b, c, d, a, x[ 5], 21, 0xfc93a039);
  II(a, b, c, d, x[12],  6, 0x655b59c3); II(d, a, b, c, x[ 3], 10, 0x8f0ccc92);
  II(c, d, a, b, x[10], 15, 0xffeff47d); II(b, c, d, a, x[ 1], 21, 0x85845dd1);
  II(a, b, c, d, x[ 8],  6, 0x6fa87e4f); II(d, a, b, c, x[15], 10, 0xfe2ce6e0);
  II(c, d, a, b, x[ 6], 15, 0xa3014314); II(b, c, d, a, x[13], 21, 0x4e0811a1);
  II(a, b, c, d, x[ 4],  6, 0xf7537e82); II(d, a, b, c, x[11], 10, 0xbd3af235);
  II(c, d, a, b, x[ 2], 15, 0x2ad7d2bb); II(b, c, d, a, x[ 9], 21, 0xeb86d391);

  state[0] += a; state[1] += b; state[2] += c; state[3] += d;

  memset(x, 0, sizeof(x));
}

/**
 * @brief Initialises an Md5Context to the standard MD5 initial values (RFC 1321 §3.3).
 *
 * Must be called before the first md5_update() call.
 * The four magic constants are the low-order 32 bits of the fractional parts
 * of the square roots of 2, 3, 5, and 7.
 *
 * @param ctx  Context to initialise.
 */
static void md5_init(Md5Context* ctx) {
  ctx->count[0] = ctx->count[1] = 0;
  ctx->state[0] = 0x67452301u;
  ctx->state[1] = 0xefcdab89u;
  ctx->state[2] = 0x98badcfeu;
  ctx->state[3] = 0x10325476u;
}

/**
 * @brief Feeds a chunk of data into an in-progress MD5 computation.
 *
 * Can be called multiple times with successive chunks of the same message.
 * Internally buffers incomplete 64-byte blocks until enough data is available
 * to call md5_transform(). The bit counter is updated on every call and
 * correctly handles overflow from the low 32-bit word to the high 32-bit word,
 * supporting inputs larger than 512 MB.
 *
 * @param ctx    Running MD5 context (must have been initialised with md5_init).
 * @param input  Pointer to the data bytes to feed in.
 * @param len    Number of bytes in input.
 */
static void md5_update(Md5Context* ctx, const uint8_t* input, size_t len) {
  uint32_t index = (ctx->count[0] >> 3) & 0x3fu;

  if ((ctx->count[0] += (uint32_t)(len << 3)) < (uint32_t)(len << 3))
    ctx->count[1]++;
  ctx->count[1] += (uint32_t)(len >> 29);

  uint32_t partLen = 64 - index;
  size_t i = 0;

  if (len >= partLen) {
    memcpy(&ctx->buffer[index], input, partLen);
    md5_transform(ctx->state, ctx->buffer);
    for (i = partLen; i + 63 < len; i += 64)
      md5_transform(ctx->state, &input[i]);
    index = 0;
  }

  memcpy(&ctx->buffer[index], &input[i], len - i);
}

/**
 * @brief Finalises the MD5 computation and writes the 16-byte digest.
 *
 * Performs the two-step RFC 1321 §3.1–3.2 finalisation:
 *   1. Appends a 0x80 byte, then zero padding, so the total message length
 *      is ≡ 56 (mod 64) bytes.
 *   2. Appends the original message length as a 64-bit little-endian integer.
 * Then runs the final md5_transform() call(s) and serialises the four
 * 32-bit state registers into a 16-byte little-endian digest.
 * The context is zeroed after use to prevent leaking hash state.
 *
 * @param ctx     Context to finalise (invalidated after this call — do not reuse).
 * @param digest  Output buffer of exactly 16 bytes to receive the raw MD5 digest.
 */
static void md5_final(Md5Context* ctx, uint8_t digest[16]) {
  uint8_t bits[8];
  for (int i = 0; i < 8; ++i)
    bits[i] = (ctx->count[i / 4] >> ((i % 4) * 8)) & 0xffu;

  uint32_t index  = (ctx->count[0] >> 3) & 0x3fu;
  uint32_t padLen = (index < 56) ? (56 - index) : (120 - index);
  md5_update(ctx, kPadding, padLen);
  md5_update(ctx, bits, 8);

  for (int i = 0; i < 4; ++i)
    for (int j = 0; j < 4; ++j)
      digest[i * 4 + j] = (ctx->state[i] >> (j * 8)) & 0xffu;

  memset(ctx, 0, sizeof(*ctx));
}

/**
 * @brief Converts raw bytes to a lowercase hex string.
 *
 * Writes exactly len*2 hex characters followed by a null terminator.
 * Caller must ensure hex points to a buffer of at least len*2 + 1 bytes.
 *
 * @param bytes  Input byte array.
 * @param len    Number of bytes to convert.
 * @param hex    Output character buffer (must be at least len*2 + 1 bytes).
 */
static void bytes_to_hex(const uint8_t* bytes, int len, char* hex) {
  static const char kHex[] = "0123456789abcdef";
  for (int i = 0; i < len; ++i) {
    hex[i * 2]     = kHex[(bytes[i] >> 4) & 0x0f];
    hex[i * 2 + 1] = kHex[bytes[i] & 0x0f];
  }
  hex[len * 2] = '\0';
}

// ---------------------------------------------------------------------------
// Exported functions (called from Dart via FFI)
// ---------------------------------------------------------------------------

/// I/O buffer size for streaming reads. 64 KB balances memory usage and
/// syscall overhead for typical file sizes.
static const size_t kIoBufferSize = 65536;

extern "C" {

/**
 * @brief Computes MD5 over the first and last N bytes of a file.
 *
 * Used as a cheap "partial fingerprint" in the duplicate detection pipeline.
 * Reading only the head and tail (rather than the whole file) is fast enough
 * to run on thousands of same-size candidates without a full read pass.
 *
 * Window behaviour:
 *   - First window : bytes [0,  min(fileSize, chunkSize))
 *   - Last window  : bytes [max(0, fileSize - chunkSize), fileSize)
 *   - When fileSize is in the range (chunkSize, 2*chunkSize), the windows
 *     overlap. Both windows are still read independently and fed into the
 *     same MD5 context — there is no short-circuit to a full read.
 *   - When fileSize <= chunkSize, both windows cover the entire file
 *     (effectively the same as md5_full for that file).
 *
 * On any I/O error, outHex is zero-filled and the function returns silently.
 *
 * @param path       Null-terminated wide-character (UTF-16) file path.
 * @param chunkSize  Number of bytes to read from each end (typically 1 MB).
 * @param outHex     Output buffer of at least 33 bytes; receives a lowercase
 *                   hex MD5 string + null terminator on success, or all zeros
 *                   on failure.
 */
void md5_partial(const wchar_t* path, int64_t chunkSize, char* outHex) {
  FILE* f = _wfopen(path, L"rb");
  if (!f) {
    memset(outHex, 0, 33);
    return;
  }

  _fseeki64(f, 0, SEEK_END);
  int64_t fileSize = _ftelli64(f);

  uint8_t* buf = static_cast<uint8_t*>(malloc(static_cast<size_t>(chunkSize)));
  if (!buf) {
    fclose(f);
    memset(outHex, 0, 33);
    return;
  }

  Md5Context ctx;
  md5_init(&ctx);

  // --- First window: bytes [0, min(fileSize, chunkSize)) ---
  int64_t firstLen = (fileSize < chunkSize) ? fileSize : chunkSize;
  if (firstLen > 0) {
    _fseeki64(f, 0, SEEK_SET);
    size_t bytesRead = fread(buf, 1, static_cast<size_t>(firstLen), f);
    if (bytesRead > 0) md5_update(&ctx, buf, bytesRead);
  }

  // --- Last window: bytes [max(0, fileSize-chunkSize), fileSize) ---
  // Read independently even when the two windows overlap.
  int64_t lastStart = fileSize - chunkSize;
  if (lastStart < 0) lastStart = 0;
  int64_t lastLen = (fileSize < chunkSize) ? fileSize : chunkSize;
  if (lastLen > 0) {
    _fseeki64(f, lastStart, SEEK_SET);
    size_t bytesRead = fread(buf, 1, static_cast<size_t>(lastLen), f);
    if (bytesRead > 0) md5_update(&ctx, buf, bytesRead);
  }

  uint8_t digest[16];
  md5_final(&ctx, digest);
  bytes_to_hex(digest, 16, outHex);

  free(buf);
  fclose(f);
}

/**
 * @brief Computes MD5 over the entire contents of a file.
 *
 * Used in the full-hash pass to confirm identity for files whose partial
 * hashes match. Streams the file in kIoBufferSize (64 KB) chunks so that
 * memory usage is constant regardless of file size.
 *
 * On any I/O error, outHex is zero-filled and the function returns silently.
 *
 * @param path    Null-terminated wide-character (UTF-16) file path.
 * @param outHex  Output buffer of at least 33 bytes; receives a lowercase
 *                hex MD5 string + null terminator on success, or all zeros
 *                on failure.
 */
void md5_full(const wchar_t* path, char* outHex) {
  FILE* f = _wfopen(path, L"rb");
  if (!f) {
    memset(outHex, 0, 33);
    return;
  }

  Md5Context ctx;
  md5_init(&ctx);

  uint8_t buf[kIoBufferSize];
  size_t bytesRead;
  while ((bytesRead = fread(buf, 1, sizeof(buf), f)) > 0) {
    md5_update(&ctx, buf, bytesRead);
  }

  uint8_t digest[16];
  md5_final(&ctx, digest);
  bytes_to_hex(digest, 16, outHex);

  fclose(f);
}

/**
 * @brief Performs a block-by-block binary identity comparison of two files.
 *
 * Used as an optional verification step after full-hash grouping. Hashes
 * can theoretically collide; a byte comparison provides mathematical certainty.
 * Files are read in kIoBufferSize (64 KB) chunks and compared with memcmp.
 * Returns as soon as a difference is found (short-circuit).
 *
 * Returns 0 (not equal) on any I/O error so that errors are treated
 * conservatively — a file that cannot be read is never reported as a duplicate.
 *
 * @param pathA  Null-terminated wide-character (UTF-16) path to the first file.
 * @param pathB  Null-terminated wide-character (UTF-16) path to the second file.
 * @return       1 if the files are byte-for-byte identical, 0 otherwise.
 */
int byte_compare(const wchar_t* pathA, const wchar_t* pathB) {
  FILE* fa = _wfopen(pathA, L"rb");
  if (!fa) return 0;
  FILE* fb = _wfopen(pathB, L"rb");
  if (!fb) { fclose(fa); return 0; }

  uint8_t bufA[kIoBufferSize];
  uint8_t bufB[kIoBufferSize];
  int result = 1;

  for (;;) {
    size_t ra = fread(bufA, 1, sizeof(bufA), fa);
    size_t rb = fread(bufB, 1, sizeof(bufB), fb);
    if (ra != rb) { result = 0; break; }
    if (ra == 0)  break; // both EOF
    if (memcmp(bufA, bufB, ra) != 0) { result = 0; break; }
  }

  fclose(fa);
  fclose(fb);
  return result;
}

} // extern "C"
