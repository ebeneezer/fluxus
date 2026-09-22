cmake_minimum_required(VERSION 3.24)

project(fluxus VERSION 0.3.0 LANGUAGES CXX)

include(CTest)

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/assets/fluxus-icon-256.png"
    "${CMAKE_CURRENT_SOURCE_DIR}/package/contents/icons/fluxus.png"
    COPYONLY
)

add_subdirectory(native/backend)

if(BUILD_TESTING)
    find_package(Qt6 REQUIRED COMPONENTS Core)
    add_executable(test_diskstats tests/test_diskstats.cpp)
    target_compile_features(test_diskstats PRIVATE cxx_std_20)
    add_test(NAME diskstats COMMAND test_diskstats)
    add_executable(test_diskdevices tests/test_diskdevices.cpp)
    target_compile_features(test_diskdevices PRIVATE cxx_std_20)
    target_link_libraries(test_diskdevices PRIVATE Qt6::Core)
    add_test(NAME diskdevices COMMAND test_diskdevices)
    find_package(Qt6 REQUIRED COMPONENTS Gui Qml Quick)
    add_executable(test_graphpreview tests/test_graphpreview.cpp
        native/backend/src/trafficgraph.cpp native/backend/src/trafficgraph.h
        native/backend/src/networksource.cpp native/backend/src/networksource.h)
    set_target_properties(test_graphpreview PROPERTIES AUTOMOC ON)
    target_compile_features(test_graphpreview PRIVATE cxx_std_20)
    target_link_libraries(test_graphpreview PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick)
    add_test(NAME graphpreview COMMAND test_graphpreview)
    set_tests_properties(graphpreview PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
endif()
