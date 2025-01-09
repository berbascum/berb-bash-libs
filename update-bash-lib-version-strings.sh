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

## Load bbl
bbl_general_version=1101
bbl_git_version=1231

start_dir=$(pwd)

source /usr/lib/berb-bash-libs/bbl_general_lib_${bbl_general_version}
source /usr/lib/berb-bash-libs/bbl_git_lib_${bbl_git_version}

LOG_FULLPATH="./"
LOG_FILE="update-bash-lib-version-strings.log"

## git dir related checks
fn_bblgit_dir_is_git
fn_bblgit_workdir_status_check


## Check for --version-str=0.0.0.0 flag
## default if both str and auto are supplied
flag_name="version-str" fn_bbgl_check_args_search_flag $@
debug "$(basename $0): FLAG_FOUND_VALUE = \"${FLAG_FOUND_VALUE}\""
version_str_supplied=${FLAG_FOUND_VALUE}
info "$(basename $0): build_release_supplied: \"${FLAG_FOUND_VALUE}\""
## Check for --version-auto=1-4 flag
flag_name="version-auto" fn_bbgl_check_args_search_flag $@
debug "$(basename $0): FLAG_FOUND_VALUE = \"${FLAG_FOUND_VALUE}\""
version_auto_supplied=${FLAG_FOUND_VALUE}
info "$(basename $0): build_release_supplied: \"${FLAG_FOUND_VALUE}\""
echo "$(basename $0): version_str_supplied ${version_str_supplied}"
echo "$(basename $0): version_auto_supplied: ${version_auto_supplied}"
## default: version_mode=str
version_mode=""
if [ -n "${version_str_supplied}" ]; then
    version_mode=str
elif [ -n "${version_auto_supplied}" ]; then
    version_mode=auto
fi


## Get vars
current_lib_relpath_file=$(find . -maxdepth 1 -name "*_lib-main.sh")
current_lib_relpath=$(dirname "${current_lib_relpath_file}")
current_lib_basename=$(basename "${current_lib_relpath_file}")
current_lib_long=$(echo "${current_lib_basename}" | awk -F'-' '{print $1}')
current_lib_short=$(echo "${current_lib_basename}" | awk -F'-' '{print $1}' | awk -F'_' '{print $2}')
#echo "current_lib_relpath_file: ${current_lib_relpath_file}"
current_version=$(cat ${current_lib_relpath_file} | awk -F'"' '/TOOL_VERSION=/ {print $2}')
current_version_int=$(echo ${current_version} | sed 's/\.//g')


echo "$(basename $0): current_lib_relpath_file: ${current_lib_relpath_file}"
echo "$(basename $0): current_lib_relpath: ${current_lib_relpath}"
echo "$(basename $0): current_lib_basename: ${current_lib_basename}"

echo "$(basename $0): current_lib_long: ${current_lib_long}"
echo "$(basename $0): current_lib_short: ${current_lib_short}"
echo "$(basename $0): current_version: ${current_version}"
echo "$(basename $0): current_version_int: ${current_version_int}"

## Set the version string

if [ "${version_mode}" == "str" ]; then
    new_version_str=${version_str_supplied}
elif [ "${version_mode}" == "auto" ]; then
    version_position=${version_auto_supplied}
    ## TODO: use a int 1-4 to increment a position
    ## from the version string digits
elif [ -n "${current_version}" ]; then
    echo "$(basename $0): current_version is: \"${current_version}\""
    ASK "Type a valid string for a new version: "
    new_version_str=${answer}
fi


[ -n "${new_version_str}" ] || error "$(basename $0): new_version_str not defined"

new_version_int=$(echo ${new_version_str} | sed 's/\.//g')

## Update the version on the lib-main
info "Updating TOOL_VERSION: ${current_lib_relpath_file}"
sed -i \
    "s/TOOL_VERSION=.*/TOOL_VERSION=\"${new_version_str}\"/g" \
    ${current_lib_relpath_file}
info "Updating TOOL_VERSION_INT: ${current_lib_relpath_file}"
sed -i \
    "s/TOOL_VERSION_INT=.*/TOOL_VERSION_INT=\"${new_version_int}\"/g" \
    ${current_lib_relpath_file}

## Update pkg_rootfs
pkg_rootfs_relpath="pkg_rootfs/usr/lib/berb-bash-libs"
[ -f "${pkg_rootfs_relpath}/${current_lib_long}_${new_version_int}" ] \
    || mv -v ${pkg_rootfs_relpath}/${current_lib_long}_* \
   ${pkg_rootfs_relpath}/${current_lib_long}_${new_version_int}
cat ${current_lib_relpath_file} > ${pkg_rootfs_relpath}/${current_lib_long}_${new_version_int}
## Update version in control Package
sed -i \
    "s/^Package: bbl-${current_lib_short}-lib.*/Package: bbl-${current_lib_short}-lib-${new_version_int}/g" \
    debian/control
#Package: bbl-git-lib

## Update lib version in berb-tools
## Get berb-tools full path which is three dirs up
berb_tools_fullpath=${start_dir}
for i in {1..3}; do
    berb_tools_fullpath=$(dirname "${berb_tools_fullpath}")
done
berb_tools_list_fullpath_file="${berb_tools_fullpath}/berb-bash-libs/berb-tools.lst"
[ -f "${berb_tools_list_fullpath_file}" ] || (echo "${berb_tools_list} not exist"; exit 1)

while IFS= read -r line; do
    berb_tool_name=${line}
    ## Update version in the berb-tools main scripts
    sed -i \
        "s/bbl_${current_lib_short}_version=.*/bbl_${current_lib_short}_version=${new_version_int}/g" \
        ${berb_tools_fullpath}/${berb_tool_name}/${berb_tool_name}-bin-main.sh
    ## Update version in the berb-tools debian controls
    sed -i \
        "s/bbl-${current_lib_short}-lib (.*/bbl-${current_lib_short}-lib (\>= ${new_version}\),/g" \
        ${berb_tools_fullpath}/${berb_tool_name}/debian/control
    #arr_berb_tools_lst+=("$line")
done < "${berb_tools_list_fullpath_file}"
