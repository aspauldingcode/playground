#!/bin/sh
set -eu

mkdir -p .build
cmake -S . -B .build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build .build
sh install.sh
