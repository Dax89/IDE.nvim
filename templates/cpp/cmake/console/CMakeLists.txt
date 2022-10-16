cmake_minimum_required(VERSION 3.11 FATAL_ERROR)
project(:name: LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)

option(ENABLE_ASAN "Enable Address Sanitizer" OFF)

# set(CPM_USE_LOCAL_PACKAGES ON)
#include(cmake/CPM.cmake) # https://github.com/TheLartians/CPM.cmake

# CPMAddPackage("uri#tag")

# CPMAddPackage(
#     NAME
#     GIT_REPOSITORY
#     GIT_TAG
#     VERSION
#     OPTIONS
#     )

file(GLOB_RECURSE INCLUDES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/include/*.h")
file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp")

add_executable(${PROJECT_NAME} ${INCLUDES} ${SOURCES})

set_target_properties(
    ${PROJECT_NAME} PROPERTIES
    CXX_STANDARD 17
    )

target_include_directories(
  ${PROJECT_NAME} PUBLIC
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
)

if(CMAKE_BUILD_TYPE MATCHES "Debug") # Enforce warnings as errors if not in Release mode
    if(MSVC)
        target_compile_options(${PROJECT_NAME} PUBLIC /W3 /WX /permissive)
        if(ENABLE_ASAN)
            target_compile_options(${PROJECT_NAME} PRIVATE /fsanitize=address)
        endif()
    else()
        target_compile_options(${PROJECT_NAME} PUBLIC -Wall -Werror -Wextra -Wno-error=extra -Wshadow -pedantic)
        if(ENABLE_ASAN)
            target_compile_options(${PROJECT_NAME} PRIVATE -fno-omit-frame-pointer -fsanitize=address)
            target_link_libraries(${PROJECT_NAME} PRIVATE -fsanitize=address)
        endif()
    endif()
endif()
