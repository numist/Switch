// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ShortcutRecorder",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v10_11)
    ],
    products: [
        .library(name: "ShortcutRecorder", targets: ["ShortcutRecorder"])
    ],
    targets: [
        .target(
            name: "ShortcutRecorder",
            exclude: [
                "Info.plist",
                "Resources/ShortcutRecorder.sketch",
                "Resources/export-ShortcutRecorder-slices.py"
            ],
            resources: [
                .process("Resources"),
                .copy("../../LICENSE.txt"),
                .copy("../../ATTRIBUTION.md"),
            ],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "ShortcutRecorderTests",
            dependencies: ["ShortcutRecorder"],
            exclude: [
                "Info.plist"
            ]
        )
    ]
)
