cmake_minimum_required(VERSION 3.24)

project(fluxus VERSION 0.1.1 LANGUAGES CXX)

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/assets/fluxus-icon-256.png"
    "${CMAKE_CURRENT_SOURCE_DIR}/package/contents/icons/fluxus.png"
    COPYONLY
)

add_subdirectory(native/backend)
