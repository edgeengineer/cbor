#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: - CBOR Encoder

/// An encoder that converts Swift values to CBOR data
public class CBOREncoder {
    public init() {}
    
    public func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = _CBOREncoder()
        let cbor = try encoder.encode(value)
        return Data(cbor.encode())
    }
}

private class _CBOREncoder {
    func encode<T: Encodable>(_ value: T) throws -> CBOR {
        let encoder = _CBOREncoderImpl(codingPath: [])
        try value.encode(to: encoder)
        return encoder.storage.topValue
    }
}

// MARK: - Encoder Storage

private class EncoderStorage {
    private(set) var values: [CBOR] = []
    
    var count: Int {
        return values.count
    }
    
    var topValue: CBOR {
        guard let value = values.last else {
            fatalError("Empty storage")
        }
        return value
    }
    
    func push(_ value: CBOR) {
        values.append(value)
    }
    
    func popValue() -> CBOR {
        guard let value = values.popLast() else {
            fatalError("Empty storage")
        }
        return value
    }
}

// MARK: - CBOR Encoder Implementation

private class _CBOREncoderImpl: Encoder {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any] = [:]
    
    fileprivate var storage: EncoderStorage
    
    init(codingPath: [CodingKey]) {
        self.codingPath = codingPath
        self.storage = EncoderStorage()
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        let container = CBORKeyedEncodingContainer<Key>(encoder: self, codingPath: codingPath)
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return CBORUnkeyedEncodingContainer(encoder: self, codingPath: codingPath)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return CBORSingleValueEncodingContainer(encoder: self, codingPath: codingPath)
    }
    
    func createSubencoder(for container: Any) -> _CBOREncoderImpl {
        let newEncoder = _CBOREncoderImpl(codingPath: codingPath)
        return newEncoder
    }
}

// MARK: - CBOR Single Value Encoding Container

private struct CBORSingleValueEncodingContainer: SingleValueEncodingContainer {
    var codingPath: [CodingKey]
    private let encoder: _CBOREncoderImpl
    
    fileprivate var _value: CBOR?
    
    init(encoder: _CBOREncoderImpl, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
    }
    
    mutating func encodeNil() throws {
        _value = CBOR.null
        encoder.storage.push(CBOR.null)
    }
    
    mutating func encode(_ value: Bool) throws {
        _value = CBOR.bool(value)
        encoder.storage.push(CBOR.bool(value))
    }
    
    mutating func encode(_ value: Double) throws {
        _value = CBOR.float(value)
        encoder.storage.push(CBOR.float(value))
    }
    
    mutating func encode(_ value: Float) throws {
        _value = CBOR.float(Double(value))
        encoder.storage.push(CBOR.float(Double(value)))
    }
    
    mutating func encode(_ value: Int) throws {
        if value < 0 {
            _value = CBOR.negativeInt(Int64(value))
            encoder.storage.push(CBOR.negativeInt(Int64(value)))
        } else {
            _value = CBOR.unsignedInt(UInt64(value))
            encoder.storage.push(CBOR.unsignedInt(UInt64(value)))
        }
    }
    
    mutating func encode(_ value: Int8) throws {
        if value < 0 {
            _value = CBOR.negativeInt(Int64(value))
            encoder.storage.push(CBOR.negativeInt(Int64(value)))
        } else {
            _value = CBOR.unsignedInt(UInt64(value))
            encoder.storage.push(CBOR.unsignedInt(UInt64(value)))
        }
    }
    
    mutating func encode(_ value: Int16) throws {
        if value < 0 {
            _value = CBOR.negativeInt(Int64(value))
            encoder.storage.push(CBOR.negativeInt(Int64(value)))
        } else {
            _value = CBOR.unsignedInt(UInt64(value))
            encoder.storage.push(CBOR.unsignedInt(UInt64(value)))
        }
    }
    
    mutating func encode(_ value: Int32) throws {
        if value < 0 {
            _value = CBOR.negativeInt(Int64(value))
            encoder.storage.push(CBOR.negativeInt(Int64(value)))
        } else {
            _value = CBOR.unsignedInt(UInt64(value))
            encoder.storage.push(CBOR.unsignedInt(UInt64(value)))
        }
    }
    
    mutating func encode(_ value: Int64) throws {
        if value < 0 {
            _value = CBOR.negativeInt(value)
            encoder.storage.push(CBOR.negativeInt(value))
        } else {
            _value = CBOR.unsignedInt(UInt64(value))
            encoder.storage.push(CBOR.unsignedInt(UInt64(value)))
        }
    }
    
    mutating func encode(_ value: UInt) throws {
        _value = CBOR.unsignedInt(UInt64(value))
        encoder.storage.push(CBOR.unsignedInt(UInt64(value)))
    }
    
    mutating func encode(_ value: UInt8) throws {
        _value = CBOR.unsignedInt(UInt64(value))
        encoder.storage.push(CBOR.unsignedInt(UInt64(value)))
    }
    
    mutating func encode(_ value: UInt16) throws {
        _value = CBOR.unsignedInt(UInt64(value))
        encoder.storage.push(CBOR.unsignedInt(UInt64(value)))
    }
    
    mutating func encode(_ value: UInt32) throws {
        _value = CBOR.unsignedInt(UInt64(value))
        encoder.storage.push(CBOR.unsignedInt(UInt64(value)))
    }
    
    mutating func encode(_ value: UInt64) throws {
        _value = CBOR.unsignedInt(value)
        encoder.storage.push(CBOR.unsignedInt(value))
    }
    
    mutating func encode(_ value: String) throws {
        _value = CBOR.textString(value)
        encoder.storage.push(CBOR.textString(value))
    }
    
    mutating func encode<T: Encodable>(_ value: T) throws {
        // Special cases for Foundation types
        if let date = value as? Date {
            let timeInterval = date.timeIntervalSince1970
            _value = CBOR.tagged(1, CBOR.float(timeInterval))
            encoder.storage.push(CBOR.tagged(1, CBOR.float(timeInterval)))
            return
        }
        
        if let url = value as? URL {
            _value = CBOR.textString(url.absoluteString)
            encoder.storage.push(CBOR.textString(url.absoluteString))
            return
        }
        
        if let data = value as? Data {
            _value = CBOR.byteString([UInt8](data))
            encoder.storage.push(CBOR.byteString([UInt8](data)))
            return
        }
        
        // Handle CBOR values directly
        if let cbor = value as? CBOR {
            _value = cbor
            encoder.storage.push(cbor)
            return
        }
        
        // For all other types, encode using a container
        let nestedEncoder = _CBOREncoderImpl(codingPath: codingPath)
        try value.encode(to: nestedEncoder)
        _value = nestedEncoder.storage.topValue
        encoder.storage.push(nestedEncoder.storage.topValue)
    }
}

// MARK: - CBOR Unkeyed Encoding Container

private struct CBORUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    var codingPath: [CodingKey]
    private let encoder: _CBOREncoderImpl
    
    fileprivate var elements: [CBOR] = []
    
    init(encoder: _CBOREncoderImpl, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
    }
    
    var count: Int {
        return elements.count
    }
    
    mutating func encodeNil() throws {
        elements.append(CBOR.null)
    }
    
    mutating func encode(_ value: Bool) throws {
        elements.append(CBOR.bool(value))
    }
    
    mutating func encode(_ value: Double) throws {
        elements.append(CBOR.float(value))
    }
    
    mutating func encode(_ value: Float) throws {
        elements.append(CBOR.float(Double(value)))
    }
    
    mutating func encode(_ value: Int) throws {
        if value < 0 {
            elements.append(CBOR.negativeInt(Int64(value)))
        } else {
            elements.append(CBOR.unsignedInt(UInt64(value)))
        }
    }
    
    mutating func encode(_ value: Int8) throws {
        if value < 0 {
            elements.append(CBOR.negativeInt(Int64(value)))
        } else {
            elements.append(CBOR.unsignedInt(UInt64(value)))
        }
    }
    
    mutating func encode(_ value: Int16) throws {
        if value < 0 {
            elements.append(CBOR.negativeInt(Int64(value)))
        } else {
            elements.append(CBOR.unsignedInt(UInt64(value)))
        }
    }
    
    mutating func encode(_ value: Int32) throws {
        if value < 0 {
            elements.append(CBOR.negativeInt(Int64(value)))
        } else {
            elements.append(CBOR.unsignedInt(UInt64(value)))
        }
    }
    
    mutating func encode(_ value: Int64) throws {
        if value < 0 {
            elements.append(CBOR.negativeInt(value))
        } else {
            elements.append(CBOR.unsignedInt(UInt64(value)))
        }
    }
    
    mutating func encode(_ value: UInt) throws {
        elements.append(CBOR.unsignedInt(UInt64(value)))
    }
    
    mutating func encode(_ value: UInt8) throws {
        elements.append(CBOR.unsignedInt(UInt64(value)))
    }
    
    mutating func encode(_ value: UInt16) throws {
        elements.append(CBOR.unsignedInt(UInt64(value)))
    }
    
    mutating func encode(_ value: UInt32) throws {
        elements.append(CBOR.unsignedInt(UInt64(value)))
    }
    
    mutating func encode(_ value: UInt64) throws {
        elements.append(CBOR.unsignedInt(value))
    }
    
    mutating func encode(_ value: String) throws {
        elements.append(CBOR.textString(value))
    }
    
    mutating func encode<T: Encodable>(_ value: T) throws {
        // Special cases for Foundation types
        if let date = value as? Date {
            let timeInterval = date.timeIntervalSince1970
            elements.append(CBOR.tagged(1, CBOR.float(timeInterval)))
            return
        }
        
        if let url = value as? URL {
            elements.append(CBOR.textString(url.absoluteString))
            return
        }
        
        if let data = value as? Data {
            elements.append(CBOR.byteString([UInt8](data)))
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
        
        let container = subencoder.storage.topValue
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
    
    private func finalize() {
        encoder.storage.push(CBOR.array(elements))
    }
}

// MARK: - CBOR Keyed Encoding Container

private struct CBORKeyedEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
    typealias Key = K
    
    var codingPath: [CodingKey]
    private let encoder: _CBOREncoderImpl
    
    fileprivate var pairs: [CBORMapPair] = []
    
    init(encoder: _CBOREncoderImpl, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
    }
    
    mutating func encodeNil(forKey key: K) throws {
        pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.null))
    }
    
    mutating func encode(_ value: Bool, forKey key: K) throws {
        pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.bool(value)))
    }
    
    mutating func encode(_ value: Double, forKey key: K) throws {
        pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.float(value)))
    }
    
    mutating func encode(_ value: Float, forKey key: K) throws {
        pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.float(Double(value))))
    }
    
    mutating func encode(_ value: Int, forKey key: K) throws {
        if value < 0 {
            pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.negativeInt(Int64(value))))
        } else {
            pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.unsignedInt(UInt64(value))))
        }
    }
    
    mutating func encode(_ value: Int8, forKey key: K) throws {
        if value < 0 {
            pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.negativeInt(Int64(value))))
        } else {
            pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.unsignedInt(UInt64(value))))
        }
    }
    
    mutating func encode(_ value: Int16, forKey key: K) throws {
        if value < 0 {
            pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.negativeInt(Int64(value))))
        } else {
            pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.unsignedInt(UInt64(value))))
        }
    }
    
    mutating func encode(_ value: Int32, forKey key: K) throws {
        if value < 0 {
            pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.negativeInt(Int64(value))))
        } else {
            pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.unsignedInt(UInt64(value))))
        }
    }
    
    mutating func encode(_ value: Int64, forKey key: K) throws {
        if value < 0 {
            pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.negativeInt(value)))
        } else {
            pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.unsignedInt(UInt64(value))))
        }
    }
    
    mutating func encode(_ value: UInt, forKey key: K) throws {
        pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.unsignedInt(UInt64(value))))
    }
    
    mutating func encode(_ value: UInt8, forKey key: K) throws {
        pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.unsignedInt(UInt64(value))))
    }
    
    mutating func encode(_ value: UInt16, forKey key: K) throws {
        pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.unsignedInt(UInt64(value))))
    }
    
    mutating func encode(_ value: UInt32, forKey key: K) throws {
        pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.unsignedInt(UInt64(value))))
    }
    
    mutating func encode(_ value: UInt64, forKey key: K) throws {
        pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.unsignedInt(value)))
    }
    
    mutating func encode(_ value: String, forKey key: K) throws {
        pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.textString(value)))
    }
    
    mutating func encode<T: Encodable>(_ value: T, forKey key: K) throws {
        // Special cases for Foundation types
        if let date = value as? Date {
            let timeInterval = date.timeIntervalSince1970
            pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.tagged(1, CBOR.float(timeInterval))))
            return
        }
        
        if let url = value as? URL {
            pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.textString(url.absoluteString)))
            return
        }
        
        if let data = value as? Data {
            pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: CBOR.byteString([UInt8](data))))
            return
        }
        
        // Handle CBOR values directly
        if let cbor = value as? CBOR {
            pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: cbor))
            return
        }
        
        // For all other types, encode using a container
        let subencoder = encoder.createSubencoder(for: self)
        try value.encode(to: subencoder)
        
        let container = subencoder.storage.topValue
        pairs.append(CBORMapPair(key: CBOR.textString(key.stringValue), value: container))
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
    
    private func finalize() {
        encoder.storage.push(CBOR.map(pairs))
    }
}
