#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: - Error Types

/// Errors that can occur during CBOR encoding and decoding.
/// 
/// These errors provide detailed information about what went wrong during
/// CBOR processing operations, helping developers diagnose and fix issues
/// in their CBOR data or usage of the CBOR API.
public enum CBORError: Error, Equatable {
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
    
    /// End of data reached.
    ///
    /// This error occurs when attempting to read beyond the end of the available data.
    case endOfData
    
    /// Invalid length specified for an operation.
    /// 
    /// This error occurs when an operation is requested with an invalid length parameter,
    /// such as a negative length for a read operation or an otherwise invalid size specification.
    case invalidLength
    
    /// Invalid position.
    ///
    /// This error occurs when attempting to seek to an invalid position in the data.
    case invalidPosition
    
    /// Invalid initial byte for CBOR item.
    /// 
    /// This error occurs when the decoder encounters an initial byte that doesn't
    /// correspond to a valid CBOR major type or data item.
    /// - Parameter byte: The invalid initial byte value
    case invalidInitialByte(UInt8)
    
    /// Length of data is too large.
    /// 
    /// This error occurs when a CBOR string, array, or map has a length that is too large
    /// to be represented as an Int in Swift.
    /// - Parameter length: The length that was too large
    case lengthTooLarge(UInt64)
    
    /// Indefinite length not supported.
    ///
    /// This error occurs when the decoder encounters an indefinite-length item.
    /// The current implementation does not support indefinite-length encoding.
    case indefiniteLengthNotSupported
    
    /// Extra data was found after decoding the top-level CBOR value.
    /// 
    /// This error occurs when the decoder successfully decodes a complete CBOR value
    /// but finds additional data afterward. This typically indicates that the input
    /// contains multiple concatenated CBOR values when only one was expected.
    case extraDataFound
    
    /// Array index out of bounds.
    /// 
    /// This error occurs when trying to access an element in a CBOR array using
    /// an index that is outside the bounds of the array.
    /// - Parameter index: The invalid index that was used
    case indexOutOfBounds(index: Int)
    
    /// The additional info in a CBOR header byte is invalid.
    ///
    /// This error occurs when the additional info bits (the lower 5 bits) in a CBOR
    /// header byte contain a value that is not valid for the given major type.
    /// - Parameter value: The invalid additional info value
    case invalidAdditionalInfo(UInt8)
    
    /// The major type in a CBOR header byte is invalid.
    ///
    /// This error occurs when the major type bits (the upper 3 bits) in a CBOR
    /// header byte contain a value that is not recognized as a valid CBOR major type.
    /// - Parameter value: The invalid major type value
    case invalidMajorType(UInt8)
    
    /// The input data is invalid or malformed.
    ///
    /// This error occurs when the data being processed is structurally valid CBOR,
    /// but contains values that don't make sense in the current context.
    case invalidData
}

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
        case .endOfData:
            return "End of data: attempted to read beyond the end of the available data"
        case .invalidLength:
            return "Invalid length: an invalid length parameter was specified for the operation"
        case .invalidPosition:
            return "Invalid position: attempted to seek to an invalid position in the data"
        case .invalidInitialByte(let byte):
            return "Invalid initial byte: 0x\(String(byte, radix: 16, uppercase: true)) is not a valid CBOR initial byte"
        case .lengthTooLarge(let length):
            return "Length too large: \(length) exceeds maximum supported length"
        case .indefiniteLengthNotSupported:
            return "Indefinite length not supported: the current implementation does not support indefinite-length encoding"
        case .extraDataFound:
            return "Extra data found: additional data was found after decoding the complete CBOR value"
        case .indexOutOfBounds(let index):
            return "Array index out of bounds: attempted to access index \(index), but array only contains elements (valid indices are 0..<count)"
        case .invalidAdditionalInfo(let value):
            return "Invalid additional info: 0x\(String(value, radix: 16, uppercase: true)) is not a valid additional info value"
        case .invalidMajorType(let value):
            return "Invalid major type: 0x\(String(value, radix: 16, uppercase: true)) is not a recognized CBOR major type"
        case .invalidData:
            return "Invalid data: the data being processed is structurally valid CBOR, but contains values that don't make sense in the current context"
        }
    }
}

extension CBORError: LocalizedError {
    public var errorDescription: String? {
        return description
    }
}

extension CBORError {
    public static func == (lhs: CBORError, rhs: CBORError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCBOR, .invalidCBOR):
            return true
        case (.typeMismatch(let expectedL, let actualL), .typeMismatch(let expectedR, let actualR)):
            return expectedL == expectedR && actualL == actualR
        case (.outOfBounds(let indexL, let countL), .outOfBounds(let indexR, let countR)):
            return indexL == indexR && countL == countR
        case (.missingKey(let keyL), .missingKey(let keyR)):
            return keyL == keyR
        case (.valueConversionFailed(let messageL), .valueConversionFailed(let messageR)):
            return messageL == messageR
        case (.invalidUTF8, .invalidUTF8):
            return true
        case (.integerOverflow, .integerOverflow):
            return true
        case (.unsupportedTag(let tagL), .unsupportedTag(let tagR)):
            return tagL == tagR
        case (.prematureEnd, .prematureEnd):
            return true
        case (.endOfData, .endOfData):
            return true
        case (.invalidLength, .invalidLength):
            return true
        case (.invalidPosition, .invalidPosition):
            return true
        case (.invalidInitialByte(let byteL), .invalidInitialByte(let byteR)):
            return byteL == byteR
        case (.lengthTooLarge(let lengthL), .lengthTooLarge(let lengthR)):
            return lengthL == lengthR
        case (.indefiniteLengthNotSupported, .indefiniteLengthNotSupported):
            return true
        case (.extraDataFound, .extraDataFound):
            return true
        case (.indexOutOfBounds(let indexL), .indexOutOfBounds(let indexR)):
            return indexL == indexR
        case (.invalidAdditionalInfo(let valueL), .invalidAdditionalInfo(let valueR)):
            return valueL == valueR
        case (.invalidMajorType(let valueL), .invalidMajorType(let valueR)):
            return valueL == valueR
        case (.invalidData, .invalidData):
            return true
        default:
            return false
        }
    }
}
