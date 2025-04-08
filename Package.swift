// swift-tools-version: 5.4

import PackageDescription

let package = Package(
	name: "TextClippingKit",
	products: [
		.library(
			name: "TextClippingKit",
			targets: ["TextClippingKit"]),
	],
	targets: [
		.target(
			name: "TextClippingKit"),
		.testTarget(
			name: "TextClippingKitTests",
			dependencies: ["TextClippingKit"],
			resources: [
				.process("resources"),
			]
		),
	]
)
