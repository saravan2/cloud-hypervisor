#!/usr/bin/env bash

WORKLOADS_DIR="$HOME/workloads"

mkdir -p "$WORKLOADS_DIR"

build_edk2() {
    EDK2_BUILD_DIR="$WORKLOADS_DIR/edk2_build"
    EDK2_REPO="https://github.com/tianocore/edk2.git"
    EDK2_DIR="$EDK2_BUILD_DIR/edk2"
    EDK2_PLAT_REPO="https://github.com/tianocore/edk2-platforms.git"
    EDK2_PLAT_DIR="$EDK2_BUILD_DIR/edk2-platforms"
    ACPICA_REPO="https://github.com/acpica/acpica.git"
    ACPICA_DIR="$EDK2_BUILD_DIR/acpica"
    export WORKSPACE="$EDK2_BUILD_DIR"
    export PACKAGES_PATH="$EDK2_DIR:$EDK2_PLAT_DIR"
    export IASL_PREFIX="$ACPICA_DIR/generate/unix/bin/"

    if [ ! -d "$EDK2_BUILD_DIR" ]; then
        mkdir -p "$EDK2_BUILD_DIR"
    fi

    # Prepare source code
    checkout_repo "$EDK2_DIR" "$EDK2_REPO" master "8ba02634ecaa6ff5d0edcea266198f42eca90c53"
    pushd "$EDK2_DIR" || exit
    git submodule update --init
    popd || exit
    checkout_repo "$EDK2_PLAT_DIR" "$EDK2_PLAT_REPO" master "8227e9e9f6a8aefbd772b40138f835121ccb2307"
    checkout_repo "$ACPICA_DIR" "$ACPICA_REPO" master "446be438238e9d339eed5182b807ac5f82df56c9"

    if [[ ! -f "$EDK2_DIR/.built" ||
        ! -f "$EDK2_PLAT_DIR/.built" ||
        ! -f "$ACPICA_DIR/.built" ]]; then
        pushd "$EDK2_BUILD_DIR" || exit
        # Build
        make -C acpica -j "$(nproc)"
        # shellcheck disable=SC1091
        source edk2/edksetup.sh
        make -C edk2/BaseTools -j "$(nproc)"
        build -a AARCH64 -t GCC5 -p ArmVirtPkg/ArmVirtCloudHv.dsc -b RELEASE -n 0
        if cp Build/ArmVirtCloudHv-AARCH64/RELEASE_GCC5/FV/CLOUDHV_EFI.fd "$WORKLOADS_DIR"; then
            touch "$EDK2_DIR"/.built
            touch "$EDK2_PLAT_DIR"/.built
            touch "$ACPICA_DIR"/.built
        else
            echo "Failed to produce aarch64 UEFI firmware. Built markers not created."
            exit 1
        fi
        popd || exit
    fi
}
