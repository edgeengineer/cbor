#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif os(Windows)
import ucrt
#endif

// MARK: - CBOR Type

/// A CBOR value
public enum CBOR: Equatable, Sendable {
    /// A positive unsigned integer
    case unsignedInt(UInt64)
    /// A negative integer
    case negativeInt(Int64)
    /// A byte string
    case byteString([UInt8])
    /// A text string
    case textString(String)
    /// An array of CBOR values
    case array([CBOR])
    /// A map of CBOR key-value pairs
    case map([CBORMapPair])
    /// A tagged CBOR value
    indirect case tagged(UInt64, CBOR)
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
    
    /// Decodes a CBOR value from bytes
    public static func decode(_ bytes: [UInt8]) throws(CBORError) -> CBOR {
        var reader = CBORReader(data: bytes)
        let value = try _decode(reader: &reader)
        
        // Ensure we've consumed all the data
        if reader.hasMoreBytes {
            throw CBORError.extraDataFound
        }
        
        return value
    }
}

/// A key-value pair in a CBOR map
///
/// - Parameters:
///   - key: The key of the pair
///   - value: The value of the pair
public struct CBORMapPair: Equatable, Sendable {
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
    case .textString(let string):
        let bytes = [UInt8](string.utf8)
        encodeUnsigned(major: 3, value: UInt64(bytes.count), into: &output)
        output.append(contentsOf: bytes)
    case .array(let array):
        encodeUnsigned(major: 4, value: UInt64(array.count), into: &output)
        for item in array {
            _encode(item, into: &output)
        }
    case .map(let pairs):
        encodeUnsigned(major: 5, value: UInt64(pairs.count), into: &output)
        for pair in pairs {
            _encode(pair.key, into: &output)
            _encode(pair.value, into: &output)
        }
    case .tagged(let tag, let item):
        encodeUnsigned(major: 6, value: tag, into: &output)
        _encode(item, into: &output)
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
        // Encode as IEEE 754 double-precision float
        output.append(0xfb)
        withUnsafeBytes(of: f) { bytes in
            // Append bytes in big-endian order
            for i in (0..<8).reversed() {
                output.append(bytes[i])
            }
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
private func _decode(reader: inout CBORReader) throws(CBORError) -> CBOR {
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
        let length = try readUIntValue(additional: additional, reader: &reader)
        guard length <= UInt64(Int.max) else {
            throw CBORError.lengthTooLarge(length)
        }
        
        return .byteString(Array(try reader.readBytes(Int(length))))
        
    case 3: // text string
        let length = try readUIntValue(additional: additional, reader: &reader)
        guard length <= UInt64(Int.max) else {
            throw CBORError.lengthTooLarge(length)
        }
        
        let bytes = try reader.readBytes(Int(length))
        
        guard let string = String(bytes: bytes, encoding: .utf8) else {
            throw CBORError.invalidUTF8
        }
        
        return .textString(string)
        
    case 4: // array
        let count = try readUIntValue(additional: additional, reader: &reader)
        guard count <= UInt64(Int.max) else {
            throw CBORError.lengthTooLarge(count)
        }
        
        var items: [CBOR] = []
        for _ in 0..<Int(count) {
            items.append(try _decode(reader: &reader))
        }
        
        return .array(items)
        
    case 5: // map
        let count = try readUIntValue(additional: additional, reader: &reader)
        guard count <= UInt64(Int.max) else {
            throw CBORError.lengthTooLarge(count)
        }
        
        var pairs: [CBORMapPair] = []
        for _ in 0..<Int(count) {
            let key = try _decode(reader: &reader)
            let value = try _decode(reader: &reader)
            pairs.append(CBORMapPair(key: key, value: value))
        }
        
        return .map(pairs)
        
    case 6: // tagged
        let tag = try readUIntValue(additional: additional, reader: &reader)
        let value = try _decode(reader: &reader)
        return .tagged(tag, value)
        
    case 7: // simple values and floats
        switch additional {
        case 20: return .bool(false)
        case 21: return .bool(true)
        case 22: return .null
        case 23: return .undefined
        case 24:
            let simple = try reader.readByte()
            return .simple(simple)
        case 25: // IEEE 754 Half-Precision Float (16 bits)
            let bits = try reader.readBigEndianInteger(UInt16.self)
            // Convert half-precision to double
            let sign = (bits & 0x8000) != 0
            let exponent = Int((bits & 0x7C00) >> 10)
            let fraction = bits & 0x03FF
            
            var value: Double
            if exponent == 0 {
                value = Double(fraction) * pow(2, -24)
            } else if exponent == 31 {
                value = fraction == 0 ? Double.infinity : Double.nan
            } else {
                value = Double(fraction | 0x0400) * pow(2, Double(exponent - 25))
            }
            
            return .float(sign ? -value : value)
            
        case 26: // IEEE 754 Single-Precision Float (32 bits)
            let bits = try reader.readBigEndianInteger(UInt32.self)
            let float = Float(bitPattern: bits)
            return .float(Double(float))
            
        case 27: // IEEE 754 Double-Precision Float (64 bits)
            let bits = try reader.readBigEndianInteger(UInt64.self)
            let double = Double(bitPattern: bits)
            return .float(double)
            
        default:
            if additional < 20 {
                return .simple(additional)
            }
            throw CBORError.invalidInitialByte(initial)
        }
        
    default:
        throw CBORError.invalidInitialByte(initial)
    }
}

/// Reads an unsigned integer value based on the additional information.
private func readUIntValue(additional: UInt8, reader: inout CBORReader) throws(CBORError) -> UInt64 {
    // Check for indefinite length first
    if additional == 31 {
        throw CBORError.indefiniteLengthNotSupported
    }
    
    if additional < 24 {
        return UInt64(additional)
    } else if additional == 24 {
        return UInt64(try reader.readByte())
    } else if additional == 25 {
        return try UInt64(reader.readBigEndianInteger(UInt16.self))
    } else if additional == 26 {
        return try UInt64(reader.readBigEndianInteger(UInt32.self))
    } else if additional == 27 {
        return try reader.readBigEndianInteger(UInt64.self)
    } else {
        throw CBORError.invalidInitialByte(additional)
    }
}