#if !hasFeature(Embedded)
#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: - CBOR Decoder

/// A decoder that converts CBOR data to Swift values
public final class CBORDecoder: Decoder {
    private var cbor: CBOR
    public var codingPath: [CodingKey]
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    
    public init() {
        self.cbor = .null
        self.codingPath = []
    }
    
    public func decode<T>(_ type: T.Type, from data: [UInt8]) throws -> T where T: Decodable {
        // First decode the CBOR value from the data
        let cbor = try CBOR.decode(data)
        
        // Special case for arrays
        if type == [Data].self, case .byteString = cbor {
            // If we're trying to decode a byteString as an array of Data,
            // wrap it in an array with a single element
            let dataArray = [Data(data)]
            return dataArray as! T
        }
        
        // Then use the regular decoder to decode the value
        let decoder = CBORDecoder(cbor: cbor, codingPath: [])
        return try decoder.decode(type)
    }
    
    public func decode<T>(_ type: T.Type, from cbor: CBOR) throws -> T where T: Decodable {
        self.cbor = cbor
        return try T(from: self)
    }
    
    // Make the initializer public to allow creating instances with specific CBOR values and coding paths
    public init(cbor: CBOR, codingPath: [CodingKey]) {
        self.cbor = cbor
        self.codingPath = codingPath
    }
    
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        guard case .map(let pairs) = cbor else {
            throw DecodingError.typeMismatch([String: Any].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode a map but found \(cbor)"
            ))
        }
        
        let container = CBORKeyedDecodingContainer<Key>(pairs: pairs, codingPath: codingPath)
        return KeyedDecodingContainer(container)
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard case .array(let elements) = cbor else {
            throw DecodingError.typeMismatch([Any].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode an array but found \(cbor)"
            ))
        }
        
        return CBORUnkeyedDecodingContainer(elements: elements, codingPath: codingPath)
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return CBORSingleValueDecodingContainer(cbor: cbor, codingPath: codingPath)
    }
    
    public func decodeNil() throws -> Bool {
        return cbor == .null
    }
    
    public func decode(_ type: Bool.Type) throws -> Bool {
        guard case .bool(let boolValue) = cbor else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Bool but found \(cbor)"
            ))
        }
        
        return boolValue
    }
    
    public func decode(_ type: String.Type) throws -> String {
        guard case .textString(let stringValue) = cbor else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode String but found \(cbor)"
            ))
        }
        
        return stringValue
    }
    
    public func decode(_ type: Double.Type) throws -> Double {
        switch cbor {
        case .float(let floatValue):
            return Double(floatValue)
        case .unsignedInt(let uintValue):
            return Double(uintValue)
        case .negativeInt(let intValue):
            return Double(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Double but found \(cbor)"
            ))
        }
    }
    
    public func decode(_ type: Float.Type) throws -> Float {
        switch cbor {
        case .float(let floatValue):
            return Float(floatValue) as Float
        case .unsignedInt(let uintValue):
            return Float(uintValue)
        case .negativeInt(let intValue):
            return Float(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Float but found \(cbor)"
            ))
        }
    }
    
    public func decode(_ type: Int.Type) throws -> Int {
        switch cbor {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows Int"
                ))
            }
            return Int(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int64(Int.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(intValue) underflows Int"
                ))
            }
            return Int(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Int but found \(cbor)"
            ))
        }
    }
    
    public func decode(_ type: Int8.Type) throws -> Int8 {
        switch cbor {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int8.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows Int8"
                ))
            }
            return Int8(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int(Int8.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(intValue) underflows Int8"
                ))
            }
            return Int8(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Int8 but found \(cbor)"
            ))
        }
    }
    
    public func decode(_ type: Int16.Type) throws -> Int16 {
        switch cbor {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int16.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows Int16"
                ))
            }
            return Int16(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int(Int16.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(intValue) underflows Int16"
                ))
            }
            return Int16(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Int16 but found \(cbor)"
            ))
        }
    }
    
    public func decode(_ type: Int32.Type) throws -> Int32 {
        switch cbor {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int32.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows Int32"
                ))
            }
            return Int32(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int(Int32.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(intValue) underflows Int32"
                ))
            }
            return Int32(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Int32 but found \(cbor)"
            ))
        }
    }
    
    public func decode(_ type: Int64.Type) throws -> Int64 {
        switch cbor {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int64.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows Int64"
                ))
            }
            return Int64(uintValue)
        case .negativeInt(let intValue):
            return Int64(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Int64 but found \(cbor)"
            ))
        }
    }
    
    public func decode(_ type: UInt.Type) throws -> UInt {
        switch cbor {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(UInt.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows UInt"
                ))
            }
            return UInt(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode UInt but found \(cbor)"
            ))
        }
    }
    
    public func decode(_ type: UInt8.Type) throws -> UInt8 {
        switch cbor {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(UInt8.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows UInt8"
                ))
            }
            return UInt8(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode UInt8 but found \(cbor)"
            ))
        }
    }
    
    public func decode(_ type: UInt16.Type) throws -> UInt16 {
        switch cbor {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(UInt16.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows UInt16"
                ))
            }
            return UInt16(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode UInt16 but found \(cbor)"
            ))
        }
    }
    
    public func decode(_ type: UInt32.Type) throws -> UInt32 {
        switch cbor {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(UInt32.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows UInt32"
                ))
            }
            return UInt32(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode UInt32 but found \(cbor)"
            ))
        }
    }
    
    public func decode(_ type: UInt64.Type) throws -> UInt64 {
        switch cbor {
        case .unsignedInt(let uintValue):
            return uintValue
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode UInt64 but found \(cbor)"
            ))
        }
    }
    
    public func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        // Special case for Data
        if type == Data.self {
            if case .byteString(let bytes) = cbor {
                return Data(bytes) as! T
            }
            
            // If we're trying to decode an array of bytes as Data
            if case .array(let elements) = cbor {
                // Check if all elements are integers
                var bytes: [UInt8] = []
                for element in elements {
                    if case .unsignedInt(let value) = element, value <= UInt64(UInt8.max) {
                        bytes.append(UInt8(value))
                    } else {
                        throw DecodingError.typeMismatch(type, DecodingError.Context(
                            codingPath: codingPath,
                            debugDescription: "Expected to decode Data but found array with non-byte element: \(element)"
                        ))
                    }
                }
                return Data(bytes) as! T
            }
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Data but found \(cbor)"
            ))
        }
        
        // Special case for arrays of Data
        if type == [Data].self {
            guard case .array(let elements) = cbor else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Expected to decode an array but found \(cbor)"
                ))
            }
            
            var dataArray: [Data] = []
            for element in elements {
                if case .byteString(let bytes) = element {
                    dataArray.append(Data(bytes))
                } else {
                    throw DecodingError.typeMismatch(type, DecodingError.Context(
                        codingPath: codingPath,
                        debugDescription: "Expected to decode an array of Data but found \(element)"
                    ))
                }
            }
            return dataArray as! T
        }
        
        // Special case for Date
        if type == Date.self {
            // First check for tagged date value (tag 1)
            if case .tagged(1, let taggedValue) = cbor {
                if case .float(let timeInterval) = taggedValue {
                    return Date(timeIntervalSince1970: timeInterval) as! T
                } else if case .unsignedInt(let timestamp) = taggedValue {
                    return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
                } else if case .negativeInt(let timestamp) = taggedValue {
                    return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
                }
            }
            
            // Also try to handle untagged float as a date for backward compatibility
            if case .float(let timeInterval) = cbor {
                return Date(timeIntervalSince1970: timeInterval) as! T
            } else if case .unsignedInt(let timestamp) = cbor {
                return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
            } else if case .negativeInt(let timestamp) = cbor {
                return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
            }
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Date but found \(cbor)"
            ))
        }
        
        // Special case for URL
        if type == URL.self {
            guard case .textString(let urlString) = cbor else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Expected to decode URL but found \(cbor)"
                ))
            }
            
            guard let url = URL(string: urlString) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Invalid URL string: \(urlString)"
                ))
            }
            
            return url as! T
        }
        
        // For other Decodable types, use a nested decoder
        let decoder = CBORDecoder(cbor: cbor, codingPath: codingPath)
        return try T(from: decoder)
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
            if case .byteString(let bytes) = value {
                return Data(bytes) as! T
            }
            
            // If we're trying to decode an array of bytes as Data
            if case .array(let elements) = value {
                // Check if all elements are integers
                var bytes: [UInt8] = []
                for element in elements {
                    if case .unsignedInt(let value) = element, value <= UInt64(UInt8.max) {
                        bytes.append(UInt8(value))
                    } else {
                        throw DecodingError.typeMismatch(type, DecodingError.Context(
                            codingPath: codingPath + [key],
                            debugDescription: "Expected to decode Data but found array with non-byte element: \(element)"
                        ))
                    }
                }
                return Data(bytes) as! T
            }
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode Data but found \(value)"
            ))
        }
        
        // Special case for arrays of Data
        if type == [Data].self {
            guard case .array(let elements) = value else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Expected to decode an array but found \(value)"
                ))
            }
            
            var dataArray: [Data] = []
            for element in elements {
                if case .byteString(let bytes) = element {
                    dataArray.append(Data(bytes))
                } else {
                    throw DecodingError.typeMismatch(type, DecodingError.Context(
                        codingPath: codingPath + [key],
                        debugDescription: "Expected to decode an array of Data but found \(element)"
                    ))
                }
            }
            return dataArray as! T
        }
        
        // Special case for Date
        if type == Date.self {
            // First check for tagged date value (tag 1)
            if case .tagged(1, let taggedValue) = value {
                if case .float(let timeInterval) = taggedValue {
                    return Date(timeIntervalSince1970: timeInterval) as! T
                } else if case .unsignedInt(let timestamp) = taggedValue {
                    return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
                } else if case .negativeInt(let timestamp) = taggedValue {
                    return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
                }
            }
            
            // Also try to handle untagged float as a date for backward compatibility
            if case .float(let timeInterval) = value {
                return Date(timeIntervalSince1970: timeInterval) as! T
            } else if case .unsignedInt(let timestamp) = value {
                return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
            } else if case .negativeInt(let timestamp) = value {
                return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
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
        let decoder = CBORDecoder(cbor: value, codingPath: codingPath + [key])
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
        return CBORDecoder(cbor: .map(pairs), codingPath: codingPath)
    }
    
    func superDecoder(forKey key: K) throws -> Decoder {
        guard let value = getValue(forKey: key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "No value associated with key \(key.stringValue)"
            ))
        }
        
        return CBORDecoder(cbor: value, codingPath: codingPath + [key])
    }
}

// MARK: - CBOR Unkeyed Decoding Container

private struct CBORUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    var codingPath: [CodingKey]
    var count: Int? {
        return elements.count
    }
    var isAtEnd: Bool {
        return currentIndex >= elements.count
    }
    var currentIndex: Int = 0
    
    private let elements: [CBOR]
    
    init(elements: [CBOR], codingPath: [CodingKey]) {
        self.elements = elements
        self.codingPath = codingPath
    }
    
    private func checkIndex() throws {
        if isAtEnd {
            throw DecodingError.valueNotFound(Any.self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Unkeyed container is at end"
            ))
        }
    }
    
    mutating func decodeNil() throws -> Bool {
        try checkIndex()
        
        if elements[currentIndex] == .null {
            currentIndex += 1
            return true
        }
        
        return false
    }
    
    mutating func decode(_ type: Bool.Type) throws -> Bool {
        try checkIndex()
        
        guard case .bool(let boolValue) = elements[currentIndex] else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Bool but found \(elements[currentIndex])"
            ))
        }
        
        currentIndex += 1
        return boolValue
    }
    
    mutating func decode(_ type: String.Type) throws -> String {
        try checkIndex()
        
        guard case .textString(let stringValue) = elements[currentIndex] else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode String but found \(elements[currentIndex])"
            ))
        }
        
        currentIndex += 1
        return stringValue
    }
    
    mutating func decode(_ type: Double.Type) throws -> Double {
        try checkIndex()
        
        let value = elements[currentIndex]
        currentIndex += 1
        
        switch value {
        case .float(let floatValue):
            return Double(floatValue)
        case .unsignedInt(let uintValue):
            return Double(uintValue)
        case .negativeInt(let intValue):
            return Double(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Double but found \(value)"
            ))
        }
    }
    
    mutating func decode(_ type: Float.Type) throws -> Float {
        try checkIndex()
        
        let value = elements[currentIndex]
        currentIndex += 1
        
        switch value {
        case .float(let floatValue):
            return Float(floatValue) as Float
        case .unsignedInt(let uintValue):
            return Float(uintValue)
        case .negativeInt(let intValue):
            return Float(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Float but found \(value)"
            ))
        }
    }
    
    mutating func decode(_ type: Int.Type) throws -> Int {
        try checkIndex()
        
        let value = elements[currentIndex]
        currentIndex += 1
        
        switch value {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows Int"
                ))
            }
            return Int(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int64(Int.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(intValue) underflows Int"
                ))
            }
            return Int(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Int but found \(value)"
            ))
        }
    }
    
    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        try checkIndex()
        
        let value = elements[currentIndex]
        currentIndex += 1
        
        switch value {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int8.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows Int8"
                ))
            }
            return Int8(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int(Int8.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(intValue) underflows Int8"
                ))
            }
            return Int8(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Int8 but found \(value)"
            ))
        }
    }
    
    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        try checkIndex()
        
        let value = elements[currentIndex]
        currentIndex += 1
        
        switch value {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int16.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows Int16"
                ))
            }
            return Int16(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int(Int16.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(intValue) underflows Int16"
                ))
            }
            return Int16(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Int16 but found \(value)"
            ))
        }
    }
    
    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        try checkIndex()
        
        let value = elements[currentIndex]
        currentIndex += 1
        
        switch value {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int32.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows Int32"
                ))
            }
            return Int32(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int(Int32.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(intValue) underflows Int32"
                ))
            }
            return Int32(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Int32 but found \(value)"
            ))
        }
    }
    
    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        try checkIndex()
        
        let value = elements[currentIndex]
        currentIndex += 1
        
        switch value {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int64.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows Int64"
                ))
            }
            return Int64(uintValue)
        case .negativeInt(let intValue):
            return intValue
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Int64 but found \(value)"
            ))
        }
    }
    
    mutating func decode(_ type: UInt.Type) throws -> UInt {
        try checkIndex()
        
        let value = elements[currentIndex]
        currentIndex += 1
        
        switch value {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(UInt.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows UInt"
                ))
            }
            return UInt(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode UInt but found \(value)"
            ))
        }
    }
    
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        try checkIndex()
        
        let value = elements[currentIndex]
        currentIndex += 1
        
        switch value {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(UInt8.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows UInt8"
                ))
            }
            return UInt8(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode UInt8 but found \(value)"
            ))
        }
    }
    
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        try checkIndex()
        
        let value = elements[currentIndex]
        currentIndex += 1
        
        switch value {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(UInt16.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows UInt16"
                ))
            }
            return UInt16(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode UInt16 but found \(value)"
            ))
        }
    }
    
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        try checkIndex()
        
        let value = elements[currentIndex]
        currentIndex += 1
        
        switch value {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(UInt32.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows UInt32"
                ))
            }
            return UInt32(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode UInt32 but found \(value)"
            ))
        }
    }
    
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        try checkIndex()
        
        let value = elements[currentIndex]
        currentIndex += 1
        
        switch value {
        case .unsignedInt(let uintValue):
            return uintValue
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode UInt64 but found \(value)"
            ))
        }
    }
    
    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        try checkIndex()
        
        let value = elements[currentIndex]
        currentIndex += 1
        
        // Special case for Data
        if type == Data.self {
            if case .byteString(let bytes) = value {
                return Data(bytes) as! T
            }
            
            // If we're trying to decode an array of bytes as Data
            if case .array(let elements) = value {
                // Check if all elements are integers
                var bytes: [UInt8] = []
                for element in elements {
                    if case .unsignedInt(let value) = element, value <= UInt64(UInt8.max) {
                        bytes.append(UInt8(value))
                    } else {
                        throw DecodingError.typeMismatch(type, DecodingError.Context(
                            codingPath: codingPath,
                            debugDescription: "Expected to decode Data but found array with non-byte element: \(element)"
                        ))
                    }
                }
                return Data(bytes) as! T
            }
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Data but found \(value)"
            ))
        }
        
        // Special case for arrays of Data
        if type == [Data].self {
            guard case .array(let elements) = value else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Expected to decode an array but found \(value)"
                ))
            }
            
            var dataArray: [Data] = []
            for element in elements {
                if case .byteString(let bytes) = element {
                    dataArray.append(Data(bytes))
                } else {
                    throw DecodingError.typeMismatch(type, DecodingError.Context(
                        codingPath: codingPath,
                        debugDescription: "Expected to decode an array of Data but found \(element)"
                    ))
                }
            }
            return dataArray as! T
        }
        
        // Special case for Date
        if type == Date.self {
            // First check for tagged date value (tag 1)
            if case .tagged(1, let taggedValue) = value {
                if case .float(let timeInterval) = taggedValue {
                    return Date(timeIntervalSince1970: timeInterval) as! T
                } else if case .unsignedInt(let timestamp) = taggedValue {
                    return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
                } else if case .negativeInt(let timestamp) = taggedValue {
                    return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
                }
            }
            
            // Also try to handle untagged float as a date for backward compatibility
            if case .float(let timeInterval) = value {
                return Date(timeIntervalSince1970: timeInterval) as! T
            } else if case .unsignedInt(let timestamp) = value {
                return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
            } else if case .negativeInt(let timestamp) = value {
                return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
            }
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Date but found \(value)"
            ))
        }
        
        // Special case for URL
        if type == URL.self {
            guard case .textString(let urlString) = value else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Expected to decode URL but found \(value)"
                ))
            }
            
            guard let url = URL(string: urlString) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Invalid URL string: \(urlString)"
                ))
            }
            
            return url as! T
        }
        
        // For other Decodable types, use a nested decoder
        let decoder = CBORDecoder(cbor: value, codingPath: codingPath)
        return try T(from: decoder)
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        try checkIndex()
        
        let value = elements[currentIndex]
        currentIndex += 1
        
        guard case .map(let pairs) = value else {
            throw DecodingError.typeMismatch([String: Any].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode a map but found \(value)"
            ))
        }
        
        let container = CBORKeyedDecodingContainer<NestedKey>(pairs: pairs, codingPath: codingPath)
        return KeyedDecodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        try checkIndex()
        
        let value = elements[currentIndex]
        currentIndex += 1
        
        guard case .array(let elements) = value else {
            throw DecodingError.typeMismatch([Any].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode an array but found \(value)"
            ))
        }
        
        return CBORUnkeyedDecodingContainer(elements: elements, codingPath: codingPath)
    }
    
    mutating func superDecoder() throws -> Decoder {
        try checkIndex()
        
        let value = elements[currentIndex]
        currentIndex += 1
        
        return CBORDecoder(cbor: value, codingPath: codingPath)
    }
}

// MARK: - CBOR Single Value Decoding Container

internal struct CBORSingleValueDecodingContainer: SingleValueDecodingContainer {
    var codingPath: [CodingKey]
    internal let cbor: CBOR
    
    init(cbor: CBOR, codingPath: [CodingKey]) {
        self.cbor = cbor
        self.codingPath = codingPath
    }
    
    func decodeNil() -> Bool {
        return cbor == .null
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        guard case .bool(let boolValue) = cbor else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Bool but found \(cbor)"
            ))
        }
        
        return boolValue
    }
    
    func decode(_ type: String.Type) throws -> String {
        guard case .textString(let stringValue) = cbor else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode String but found \(cbor)"
            ))
        }
        
        return stringValue
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        switch cbor {
        case .float(let floatValue):
            return Double(floatValue)
        case .unsignedInt(let uintValue):
            return Double(uintValue)
        case .negativeInt(let intValue):
            return Double(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Double but found \(cbor)"
            ))
        }
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        switch cbor {
        case .float(let floatValue):
            return Float(floatValue) as Float
        case .unsignedInt(let uintValue):
            return Float(uintValue)
        case .negativeInt(let intValue):
            return Float(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Float but found \(cbor)"
            ))
        }
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        switch cbor {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows Int"
                ))
            }
            return Int(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int64(Int.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(intValue) underflows Int"
                ))
            }
            return Int(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Int but found \(cbor)"
            ))
        }
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        switch cbor {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int8.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows Int8"
                ))
            }
            return Int8(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int(Int8.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(intValue) underflows Int8"
                ))
            }
            return Int8(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Int8 but found \(cbor)"
            ))
        }
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        switch cbor {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int16.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows Int16"
                ))
            }
            return Int16(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int(Int16.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(intValue) underflows Int16"
                ))
            }
            return Int16(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Int16 but found \(cbor)"
            ))
        }
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        switch cbor {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int32.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows Int32"
                ))
            }
            return Int32(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int(Int32.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(intValue) underflows Int32"
                ))
            }
            return Int32(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Int32 but found \(cbor)"
            ))
        }
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        switch cbor {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(Int64.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows Int64"
                ))
            }
            return Int64(uintValue)
        case .negativeInt(let intValue):
            return intValue
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Int64 but found \(cbor)"
            ))
        }
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        switch cbor {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(UInt.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows UInt"
                ))
            }
            return UInt(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode UInt but found \(cbor)"
            ))
        }
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        switch cbor {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(UInt8.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows UInt8"
                ))
            }
            return UInt8(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode UInt8 but found \(cbor)"
            ))
        }
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        switch cbor {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(UInt16.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows UInt16"
                ))
            }
            return UInt16(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode UInt16 but found \(cbor)"
            ))
        }
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        switch cbor {
        case .unsignedInt(let uintValue):
            guard uintValue <= UInt64(UInt32.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Value \(uintValue) overflows UInt32"
                ))
            }
            return UInt32(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode UInt32 but found \(cbor)"
            ))
        }
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        switch cbor {
        case .unsignedInt(let uintValue):
            return uintValue
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode UInt64 but found \(cbor)"
            ))
        }
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        // Special case for Data
        if type == Data.self {
            if case .byteString(let bytes) = cbor {
                return Data(bytes) as! T
            }
            
            // If we're trying to decode an array of bytes as Data
            if case .array(let elements) = cbor {
                // Check if all elements are integers
                var bytes: [UInt8] = []
                for element in elements {
                    if case .unsignedInt(let value) = element, value <= UInt64(UInt8.max) {
                        bytes.append(UInt8(value))
                    } else {
                        throw DecodingError.typeMismatch(type, DecodingError.Context(
                            codingPath: codingPath,
                            debugDescription: "Expected to decode Data but found array with non-byte element: \(element)"
                        ))
                    }
                }
                return Data(bytes) as! T
            }
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Data but found \(cbor)"
            ))
        }
        
        // Special case for arrays of Data
        if type == [Data].self {
            guard case .array(let elements) = cbor else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Expected to decode an array but found \(cbor)"
                ))
            }
            
            var dataArray: [Data] = []
            for element in elements {
                if case .byteString(let bytes) = element {
                    dataArray.append(Data(bytes))
                } else {
                    throw DecodingError.typeMismatch(type, DecodingError.Context(
                        codingPath: codingPath,
                        debugDescription: "Expected to decode an array of Data but found \(element)"
                    ))
                }
            }
            return dataArray as! T
        }
        
        // Special case for Date
        if type == Date.self {
            // First check for tagged date value (tag 1)
            if case .tagged(1, let taggedValue) = cbor {
                if case .float(let timeInterval) = taggedValue {
                    return Date(timeIntervalSince1970: timeInterval) as! T
                } else if case .unsignedInt(let timestamp) = taggedValue {
                    return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
                } else if case .negativeInt(let timestamp) = taggedValue {
                    return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
                }
            }
            
            // Also try to handle untagged float as a date for backward compatibility
            if case .float(let timeInterval) = cbor {
                return Date(timeIntervalSince1970: timeInterval) as! T
            } else if case .unsignedInt(let timestamp) = cbor {
                return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
            } else if case .negativeInt(let timestamp) = cbor {
                return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
            }
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Date but found \(cbor)"
            ))
        }
        
        // Special case for URL
        if type == URL.self {
            guard case .textString(let urlString) = cbor else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Expected to decode URL but found \(cbor)"
                ))
            }
            
            guard let url = URL(string: urlString) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Invalid URL string: \(urlString)"
                ))
            }
            
            return url as! T
        }
        
        // For other Decodable types, use a nested decoder
        let decoder = CBORDecoder(cbor: cbor, codingPath: codingPath)
        return try T(from: decoder)
    }
}
#endif