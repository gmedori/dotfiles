import Foundation

/// The JSON that `prepare` and `create` print, with snake_case keys.
enum JSON {
	/// `value` as pretty-printed JSON with sorted, snake_case keys.
	static func encode(_ value: some Encodable) throws -> String {
		let encoder = JSONEncoder()
		encoder.keyEncodingStrategy = .convertToSnakeCase
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
		guard let json = try String(bytes: encoder.encode(value), encoding: .utf8) else {
			preconditionFailure("JSONEncoder wrote JSON that isn't UTF-8.")
		}

		return json
	}

	/// A decoder for the JSON that `encode(_:)` writes.
	static func decoder() -> JSONDecoder {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		return decoder
	}
}
