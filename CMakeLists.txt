cmake_minimum_required(VERSION 3.24)

project(fluxus VERSION 0.2.0 LANGUAGES CXX)

include(CTest)

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/assets/fluxus-icon-256.png"
    "${CMAKE_CURRENT_SOURCE_DIR}/package/contents/icons/fluxus.png"
    COPYONLY
)

add_subdirectory(native/backend)

if(BUILD_TESTING)
    add_executable(test_diskstats tests/test_diskstats.cpp)
    target_compile_features(test_diskstats PRIVATE cxx_std_20)
    add_test(NAME diskstats COMMAND test_diskstats)
endif()
