# Papyrus

For client or shared targets (iOS, macOS, etc) you'll also add the alchemy package as a dependency, but depend on products `Fusion` and/or `Papyrus`.

```swift
dependencies: [
    .package(url: "https://github.com/joshuawright11/alchemy", .branch("master"))
    ...
],
targets: [
    // A library for sharing code between client & server
    .target(name: "MySharedLibrary", dependencies: [
        .product(name: "Fusion", package: "alchemy"),
        .product(name: "Papyrus", package: "alchemy"),
    ]),
]
```

If you'd like your client to request endpoints on a `Papyrus` interface through Alamofire, add `PapyrusAlamofire` to your client target's dependencies instead of `Papyrus`; likely through `File` -> `Swift Packages` -> `Add Package Dependency`.

_Next page: [Database: Basics](4a_DatabaseBasics.md)_