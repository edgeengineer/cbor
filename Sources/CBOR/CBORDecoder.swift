#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: - CBOR Decoder

/// A decoder that converts CBOR data to Swift values
public class CBORDecoder {
    public init() {}
    
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let bytes = [UInt8](data)
        let cbor = try CBOR.decode(bytes)
        let decoder = _CBORDecoderImpl(cbor: cbor, codingPath: [])
        return try T(from: decoder)
    }
}

private class _CBORDecoderImpl: Decoder {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any] = [:]
    
    private let cbor: CBOR
    
    init(cbor: CBOR, codingPath: [CodingKey]) {
        self.cbor = cbor
        self.codingPath = codingPath
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        guard case .map(let pairs) = cbor else {
            throw DecodingError.typeMismatch([String: Any].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode a map but found \(cbor)"
            ))
        }
        
        let container = CBORKeyedDecodingContainer<Key>(pairs: pairs, codingPath: codingPath)
        return KeyedDecodingContainer(container)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard case .array(let elements) = cbor else {
            throw DecodingError.typeMismatch([Any].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode an array but found \(cbor)"
            ))
        }
        
        return CBORUnkeyedDecodingContainer(elements: elements, codingPath: codingPath)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return CBORSingleValueDecodingContainer(cbor: cbor, codingPath: codingPath)
    }
}

// MARK: - CBOR Keyed Decoding Container

private struct CBORKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    var codingPath: [CodingKey]
    var allKeys: [K] {
        return pairs.compactMap { pair in
            if case .textString(let key) = pair.key {
                return K(stringValue: key)
            }
            return nil
        }
    }
    
    private let pairs: [CBORMapPair]
    
    init(pairs: [CBORMapPair], codingPath: [CodingKey]) {
        self.pairs = pairs
        self.codingPath = codingPath
    }
    
    private func getValue(forKey key: K) -> CBOR? {
        for pair in pairs {
            if case .textString(let keyString) = pair.key, keyString == key.stringValue {
                return pair.value
            }
        }
        return nil
    }
    
    func contains(_ key: K) -> Bool {
        return getValue(forKey: key) != nil
    }
    
    func decodeNil(forKey key: K) throws -> Bool {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        return value == .null
    }
    
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        guard case .bool(let boolValue) = value else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode Bool but found \(value)"
            ))
        }
        
        return boolValue
    }
    
    func decode(_ type: String.Type, forKey key: K) throws -> String {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        guard case .textString(let stringValue) = value else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode String but found \(value)"
            ))
        }
        
        return stringValue
    }
    
    func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        switch value {
        case .float(let floatValue):
            return Double(floatValue)
        case .unsignedInt(let uintValue):
            return Double(uintValue)
        case .negativeInt(let intValue):
            return Double(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode Double but found \(value)"
            ))
        }
    }
    
    func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        switch value {
        case .float(let floatValue):
            return Float(floatValue) as Float
        case .unsignedInt(let uintValue):
            return Float(uintValue)
        case .negativeInt(let intValue):
            return Float(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode Float but found \(value)"
            ))
        }
    }
    
    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        switch value {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Value \(uintValue) overflows Int"
                ))
            }
            return Int(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int64(Int.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Value \(intValue) underflows Int"
                ))
            }
            return Int(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode Int but found \(value)"
            ))
        }
    }
    
    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        switch value {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int8.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Value \(uintValue) overflows Int8"
                ))
            }
            return Int8(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int(Int8.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Value \(intValue) underflows Int8"
                ))
            }
            return Int8(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode Int8 but found \(value)"
            ))
        }
    }
    
    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        switch value {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int16.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Value \(uintValue) overflows Int16"
                ))
            }
            return Int16(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int(Int16.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Value \(intValue) underflows Int16"
                ))
            }
            return Int16(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode Int16 but found \(value)"
            ))
        }
    }
    
    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        switch value {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int32.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Value \(uintValue) overflows Int32"
                ))
            }
            return Int32(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int(Int32.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Value \(intValue) underflows Int32"
                ))
            }
            return Int32(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode Int32 but found \(value)"
            ))
        }
    }
    
    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        switch value {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int64.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Value \(uintValue) overflows Int64"
                ))
            }
            return Int64(uintValue)
        case .negativeInt(let intValue):
            return Int64(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode Int64 but found \(value)"
            ))
        }
    }
    
    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        switch value {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(UInt.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Value \(uintValue) overflows UInt"
                ))
            }
            return UInt(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode UInt but found \(value)"
            ))
        }
    }
    
    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        switch value {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(UInt8.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Value \(uintValue) overflows UInt8"
                ))
            }
            return UInt8(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode UInt8 but found \(value)"
            ))
        }
    }
    
    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        switch value {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(UInt16.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Value \(uintValue) overflows UInt16"
                ))
            }
            return UInt16(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode UInt16 but found \(value)"
            ))
        }
    }
    
    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        switch value {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(UInt32.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Value \(uintValue) overflows UInt32"
                ))
            }
            return UInt32(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode UInt32 but found \(value)"
            ))
        }
    }
    
    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        switch value {
        case .unsignedInt(let uintValue):
            return uintValue
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode UInt64 but found \(value)"
            ))
        }
    }
    
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        // Special case for Data
        if type == Data.self {
            guard case .byteString(let bytes) = value else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Expected to decode Data but found \(value)"
                ))
            }
            return Data(bytes) as! T
        }
        
        // Special case for Date
        if type == Date.self {
            if case .tagged(1, let taggedValue) = value {
                if case .float(let timeInterval) = taggedValue {
                    return Date(timeIntervalSince1970: timeInterval) as! T
                }
            }
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode Date but found \(value)"
            ))
        }
        
        // Special case for URL
        if type == URL.self {
            guard case .textString(let urlString) = value else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Expected to decode URL but found \(value)"
                ))
            }
            
            guard let url = URL(string: urlString) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Invalid URL string: \(urlString)"
                ))
            }
            
            return url as! T
        }
        
        // For other Decodable types, use a nested decoder
        let decoder = _CBORDecoderImpl(cbor: value, codingPath: codingPath + [key])
        return try T(from: decoder)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        guard case .map(let pairs) = value else {
            throw DecodingError.typeMismatch([String: Any].self, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode a map but found \(value)"
            ))
        }
        
        let container = CBORKeyedDecodingContainer<NestedKey>(pairs: pairs, codingPath: codingPath + [key])
        return KeyedDecodingContainer(container)
    }
    
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        guard case .array(let elements) = value else {
            throw DecodingError.typeMismatch([Any].self, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode an array but found \(value)"
            ))
        }
        
        return CBORUnkeyedDecodingContainer(elements: elements, codingPath: codingPath + [key])
    }
    
    func superDecoder() throws -> Decoder {
        return _CBORDecoderImpl(cbor: .map(pairs), codingPath: codingPath)
    }
    
    func superDecoder(forKey key: K) throws -> Decoder {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        return _CBORDecoderImpl(cbor: value, codingPath: codingPath + [key])
    }
}
