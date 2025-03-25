#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: - CBOR Unkeyed Encoding Container

// This file contains container implementations that were previously defined
// The actual implementations are now in CBOREncoder.swift
// This file is kept for reference but its contents are not used

/*
struct CBORUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    var codingPath: [CodingKey]
    private let encoder: _CBOREncoderImpl
    
    private var elements: [CBOR] = []
    
    init(encoder: _CBOREncoderImpl, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
    }
    
    var count: Int {
        return elements.count
    }
    
    mutating func encodeNil() throws {
        elements.append(.null)
    }
    
    mutating func encode(_ value: Bool) throws {
        elements.append(.bool(value))
    }
    
    mutating func encode(_ value: Double) throws {
        elements.append(.float(value))
    }
    
    mutating func encode(_ value: Float) throws {
        elements.append(.float(Double(value)))
    }
    
    mutating func encode(_ value: Int) throws {
        if value < 0 {
            elements.append(.negativeInt(Int64(value)))
        } else {
            elements.append(.unsignedInt(UInt64(value)))
        }
    }
    
    mutating func encode(_ value: Int8) throws {
        if value < 0 {
            elements.append(.negativeInt(Int64(value)))
        } else {
            elements.append(.unsignedInt(UInt64(value)))
        }
    }
    
    mutating func encode(_ value: Int16) throws {
        if value < 0 {
            elements.append(.negativeInt(Int64(value)))
        } else {
            elements.append(.unsignedInt(UInt64(value)))
        }
    }
    
    mutating func encode(_ value: Int32) throws {
        if value < 0 {
            elements.append(.negativeInt(Int64(value)))
        } else {
            elements.append(.unsignedInt(UInt64(value)))
        }
    }
    
    mutating func encode(_ value: Int64) throws {
        if value < 0 {
            elements.append(.negativeInt(value))
        } else {
            elements.append(.unsignedInt(UInt64(value)))
        }
    }
    
    mutating func encode(_ value: UInt) throws {
        elements.append(.unsignedInt(UInt64(value)))
    }
    
    mutating func encode(_ value: UInt8) throws {
        elements.append(.unsignedInt(UInt64(value)))
    }
    
    mutating func encode(_ value: UInt16) throws {
        elements.append(.unsignedInt(UInt64(value)))
    }
    
    mutating func encode(_ value: UInt32) throws {
        elements.append(.unsignedInt(UInt64(value)))
    }
    
    mutating func encode(_ value: UInt64) throws {
        elements.append(.unsignedInt(value))
    }
    
    mutating func encode(_ value: String) throws {
        elements.append(.textString(value))
    }
    
    mutating func encode<T: Encodable>(_ value: T) throws {
        // Special cases for Foundation types
        if let date = value as? Date {
            let timeInterval = date.timeIntervalSince1970
            elements.append(.tagged(1, .float(timeInterval)))
            return
        }
        
        if let url = value as? URL {
            elements.append(.textString(url.absoluteString))
            return
        }
        
        if let data = value as? Data {
            elements.append(.byteString([UInt8](data)))
            return
        }
        
        // Handle CBOR values directly
        if let cbor = value as? CBOR {
            elements.append(cbor)
            return
        }
        
        // For all other types, encode using a container
        let subencoder = encoder.createSubencoder(for: self)
        try value.encode(to: subencoder)
        
        guard let container = subencoder.container else {
            let context = EncodingError.Context(
                codingPath: codingPath,
                debugDescription: "Value \(value) of type \(T.self) did not encode any values."
            )
            throw EncodingError.invalidValue(value, context)
        }
        
        elements.append(container)
    }
    
    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        let container = CBORKeyedEncodingContainer<NestedKey>(encoder: encoder, codingPath: codingPath)
        return KeyedEncodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return CBORUnkeyedEncodingContainer(encoder: encoder, codingPath: codingPath)
    }
    
    mutating func superEncoder() -> Encoder {
        return encoder.createSubencoder(for: self)
    }
}

extension CBORUnkeyedEncodingContainer {
    var value: CBOR {
        return .array(elements)
    }
}

// MARK: - CBOR Keyed Encoding Container

struct CBORKeyedEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
    typealias Key = K
    
    var codingPath: [CodingKey]
    private let encoder: _CBOREncoderImpl
    
    private var pairs: [CBORMapPair] = []
    
    init(encoder: _CBOREncoderImpl, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
    }
    
    mutating func encodeNil(forKey key: K) throws {
        pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .null))
    }
    
    mutating func encode(_ value: Bool, forKey key: K) throws {
        pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .bool(value)))
    }
    
    mutating func encode(_ value: Double, forKey key: K) throws {
        pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .float(value)))
    }
    
    mutating func encode(_ value: Float, forKey key: K) throws {
        pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .float(Double(value))))
    }
    
    mutating func encode(_ value: Int, forKey key: K) throws {
        if value < 0 {
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .negativeInt(Int64(value))))
        } else {
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .unsignedInt(UInt64(value))))
        }
    }
    
    mutating func encode(_ value: Int8, forKey key: K) throws {
        if value < 0 {
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .negativeInt(Int64(value))))
        } else {
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .unsignedInt(UInt64(value))))
        }
    }
    
    mutating func encode(_ value: Int16, forKey key: K) throws {
        if value < 0 {
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .negativeInt(Int64(value))))
        } else {
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .unsignedInt(UInt64(value))))
        }
    }
    
    mutating func encode(_ value: Int32, forKey key: K) throws {
        if value < 0 {
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .negativeInt(Int64(value))))
        } else {
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .unsignedInt(UInt64(value))))
        }
    }
    
    mutating func encode(_ value: Int64, forKey key: K) throws {
        if value < 0 {
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .negativeInt(value)))
        } else {
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .unsignedInt(UInt64(value))))
        }
    }
    
    mutating func encode(_ value: UInt, forKey key: K) throws {
        pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .unsignedInt(UInt64(value))))
    }
    
    mutating func encode(_ value: UInt8, forKey key: K) throws {
        pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .unsignedInt(UInt64(value))))
    }
    
    mutating func encode(_ value: UInt16, forKey key: K) throws {
        pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .unsignedInt(UInt64(value))))
    }
    
    mutating func encode(_ value: UInt32, forKey key: K) throws {
        pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .unsignedInt(UInt64(value))))
    }
    
    mutating func encode(_ value: UInt64, forKey key: K) throws {
        pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .unsignedInt(value)))
    }
    
    mutating func encode(_ value: String, forKey key: K) throws {
        pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .textString(value)))
    }
    
    mutating func encode<T: Encodable>(_ value: T, forKey key: K) throws {
        // Special cases for Foundation types
        if let date = value as? Date {
            let timeInterval = date.timeIntervalSince1970
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .tagged(1, .float(timeInterval))))
            return
        }
        
        if let url = value as? URL {
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .textString(url.absoluteString)))
            return
        }
        
        if let data = value as? Data {
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .byteString([UInt8](data))))
            return
        }
        
        // Handle CBOR values directly
        if let cbor = value as? CBOR {
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: cbor))
            return
        }
        
        // For all other types, encode using a container
        let subencoder = encoder.createSubencoder(for: self)
        try value.encode(to: subencoder)
        
        guard let container = subencoder.container else {
            let context = EncodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Value \(value) of type \(T.self) did not encode any values."
            )
            throw EncodingError.invalidValue(value, context)
        }
        
        pairs.append(CBORMapPair(key: .textString(key.stringValue), value: container))
    }
    
    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> {
        let container = CBORKeyedEncodingContainer<NestedKey>(encoder: encoder, codingPath: codingPath + [key])
        return KeyedEncodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        return CBORUnkeyedEncodingContainer(encoder: encoder, codingPath: codingPath + [key])
    }
    
    mutating func superEncoder() -> Encoder {
        return encoder.createSubencoder(for: self)
    }
    
    mutating func superEncoder(forKey key: K) -> Encoder {
        return encoder.createSubencoder(for: self)
    }
}

extension CBORKeyedEncodingContainer {
    var value: CBOR {
        return .map(pairs)
    }
}

// MARK: - CBOR Single Value Encoding Container

struct CBORSingleValueEncodingContainer: SingleValueEncodingContainer {
    var codingPath: [CodingKey]
    private let encoder: _CBOREncoderImpl
    
    private var _value: CBOR?
    
    init(encoder: _CBOREncoderImpl, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
    }
    
    mutating func encodeNil() throws {
        _value = .null
    }
    
    mutating func encode(_ value: Bool) throws {
        _value = .bool(value)
    }
    
    mutating func encode(_ value: Double) throws {
        _value = .float(value)
    }
    
    mutating func encode(_ value: Float) throws {
        _value = .float(Double(value))
    }
    
    mutating func encode(_ value: Int) throws {
        if value < 0 {
            _value = .negativeInt(Int64(value))
        } else {
            _value = .unsignedInt(UInt64(value))
        }
    }
    
    mutating func encode(_ value: Int8) throws {
        if value < 0 {
            _value = .negativeInt(Int64(value))
        } else {
            _value = .unsignedInt(UInt64(value))
        }
    }
    
    mutating func encode(_ value: Int16) throws {
        if value < 0 {
            _value = .negativeInt(Int64(value))
        } else {
            _value = .unsignedInt(UInt64(value))
        }
    }
    
    mutating func encode(_ value: Int32) throws {
        if value < 0 {
            _value = .negativeInt(Int64(value))
        } else {
            _value = .unsignedInt(UInt64(value))
        }
    }
    
    mutating func encode(_ value: Int64) throws {
        if value < 0 {
            _value = .negativeInt(value)
        } else {
            _value = .unsignedInt(UInt64(value))
        }
    }
    
    mutating func encode(_ value: UInt) throws {
        _value = .unsignedInt(UInt64(value))
    }
    
    mutating func encode(_ value: UInt8) throws {
        _value = .unsignedInt(UInt64(value))
    }
    
    mutating func encode(_ value: UInt16) throws {
        _value = .unsignedInt(UInt64(value))
    }
    
    mutating func encode(_ value: UInt32) throws {
        _value = .unsignedInt(UInt64(value))
    }
    
    mutating func encode(_ value: UInt64) throws {
        _value = .unsignedInt(value)
    }
    
    mutating func encode(_ value: String) throws {
        _value = .textString(value)
    }
    
    mutating func encode<T: Encodable>(_ value: T) throws {
        // Special cases for Foundation types
        if let date = value as? Date {
            let timeInterval = date.timeIntervalSince1970
            _value = .tagged(1, .float(timeInterval))
            return
        }
        
        if let url = value as? URL {
            _value = .textString(url.absoluteString)
            return
        }
        
        if let data = value as? Data {
            _value = .byteString([UInt8](data))
            return
        }
        
        // Handle CBOR values directly
        if let cbor = value as? CBOR {
            _value = cbor
            return
        }
        
        // For all other types, encode using a container
        let nestedEncoder = _CBOREncoderImpl(codingPath: codingPath)
        try value.encode(to: nestedEncoder)
        _value = nestedEncoder.storage.topValue
    }
}

extension CBORSingleValueEncodingContainer {
    var value: CBOR? {
        return _value
    }
}

// MARK: - CBOR Key

struct CBORKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
    
    init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }
}
*/
