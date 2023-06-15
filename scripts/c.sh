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
    command_flags -t bool -d 'Embedding bundle.js' \
        -v bundle -s b
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
c_find(){
    local ifs=$IFS
    IFS=$'\n'
    files=(`find "$1" -name "$2"`)
    IFS=$ifs
}
c_bundle(){
    c_find "bin/src" "*.ts"
    local sum0="bin/bundle.0.sum"
    local sum="bin/bundle.sum"
    echo > "$sum0"
    for file in "${files[@]}";do
        md5sum "$file" >> "$sum0"
    done
    if [[ -f "$sum" ]];then
        local v0=(`md5sum "$sum0"`)
        local v1=(`md5sum "$sum"`)
        if [[ "$v0" == "$v1" ]];then
            return
        fi
    fi
    webpack
    cp "$sum0" "$sum"
}
c_execute(){
    core_call_assert time_unix
    local start=$result
    if [[ $bundle == true ]];then
        log_info "webpack"
        time_unix
        used=$result
        c_bundle
        time_since $used
        log_info "webpack, used ${result}s"

        echo "#ifndef MY_IOTJS_BIN_BUNDLE_XXD_H" > "src/bundle.h"
        echo "#define MY_IOTJS_BIN_BUNDLE_XXD_H" >> "src/bundle.h"
        xxd -i "bin/bundle.js" >> "src/bundle.h"
        echo "#endif // MY_IOTJS_BIN_BUNDLE_XXD_H" >> "src/bundle.h"
    fi

    local target="${os}_$arch"
    local iotjs_arch=$arch
    local cmake_args=(
        -DCMAKE_SYSTEM_NAME=Linux
    )
    if [[ $bundle == true ]];then
        cmake_args=(
            -DIOTJS_BUNDLE=ON
        )
    fi
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