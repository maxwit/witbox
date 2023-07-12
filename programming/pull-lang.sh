#!/usr/bin/env bash

i=1
lang_list=(gcc mcr.microsoft.com/dotnet/sdk dart golang openjdk denoland/deno node rust swift)
for lang in ${lang_list[@]}
do
    echo "[$i/${#lang_list[@]}] Installing $lang ..."
    docker pull $lang
    ((i++))
    echo
done

