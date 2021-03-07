#!/bin/bash

#======================================================================================================================
# https://github.com/ophub/amlogic-s9xxx-openwrt
# Description: Automatically Packaged OpenWrt for Amlogic S9xxx STB
# Function: Use Flippy's amlogic-s9xxx kernel files to build kernel
# Copyright (C) 2020 Flippy
# Copyright (C) 2020 https://github.com/ophub/amlogic-s9xxx-openwrt
#======================================================================================================================
#
# example: ~/*/amlogic-s9xxx/amlogic-kernel/build_kernel/
# ├── flippy
# │   ├── boot-5.9.5-flippy-48+.tar.gz
# │   ├── amlogic-dtb-5.9.5-flippy-48+.tar.gz
# │   └── modules-5.9.5-flippy-48+.tar.gz
# └── make_use_kernel.sh
#
# Usage: Use Ubuntu 18 LTS 64-bit
# 01. Log in to the home directory of the local Ubuntu system.
# 02. git clone https://github.com/ophub/amlogic-s9xxx-openwrt.git
# 03. cd ~/*/amlogic-s9xxx/amlogic-kernel/build_kernel/
# 04. Prepare Flippy's ${build_boot}, ${build_dtb} & ${build_modules} three files. 
# 05. Put this three files into ${flippy_folder}
# 06. Modify ${flippy_version} to kernel version. E.g: flippy_version="5.9.5-flippy-48+"
#     If the files of ${flippy_version} is not found, Will search for other files in the ${flippy_folder} directory.
# 07. Run: sudo ./make_use_kernel.sh
# 08. The generated files path: ~/*/amlogic-s9xxx/amlogic-kernel/kernel/${build_save_folder}
#
# Tips: If run 'sudo ./make_use_kernel.sh' is 'Command not found'. Run: sudo chmod +x make_use_kernel.sh
#
#======================================================================================================================

# Modify Flippy's kernel folder & version
build_path=${PWD}
flippy_folder=${build_path}/"flippy"
flippy_version="5.9.5-flippy-48+"

# Default setting ( Don't modify )
build_tmp_folder=${build_path}/"build_tmp"
build_boot="boot-${flippy_version}.tar.gz"
build_dtb="amlogic-dtb-${flippy_version}.tar.gz"
build_modules="modules-${flippy_version}.tar.gz"
build_save_folder=${flippy_version%-flippy*}
amlogic_path=${build_path%/amlogic-kernel*}

# echo color codes
echo_color() {
    this_color=${1}
        case "${this_color}" in
        red)
            echo -e " \033[1;31m[ ${2} ]\033[0m ${3}"
            echo -e "--------------------------------------------"
            echo -e "Current path -PWD-:-----------------\n${PWD}"
            echo -e "Situation -lsblk-:----------------\n$(lsblk)"
            echo -e "Directory file list -ls-:----------\n$(ls .)"
            echo -e "--------------------------------------------"
            exit 1
            ;;
        green)
            echo -e " \033[1;32m[ ${2} ]\033[0m ${3}"
            ;;
        yellow)
            echo -e " \033[1;33m[ ${2} ]\033[0m ${3}"
            ;;
        blue)
            echo -e " \033[1;34m[ ${2} ]\033[0m ${3}"
            ;;
        purple)
            echo -e " \033[1;35m[ ${2} ]\033[0m ${3}"
            ;;
        *)
            echo -e " \033[1;30m[ ${2} ]\033[0m ${3}"
            ;;
        esac
}

# Check files
check_build_files() {
    echo "Check files ..."
    if   [ -f "${flippy_folder}/${build_boot}" -a -f "${flippy_folder}/${build_dtb}" -a -f "${flippy_folder}/${build_modules}" ]; then

        echo_color "blue" "(1/7) The specified file exists." "USE: ${build_boot} and other files to start compiling ..."

    elif [ $( ls ${flippy_folder}/*.tar.gz -l 2>/dev/null | grep "^-" | wc -l ) -ge 3 ]; then

        unset flippy_version && unset build_save_folder && unset build_boot && unset build_dtb && unset build_modules

        if  [ $( ls ${flippy_folder}/boot-*.tar.gz -l 2>/dev/null | grep "^-" | wc -l ) -ge 1 ]; then
            build_boot=$( ls ${flippy_folder}/boot-*.tar.gz | head -n 1 ) && build_boot=${build_boot##*/}
            flippy_version=${build_boot/boot-/} && flippy_version=${flippy_version/.tar.gz/}
            build_save_folder=${flippy_version%-flippy*}
            build_save_folder=$(echo ${build_save_folder} | grep -oE '^[1-9].[0-9]{1,2}.[0-9]+')
        else
            echo_color "red" "(1/7) Error: Have no boot-*.tar.gz file found in the ${flippy_folder} directory." "..."
        fi

        if  [ -f ${flippy_folder}/amlogic-dtb-${flippy_version}.tar.gz ]; then
            build_dtb="amlogic-dtb-${flippy_version}.tar.gz"
        else
            echo_color "red" "(1/7) Error: Have no amlogic-dtb-*.tar.gz file found in the ${flippy_folder} directory." "..."
        fi

        if  [ -f ${flippy_folder}/modules-${flippy_version}.tar.gz ]; then
            build_modules="modules-${flippy_version}.tar.gz"
        else
            echo_color "red" "(1/7) Error: Have no modules-*.tar.gz file found in the ${flippy_folder} directory." "..."
        fi

        echo_color "yellow" "(1/7) Unset flippy_version, build_save_folder, build_boot, build_dtb and build_modules."  "\n \
        Try to using this files to building the kernel: \n \
        flippy_version: ${flippy_version} \n \
        build_save_folder: ${build_save_folder} \n \
        build_boot: ${build_boot} \n \
        build_dtb: ${build_dtb} \n \
        build_modules: ${build_modules}"

    else
        echo_color "red" "(1/7) Error: Please put the compiled files in the [ ${flippy_folder} ] directory." "..."
    fi

    # begin run the script
    echo_color "purple" "Start building"  "${build_save_folder}: kernel.tar.xz & modules.tar.xz ..."
    echo_color "green" "(1/4) End check_build_files"  "..."
}

# build kernel.tar.xz
build_kernel() {
     [ -d ${build_tmp_folder} ] && rm -rf ${build_tmp_folder} 2>/dev/null
     mkdir -p ${build_tmp_folder}/kernel/Temp_kernel/dtb/amlogic
     mkdir -p ${build_save_folder}

     cp -rf ${flippy_folder}/${build_boot} ${build_tmp_folder}/kernel
     cp -rf ${flippy_folder}/${build_dtb} ${build_tmp_folder}/kernel
     sync

  cd ${build_tmp_folder}/kernel
     echo_color "blue" "Start Unzip ${build_boot}"  "..."
     if [ "${build_boot##*.}"c = "gz"c ]; then
        tar -xzf ${build_boot}
     elif [ "${build_boot##*.}"c = "xz"c ]; then
        tar -xJf ${build_boot}
     else
        echo_color "red" "(2/4) Error build_kernel ${build_boot}"  "The suffix of ${build_boot} must be .tar.gz or .tar.xz ..."
     fi

     [ -f config-${flippy_version} ] && cp -f config* Temp_kernel/ || echo_color "red" "(2/4) config* does not exist" "..."
     [ -f initrd.img-${flippy_version} ] && cp -f initrd.img* Temp_kernel/ || echo_color "red" "(2/4) initrd.img* does not exist" "..."
     [ -f System.map-${flippy_version} ] && cp -f System.map* Temp_kernel/ || echo_color "red" "(2/4) System.map* does not exist" "..."
     [ -f uInitrd-${flippy_version} ] && cp -f uInitrd* Temp_kernel/uInitrd || echo_color "red" "(2/4) uInitrd* does not exist" "..."
     [ -f vmlinuz-${flippy_version} ] && cp -f vmlinuz* Temp_kernel/zImage || echo_color "red" "(2/4) vmlinuz* does not exist" "..."
     sync

     echo_color "blue" "Start Unzip ${build_dtb}"  "..."
     if [ "${build_dtb##*.}"c = "gz"c ]; then
        tar -xzf ${build_dtb}
     elif [ "${build_dtb##*.}"c = "xz"c ]; then
        tar -xJf ${build_dtb}
     else
        echo_color "red" "(2/4) Error build_kernel"  "The suffix of ${build_dtb} must be .tar.gz or .tar.xz ..."
     fi

     echo_color "blue" "(2/4) Start Copy ${build_dtb} files"  "..."
     [ -f meson-gxl-s905d-phicomm-n1.dtb ] && cp -rf *.dtb Temp_kernel/dtb/amlogic/ || echo_color "yellow" "(2/4) All *.dtb files does not exist." "..."
     sync

  cd ${build_tmp_folder}/kernel/Temp_kernel/dtb/amlogic/
     if [ ! -f meson-gxl-s905d-phicomm-n1.dtb ]; then
        cp -f ${amlogic_path}/amlogic-dtb/*phicomm-n1* .
        echo_color "yellow" "(3/7) The phicomm-n1 .dtb files is Missing. Has been copied from the dtb library!" "..."
     fi

     if [ ! -f meson-sm1-x96-max-plus-100m.dtb ]; then
        cp -f ${amlogic_path}/amlogic-dtb/*x96-max* .
        echo_color "yellow" "(3/7) The X96 .dtb core files is Missing. Has been copied from the dtb library!" "..."
     fi

     if [ ! -f meson-sm1-hk1box-vontar-x3.dtb ]; then
        cp -f ${amlogic_path}/amlogic-dtb/*hk1box* .
        echo_color "yellow" "(3/7) Some HX1 .dtb files is Missing. Has been copied from the dtb library!" "..."
     fi

     if [ ! -f meson-sm1-h96-max-x3.dtb ]; then
        cp -f ${amlogic_path}/amlogic-dtb/*h96-max* .
        echo_color "yellow" "(3/7) Some H96 .dtb files is Missing. Has been copied from the dtb library!" "..."
     fi

     if [ ! -f meson-gxm-octopus-planet.dtb ]; then
        cp -f ${amlogic_path}/amlogic-dtb/*octopus* .
        echo_color "yellow" "(3/7) The octopus-planet .dtb files is Missing. Has been copied from the dtb library!" "..."
     fi

     if [ ! -f meson-g12b-gtking-pro.dtb ]; then
        cp -f ${amlogic_path}/amlogic-dtb/*gtking* .
        echo_color "yellow" "(3/7) The gtking .dtb files is Missing. Has been copied from the dtb library!" "..."
     fi

     if [ ! -f meson-g12b-ugoos-am6.dtb ]; then
        cp -f ${amlogic_path}/amlogic-dtb/*ugoos* .
        echo_color "yellow" "(3/7) The ugoos .dtb files is Missing. Has been copied from the dtb library!" "..."
     fi

     sync

  cd ${build_tmp_folder}/kernel/Temp_kernel
     echo_color "blue" "(2/4) Start zip kernel.tar.xz"  "..."
     tar -cf kernel.tar *
     xz -z kernel.tar
     mv -f kernel.tar.xz ${build_path}/${build_save_folder} && sync

     echo_color "green" "(2/4) End build_kernel"  "The save path is ${build_save_folder}/kernel.tar.xz ..."
}

# build modules.tar.xz
build_modules() {
  cd ${build_path}
     rm -rf ${build_tmp_folder} && sync
     mkdir -p ${build_tmp_folder}/modules/lib/modules
     cp -rf ${flippy_folder}/${build_modules} ${build_tmp_folder}/modules/lib/modules
     #Add drivers
     cp -rf ${amlogic_path}/common-files/patches/wireless/* ${build_tmp_folder}/modules/lib/modules/*/kernel/drivers/net/wireless/
     sync

  cd ${build_tmp_folder}/modules/lib/modules

     echo_color "blue" "(3/4) Start Unzip ${build_modules}"  "..."
     if [ "${build_modules##*.}"c = "gz"c ]; then
        tar -xzf ${build_modules}
     elif [ "${build_modules##*.}"c = "xz"c ]; then
        tar -xJf ${build_modules}
     else
        echo_color "red" "(3/4) Error build_modules"  "The suffix of ${build_modules} must be .tar.gz or .tar.xz ..."
     fi

  cd ${flippy_version}
     rm -f *.ko
     x=0
     find ./ -type f -name '*.ko' -exec ln -s {} ./ \;
     sync && sleep 3
     x=$( ls *.ko -l 2>/dev/null | grep "^l" | wc -l )
     
     if [ $x -eq 0 ]; then
        echo_color "red" "(3/4) Error *.ko Files not found"  "..."
     else
        echo_color "blue" "(3/4) Have [ ${x} ] files make *.ko link"  "..."
     fi

  cd ${build_tmp_folder}/modules/lib/modules
     rm -f ${build_modules}

  cd ${build_tmp_folder}/modules/
     echo_color "blue" "(3/4) Start zip modules.tar.xz"  "..."
     tar -cf modules.tar *
     xz -z modules.tar
     mv -f modules.tar.xz ${build_path}/${build_save_folder} && sync

     echo_color "green" "(3/4) End build_modules"  "The save path is ${build_save_folder}/modules.tar.xz ..."
}

# copy kernel.tar.xz & modules.tar.xz to amlogic-s9xxx/amlogic-kernel/kernel/${build_save_folder}
copy_kernel_modules() {
     cd ${build_path}

     cp -rf ${build_save_folder} ../kernel/ && sync
     rm -rf ${build_tmp_folder} ${build_save_folder} ${flippy_folder}/* 2>/dev/null

     echo_color "green" "(4/4) End copy_kernel_modules"  "Copy ${build_save_folder}/kernel.tar.xz & modules.tar.xz to ../kernel/"
}

check_build_files
build_kernel
build_modules
copy_kernel_modules

echo_color "purple" "Build completed"  "${build_save_folder} ..."
# end run the script

