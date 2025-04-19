#!/bin/sh
cp web/index.html web/main.dart.js site/
dart compile wasm -O4 web/main.dart -o site/main.wasm