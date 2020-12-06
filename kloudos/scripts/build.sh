#! /bin/bash

###################################################################
#Sanity checks the options passed from build.sh.
###################################################################

###### exit on any script line that fails #########################
set -o errexit
###### bail on any unitialized variable reads #####################
set -o nounset
###### bail on failing commands before last pipe #################
set -o pipefail
###### Use this to ignore Errors for certian commands ###########

######Globals ####################################################

BUILD_TYPE=${1:-"--clean"} # Possible values: --incremental, --clean
BUILD_DEBUG=${2:-"--false"} # Possible values: --false, --true
BUILD_TARGET=${3:-"--client"} # Possible values: --client, --ds, --server
BUILD_VENDOR_CPU=${4:-"--intel"} # Possible values: --amd, --intel, --arm64
BUILD_VENDOR_MAIN_GPU=${5:-"--intel"} # Possible values: --amd, --intel, --nvidia
BUILD_VENDOR_SECONDARY_GPU=${6:-"--none"} # Possible values: --none, --amd, --intel, --nvidia

###############################################################################
##main()
###############################################################################

## Build def_config_name
BUILD_PREFIX_NAME=kloudos_client
BUILD_CPU_VENDOR_NAME=intel
BUILD_MAIN_GPU_VENDOR_NAME=intel
BUILD_SECONDARY_GPU_VENDOR_NAME=none
BUILD_TARGET_TYPE=release
BUILD_ARCH=64
BUILD_SEPERATOR='_'
BUILD_POSTFIX=defconfig
if [[ "$BUILD_TARGET" == "--ds" ]]; then
	BUILD_PREFIX_NAME=kloudos_ds
else
	if [[ "$BUILD_TARGET" == "--server" ]]; then
		BUILD_PREFIX_NAME=kloudos_server
	fi
fi

if [[ "$BUILD_VENDOR_CPU" == "--amd" ]]; then
	BUILD_CPU_VENDOR_NAME=amd
else
	if [[ $BUILD_VENDOR_CPU == "--arm64" ]]; then
		BUILD_CPU_VENDOR_NAME=arm64
	fi

	if [[ $BUILD_VENDOR_CPU == "--all" ]]; then
		BUILD_CPU_VENDOR_NAME=all
	fi
fi

if [[ "$BUILD_VENDOR_MAIN_GPU" == "--amd" ]]; then
	BUILD_MAIN_GPU_VENDOR_NAME=amd
else
	if [[ "$BUILD_VENDOR_MAIN_GPU" == "--nvidia" ]]; then
		BUILD_MAIN_GPU_VENDOR_NAME=nvidia
	fi

	if [[ "$BUILD_VENDOR_MAIN_GPU" == "--all" ]]; then
		BUILD_MAIN_GPU_VENDOR_NAME=all
	fi
fi

if [[ "$BUILD_DEBUG" == "--true" ]]; then
	BUILD_TARGET_TYPE=debug
fi

if [[ "$BUILD_VENDOR_SECONDARY_GPU" == "--amd" ]]; then
	BUILD_SECONDARY_GPU_VENDOR_NAME=amd
else
	if [[ "$BUILD_VENDOR_SECONDARY_GPU" == "--nvidia" ]]; then
		BUILD_SECONDARY_GPU_VENDOR_NAME=nvidia
	fi

	if [[ "$BUILD_VENDOR_SECONDARY_GPU" == "--all" ]]; then
		BUILD_SECONDARY_GPU_VENDOR_NAME=all
	fi
fi

BUILD_DEF_CONFIG_NAME=$BUILD_PREFIX_NAME$BUILD_SEPERATOR$BUILD_ARCH$BUILD_SEPERATOR$BUILD_CPU_VENDOR_NAME$BUILD_SEPERATOR$BUILD_MAIN_GPU_VENDOR_NAME$BUILD_SEPERATOR$BUILD_SECONDARY_GPU_VENDOR_NAME$BUILD_SEPERATOR$BUILD_TARGET_TYPE$BUILD_SEPERATOR$BUILD_POSTFIX

if [[ $BUILD_TYPE == "--clean" ]]; then
        cd ../
        rm linux-* || true
        cd -
	rm -rf debian
	git checkout debian
	rm -rf fs
	git checkout fs
	if [[ -e .config ]]; then
		echo "Removing Config..."
		rm .config
		make clean || true
	fi

	echo "Starting Clean Build" $BUILD_DEF_CONFIG_NAME
	chmod a+x debian/rules
	chmod a+x debian/scripts/*
	chmod a+x debian/scripts/misc/*
	KCONFIG_ALLCONFIG=arch/x86/configs/$BUILD_DEF_CONFIG_NAME make allnoconfig
	make -j `getconf _NPROCESSORS_ONLN` deb-pkg LOCALVERSION=-kloudos
else
	echo "Starting Incremental Build"
	make -j `getconf _NPROCESSORS_ONLN` bindeb-pkg LOCALVERSION=-kloudos
fi

#LANG=C fakeroot debian/rules binary-headers binary-generic binary-perarch
