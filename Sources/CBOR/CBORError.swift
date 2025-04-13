// MARK: - Error Types

/// Errors that can occur during CBOR encoding and decoding.
/// 
/// These errors provide detailed information about what went wrong during
/// CBOR processing operations, helping developers diagnose and fix issues
/// in their CBOR data or usage of the CBOR API.
public enum CBORError: Error, Equatable, Sendable {
    /// The input data is not valid CBOR.
    /// 
    /// This error occurs when the decoder encounters data that doesn't conform to
    /// the CBOR specification (RFC 8949). This could be due to corrupted data,
    /// incomplete data, or data encoded with a different format entirely.
    case invalidCBOR
    
    /// Invalid UTF-8 string data.
    /// 
    /// This error occurs when decoding a CBOR text string that contains invalid UTF-8 sequences.
    /// All CBOR text strings must contain valid UTF-8 data according to the specification.
    case invalidUTF8
    
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
        case .invalidUTF8:
            return "Invalid UTF-8 data: the CBOR text string contains invalid UTF-8 sequences"
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
