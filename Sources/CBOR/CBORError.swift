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
    /// to be processed by the current implementation, typically due to memory constraints.
    /// - Parameter length: The length value that exceeded the implementation's limits
    case lengthTooLarge(UInt64, maximum: UInt64)
    
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
        case .endOfData:
            return "End of data: attempted to read beyond the end of the available data"
        case .invalidLength:
            return "Invalid length: an invalid length parameter was specified for the operation"
        case .invalidPosition:
            return "Invalid position: attempted to seek to an invalid position in the data"
        case .invalidInitialByte(let byte):
            return "Invalid initial byte: 0x\(String(byte, radix: 16, uppercase: true)) is not a valid CBOR initial byte"
        case .lengthTooLarge(let length, let maximum):
            return "Length too large: the specified length \(length) exceeds the implementation's limits of \(maximum)"
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

extension CBORError {
    public static func == (lhs: CBORError, rhs: CBORError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCBOR, .invalidCBOR):
            return true
        case (.invalidUTF8, .invalidUTF8):
            return true
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
        case (.lengthTooLarge(let lengthL, let maximumL), .lengthTooLarge(let lengthR, let maximumR)):
            return lengthL == lengthR && maximumL == maximumR
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
