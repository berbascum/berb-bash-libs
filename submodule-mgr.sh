#!/bin/bash

## Script to add or update berb-bash-libs submodules
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


[ ! -d ".git" ] && echo "$(basename $0): Not a git repo" && exit

fn_submodule_url_set() {
    module_url="https://github.com/berbascum/bbl-${bbl_lib_name_short}-lib"
}

fn_check_args() {
arg_found=""
    for arg_supplied in $@; do
        arg_found="$(echo "${arg_supplied}" \
            | grep "\-\-${arg_name}=" \
            | awk -F'=' '{print $2}')"
        #echo "arg_found: $arg_name = $arg_found"
        [ -n "${arg_found}" ] && break
    done
}

## Check --branch-name arg
arg_name=branch-name && fn_check_args $@
branch_name="${arg_found}"
[ -n "${arg_found}" ] || (echo "$(basename $0): Missing --${arg_name}=<name> flag"; exit 1)

## Check --bbl-lib-name arg
arg_name=bbl-lib-name && fn_check_args $@
bbl_lib_name_short=${arg_found}
[ -n "${arg_found}" ] || (echo "$(basename $0): Missing --${arg_name}=<name> flag"; exit 1)

## Check --command arg
arg_name=action && fn_check_args $@
action="${arg_found}"
[ -n "${arg_found}" ] || (echo "$(basename $0): Missing --${arg_name}=<add>|<update> flag"; exit 1)

## Check if branch_name exist in origin
fn_submodule_url_set
branch_found_origin=$(git ls-remote --heads ${module_url} | grep "${branch_name}" | awk -F'/' '{print $NF}')
[ "${branch_found_origin}" == "${branch_name}" ] || (echo "$(basename $0): The supplied branch does not exist in origin"; exit 1)


echo  "branch_name = ${branch_name}"
echo  "bbl_lib_name_short = ${bbl_lib_name_short}"
echo  "branch_found_origin = ${branch_found_origin}"

## Exec the supplied action
case ${action} in
    add)
        git submodule add -b ${branch_name} \
            ${module_url} \
            modules/bbl-${bbl_lib_name_short}-lib \
            && git commit -S -m "(submodule) bbl-${bbl_lib_name_short}-lib: add"
            ;;
    update)
        git submodule update \
            --init --recursive --remote
            ;;
esac
