#!/bin/bash
define_command(){
    command_begin --name c \
    --short 'build *.c' \
    --func c_execute
    local cmd=$result

    command_flags -t string -d 'Build arch' \
        -v arch \
        -V amd64 -V arm -V csky \
        -D amd64
    command_flags -t string -d 'Build os' \
        -v os \
        -V linux \
        -D linux
    command_flags -t string -d 'GCC toolchain path' \
        -v toolchain \
        -D "/usr"

    command_flags -t bool -d 'Delete build' \
        -v delete -s d
    command_flags -t bool -d 'Execute cmake' \
        -v cmake -s c
    command_flags -t bool -d 'Execute make' \
        -v make -s m
    command_flags -t string -d 'set CMAKE_BUILD_TYPE' \
        -v build_type -l build-type \
        -V None -V Debug -V Release -V RelWithDebInfo -V MinSizeRel \
        -D Release

    command_commit
    result=$cmd
}
define_command

c_iotjs(){
    cd "$rootDir/../iotjs/dst/$target"
    local iotjs_root_dir=`pwd`
    cd "$rootDir/$dir"
        
    if [[ $cmake == true ]];then
        log_info "cmake for $target"
        local args=(cmake ../../
            -DCMAKE_BUILD_TYPE=$build_type
            -DVM_IOTJS_OS=$os
            -DVM_IOTJS_ARCH=$iotjs_arch
            "-DIOTJS_ROOT_DIR=$iotjs_root_dir"
        )
        args+=("${cmake_args[@]}")
        log_info "${args[@]}"
        "${args[@]}"
    fi
    if [[ $make == true ]];then
        log_info "make for $target"
        make
    fi
}
c_execute(){
    core_call_assert time_unix
    local start=$result

    local target="${os}_$arch"
    local iotjs_arch=$arch
    local cmake_args=(
        -DCMAKE_SYSTEM_NAME=Linux
    )
    local wolfssl_host
    case "$target" in
        linux_csky)
            export CC="$toolchain/bin/csky-linux-gcc"
            cmake_args+=(
                "-DLINK_STATIC_GLIC=ON"
                "-DCMAKE_C_COMPILER=$toolchain/bin/csky-linux-gcc"
                "-DCMAKE_CXX_COMPILER=$toolchain/bin/csky-linux-g++"
            )
        ;;
        linux_arm)
            export CC="$toolchain/bin/arm-linux-gnueabihf-gcc"
            wolfssl_host=arm-linux
            cmake_args+=(
                "-DCMAKE_C_COMPILER=$toolchain/bin/arm-linux-gnueabihf-gcc"
                "-DCMAKE_CXX_COMPILER=$toolchain/bin/arm-linux-gnueabihf-g++"
            )
        ;;
        linux_amd64)
            wolfssl_host=x86_64-linux
            export CC="$toolchain/bin/gcc"
            cmake_args+=(
                "-DCMAKE_C_COMPILER=$toolchain/bin/gcc"
                "-DCMAKE_CXX_COMPILER=$toolchain/bin/g++"
            )
        ;;
        *)
            log_fatal "unknow target: '$target'"
        ;;
    esac
    local dir="dst/$target"
    if [[ $delete == true ]];then
        if [[ -d "$dir" ]];then
            log_info "delete cache '$dir'"
            rm "$dir" -rf
        fi
    fi
    if [[ $cmake == true ]] || [[ $make == true ]];then
        if [[ ! -d "$dir" ]];then
            mkdir "$dir" -p
        fi
        c_iotjs
    fi
    core_call_assert time_since "$start"
    local used=$result
    log_info "success, used ${used}s"
}