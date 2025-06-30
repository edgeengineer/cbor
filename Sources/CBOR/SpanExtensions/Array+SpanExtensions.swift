// Array+SpanExtensions.swift
// Extensions to Array for Swift 6.2's Span support

#if compiler(>=6.2)

// Add Array extensions to provide span
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, *)
@available(swift 6.2)
extension Array where Element == UInt8 {
    /// Decode CBOR directly from an array
    func decodeCBOR() throws(CBORError) -> CBOR {
        return try CBOR.decode(self)
    }
}

#endif