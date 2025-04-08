@testable import TextClippingKit
import Foundation

enum TestErrors: Error {
	case cannotUnwrap
}

func Unwrap<T>(_ item: T?) throws -> T {
	guard let item else { throw TestErrors.cannotUnwrap }
	return item
}

/// Locate the URL for the specified resource name
func resourceURL(for name: String) throws -> URL {
	let encoded = try Unwrap(name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed))
	let core = try Unwrap(URL(string: encoded))
	let extn = core.pathExtension
	let name = core.deletingPathExtension().path
	return try Unwrap(Bundle.module.url(forResource: name, withExtension: extn))
}

/// Convenience for loading a text cliiping from a resource
func resourceTextClipping(for name: String) throws -> TextClipping {
	let fileURL = try resourceURL(for: name)
	return try TextClipping(fileURL: fileURL)
}
