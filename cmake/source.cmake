set(dirs
    src/modules
)
include_directories("${CMAKE_SOURCE_DIR}/src")
foreach(dir ${dirs})
    file(GLOB  files 
        "${CMAKE_SOURCE_DIR}/${dir}/*.c"
    )
    list(APPEND target_sources
        "${files}"
    )
endforeach()