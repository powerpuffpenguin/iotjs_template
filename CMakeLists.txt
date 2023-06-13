cmake_minimum_required(VERSION 3.0)

set(target_name iotjs_template)
set(target_definitions) # define
set(target_sources "${CMAKE_SOURCE_DIR}/src/main.c") # *.c
set(target_libs) # library

project(${target_name})
list(APPEND target_definitions
    "-DVM_IOTJS_OS=\"${VM_IOTJS_OS}\""
    "-DVM_IOTJS_ARCH=\"${VM_IOTJS_ARCH}\""
)


if(LINK_STATIC_GLIC)
    set(CMAKE_EXE_LINKER_FLAGS "-static")
endif()
set(CMAKE_C_FLAGS "-std=gnu99")

include(${CMAKE_SOURCE_DIR}/cmake/third_party.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/source.cmake)

list(APPEND target_libs
    -lm
)

add_definitions(${target_definitions})
add_executable(${target_name} ${target_sources})
target_link_libraries(${target_name} ${target_libs})
