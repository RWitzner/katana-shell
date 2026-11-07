// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KatanaShell",
    platforms: [.macOS(.v14)],
    products: [
        // The views: sidebar, Katana pane, task page and the window that holds them.
        .library(name: "KatanaShell", targets: ["KatanaShell"]),
        // A runnable app that shows the views with made-up content and fake behaviour.
        .executable(name: "KatanaShellDemo", targets: ["KatanaShellDemo"]),
    ],
    targets: [
        .target(name: "KatanaShell"),
        .executableTarget(
            name: "KatanaShellDemo",
            dependencies: ["KatanaShell"],
            resources: [.process("Resources")]
        ),
    ]
)
