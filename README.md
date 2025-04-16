A small Snake game made with Dart to try compilation to WebAssembly.

Uses [`package:web`](https://pub.dev/packages/web)
to interop with JS and the DOM.
It work when compiled to JavaScript as well as WebAssembly.

## Running and building

To run the app in JavaScript mode,
activate and use [`package:webdev`](https://dart.dev/tools/webdev):

At the time of publication webdev doesn't support serving WASM directly.

```
dart pub global activate webdev
webdev serve
```

To build a production WASM version ready for deployment,
use the `build2wasm` command:

```
sh build2wasm.sh
```

To build a production JavaScript version ready for deployment,
use the `webdev build` command:

```
webdev build
```
