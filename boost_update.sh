#!/usr/bin/bash

enf_url=git@github.com:AntelopeIO/boost.git
boost_url=git@github.com:boostorg/boost.git

enf_repo="$(mktemp -d)"
boost_repo="$(mktemp -d)"

enf_subs="libs/accumulators libs/algorithm libs/align libs/any libs/array libs/asio libs/assert libs/assign libs/atomic libs/beast libs/bimap libs/bind libs/chrono libs/circular_buffer libs/concept_check libs/config libs/container libs/container_hash libs/context libs/conversion libs/core libs/coroutine libs/date_time libs/describe libs/detail libs/dll libs/dynamic_bitset libs/endian libs/exception libs/fiber libs/filesystem libs/foreach libs/format libs/function libs/function_types libs/functional libs/fusion libs/graph libs/graph_parallel libs/hana libs/headers libs/integer libs/interprocess libs/intrusive libs/io libs/iostreams libs/iterator libs/json libs/lambda libs/lexical_cast libs/locale libs/lockfree libs/log libs/logic libs/math libs/move libs/mp11 libs/mpi libs/mpl libs/multi_index libs/multiprecision libs/nowide libs/numeric/conversion libs/optional libs/parameter libs/phoenix libs/pool libs/predef libs/preprocessor libs/process libs/program_options libs/property_map libs/property_tree libs/proto libs/ptr_container libs/python libs/random libs/range libs/ratio libs/rational libs/regex libs/serialization libs/signals2 libs/smart_ptr libs/spirit libs/static_assert libs/static_string libs/system libs/test libs/thread libs/throw_exception libs/timer libs/tokenizer libs/tti libs/tuple libs/type_index libs/type_traits libs/typeof libs/unordered libs/utility libs/variant libs/variant2 libs/wave libs/winapi libs/xpressive more tools/auto_index tools/bcp tools/boost_install tools/boostdep tools/build tools/check_build tools/cmake tools/docca tools/inspect tools/litre tools/quickbook"

cleanup () {
    echo "cleanup"
    rm -fr $enf_repo
    rm -fr $boost_repo
}

trap cleanup EXIT

## get boost repo and strip it from what we don't need
function get_boost_repo() {
    ## ----- get boost repo at the right tag
    git clone $boost_url $boost_repo
    cd $boost_repo
    git checkout $1 || { echo "Invalid boost tag: $1" >&2; exit 1; }
    
    ## ----- get the submodules we want
    for i in ${enf_subs}; do git submodule update --init --recursive -- ${i}; done
    
    ## ----- remove stuff we don't need
    echo "remove stuff we don't need..." >&2
    find . -name doc -o -name test -o -name tests -o -name example -o -name examples -o -name bench | grep -v "libs/test" | xargs rm -fr
    rm -fr status more
    
    ## ----- strip this directory from all git info
    echo "stripping git info..." >&2
    find . -name .git\* | xargs rm -fr
}

function get_enf_repo() {
    git clone $enf_url $enf_repo
    cd $enf_repo
    if [ $(git tag -l "$1") ]; then
        echo "Tag already exists in enf boost repo: $1" >&2; exit 1;
    fi
}

## update ENF repo with latest boost tag
function update_enf_repo() {
    cd $enf_repo  || { echo "Can't cd to: $enf_repo" >&2; exit 1; }
    git checkout main

    ## ----- remove all existing files except for the .git
    rm -fr *
    cp -pr ${boost_repo}/* .
    cp $2 .
    git add -A
    git commit -m "changes from boost tag: $1" || { echo "commit failed" >&2; exit 1; }
    git remote add origin $enf_url
    git tag $1
    git push -u --tags origin main
    
}


if [[ $# -ne 1 ]]; then
    echo "usage example: boost_update.sh boost-1.82.0"
fi

update_script="$(pwd)/$(dirname -- "${BASH_SOURCE[0]}")/$(basename "$0")"

get_enf_repo $1
get_boost_repo $1
update_enf_repo $1 $update_script

echo "All set, friend"

