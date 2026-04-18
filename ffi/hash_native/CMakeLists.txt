cmake_minimum_required(VERSION 3.14)

add_library(hash_native SHARED
  hash_native.cpp
)

target_compile_features(hash_native PRIVATE cxx_std_17)

target_compile_definitions(hash_native PRIVATE
  UNICODE
  _UNICODE
)

install(TARGETS hash_native
  RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
)
