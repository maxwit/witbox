#!/usr/bin/env bash

i=1
lang_list=(gcc mcr.microsoft.com/dotnet/sdk openjdk python dart golang rust denoland/deno node swift)
for lang in ${lang_list[@]}
do
    echo "[$i/${#lang_list[@]}]. Installing $lang ..."
    docker pull $lang
	((i++))
    echo
done

