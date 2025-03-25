#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

// This file contains container implementations that were previously defined
// The actual implementations are now in CBORDecoder.swift
// This file is kept for reference but its contents are not used

// MARK: - CBOR Unkeyed Decoding Container

struct CBORUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    var codingPath: [CodingKey]
    var count: Int? { return elements.count }
    var isAtEnd: Bool { return currentIndex >= elements.count }
    var currentIndex: Int = 0
    
    private let elements: [CBOR]
    
    init(elements: [CBOR], codingPath: [CodingKey]) {
        self.elements = elements
        self.codingPath = codingPath
    }
    
    private func checkIndex() throws {
        if isAtEnd {
            throw DecodingError.valueNotFound(Any.self, DecodingError.Context(
                codingPath: codingPath + [CBORKey(index: currentIndex)],
                debugDescription: "Unkeyed container is at end"
            ))
        }
    }
    
    mutating func decodeNil() throws -> Bool {
        try checkIndex()
        
        if case .null = elements[currentIndex] {
            currentIndex += 1
            return true
        }
        
        return false
    }
    
    mutating func decode(_ type: Bool.Type) throws -> Bool {
        try checkIndex()
        
        guard case .bool(let value) = elements[currentIndex] else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [CBORKey(index: currentIndex)],
                debugDescription: "Expected to decode Bool but found \(elements[currentIndex])"
            ))
        }
        
        currentIndex += 1
        return value
    }
    
    mutating func decode(_ type: String.Type) throws -> String {
        try checkIndex()
        
        guard case .textString(let value) = elements[currentIndex] else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [CBORKey(index: currentIndex)],
                debugDescription: "Expected to decode String but found \(elements[currentIndex])"
            ))
        }
        
        currentIndex += 1
        return value
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
                codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
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
            return Float(floatValue)
        case .unsignedInt(let uintValue):
            return Float(uintValue)
        case .negativeInt(let intValue):
            return Float(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
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
                    codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
                    debugDescription: "Value \(uintValue) overflows Int"
                ))
            }
            return Int(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int64(Int.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
                    debugDescription: "Value \(intValue) underflows Int"
                ))
            }
            return Int(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
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
                    codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
                    debugDescription: "Value \(uintValue) overflows Int8"
                ))
            }
            return Int8(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int(Int8.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
                    debugDescription: "Value \(intValue) underflows Int8"
                ))
            }
            return Int8(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
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
                    codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
                    debugDescription: "Value \(uintValue) overflows Int16"
                ))
            }
            return Int16(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int(Int16.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
                    debugDescription: "Value \(intValue) underflows Int16"
                ))
            }
            return Int16(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
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
                    codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
                    debugDescription: "Value \(uintValue) overflows Int32"
                ))
            }
            return Int32(uintValue)
        case .negativeInt(let intValue):
            guard intValue >= Int(Int32.min) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
                    debugDescription: "Value \(intValue) underflows Int32"
                ))
            }
            return Int32(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
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
                    codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
                    debugDescription: "Value \(uintValue) overflows Int64"
                ))
            }
            return Int64(uintValue)
        case .negativeInt(let intValue):
            return Int64(intValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
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
                    codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
                    debugDescription: "Value \(uintValue) overflows UInt"
                ))
            }
            return UInt(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
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
                    codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
                    debugDescription: "Value \(uintValue) overflows UInt8"
                ))
            }
            return UInt8(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
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
                    codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
                    debugDescription: "Value \(uintValue) overflows UInt16"
                ))
            }
            return UInt16(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
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
                    codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
                    debugDescription: "Value \(uintValue) overflows UInt32"
                ))
            }
            return UInt32(uintValue)
        default:
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
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
                codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
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
            guard case .byteString(let bytes) = value else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(
                    codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
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
                codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
                debugDescription: "Expected to decode Date but found \(value)"
            ))
        }
        
        // Special case for URL
        if type == URL.self {
            guard case .textString(let urlString) = value else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(
                    codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
                    debugDescription: "Expected to decode URL but found \(value)"
                ))
            }
            
            guard let url = URL(string: urlString) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath + [CBORKey(index: currentIndex - 1)],
                    debugDescription: "Invalid URL string: \(urlString)"
                ))
            }
            
            return url as! T
        }
        
        // For other Decodable types, use a nested decoder
        let decoder = CBORDecoder()
        let data = Data(value.encode())
        return try decoder.decode(T.self, from: data)
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        try checkIndex()
        
        let value = elements[currentIndex]
        
        guard case .map(_) = value else {
            throw DecodingError.typeMismatch([String: Any].self, DecodingError.Context(
                codingPath: codingPath + [CBORKey(index: currentIndex)],
                debugDescription: "Expected to decode map but found \(value)"
            ))
        }
        
        currentIndex += 1
        
        // Create an empty container since we can't use CBORKeyedDecodingContainer
        let emptyContainer = EmptyKeyedDecodingContainer<NestedKey>(codingPath: codingPath + [CBORKey(index: currentIndex - 1)])
        return KeyedDecodingContainer(emptyContainer)
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        try checkIndex()
        
        guard case .array(let elements) = elements[currentIndex] else {
            throw DecodingError.typeMismatch([Any].self, DecodingError.Context(
                codingPath: codingPath + [CBORKey(index: currentIndex)],
                debugDescription: "Expected to decode an array but found \(elements[currentIndex])"
            ))
        }
        
        currentIndex += 1
        return CBORUnkeyedDecodingContainer(elements: elements, codingPath: codingPath + [CBORKey(index: currentIndex - 1)])
    }
    
    mutating func superDecoder() throws -> Decoder {
        try checkIndex()
        
        currentIndex += 1
        
        // Use a dummy decoder instead of _CBORDecoderImpl
        return _DummyDecoder(codingPath: codingPath + [CBORKey(index: currentIndex - 1)])
    }
}

// MARK: - Dummy Decoder

private class _DummyDecoder: Decoder {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any] = [:]
    
    init(codingPath: [CodingKey]) {
        self.codingPath = codingPath
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedDecodingContainer<Key> where Key: CodingKey {
        let container = EmptyKeyedDecodingContainer<Key>(codingPath: codingPath)
        return KeyedDecodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedDecodingContainer {
        return CBORUnkeyedDecodingContainer(elements: [], codingPath: codingPath)
    }
    
    func singleValueContainer() -> SingleValueDecodingContainer {
        return CBORSingleValueDecodingContainer(cbor: .null, codingPath: codingPath)
    }
}

// MARK: - Empty Keyed Decoding Container

struct EmptyKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    var codingPath: [CodingKey]
    var allKeys: [K] { return [] }
    
    init(codingPath: [CodingKey]) {
        self.codingPath = codingPath
    }
    
    func contains(_ key: K) -> Bool { return false }
    func decodeNil(forKey key: K) throws -> Bool { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
    func decode(_ type: String.Type, forKey key: K) throws -> String { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
    func decode(_ type: Double.Type, forKey key: K) throws -> Double { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
    func decode(_ type: Float.Type, forKey key: K) throws -> Float { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
    func decode(_ type: Int.Type, forKey key: K) throws -> Int { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
    func nestedContainer<NK>(keyedBy type: NK.Type, forKey key: K) throws -> KeyedDecodingContainer<NK> where NK : CodingKey { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
    func superDecoder() throws -> Decoder { throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Not implemented")) }
    func superDecoder(forKey key: K) throws -> Decoder { throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "Key not found")) }
}

// MARK: - CBOR Single Value Decoding Container

struct CBORSingleValueDecodingContainer: SingleValueDecodingContainer {
    var codingPath: [CodingKey]
    
    private let cbor: CBOR
    
    init(cbor: CBOR, codingPath: [CodingKey]) {
        self.cbor = cbor
        self.codingPath = codingPath
    }
    
    func decodeNil() -> Bool {
        return cbor == .null
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        guard case .bool(let value) = cbor else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode Bool but found \(cbor)"
            ))
        }
        
        return value
    }
    
    func decode(_ type: String.Type) throws -> String {
        guard case .textString(let value) = cbor else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Expected to decode String but found \(cbor)"
            ))
        }
        
        return value
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
            return Float(floatValue)
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
            return Int64(intValue)
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
            guard case .byteString(let bytes) = cbor else {
                throw DecodingError.typeMismatch(type, DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Expected to decode Data but found \(cbor)"
                ))
            }
            return Data(bytes) as! T
        }
        
        // Special case for Date
        if type == Date.self {
            if case .tagged(1, let taggedValue) = cbor {
                if case .float(let timeInterval) = taggedValue {
                    return Date(timeIntervalSince1970: timeInterval) as! T
                }
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
        let decoder = CBORDecoder()
        let data = Data(cbor.encode())
        return try decoder.decode(T.self, from: data)
    }
}
