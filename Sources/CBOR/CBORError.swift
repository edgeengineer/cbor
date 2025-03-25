#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: - Error Types

/// Errors that can occur during CBOR encoding and decoding
public enum CBORError: Error {
    /// The input data is not valid CBOR
    case invalidCBOR
    
    /// Expected a specific type but found another
    case typeMismatch(expected: String, actual: String)
    
    /// Array index out of bounds
    case outOfBounds(index: Int, count: Int)
    
    /// Required key missing from map
    case missingKey(String)
    
    /// Value conversion failed
    case valueConversionFailed(String)
    
    /// Invalid UTF-8 string data
    case invalidUTF8
    
    /// Integer overflow during encoding/decoding
    case integerOverflow
    
    /// Tag value is not supported
    case unsupportedTag(UInt64)
    
    /// Reached end of data while decoding
    case prematureEnd
    
    /// Invalid initial byte for CBOR item
    case invalidInitialByte(UInt8)
    
    /// Length of data is too large
    case lengthTooLarge(UInt64)
    
    /// Indefinite length encoding is not supported for this type
    case indefiniteLengthNotSupported

     /// Extra data was found after decoding the top-level CBOR value.
    case extraDataFound
}

extension CBORError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidCBOR:
            return "Invalid CBOR data"
        case .typeMismatch(let expected, let actual):
            return "Type mismatch: expected \(expected), found \(actual)"
        case .outOfBounds(let index, let count):
            return "Array index out of bounds: index \(index), count \(count)"
        case .missingKey(let key):
            return "Missing key: \(key)"
        case .valueConversionFailed(let message):
            return "Value conversion failed: \(message)"
        case .invalidUTF8:
            return "Invalid UTF-8 data"
        case .integerOverflow:
            return "Integer overflow"
        case .unsupportedTag(let tag):
            return "Unsupported tag: \(tag)"
        case .prematureEnd:
            return "Unexpected end of data"
        case .invalidInitialByte(let byte):
            return "Invalid initial byte: \(byte)"
        case .lengthTooLarge(let length):
            return "Length too large: \(length)"
        case .indefiniteLengthNotSupported:
            return "Indefinite length encoding not supported for this type"
        case .extraDataFound:
            return "Extra data found after decoding the top-level CBOR value"
        }
    }
}
