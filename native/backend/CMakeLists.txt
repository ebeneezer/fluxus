cmake_minimum_required(VERSION 3.24)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

set(FLUXUS_PACKAGE_IMPORT_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}/../../package/contents/imports/de/idoc/fluxus/backend"
)

add_library(fluxusbackendplugin MODULE
    src/fluxusbackendplugin.cpp
    src/networksource.cpp
    src/networksource.h
    src/diskstats.h
    src/trafficgraph.cpp
    src/trafficgraph.h
)

target_link_libraries(fluxusbackendplugin
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Qml
        Qt6::Quick
)

target_compile_options(fluxusbackendplugin PRIVATE
    $<$<CXX_COMPILER_ID:GNU,Clang>:-Wall -Wextra -Wpedantic>
)

set_target_properties(fluxusbackendplugin PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${FLUXUS_PACKAGE_IMPORT_DIR}"
)
