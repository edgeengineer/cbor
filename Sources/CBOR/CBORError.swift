// MARK: - Error Types

/// Errors that can occur during CBOR encoding and decoding.
/// 
/// These errors provide detailed information about what went wrong during
/// CBOR processing operations, helping developers diagnose and fix issues
/// in their CBOR data or usage of the CBOR API.
public enum CBORError: Error {
    /// The input data is not valid CBOR.
    /// 
    /// This error occurs when the decoder encounters data that doesn't conform to
    /// the CBOR specification (RFC 8949). This could be due to corrupted data,
    /// incomplete data, or data encoded with a different format entirely.
    case invalidCBOR
    
    /// Expected a specific type but found another.
    /// 
    /// This error occurs when trying to decode a CBOR value as a specific type,
    /// but the actual type of the value doesn't match the expected type.
    /// - Parameters:
    ///   - expected: The type that was expected (e.g., "String", "Int", "Array")
    ///   - actual: The actual type that was found in the CBOR data
    case typeMismatch(expected: String, actual: String)
    
    /// Array index out of bounds.
    /// 
    /// This error occurs when attempting to access an element in a CBOR array
    /// using an index that is outside the valid range for the array.
    /// - Parameters:
    ///   - index: The requested index that was attempted to be accessed
    ///   - count: The actual number of elements in the array (valid indices are 0..<count)
    case outOfBounds(index: Int, count: Int)
    
    /// Required key missing from map.
    /// 
    /// This error occurs when trying to decode a CBOR map into a Swift struct or class,
    /// but a required key is not present in the map.
    /// - Parameter key: The name of the missing key
    case missingKey(String)
    
    /// Value conversion failed.
    /// 
    /// This error occurs when a CBOR value cannot be converted to the requested Swift type,
    /// even though the CBOR type is compatible with the requested type.
    /// - Parameter message: A description of what went wrong during the conversion
    case valueConversionFailed(String)
    
    /// Invalid UTF-8 string data.
    /// 
    /// This error occurs when decoding a CBOR text string that contains invalid UTF-8 sequences.
    /// All CBOR text strings must contain valid UTF-8 data according to the specification.
    case invalidUTF8
    
    /// Integer overflow during encoding/decoding.
    /// 
    /// This error occurs when a CBOR integer value is too large to fit into the
    /// corresponding Swift integer type (e.g., trying to decode a UInt64.max into an Int).
    case integerOverflow
    
    /// Tag value is not supported.
    /// 
    /// This error occurs when the decoder encounters a CBOR tag that is not supported
    /// by the current implementation.
    /// - Parameter tag: The unsupported tag number
    case unsupportedTag(UInt64)
    
    /// Reached end of data while decoding.
    /// 
    /// This error occurs when the decoder unexpectedly reaches the end of the input data
    /// before completing the decoding of a CBOR value. This typically indicates truncated
    /// or incomplete CBOR data.
    case prematureEnd
    
    /// Invalid initial byte for CBOR item.
    /// 
    /// This error occurs when the decoder encounters an initial byte that doesn't
    /// correspond to a valid CBOR major type or data item.
    /// - Parameter byte: The invalid initial byte value
    case invalidInitialByte(UInt8)
    
    /// Length of data is too large.
    /// 
    /// This error occurs when a CBOR string, array, or map has a length that is too large
    /// to be processed by the current implementation, typically due to memory constraints.
    /// - Parameter length: The length value that exceeded the implementation's limits
    case lengthTooLarge(UInt64)
    
    /// Indefinite length encoding is not supported for this type.
    /// 
    /// This error occurs when the decoder encounters indefinite length encoding for a type
    /// that doesn't support it in the current implementation.
    case indefiniteLengthNotSupported

    /// Extra data was found after decoding the top-level CBOR value.
    /// 
    /// This error occurs when the decoder successfully decodes a complete CBOR value
    /// but finds additional data afterward. This typically indicates that the input
    /// contains multiple concatenated CBOR values when only one was expected.
    case extraDataFound
}

@_unavailableInEmbedded
extension CBORError: CustomStringConvertible {
    /// A human-readable description of the error.
    public var description: String {
        switch self {
        case .invalidCBOR:
            return "Invalid CBOR data: The input does not conform to the CBOR specification (RFC 8949)"
        case .typeMismatch(let expected, let actual):
            return "Type mismatch: expected \(expected), found \(actual)"
        case .outOfBounds(let index, let count):
            return "Array index out of bounds: attempted to access index \(index), but array only contains \(count) elements (valid indices are 0..<\(count))"
        case .missingKey(let key):
            return "Missing key: required key '\(key)' was not found in the CBOR map"
        case .valueConversionFailed(let message):
            return "Value conversion failed: \(message)"
        case .invalidUTF8:
            return "Invalid UTF-8 data: the CBOR text string contains invalid UTF-8 sequences"
        case .integerOverflow:
            return "Integer overflow: the CBOR integer value is too large for the target Swift integer type"
        case .unsupportedTag(let tag):
            return "Unsupported tag: tag \(tag) is not supported by this implementation"
        case .prematureEnd:
            return "Unexpected end of data: reached the end of input before completing the CBOR value"
        case .invalidInitialByte(let byte):
            return "Invalid initial byte: 0x\(String(byte, radix: 16, uppercase: true)) is not a valid CBOR initial byte"
        case .lengthTooLarge(let length):
            return "Length too large: the specified length \(length) exceeds the implementation's limits"
        case .indefiniteLengthNotSupported:
            return "Indefinite length encoding not supported: this implementation does not support indefinite length encoding for this type"
        case .extraDataFound:
            return "Extra data found: additional data was found after decoding the complete CBOR value"
        }
    }
}

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

@_unavailableInEmbedded
extension CBORError: LocalizedError {
    public var errorDescription: String? {
        return description
    }
}
