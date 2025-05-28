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
        guard case .map(_) = cbor else {
            throw DecodingError.typeMismatch([String: Any].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode a map but found \(cbor)"
            ))
        }
        
        // Decode the map bytes to get the pairs
        let pairs = try cbor.mapValue() ?? []
        
        let container = CBORKeyedDecodingContainer<Key>(pairs: pairs, codingPath: codingPath)
        return KeyedDecodingContainer(container)
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard case .array(_) = cbor else {
            throw DecodingError.typeMismatch([Any].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode an array but found \(cbor)"
            ))
        }
        
        // Decode the array bytes to get the elements
        let elements = try cbor.arrayValue() ?? []
        
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
    
    // Helper method to convert CBOR text string bytes to a Swift String
    static func bytesToString(_ bytes: ArraySlice<UInt8>) throws -> String {
        guard let string = String(data: Data(bytes), encoding: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [],
                debugDescription: "Invalid UTF-8 data in CBOR text string"
            ))
        }
        return string
    }
    
    public func decode(_ type: String.Type) throws -> String {
        switch cbor {
        case .textString(let bytes):
            return try CBORDecoder.bytesToString(bytes)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode String but found \(cbor)"
            ))
        }
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
            return intValue
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
                return Data(Array(bytes)) as! T
            }
        }
        
        // Special case for Date
        if type == Date.self {
            // First check for tagged date value (tag 1)
            if case .tagged(let tag, let valueBytes) = cbor {
                if tag == 1 {
                    // Decode the tagged value
                    if let taggedValue = try? CBOR.decode(valueBytes) {
                        if case .unsignedInt(let timestamp) = taggedValue {
                            // RFC 8949 section 3.4.1: Tag 1 is for epoch timestamp
                            return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
                        } else if case .negativeInt(let timestamp) = taggedValue {
                            // Handle negative timestamps
                            return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
                        } else if case .float(let timestamp) = taggedValue {
                            // Handle floating-point timestamps
                            return Date(timeIntervalSince1970: timestamp) as! T
                        }
                    }
                }
            }
            
            // Try ISO8601 string
            if case .textString(let bytes) = cbor {
                if let string = try? CBORDecoder.bytesToString(bytes) {
                    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
                    let formatter = ISO8601DateFormatter()
                    if let date = formatter.date(from: string) {
                        return date as! T
                    }
                    #endif
                }
            }
        }
        
        // Special case for URL
        if type == URL.self {
            if case .textString(let bytes) = cbor {
                if let string = try? CBORDecoder.bytesToString(bytes) {
                    if let url = URL(string: string) {
                        return url as! T
                    } else {
                        throw DecodingError.dataCorrupted(DecodingError.Context(
                            codingPath: codingPath,
                            debugDescription: "Invalid URL string: \(string)"
                        ))
                    }
                }
            }
        }
        
        // Special case for arrays of primitive types
        if type == [UInt8].self {
            if case .byteString(let bytes) = cbor {
                return Array(bytes) as! T
            }
            
            if case .array(_) = cbor {
                // Decode the array
                if let array = try cbor.arrayValue() {
                    var bytes: [UInt8] = []
                    for element in array {
                        if case .unsignedInt(let value) = element, value <= UInt64(UInt8.max) {
                            bytes.append(UInt8(value))
                        } else {
                            throw DecodingError.typeMismatch(type, DecodingError.Context(
                                codingPath: codingPath,
                                debugDescription: "Expected to decode [UInt8] but array contains non-UInt8 values"
                            ))
                        }
                    }
                    return bytes as! T
                }
            }
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode [UInt8] but found \(cbor)"
            ))
        }
        
        if type == [Data].self {
            if case .array(_) = cbor {
                // Decode the array
                if let array = try cbor.arrayValue() {
                    var dataArray: [Data] = []
                    for element in array {
                        if case .byteString(let bytes) = element {
                            dataArray.append(Data(Array(bytes)))
                        } else {
                            throw DecodingError.typeMismatch(type, DecodingError.Context(
                                codingPath: codingPath,
                                debugDescription: "Expected to decode [Data] but array contains non-byteString values"
                            ))
                        }
                    }
                    return dataArray as! T
                }
            }
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode [Data] but found \(cbor)"
            ))
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
            if case .textString(let bytes) = pair.key {
                if let string = try? CBORDecoder.bytesToString(bytes) {
                    return K(stringValue: string)
                }
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
            if case .textString(let keyString) = pair.key {
                if let string = try? CBORDecoder.bytesToString(keyString) {
                    if string == key.stringValue {
                        return pair.value
                    }
                }
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
        
        return try CBORDecoder.bytesToString(stringValue)
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
            return intValue
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
                return Data(Array(bytes)) as! T
            }
        }
        
        // Special case for Date
        if type == Date.self {
            // First check for tagged date value (tag 1)
            if case .tagged(let tag, let valueBytes) = value {
                if tag == 1 {
                    // Decode the tagged value
                    if let taggedValue = try? CBOR.decode(valueBytes) {
                        if case .unsignedInt(let timestamp) = taggedValue {
                            // RFC 8949 section 3.4.1: Tag 1 is for epoch timestamp
                            return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
                        } else if case .negativeInt(let timestamp) = taggedValue {
                            // Handle negative timestamps
                            return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
                        } else if case .float(let timestamp) = taggedValue {
                            // Handle floating-point timestamps
                            return Date(timeIntervalSince1970: timestamp) as! T
                        }
                    }
                }
            }
            
            // Try ISO8601 string
            if case .textString(let bytes) = value {
                if let string = try? CBORDecoder.bytesToString(bytes) {
                    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
                    let formatter = ISO8601DateFormatter()
                    if let date = formatter.date(from: string) {
                        return date as! T
                    }
                    #endif
                }
            }
        }
        
        // Special case for URL
        if type == URL.self {
            if case .textString(let bytes) = value {
                if let string = try? CBORDecoder.bytesToString(bytes) {
                    if let url = URL(string: string) {
                        return url as! T
                    } else {
                        throw DecodingError.dataCorrupted(DecodingError.Context(
                            codingPath: codingPath + [key],
                            debugDescription: "Invalid URL string: \(string)"
                        ))
                    }
                }
            } else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(
                    codingPath: codingPath + [key],
                    debugDescription: "Expected to decode URL but found \(value)"
                ))
            }
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
        
        guard case .map(_) = value else {
            throw DecodingError.typeMismatch([String: Any].self, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode a map but found \(value)"
            ))
        }
        
        // Decode the map bytes to get the pairs
        let pairs = try value.mapValue() ?? []
        
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
        
        guard case .array(_) = value else {
            throw DecodingError.typeMismatch([Any].self, DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected to decode an array but found \(value)"
            ))
        }
        
        // Decode the array bytes to get the elements
        let elements = try value.arrayValue() ?? []
        
        return CBORUnkeyedDecodingContainer(elements: elements, codingPath: codingPath + [key])
    }
    
    func superDecoder() throws -> Decoder {
        // Encode the map pairs into a byte array
        var encodedBytes: [UInt8] = []
        // Add map header
        encodeUnsigned(major: 5, value: UInt64(pairs.count), into: &encodedBytes)
        
        // Add each key-value pair
        for pair in pairs {
            encodedBytes.append(contentsOf: pair.key.encode())
            encodedBytes.append(contentsOf: pair.value.encode())
        }
        
        return CBORDecoder(cbor: .map(ArraySlice(encodedBytes)), codingPath: codingPath)
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
        
        guard case .textString(let bytes) = elements[currentIndex] else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode String but found \(elements[currentIndex])"
            ))
        }
        
        currentIndex += 1
        return try CBORDecoder.bytesToString(bytes)
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
                return Data(Array(bytes)) as! T
            }
        }
        
        // Special case for Date
        if type == Date.self {
            // First check for tagged date value (tag 1)
            if case .tagged(let tag, let valueBytes) = value {
                if tag == 1 {
                    // Decode the tagged value
                    if let taggedValue = try? CBOR.decode(valueBytes) {
                        if case .unsignedInt(let timestamp) = taggedValue {
                            // RFC 8949 section 3.4.1: Tag 1 is for epoch timestamp
                            return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
                        } else if case .negativeInt(let timestamp) = taggedValue {
                            // Handle negative timestamps
                            return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
                        } else if case .float(let timestamp) = taggedValue {
                            // Handle floating-point timestamps
                            return Date(timeIntervalSince1970: timestamp) as! T
                        }
                    }
                }
            }
            
            // Try ISO8601 string
            if case .textString(let bytes) = value {
                if let string = try? CBORDecoder.bytesToString(bytes) {
                    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
                    let formatter = ISO8601DateFormatter()
                    if let date = formatter.date(from: string) {
                        return date as! T
                    }
                    #endif
                }
            }
        }
        
        // Special case for URL
        if type == URL.self {
            if case .textString(let bytes) = value {
                if let string = try? CBORDecoder.bytesToString(bytes) {
                    if let url = URL(string: string) {
                        return url as! T
                    } else {
                        throw DecodingError.dataCorrupted(DecodingError.Context(
                            codingPath: codingPath,
                            debugDescription: "Invalid URL string"
                        ))
                    }
                }
            }
        }
        
        // Special case for arrays of primitive types
        if type == [UInt8].self {
            if case .byteString(let bytes) = value {
                return Array(bytes) as! T
            }
            
            if case .array(_) = value {
                // Decode the array
                if let array = try value.arrayValue() {
                    var bytes: [UInt8] = []
                    for element in array {
                        if case .unsignedInt(let value) = element, value <= UInt64(UInt8.max) {
                            bytes.append(UInt8(value))
                        } else {
                            throw DecodingError.typeMismatch(type, DecodingError.Context(
                                codingPath: codingPath,
                                debugDescription: "Expected to decode [UInt8] but array contains non-UInt8 values"
                            ))
                        }
                    }
                    return bytes as! T
                }
            }
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode [UInt8] but found \(value)"
            ))
        }
        
        if type == [Data].self {
            if case .array(_) = value {
                // Decode the array
                if let array = try value.arrayValue() {
                    var dataArray: [Data] = []
                    for element in array {
                        if case .byteString(let bytes) = element {
                            dataArray.append(Data(Array(bytes)))
                        } else {
                            throw DecodingError.typeMismatch(type, DecodingError.Context(
                                codingPath: codingPath,
                                debugDescription: "Expected to decode [Data] but array contains non-byteString values"
                            ))
                        }
                    }
                    return dataArray as! T
                }
            }
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode [Data] but found \(value)"
            ))
        }
        
        // For other Decodable types, use a nested decoder
        let decoder = CBORDecoder(cbor: value, codingPath: codingPath)
        return try T(from: decoder)
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        try checkIndex()
        
        let value = elements[currentIndex]
        currentIndex += 1
        
        guard case .map(_) = value else {
            throw DecodingError.typeMismatch([String: Any].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode a map but found \(value)"
            ))
        }
        
        // Decode the map bytes to get the pairs
        let pairs = try value.mapValue() ?? []
        
        let container = CBORKeyedDecodingContainer<NestedKey>(pairs: pairs, codingPath: codingPath)
        return KeyedDecodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        try checkIndex()
        
        let value = elements[currentIndex]
        currentIndex += 1
        
        guard case .array(_) = value else {
            throw DecodingError.typeMismatch([Any].self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode an array but found \(value)"
            ))
        }
        
        // Decode the array bytes to get the elements
        let elements = try value.arrayValue() ?? []
        
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
        guard case .textString(let bytes) = cbor else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode String but found \(cbor)"
            ))
        }
        
        return try CBORDecoder.bytesToString(bytes)
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
                return Data(Array(bytes)) as! T
            }
        }
        
        // Special case for Date
        if type == Date.self {
            // First check for tagged date value (tag 1)
            if case .tagged(let tag, let valueBytes) = cbor {
                if tag == 1 {
                    // Decode the tagged value
                    if let taggedValue = try? CBOR.decode(valueBytes) {
                        if case .unsignedInt(let timestamp) = taggedValue {
                            // RFC 8949 section 3.4.1: Tag 1 is for epoch timestamp
                            return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
                        } else if case .negativeInt(let timestamp) = taggedValue {
                            // Handle negative timestamps
                            return Date(timeIntervalSince1970: TimeInterval(timestamp)) as! T
                        } else if case .float(let timestamp) = taggedValue {
                            // Handle floating-point timestamps
                            return Date(timeIntervalSince1970: timestamp) as! T
                        }
                    }
                }
            }
            
            // Try ISO8601 string
            if case .textString(let bytes) = cbor {
                if let string = try? CBORDecoder.bytesToString(bytes) {
                    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
                    let formatter = ISO8601DateFormatter()
                    if let date = formatter.date(from: string) {
                        return date as! T
                    }
                    #endif
                }
            }
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Date but found \(cbor)"
            ))
        }
        
        // Special case for URL
        if type == URL.self {
            if case .textString(let bytes) = cbor {
                if let string = try? CBORDecoder.bytesToString(bytes) {
                    if let url = URL(string: string) {
                        return url as! T
                    } else {
                        throw DecodingError.dataCorrupted(DecodingError.Context(
                            codingPath: codingPath,
                            debugDescription: "Invalid URL string: \(string)"
                        ))
                    }
                }
            }
            
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode URL but found \(cbor)"
            ))
        }
        
        // For other Decodable types, use a nested decoder
        let decoder = CBORDecoder(cbor: cbor, codingPath: codingPath)
        return try T(from: decoder)
    }
}
#endif