#!/bin/sh
cp web/index.html site/
dart compile wasm -O4 web/main.dart -o site/main.wasm