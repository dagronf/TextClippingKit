//
//  Copyright © 2025 Darren Ford. All rights reserved.
//
//  MIT license
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial
//  portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
//  WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
//  OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
//  OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// A wrapper around Apple's textClipping format
public struct TextClipping {
	/// The UTI for a textclipping file
	public static let utTypeString = "com.apple.finder.textclipping"
	/// The expected file extension for the text clipping file
	public static let fileExtension = "textclipping"


#if canImport(UniformTypeIdentifiers)
	/// The uniform type identifier for this type
	@available(macOS 11.0, *)
	static let utType = UTType(Self.utTypeString)!
#endif

	/// UTF8 content
	public private(set) var utf8: String?
	/// UTF16 content
	public private(set) var utf16: String?
	/// RTF content
	public private(set) var rtf: NSAttributedString?
	/// RTFD content
	public private(set) var rtfd: NSAttributedString?
	/// HTML content
	public private(set) var html: String?
	/// WebArchive content
	public private(set) var webarchive: Data?

	/// Load a textClipping from the contents of a file
	/// - Parameter fileURL: The url containing the text clipping
	public init(fileURL: URL) throws {
		guard let s = InputStream(url: fileURL) else {
			throw TextClippingErrors.cannotLoad
		}
		try self.init(inputStream: s)
	}

	/// Load a textClipping from raw data
	/// - Parameter data: The data containing the text clipping
	public init(data: Data) throws {
		try self.init(inputStream: InputStream(data: data))
	}

	/// Load a textClipping from an input stream
	/// - Parameter inputStream: The stream containing the text clipping
	///
	/// This function opens the input stream before reading
	public init(inputStream: InputStream) throws {
		inputStream.open()
		do {
			let s = try PropertyListSerialization.propertyList(with: inputStream, format: nil)
			self.content = try Unwrap(s as? NSDictionary)
			self.utiData = try Unwrap(self.content["UTI-Data"] as? NSDictionary)
		}
		catch {
			throw TextClippingErrors.cannotLoad
		}

		self.decode()
	}

	// private
	private let content: NSDictionary
	private let utiData: NSDictionary
}

// MARK: - Decoding

public extension TextClipping {
	mutating func decode() {
		// utf8
		self.utf8 = self.utiData["public.utf8-plain-text"] as? String

		// utf16
		if let data = self.utiData["public.utf16-plain-text"] as? Data,
			let rawString = NSString(data: data, encoding: NSUTF16LittleEndianStringEncoding)
		{
			self.utf16 = rawString as String
		}

		// rtf
		if let str = self.utiData["public.rtf"] as? String,
			let data = str.data(using: .utf8)
		{
			self.rtf = try? NSAttributedString(data: data, documentAttributes: nil)
		}

		// rtfd
		if let data = self.utiData["com.apple.flat-rtfd"] as? Data {
			self.rtfd = try? NSAttributedString(data: data, documentAttributes: nil)
		}

		// html
		if let data = self.utiData["public.html"] as? Data {
			self.html = String(data: data, encoding: .utf8)
		}

		// webarchive
		self.webarchive = self.utiData["com.apple.webarchive"] as? Data
	}
}

// MARK: - Encoding

public extension TextClipping {
	/// Encode the supplied string to a .textClipping representation
	/// - Parameter string: The string to encode
	/// - Returns: textClipping data
	static func Encode(_ string: String) throws -> Data {
		let utiData = NSMutableDictionary()
		Self.insertUtf8Encoded(utiData, string: string)
		Self.insertUtf16Encoded(utiData, string: string)
		Self.insertRtfEncoded(utiData, string: string)
		Self.insertHtmlEncoded(utiData, string: string)

		let result = NSMutableDictionary()
		result["UTI-Data"] = utiData

		return try PropertyListSerialization.data(
			fromPropertyList: result,
			format: .binary,
			options: 0
		)
	}

	/// Encode an attributed string to a textClipping
	/// - Parameters:
	///   - attributedString: The attributed string to write
	///   - fileURL: The file URL to write to
	static func Encode(_ string: String, to fileURL: URL) throws {
		let data = try Self.Encode(string)
		try data.write(to: fileURL)

		try FileManager.default.setAttributes([
			FileAttributeKey.hfsTypeCode : "clpt"
			],
			ofItemAtPath: fileURL.path
		)
	}
}

public extension TextClipping {
	/// Encode the supplied attributed string to a .textClipping representation
	/// - Parameter attributedString: The string to encode
	/// - Returns: textClipping data
	static func Encode(_ attributedString: NSAttributedString) throws -> Data {
		let utiData = NSMutableDictionary()
		Self.insertUtf8Encoded(utiData, string: attributedString.string)
		Self.insertUtf16Encoded(utiData, string: attributedString.string)
		Self.insertRtfEncoded(utiData, attributedString: attributedString)
		Self.insertHtmlEncoded(utiData, attributedString: attributedString)

		let result = NSMutableDictionary()
		result["UTI-Data"] = utiData

		return try PropertyListSerialization.data(
			fromPropertyList: result,
			format: .binary,
			options: 0
		)
	}

	/// Encode an attributed string to a textClipping
	/// - Parameters:
	///   - attributedString: The attributed string to write
	///   - fileURL: The file URL to write to
	static func Encode(_ attributedString: NSAttributedString, to fileURL: URL) throws {
		let data = try Self.Encode(attributedString)
		try data.write(to: fileURL)
	}
}

// MARK: Encoding support

private extension TextClipping {
	private static func insertUtf8Encoded(_ utiData: NSMutableDictionary, string: String) {
		if let utf8Data = string.data(using: .utf8) {
			utiData["public.utf8-plain-text"] = NSString(data: utf8Data, encoding: NSUTF8StringEncoding)
		}
	}

	private static func insertUtf16Encoded(_ utiData: NSMutableDictionary, string: String) {
		if let utf16Data = string.data(using: .utf16LittleEndian) {
			utiData["public.utf16-plain-text"] = utf16Data as NSData
		}
	}

	private static func insertRtfEncoded(_ utiData: NSMutableDictionary, string: String) {
		do {
			let rtf = NSAttributedString(string: string)
			let rtfData = try rtf.data(
				from: NSRange(location: 0, length: rtf.length),
				documentAttributes: [
					.documentType: NSAttributedString.DocumentType.rtf,
				]
			)
			let rtfs = NSString(data: rtfData, encoding: NSUTF8StringEncoding)
			utiData["public.rtf"] = rtfs
		}
		catch {
			// ignore
		}
	}

	private static func insertRtfEncoded(_ utiData: NSMutableDictionary, attributedString: NSAttributedString) {
		do {
			let rtfData = try attributedString.data(
				from: NSRange(location: 0, length: attributedString.length),
				documentAttributes: [
					.documentType: NSAttributedString.DocumentType.rtf,
				]
			)
			let rtfs = NSString(data: rtfData, encoding: NSUTF8StringEncoding)
			utiData["public.rtf"] = rtfs
		}
		catch {
			// ignore
		}
	}

	private static func insertHtmlEncoded(_ utiData: NSMutableDictionary, string: String) {
		// HTML
		do {
			let rtf = NSAttributedString(string: string)
			let rtfData = try rtf.data(
				from: NSRange(location: 0, length: rtf.length),
				documentAttributes: [
					.documentType: NSAttributedString.DocumentType.html,
				]
			)
			utiData["public.html"] = rtfData
		}
		catch {
			// ignore
		}
	}

	private static func insertHtmlEncoded(_ utiData: NSMutableDictionary, attributedString: NSAttributedString) {
		// HTML
		do {
			let rtfData = try attributedString.data(
				from: NSRange(location: 0, length: attributedString.length),
				documentAttributes: [
					.documentType: NSAttributedString.DocumentType.html,
				]
			)
			utiData["public.html"] = rtfData
		}
		catch {
			// ignore
		}
	}
}
