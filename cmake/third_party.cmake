
include_directories("${IOTJS_ROOT_DIR}/include")
include_directories("${IOTJS_ROOT_DIR}/iotjs/include")

set(items
    libiotjs.a

    libtomcrypt.a

    libevent.a
    libevent_pthreads.a
    libevent_openssl.a

    libwolfssl.a
)
foreach(item ${items})
    list(APPEND target_libs
        "${IOTJS_ROOT_DIR}/libs/${item}"
    )
endforeach()

find_package(Threads REQUIRED)
if (NOT CMAKE_USE_PTHREADS_INIT)
    message(FATAL_ERROR "Failed to find Pthreads")
endif()
list(APPEND target_libs ${CMAKE_THREAD_LIBS_INIT})