#!/usr/bin/env bash

DIR=./src

find $DIR -type f -iname "*.sas" -exec \
    sed -i -e 's/\n\n\n\n/\n<p>/g' -e 's/``/<code>/g' \
    -e 's/`;/<\/code>/g' -e 's/
