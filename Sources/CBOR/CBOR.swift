#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif os(Windows)
import ucrt
#endif

// MARK: - CBOR Type

/// A CBOR value
public indirect enum CBOR: Equatable {
    /// A positive unsigned integer
    case unsignedInt(UInt64)
    /// A negative integer
    case negativeInt(Int64)
    /// A byte string
    case byteString(ArraySlice<UInt8>)
    /// A text string
    case textString(ArraySlice<UInt8>)
    /// An array of CBOR values
    case array(ArraySlice<UInt8>)
    /// A map of CBOR key-value pairs
    case map(ArraySlice<UInt8>)
    /// A tagged CBOR value
    case tagged(UInt64, ArraySlice<UInt8>)
    /// A simple value
    case simple(UInt8)
    /// A boolean value
    case bool(Bool)
    /// A null value
    case null
    /// An undefined value
    case undefined
    /// A floating-point number
    case float(Double)
    
    /// Encodes the CBOR value to bytes
    public func encode() -> [UInt8] {
        var output: [UInt8] = []
        _encode(self, into: &output)
        return output
    }
    
    /// Decodes a CBOR value from bytes.
    ///
    /// - Parameter bytes: The bytes to decode
    /// - Returns: The decoded CBOR value
    /// - Throws: A `CBORError` if the decoding fails
    public static func decode(_ bytes: [UInt8]) throws -> CBOR {
        var reader = CBORReader(data: bytes)
        let value = try _decode(reader: &reader)
        
        // Check if there's any extra data
        if reader.hasMoreBytes {
            throw CBORError.extraDataFound
        }
        
        return value
    }
    
    /// Decodes a CBOR value from bytes.
    ///
    /// - Parameter bytes: The bytes to decode
    /// - Returns: The decoded CBOR value
    /// - Throws: A `CBORError` if the decoding fails
    public static func decode(_ bytes: ArraySlice<UInt8>) throws -> CBOR {
        var reader = CBORReader(data: Array(bytes))
        let value = try _decode(reader: &reader)
        
        // Check if there's any extra data
        if reader.hasMoreBytes {
            throw CBORError.extraDataFound
        }
        
        return value
    }
    
    /// Get the byte string value as ArraySlice to avoid copying
    /// - Returns: The byte string as ArraySlice<UInt8>, or nil if this is not a byte string
    public func byteStringSlice() -> ArraySlice<UInt8>? {
        guard case .byteString(let bytes) = self else { return nil }
        return bytes
    }
    
    /// Get the byte string value
    /// - Returns: The byte string as [UInt8], or nil if this is not a byte string
    public func byteStringValue() -> [UInt8]? {
        guard case .byteString(let bytes) = self else { return nil }
        return Array(bytes)
    }
    
    /// Get the text string value as ArraySlice to avoid copying
    /// - Returns: The text string as ArraySlice<UInt8>, or nil if this is not a text string
    public func textStringSlice() -> ArraySlice<UInt8>? {
        guard case .textString(let bytes) = self else { return nil }
        return bytes
    }
    
    /// Get the text string value
    /// - Returns: The text string as [UInt8], or nil if this is not a text string
    public func textStringValue() -> [UInt8]? {
        guard case .textString(let bytes) = self else { return nil }
        return Array(bytes)
    }
    
    /// Returns the array value of this CBOR value
    ///
    /// - Returns: An array of CBOR values, or nil if this is not an array
    /// - Throws: CBORError if the array cannot be decoded
    public func arrayValue() throws -> [CBOR]? {
        guard case .array(let bytes) = self else {
            return nil
        }
        
        // Safety check for empty bytes
        if bytes.isEmpty {
            return []
        }
        
        // Convert ArraySlice to Array to avoid potential index issues
        let byteArray = Array(bytes)
        
        do {
            var result: [CBOR] = []
            var reader = CBORReader(data: byteArray)
            
            // Get the array length from the initial byte
            let initial = try reader.readByte()
            let major = initial >> 5
            let additional = initial & 0x1f
            
            // Ensure this is an array
            guard major == 4 else {
                throw CBORError.invalidData
            }
            
            // Get the array length
            let count = try readUIntValue(additional: additional, reader: &reader)
            
            // Read each array element
            for _ in 0..<Int(count) {
                let element = try _decode(reader: &reader)
                result.append(element)
            }
            
            return result
        } catch {
            if let cborError = error as? CBORError {
                throw cborError
            } else {
                throw CBORError.invalidData
            }
        }
    }
    
    /// Returns the map value of this CBOR value
    ///
    /// - Returns: An array of CBOR key-value pairs, or nil if this is not a map
    /// - Throws: CBORError if the map cannot be decoded
    public func mapValue() throws -> [CBORMapPair]? {
        guard case .map(let bytes) = self else {
            return nil
        }
        
        // Safety check for empty bytes
        if bytes.isEmpty {
            return []
        }
        
        // Convert ArraySlice to Array to avoid potential index issues
        let byteArray = Array(bytes)
        
        do {
            var result: [CBORMapPair] = []
            var reader = CBORReader(data: byteArray)
            
            // Get the map length from the initial byte
            let initial = try reader.readByte()
            let major = initial >> 5
            let additional = initial & 0x1f
            
            // Ensure this is a map
            guard major == 5 else {
                throw CBORError.invalidData
            }
            
            // Get the map length
            let count = try readUIntValue(additional: additional, reader: &reader)
            
            // Read each key-value pair
            for _ in 0..<Int(count) {
                let key = try _decode(reader: &reader)
                let value = try _decode(reader: &reader)
                result.append(CBORMapPair(key: key, value: value))
            }
            
            return result
        } catch {
            if let cborError = error as? CBORError {
                throw cborError
            } else {
                throw CBORError.invalidData
            }
        }
    }
    
    /// Returns the tagged value of this CBOR value
    ///
    /// - Returns: A tuple containing the tag and the tagged value, or nil if this is not a tagged value
    /// - Throws: CBORError if the tagged value cannot be decoded
    public func taggedValue() throws -> (UInt64, CBOR)? {
        guard case .tagged(let tag, let bytes) = self else {
            return nil
        }
        
        // Safety check for empty bytes
        if bytes.isEmpty {
            throw CBORError.invalidData
        }
        
        do {
            // Decode the tagged value
            let value = try CBOR.decode(bytes)
            
            return (tag, value)
        } catch {
            // If there's an error decoding the tagged value, wrap it
            if let cborError = error as? CBORError {
                throw cborError
            } else {
                throw CBORError.invalidData
            }
        }
    }
    
    /// Iterator for CBOR array elements to avoid heap allocations
    public func arrayIterator() throws -> CBORArrayIterator? {
        guard case .array(let bytes) = self else {
            return nil
        }
        return try CBORArrayIterator(bytes: bytes)
    }
    
    /// Iterator for CBOR map entries to avoid heap allocations
    public func mapIterator() throws -> CBORMapIterator? {
        guard case .map(let bytes) = self else {
            return nil
        }
        return try CBORMapIterator(bytes: bytes)
    }
}

/// A key-value pair in a CBOR map
///
/// - Parameters:
///   - key: The key of the pair
///   - value: The value of the pair
public struct CBORMapPair: Equatable {
    public let key: CBOR
    public let value: CBOR
    
    public init(key: CBOR, value: CBOR) {
        self.key = key
        self.value = value
    }
}

// MARK: - Encoding

/// Encodes a CBOR value to bytes
///
/// - Parameters:
///   - value: The CBOR value to encode
///   - output: The output buffer to write the encoded bytes to
private func _encode(_ value: CBOR, into output: inout [UInt8]) {
    switch value {
    case .unsignedInt(let u):
        encodeUnsigned(major: 0, value: u, into: &output)
    case .negativeInt(let n):
        // In CBOR, negative integers are encoded as -(n+1) where n is a non-negative integer
        // So we need to convert our negative Int64 to the correct positive UInt64 value
        if n < 0 {
            // For negative values, we encode as -(n+1)
            let positiveValue = UInt64(-1 - n)
            encodeUnsigned(major: 1, value: positiveValue, into: &output)
        } else {
            // For non-negative values, we encode as n
            encodeUnsigned(major: 1, value: UInt64(n), into: &output)
        }
    case .byteString(let bytes):
        encodeUnsigned(major: 2, value: UInt64(bytes.count), into: &output)
        output.append(contentsOf: bytes)
    case .textString(let bytes):
        encodeUnsigned(major: 3, value: UInt64(bytes.count), into: &output)
        output.append(contentsOf: bytes)
    case .array(let bytes):
        // For array, we just copy the raw bytes as they already contain the encoded array
        output.append(contentsOf: bytes)
    case .map(let bytes):
        // For map, we just copy the raw bytes as they already contain the encoded map
        output.append(contentsOf: bytes)
    case .tagged(let tag, let bytes):
        encodeUnsigned(major: 6, value: tag, into: &output)
        output.append(contentsOf: bytes)
    case .simple(let simple):
        if simple < 24 {
            output.append(0xe0 | simple)
        } else {
            output.append(0xf8)
            output.append(simple)
        }
    case .bool(let b):
        output.append(b ? 0xf5 : 0xf4)
    case .null:
        output.append(0xf6)
    case .undefined:
        output.append(0xf7)
    case .float(let f):
        // Encode as IEEE 754 double-precision float (CBOR major type 7, additional info 27)
        output.append(0xfb)
        var value = f
        
        // CBOR specification (RFC 8949) requires all numbers to be encoded in network byte order (big-endian)
        // We need to ensure the bytes are in the correct order regardless of the system's native endianness
        withUnsafeBytes(of: &value) { bytes in
            #if _endian(little)
                // On little-endian systems (most modern processors), we need to reverse the bytes
                // to convert from the system's native little-endian to CBOR's required big-endian
                for i in (0..<8).reversed() {
                    output.append(bytes[i])
                }
            #else
                // On big-endian systems, we can append bytes directly as they're already in the correct order
                for i in 0..<8 {
                    output.append(bytes[i])
                }
            #endif
        }
    }
}

/// Encodes an unsigned integer with the given major type
///
/// - Parameters:
///   - major: The major type of the integer
///   - value: The unsigned integer value
///   - output: The output buffer to write the encoded bytes to
private func encodeUnsigned(major: UInt8, value: UInt64, into output: inout [UInt8]) {
    let majorByte = major << 5
    if value < 24 {
        output.append(majorByte | UInt8(value))
    } else if value <= UInt8.max {
        output.append(majorByte | 24)
        output.append(UInt8(value))
    } else if value <= UInt16.max {
        output.append(majorByte | 25)
        output.append(UInt8(value >> 8))
        output.append(UInt8(value & 0xff))
    } else if value <= UInt32.max {
        output.append(majorByte | 26)
        output.append(UInt8(value >> 24))
        output.append(UInt8((value >> 16) & 0xff))
        output.append(UInt8((value >> 8) & 0xff))
        output.append(UInt8(value & 0xff))
    } else {
        output.append(majorByte | 27)
        output.append(UInt8(value >> 56))
        output.append(UInt8((value >> 48) & 0xff))
        output.append(UInt8((value >> 40) & 0xff))
        output.append(UInt8((value >> 32) & 0xff))
        output.append(UInt8((value >> 24) & 0xff))
        output.append(UInt8((value >> 16) & 0xff))
        output.append(UInt8((value >> 8) & 0xff))
        output.append(UInt8(value & 0xff))
    }
}

// MARK: - Decoding

/// Decodes a CBOR value from the reader.
///
/// - Parameters:
///   - reader: The reader to decode from
/// - Returns: The decoded CBOR value
/// - Throws: A `CBORError` if the decoding fails
private func _decode(reader: inout CBORReader) throws -> CBOR {
    let initial = try reader.readByte()
    
    // Check for break marker (0xff)
    if initial == 0xff {
        throw CBORError.invalidInitialByte(initial)
    }
    
    let majorType = initial >> 5
    let additional = initial & 0x1f
    
    switch majorType {
    case 0: // unsigned integer
        let value = try readUIntValue(additional: additional, reader: &reader)
        return .unsignedInt(value)
        
    case 1: // negative integer
        let value = try readUIntValue(additional: additional, reader: &reader)
        return .negativeInt(Int64(-1 - Int64(value)))
        
    case 2: // byte string
        // Get the length of the byte string
        let length = try readUIntValue(additional: additional, reader: &reader)
        guard length <= UInt64(Int.max) else {
            throw CBORError.lengthTooLarge(length)
        }
        
        // Read the byte string data directly
        let bytes = try reader.readBytes(Int(length))
        
        // Store the raw bytes
        return .byteString(bytes)
        
    case 3: // text string
        // Get the length of the text string
        let length = try readUIntValue(additional: additional, reader: &reader)
        guard length <= UInt64(Int.max) else {
            throw CBORError.lengthTooLarge(length)
        }
        
        // Read the text string data
        let bytes = try reader.readBytes(Int(length))
        
        // Validate UTF-8 encoding
        guard String(bytes: bytes, encoding: .utf8) != nil else {
            throw CBORError.invalidUTF8
        }
        
        // Store the raw bytes
        return .textString(bytes)
        
    case 4: // array
        // Check for indefinite length arrays
        if additional == 31 {
            throw CBORError.indefiniteLengthNotSupported
        }
        
        // Get the array length
        let count = try readUIntValue(additional: additional, reader: &reader)
        guard count <= UInt64(Int.max) else {
            throw CBORError.lengthTooLarge(count)
        }
        
        // Read each array element
        var elements: [CBOR] = []
        for _ in 0..<Int(count) {
            let element = try _decode(reader: &reader)
            elements.append(element)
        }
        
        // Create a new array with the decoded elements
        var arrayBuffer: [UInt8] = []
        // Add array header
        let majorType: UInt8 = 4 << 5
        if count <= 23 {
            arrayBuffer.append(majorType | UInt8(count))
        } else if count <= UInt64(UInt8.max) {
            arrayBuffer.append(majorType | 24)
            arrayBuffer.append(UInt8(count))
        } else if count <= UInt64(UInt16.max) {
            arrayBuffer.append(majorType | 25)
            arrayBuffer.append(UInt8(count >> 8))
            arrayBuffer.append(UInt8(count & 0xFF))
        } else if count <= UInt64(UInt32.max) {
            arrayBuffer.append(majorType | 26)
            arrayBuffer.append(UInt8(count >> 24))
            arrayBuffer.append(UInt8((count >> 16) & 0xFF))
            arrayBuffer.append(UInt8((count >> 8) & 0xFF))
            arrayBuffer.append(UInt8(count & 0xFF))
        } else {
            arrayBuffer.append(majorType | 27)
            arrayBuffer.append(UInt8(count >> 56))
            arrayBuffer.append(UInt8((count >> 48) & 0xFF))
            arrayBuffer.append(UInt8((count >> 40) & 0xFF))
            arrayBuffer.append(UInt8((count >> 32) & 0xFF))
            arrayBuffer.append(UInt8((count >> 24) & 0xFF))
            arrayBuffer.append(UInt8((count >> 16) & 0xFF))
            arrayBuffer.append(UInt8((count >> 8) & 0xFF))
            arrayBuffer.append(UInt8(count & 0xFF))
        }
        
        // Add each element's encoded bytes
        for element in elements {
            arrayBuffer.append(contentsOf: element.encode())
        }
        
        return .array(ArraySlice(arrayBuffer))
        
    case 5: // map
        // Check for indefinite length maps
        if additional == 31 {
            throw CBORError.indefiniteLengthNotSupported
        }
        
        // Get the map length
        let count = try readUIntValue(additional: additional, reader: &reader)
        guard count <= UInt64(Int.max) else {
            throw CBORError.lengthTooLarge(count)
        }
        
        // Read each map key-value pair
        var pairs: [CBORMapPair] = []
        for _ in 0..<Int(count) {
            let key = try _decode(reader: &reader)
            let value = try _decode(reader: &reader)
            pairs.append(CBORMapPair(key: key, value: value))
        }
        
        // Create a new map with the decoded pairs
        var mapBuffer: [UInt8] = []
        // Add map header
        let majorType: UInt8 = 5 << 5
        if count <= 23 {
            mapBuffer.append(majorType | UInt8(count))
        } else if count <= UInt64(UInt8.max) {
            mapBuffer.append(majorType | 24)
            mapBuffer.append(UInt8(count))
        } else if count <= UInt64(UInt16.max) {
            mapBuffer.append(majorType | 25)
            mapBuffer.append(UInt8(count >> 8))
            mapBuffer.append(UInt8(count & 0xFF))
        } else if count <= UInt64(UInt32.max) {
            mapBuffer.append(majorType | 26)
            mapBuffer.append(UInt8(count >> 24))
            mapBuffer.append(UInt8((count >> 16) & 0xFF))
            mapBuffer.append(UInt8((count >> 8) & 0xFF))
            mapBuffer.append(UInt8(count & 0xFF))
        } else {
            mapBuffer.append(majorType | 27)
            mapBuffer.append(UInt8(count >> 56))
            mapBuffer.append(UInt8((count >> 48) & 0xFF))
            mapBuffer.append(UInt8((count >> 40) & 0xFF))
            mapBuffer.append(UInt8((count >> 32) & 0xFF))
            mapBuffer.append(UInt8((count >> 24) & 0xFF))
            mapBuffer.append(UInt8((count >> 16) & 0xFF))
            mapBuffer.append(UInt8((count >> 8) & 0xFF))
            mapBuffer.append(UInt8(count & 0xFF))
        }
        
        // Add each key-value pair's encoded bytes
        for pair in pairs {
            mapBuffer.append(contentsOf: pair.key.encode())
            mapBuffer.append(contentsOf: pair.value.encode())
        }
        
        return .map(ArraySlice(mapBuffer))
        
    case 6: // tagged value
        // Get the tag
        let tag = try readUIntValue(additional: additional, reader: &reader)
        
        // Create a buffer to hold the encoded tagged value
        var tagBuffer: [UInt8] = []
        
        // Add the tag header byte
        tagBuffer.append(initial)
        
        // If the tag required additional bytes, add those too
        if additional >= 24 {
            // Calculate how many bytes were used for the tag
            let bytesForTag: Int
            if additional == 24 {
                bytesForTag = 1
            } else if additional == 25 {
                bytesForTag = 2
            } else if additional == 26 {
                bytesForTag = 4
            } else if additional == 27 {
                bytesForTag = 8
            } else {
                throw CBORError.invalidAdditionalInfo(additional)
            }
            
            // Go back to read the tag bytes
            let currentPos = reader.currentPosition
            try reader.seek(to: currentPos - bytesForTag)
            let tagBytes = try reader.readBytes(bytesForTag)
            tagBuffer.append(contentsOf: tagBytes)
        }
        
        // Read the tagged value
        let valueStartPos = reader.currentPosition
        let _ = try _decode(reader: &reader)
        let valueEndPos = reader.currentPosition
        
        // Get the raw bytes for the value
        try reader.seek(to: valueStartPos)
        let valueBytes = try reader.readBytes(valueEndPos - valueStartPos)
        
        return .tagged(tag, ArraySlice(valueBytes))
        
    case 7: // simple values and floats
        switch additional {
        case 20: return .bool(false)
        case 21: return .bool(true)
        case 22: return .null
        case 23: return .undefined
        case 24:
            // Simple value in the next byte
            let value = try reader.readByte()
            return .simple(value)
        case 25:
            // Half-precision float (16-bit)
            let byte1 = try reader.readByte()
            let byte2 = try reader.readByte()
            
            // Convert half-precision to double
            let halfPrecision = UInt16(byte1) << 8 | UInt16(byte2)
            let value = convertHalfPrecisionToDouble(halfPrecision)
            return .float(value)
        case 26:
            // Single-precision float (32-bit)
            let byte1 = try reader.readByte()
            let byte2 = try reader.readByte()
            let byte3 = try reader.readByte()
            let byte4 = try reader.readByte()
            
            // Convert to float and then to double
            let bits = UInt32(byte1) << 24 | UInt32(byte2) << 16 | UInt32(byte3) << 8 | UInt32(byte4)
            let value = Float(bitPattern: bits)
            return .float(Double(value))
        case 27:
            // Double-precision float (64-bit)
            let byte1 = try reader.readByte()
            let byte2 = try reader.readByte()
            let byte3 = try reader.readByte()
            let byte4 = try reader.readByte()
            let byte5 = try reader.readByte()
            let byte6 = try reader.readByte()
            let byte7 = try reader.readByte()
            let byte8 = try reader.readByte()
            
            // Convert to double
            let bits = UInt64(byte1) << 56 | UInt64(byte2) << 48 | UInt64(byte3) << 40 | UInt64(byte4) << 32 |
                       UInt64(byte5) << 24 | UInt64(byte6) << 16 | UInt64(byte7) << 8 | UInt64(byte8)
            let value = Double(bitPattern: bits)
            return .float(value)
        default:
            throw CBORError.invalidAdditionalInfo(additional)
        }
    default:
        throw CBORError.invalidMajorType(majorType)
    }
}

/// Converts a half-precision float (IEEE 754) to a double
///
/// - Parameter halfPrecision: The half-precision float bits
/// - Returns: The converted double value
private func convertHalfPrecisionToDouble(_ halfPrecision: UInt16) -> Double {
    let sign = (halfPrecision & 0x8000) != 0
    let exponent = Int((halfPrecision & 0x7C00) >> 10)
    let fraction = halfPrecision & 0x03FF
    
    var value: Double
    if exponent == 0 {
        // Subnormal number
        value = Double(fraction) * pow(2, -24)
    } else if exponent == 31 {
        // Infinity or NaN
        value = fraction == 0 ? Double.infinity : Double.nan
    } else {
        // Normal number
        value = Double(fraction | 0x0400) * pow(2, Double(exponent - 25))
    }
    
    return sign ? -value : value
}

/// Reads an unsigned integer value based on the additional information.
private func readUIntValue(additional: UInt8, reader: inout CBORReader) throws -> UInt64 {
    // Check for indefinite length first
    if additional == 31 {
        throw CBORError.indefiniteLengthNotSupported
    }
    
    if additional < 24 {
        return UInt64(additional)
    } else if additional == 24 {
        return UInt64(try reader.readByte())
    } else if additional == 25 {
        let bytes = try reader.readBytes(2)
        return UInt64(bytes[0]) << 8 | UInt64(bytes[1])
    } else if additional == 26 {
        let bytes = try reader.readBytes(4)
        return UInt64(bytes[0]) << 24 | UInt64(bytes[1]) << 16 | UInt64(bytes[2]) << 8 | UInt64(bytes[3])
    } else if additional == 27 {
        let bytes = try reader.readBytes(8)
        let byte0 = UInt64(bytes[0]) << 56
        let byte1 = UInt64(bytes[1]) << 48
        let byte2 = UInt64(bytes[2]) << 40
        let byte3 = UInt64(bytes[3]) << 32
        let byte4 = UInt64(bytes[4]) << 24
        let byte5 = UInt64(bytes[5]) << 16
        let byte6 = UInt64(bytes[6]) << 8
        let byte7 = UInt64(bytes[7])
        return byte0 | byte1 | byte2 | byte3 | byte4 | byte5 | byte6 | byte7
    } else {
        throw CBORError.invalidInitialByte(additional)
    }
}

// MARK: - Iterator Types

/// Iterator for CBOR arrays that avoids heap allocations
public struct CBORArrayIterator: IteratorProtocol {
    private var reader: CBORReader
    private let count: Int
    private var currentIndex: Int = 0
    
    init(bytes: ArraySlice<UInt8>) throws {
        // Safety check for empty bytes
        if bytes.isEmpty {
            throw CBORError.invalidData
        }
        
        // Convert ArraySlice to Array to avoid potential index issues
        let byteArray = Array(bytes)
        self.reader = CBORReader(data: byteArray)
        
        // Get the array length from the initial byte
        let initial = try reader.readByte()
        let major = initial >> 5
        let additional = initial & 0x1f
        
        // Ensure this is an array
        guard major == 4 else {
            throw CBORError.invalidData
        }
        
        // Get the array length
        let arrayCount = try readUIntValue(additional: additional, reader: &reader)
        self.count = Int(arrayCount)
    }
    
    public mutating func next() -> CBOR? {
        guard currentIndex < count else { return nil }
        
        do {
            let element = try _decode(reader: &reader)
            currentIndex += 1
            return element
        } catch {
            return nil
        }
    }
}

/// Iterator for CBOR maps that avoids heap allocations
public struct CBORMapIterator: IteratorProtocol {
    private var reader: CBORReader
    private let count: Int
    private var currentIndex: Int = 0
    
    init(bytes: ArraySlice<UInt8>) throws {
        // Safety check for empty bytes
        if bytes.isEmpty {
            throw CBORError.invalidData
        }
        
        // Convert ArraySlice to Array to avoid potential index issues
        let byteArray = Array(bytes)
        self.reader = CBORReader(data: byteArray)
        
        // Get the map length from the initial byte
        let initial = try reader.readByte()
        let major = initial >> 5
        let additional = initial & 0x1f
        
        // Ensure this is a map
        guard major == 5 else {
            throw CBORError.invalidData
        }
        
        // Get the map length
        let mapCount = try readUIntValue(additional: additional, reader: &reader)
        self.count = Int(mapCount)
    }
    
    public mutating func next() -> CBORMapPair? {
        guard currentIndex < count else { return nil }
        
        do {
            let key = try _decode(reader: &reader)
            let value = try _decode(reader: &reader)
            currentIndex += 1
            return CBORMapPair(key: key, value: value)
        } catch {
            return nil
        }
    }
}