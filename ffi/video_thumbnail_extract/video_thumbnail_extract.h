// thumbnail.h
#pragma once

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

#include <stdint.h>

extern "C" {
    EXPORT uint8_t* extract_thumbnail(const char* video_path, int* out_size);
    EXPORT void free_buffer(uint8_t* buffer);
}