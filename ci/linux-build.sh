#!/bin/bash
set -ex

export ROOT_DIR=$(pwd)

if [ "${COMPILER}" == "clang" ]; then
    export LIBCXX_PACKAGES="libc++-11-dev libc++abi-11-dev"
    sudo apt-get update -q
    sudo apt-get install ${LIBCXX_PACKAGES} -y
fi

if [ "${GENERATOR}" == "Ninja" ]; then
    sudo apt-get update -q
    sudo apt-get install ninja-build -y
fi

mkdir -p build
cd build

cmake -DCMAKE_INSTALL_PREFIX="${ROOT_DIR}/build/install" -G "${GENERATOR}" ..
cmake --build .
cmake --build . --target package

mv external-0.1.1-Linux.tar.bz2 "${ROOT_DIR}/external-${PLATFORM}-${COMPILER}.tar.bz2"
