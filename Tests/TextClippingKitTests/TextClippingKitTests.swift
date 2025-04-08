import Testing
import Foundation

#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

@testable import TextClippingKit

@Test func basicLoad() async throws {

	let url = try resourceURL(for: "first.textClipping")
	let ts = try TextClipping(fileURL: url)

	#expect(ts.utf8 != nil)
	#expect(ts.utf8?.contains("PAL.CommonError") ?? false)
}

@Test func basicLoadWithImages() async throws {
	let url = try resourceURL(for: "second.textClipping")
	let ts = try TextClipping(fileURL: url)

	#expect(ts.utf8 != nil)
	#expect(ts.utf8?.contains("FreeDOS") ?? false)
}

@Test func createSaveReload() async throws {
	do {
		let orig = try TextClipping.Encode("This is a test")
		let ts = try TextClipping(data: orig)
		#expect(ts.utf8 == "This is a test")
		#expect("This is a test" == ts.rtf?.string)
		#expect(ts.html != nil)
	}

	do {
		let ats = NSAttributedString(
			string: "This is a test",
			attributes: [
				.foregroundColor: NSColor.red
			])

		try TextClipping.Encode(ats, to: URL(fileURLWithPath: "/tmp/super.textClipping"))
	}
}

@Test func emojiSupport() async throws {
	let orig = try resourceTextClipping(for: "third.textClipping")

	let expectedRawText = #""ABCD🥶🫥""#

	#expect(orig.utf8 == expectedRawText)
	#expect(orig.utf16 == expectedRawText)
	#expect(orig.rtf?.string == expectedRawText)
}
