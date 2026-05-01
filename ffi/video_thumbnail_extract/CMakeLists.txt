cmake_minimum_required(VERSION 3.14)

add_library(video_thumbnail_extract SHARED
        video_thumbnail_extract.cpp
)

target_compile_features(video_thumbnail_extract PRIVATE cxx_std_17)

target_compile_definitions(video_thumbnail_extract PRIVATE
        UNICODE
        _UNICODE
        _CRT_SECURE_NO_WARNINGS   # suppress MSVC deprecation warning for _wfopen
)

install(TARGETS video_thumbnail_extract
        RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
)
