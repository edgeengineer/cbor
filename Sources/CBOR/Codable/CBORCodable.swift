#if !hasFeature(Embedded)
#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: - CBOR Codable Extensions

extension CBOR: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let container = container as? CBOREncoderSingleValueContainer {
            container.encoder.push(self)
            return
        }
        
        switch self {
        case .unsignedInt(let value):
            try container.encode(value)
        case .negativeInt(let value):
            try container.encode(value)
        case .byteString(let bytes):
            try container.encode(Data(Array(bytes)))
        case .textString(let bytes):
            // Convert the bytes to a String
            if let string = try? CBORDecoder.bytesToString(bytes) {
                try container.encode(string)
            } else {
                throw EncodingError.invalidValue(self, EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Invalid UTF-8 data in CBOR text string"
                ))
            }
        case .array(let arrayBytes):
            // For array, we need to decode the array first
            var reader = CBORReader(data: Array(arrayBytes))
            let array = try arrayValue() ?? []
            try container.encode(array)
        case .map(let mapBytes):
            // For map, we need to decode the map first
            let pairs = try mapValue() ?? []
            var keyedContainer = encoder.container(keyedBy: CBORKey.self)
            for pair in pairs {
                switch pair.key {
                case .textString(let keyBytes):
                    // Convert the key bytes to a String
                    if let keyString = try? CBORDecoder.bytesToString(keyBytes) {
                        try keyedContainer.encode(pair.value, forKey: CBORKey(stringValue: keyString))
                    } else {
                        throw EncodingError.invalidValue(pair.key, EncodingError.Context(
                            codingPath: encoder.codingPath,
                            debugDescription: "Invalid UTF-8 data in CBOR map key"
                        ))
                    }
                default:
                    throw EncodingError.invalidValue(pair.key, EncodingError.Context(
                        codingPath: encoder.codingPath,
                        debugDescription: "CBOR map keys must be text strings for Encodable"
                    ))
                }
            }
        case .tagged(let tag, let valueBytes):
            // For tagged, we need to decode the value first
            let taggedValue = try taggedValue()
            if let (tag, value) = taggedValue, tag == 1, case .float(let timeInterval) = value {
                // Tag 1 with a float is a standard date representation
                try container.encode(Date(timeIntervalSince1970: timeInterval))
            } else if let (tag, value) = taggedValue {
                // For other tags, encode as a special dictionary
                var keyedContainer = encoder.container(keyedBy: CBORKey.self)
                try keyedContainer.encode(tag, forKey: CBORKey(stringValue: "tag"))
                try keyedContainer.encode(value, forKey: CBORKey(stringValue: "value"))
            } else {
                throw EncodingError.invalidValue(self, EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Failed to decode tagged value"
                ))
            }
        case .simple(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        case .undefined:
            try container.encodeNil()
        case .float(let value):
            try container.encode(value)
        }
    }
}

extension CBOR: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let container = container as? CBORSingleValueDecodingContainer {
            self = container.cbor
            return
        }
        
        if container.decodeNil() {
            self = .null
            return
        }
        
        // Try to decode as various types
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
            return
        }
        
        if let value = try? container.decode(Double.self) {
            self = .float(value)
            return
        }
        
        if let value = try? container.decode(String.self) {
            // Convert the string to UTF-8 bytes
            if let utf8Data = value.data(using: .utf8) {
                let bytes = [UInt8](utf8Data)
                self = .textString(ArraySlice(bytes))
                return
            } else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Invalid UTF-8 data in string"
                ))
            }
        }
        
        if let value = try? container.decode(UInt64.self) {
            self = .unsignedInt(value)
            return
        }
        
        if let value = try? container.decode(Int64.self) {
            if value < 0 {
                self = .negativeInt(value)
            } else {
                self = .unsignedInt(UInt64(value))
            }
            return
        }
        
        if let value = try? container.decode([CBOR].self) {
            // For array, we need to encode the array elements
            var encodedBytes: [UInt8] = []
            // Add array header
            CBOR.encodeUnsigned(major: 4, value: UInt64(value.count), into: &encodedBytes)
            
            // Add each element
            for item in value {
                encodedBytes.append(contentsOf: item.encode())
            }
            
            self = .array(ArraySlice(encodedBytes))
            return
        }
        
        if let value = try? container.decode(Data.self) {
            self = .byteString(ArraySlice([UInt8](value)))
            return
        }
        
        // Try to decode as a map
        if let keyedContainer = try? decoder.container(keyedBy: CBORKey.self) {
            // Check if it's a tagged value
            if let tag = try? keyedContainer.decode(UInt64.self, forKey: CBORKey(stringValue: "tag")),
               let value = try? keyedContainer.decode(CBOR.self, forKey: CBORKey(stringValue: "value")) {
                // For tagged, we need to encode the value first
                let encodedValue = value.encode()
                self = .tagged(tag, ArraySlice(encodedValue))
                return
            }
            
            // Otherwise decode as a regular map
            var pairs: [CBORMapPair] = []
            for key in keyedContainer.allKeys {
                let value = try keyedContainer.decode(CBOR.self, forKey: key)
                // Convert the key string to UTF-8 bytes
                if let utf8Data = key.stringValue.data(using: .utf8) {
                    let bytes = [UInt8](utf8Data)
                    pairs.append(CBORMapPair(key: .textString(ArraySlice(bytes)), value: value))
                } else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Invalid UTF-8 data in key string"
                    ))
                }
            }
            
            // For map, we need to encode the pairs
            var encodedBytes: [UInt8] = []
            // Add map header
            CBOR.encodeUnsigned(major: 5, value: UInt64(pairs.count), into: &encodedBytes)
            
            // Add each key-value pair
            for pair in pairs {
                encodedBytes.append(contentsOf: pair.key.encode())
                encodedBytes.append(contentsOf: pair.value.encode())
            }
            
            self = .map(ArraySlice(encodedBytes))
            return
        }
        
        throw DecodingError.typeMismatch(CBOR.self, DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription: "Could not decode as any CBOR type"
        ))
    }
    
    /// Encodes an unsigned integer with the given major type
    ///
    /// - Parameters:
    ///   - major: The major type of the integer
    ///   - value: The unsigned integer value
    ///   - output: The output buffer to write the encoded bytes to
    private static func encodeUnsigned(major: UInt8, value: UInt64, into output: inout [UInt8]) {
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
}

// MARK: - Helper Types

struct CBORKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
    
    init(index: Int) {
        self.stringValue = String(index)
        self.intValue = index
    }
}
#endif