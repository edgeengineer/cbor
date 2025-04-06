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
        
        switch self {
        case .unsignedInt(let value):
            try container.encode(value)
        case .negativeInt(let value):
            try container.encode(value)
        case .byteString(let bytes):
            try container.encode(Data(bytes))
        case .textString(let string):
            try container.encode(string)
        case .array(let array):
            try container.encode(array)
        case .map(let pairs):
            var keyedContainer = encoder.container(keyedBy: CBORKey.self)
            for pair in pairs {
                switch pair.key {
                case .textString(let key):
                    try keyedContainer.encode(pair.value, forKey: CBORKey(stringValue: key))
                default:
                    throw EncodingError.invalidValue(pair.key, EncodingError.Context(
                        codingPath: encoder.codingPath,
                        debugDescription: "CBOR map keys must be text strings for Encodable"
                    ))
                }
            }
        case .tagged(let tag, let value):
            // Special handling for tagged values
            if tag == 1, case .float(let timeInterval) = value {
                // Tag 1 with a float is a standard date representation
                try container.encode(Date(timeIntervalSince1970: timeInterval))
            } else {
                // For other tags, encode as a special dictionary
                var keyedContainer = encoder.container(keyedBy: CBORKey.self)
                try keyedContainer.encode(tag, forKey: CBORKey(stringValue: "tag"))
                try keyedContainer.encode(value, forKey: CBORKey(stringValue: "value"))
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
            self = .textString(value)
            return
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
            self = .array(value)
            return
        }
        
        if let value = try? container.decode(Data.self) {
            self = .byteString([UInt8](value))
            return
        }
        
        // Try to decode as a map
        if let keyedContainer = try? decoder.container(keyedBy: CBORKey.self) {
            // Check if it's a tagged value
            if let tag = try? keyedContainer.decode(UInt64.self, forKey: CBORKey(stringValue: "tag")),
               let value = try? keyedContainer.decode(CBOR.self, forKey: CBORKey(stringValue: "value")) {
                self = .tagged(tag, value)
                return
            }
            
            // Otherwise decode as a regular map
            var pairs: [CBORMapPair] = []
            for key in keyedContainer.allKeys {
                let value = try keyedContainer.decode(CBOR.self, forKey: key)
                pairs.append(CBORMapPair(key: .textString(key.stringValue), value: value))
            }
            self = .map(pairs)
            return
        }
        
        throw DecodingError.typeMismatch(CBOR.self, DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription: "Could not decode as any CBOR type"
        ))
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