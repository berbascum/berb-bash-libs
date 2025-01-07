#!/bin/bash

## Script increase the package version add update the strings where needed
#
# Version 0.0.1
#
# Upstream-Name: berb-bash-libs
# Source: https://github.com/berbascum/berb-bash-libs
#
# Copyright (C) 2025 Berbascum <berbascum@ticv.cat>
# All rights reserved.
#
# BSD 3-Clause License


## Get the berb-tools full path which is three dirs up
start_dir=$(pwd)
berb_tools_fullpath=${start_dir}
for i in {1..3}; do
    berb_tools_fullpath=$(dirname "${berb_tools_fullpath}")
done


## Get vars
current_lib_relpath_file=$(find libs/modules -name "*_lib-main.sh")
current_lib_relpath=$(dirname "${current_lib_relpath_file}")
current_lib_basename=$(basename "${current_lib_relpath_file}")
current_lib_long=$(echo "${current_lib_basename}" | awk -F'-' '{print $1}')
current_lib_short=$(echo "${current_lib_basename}" | awk -F'-' '{print $1}' | awk -F'_' '{print $2}')
current_version=$(cat ${current_lib_relpath_file} | awk -F'"' '/TOOL_VERSION=/ {print $2}')
current_version_int=$(echo ${current_version} | sed 's/\.//g')


echo "current_lib_relpath_file: ${current_lib_relpath_file}"
echo "current_lib_relpath: ${current_lib_relpath}"
echo "current_lib_basename: ${current_lib_basename}"

echo "current_lib_long: ${current_lib_long}"
echo "current_lib_short: ${current_lib_short}"
echo "current_version: ${current_version}"
echo "current_version_int: ${current_version_int}"

## Set the version string


## Update pkg_rootfs
pkg_rootfs_relpath="pkg_rootfs/usr/lib/berb-bash-libs"
[ -f "${pkg_rootfs_relpath}/${current_lib_long}_${current_version_int}" ] \
    || mv -v ${pkg_rootfs_relpath}/${current_lib_long}_* \
   ${pkg_rootfs_relpath}/${current_lib_long}_${current_version_int}
cat ${current_lib_relpath_file} > ${pkg_rootfs_relpath}/${current_lib_long}_${current_version_int}
## Update version in control Package
sed -i \
    "s/^Package: bbl-${current_lib_short}-lib.*/Package: bbl-${current_lib_short}-lib-${current_version_int}/g" \
    debian/control
#Package: bbl-git-lib

## Update lib version in berb-tools
berb_tools_list_fullpath_file="${berb_tools_fullpath}/berb-bash-libs/berb-tools.lst"
[ -f "${berb_tools_list_fullpath_file}" ] || echo "${berb_tools_list} not exist"; exit 1
while IFS= read -r line; do
    berb_tool_name=${line}
    ## Update version in the berb-tools main scripts
    sed -i \
        "s/bbl_${current_lib_short}_version=.*/bbl_${current_lib_short}_version=${current_version_int}/g" \
        ${berb_tools_fullpath}/${berb_tool_name}/${berb_tool_name}-bin-main.sh
    ## Update version in the berb-tools debian controls
    sed -i \
        "s/bbl-${current_lib_short}-lib (.*/bbl-${current_lib_short}-lib (\>= ${current_version}\),/g" \
        ${berb_tools_fullpath}/${berb_tool_name}/debian/control
    #arr_berb_tools_lst+=("$line")
done < "${berb_tools_list_fullpath_file}"
