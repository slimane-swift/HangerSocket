import PackageDescription

let package = Package(
    name: "WS",
    dependencies: [
        .Package(url: "https://github.com/slimane-swift/Hanger.git", majorVersion: 0, minor: 1),
        .Package(url: "https://github.com/noppoMan/Crypto.git", majorVersion: 0, minor: 2)
    ]
)
