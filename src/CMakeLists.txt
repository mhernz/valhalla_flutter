# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

if (APPLE)
    set(CMAKE_THREAD_LIBS_INIT "-lpthread")
    set(CMAKE_HAVE_THREADS_LIBRARY 1)
    set(CMAKE_USE_WIN32_THREADS_INIT 0)
    set(CMAKE_USE_PTHREADS_INIT 1)
    set(THREADS_PREFER_PTHREAD_FLAG ON)
    set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE $ENV{VCPKG_ROOT}/scripts/toolchains/ios.cmake)
endif()

set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake"
    CACHE STRING "vcpkg toolchain file")

project(valhalla_flutter_library VERSION 0.0.1 LANGUAGES C CXX)

add_library(valhalla_flutter SHARED
  "valhalla_actor.cpp"
  "valhalla_actor.h"
)

# valhalla_mobile --------------------------------------------------------------

set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ language version to use (default is 17)")
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(ENABLE_TOOLS OFF)
set(ENABLE_DATA_TOOLS OFF)
set(ENABLE_PYTHON_BINDINGS OFF)
set(ENABLE_HTTP OFF)
set(ENABLE_SERVICES OFF)
set(ENABLE_TESTS OFF)
# workaround until we fix iOS date library
set(ENABLE_SINGLE_FILES_WERROR OFF)

# Configure OSX
if (APPLE)
    message(STATUS "Configured for APPLE")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -lpthread -Wno-shorten-64-to-32 -Wno-sign-compare")

    # tvOS and watchOS modifications
    if(CMAKE_OSX_SYSROOT MATCHES ".*watchos.*" OR CMAKE_OSX_SYSROOT MATCHES ".*appletvos.*")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DPOCO_NO_FORK_EXEC=1")
    endif()

    # Configure the date library
    set(BUILD_TZ_LIB ON CACHE INTERNAL "")
    set(MANUAL_TZ_DB ON CACHE INTERNAL "")
endif()

find_package(absl CONFIG REQUIRED)
find_package(protobuf CONFIG REQUIRED)
set(protobuf_BUILD_STATIC_LIBS ON CACHE INTERNAL "")
set(Protobuf_INCLUDE_DIR ${protobuf_SOURCE_DIR}/src)
set(Protobuf_LIBRARIES protobuf::libprotobuf-lite)
find_package(Boost REQUIRED)
find_package(robin_hood CONFIG REQUIRED)
find_package(RapidJSON CONFIG REQUIRED)

# link_libraries(robin_hood::robin_hood)
# include_directories(${ROBIN_HOOD_INCLUDE_DIRS})

# link_libraries(rapidjson)
# include_directories(${RAPIDJSON_INCLUDE_DIRS})

# link_libraries(Boost::boost)
# include_directories(${Boost_INCLUDE_DIRS})

add_subdirectory(valhalla/third_party/date date)
# link_libraries(date)
# include_directories(${Date_INCLUDE_DIRS})

add_subdirectory(valhalla)

# Valhalla source directory
set(VALHALLA_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/valhalla)
set(VALHALLA_BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/valhalla)
set_property(DIRECTORY valhalla PROPERTY VALHALLA_SOURCE_DIR ${VALHALLA_SOURCE_DIR})
set_property(DIRECTORY valhalla PROPERTY VALHALLA_BUILD_DIR ${VALHALLA_BUILD_DIR})

target_link_libraries(valhalla_flutter
    PRIVATE
    ${Protobuf_LIBRARIES}
    absl::base
    absl::log
    absl::strings
    absl::status
    Boost::boost
    ${DATE_LIBRARY}
    robin_hood::robin_hood
    Boost::boost
    rapidjson
    date
    valhalla
)

target_include_directories(valhalla_flutter
    PRIVATE
    # ${Boost_INCLUDE_DIRS}
    ${VALHALLA_SOURCE_DIR}/valhalla
)

function(install_vcpkg_libs_wildcard pattern)
    file(GLOB LIBS_TO_INSTALL
         "${CMAKE_BINARY_DIR}/vcpkg_installed/${VCPKG_TARGET_TRIPLET}/lib/${pattern}.a")
    install(FILES ${LIBS_TO_INSTALL}
            DESTINATION "${CMAKE_INSTALL_PREFIX}/lib")
endfunction()

function(install_vcpkg_libs)
    foreach(lib ${ARGN})
        install(FILES
            "${CMAKE_BINARY_DIR}/vcpkg_installed/${VCPKG_TARGET_TRIPLET}/lib/${lib}.a"
            DESTINATION "${CMAKE_INSTALL_PREFIX}/lib"
        )
    endforeach()
endfunction()

if (APPLE)
    install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/valhalla/third_party/date/include
            DESTINATION ${CMAKE_INSTALL_PREFIX})

    install(DIRECTORY ${Boost_INCLUDE_DIRS}
            DESTINATION ${CMAKE_INSTALL_PREFIX}
            COMPONENT development)

    install_vcpkg_libs(liblz4 libprotobuf-lite)
    install_vcpkg_libs_wildcard("libabsl*")
    install_vcpkg_libs_wildcard("libutf8*")
endif()

# # end VALHALLA_MOBILE ----------------------------------------------------------

set_target_properties(valhalla_flutter PROPERTIES
    PUBLIC_HEADER valhalla_actor.h
    OUTPUT_NAME "valhalla_flutter"
)

if (APPLE)
    set_target_properties(valhalla_flutter PROPERTIES
        FRAMEWORK TRUE
        FRAMEWORK_VERSION C
        MACOSX_FRAMEWORK_IDENTIFIER com.mateoeh.valhalla_flutter
        # MACOSX_FRAMEWORK_INFO_PLIST Info.plist
    # "current version" in semantic format in Mach-O binary file
        VERSION 1.0.0
    # "compatibility version" in semantic format in Mach-O binary file
        SOVERSION 1.0.0
        PUBLIC_HEADER valhalla_actor.h
        # XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "iPhone Developer"
    )
else()
    target_compile_definitions(valhalla_flutter PUBLIC DART_SHARED_LIB)

    if (ANDROID)
        # Support Android 15 16k page size
        target_link_options(valhalla_flutter PRIVATE "-Wl,-z,max-page-size=16384")
    endif()
endif()

install(TARGETS
        valhalla_flutter
        DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)