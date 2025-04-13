#if !hasFeature(Embedded)
#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: - CBOR Encoder

public final class CBOREncoder {
    // MARK: - Storage
    
    private class Storage {
        var values: [CBOR] = []
        
        var count: Int {
            return values.count
        }
        
        func push(_ value: CBOR) {
            values.append(value)
        }
        
        var topValue: CBOR {
            guard let value = values.last else {
                return CBOR.null
            }
            return value
        }
    }
    
    private var storage = Storage()
    
    // MARK: - Properties
    
    public var codingPath: [CodingKey] = []
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    
    // MARK: - Public API
    
    public init() {}
    
    public func encode<T: Encodable>(_ value: T) throws -> [UInt8] {
        let cbor: CBOR
        switch value {
        case let data as Data:
            cbor = CBOR.byteString(Array(data))
        case let date as Date:
            cbor = CBOR.tagged(1, CBOR.float(date.timeIntervalSince1970))
        case let url as URL:
            cbor = CBOR.textString(url.absoluteString)
        case let array as [Int]:
            cbor = CBOR.array(array.map { $0 < 0 ? CBOR.negativeInt(Int64(-1 - $0)) : CBOR.unsignedInt(UInt64($0)) })
        case let array as [String]:
            cbor = CBOR.array(array.map { CBOR.textString($0) })
        case let array as [Bool]:
            cbor = CBOR.array(array.map { CBOR.bool($0) })
        case let array as [Double]:
            cbor = CBOR.array(array.map { CBOR.float($0) })
        case let array as [Float]:
            cbor = CBOR.array(array.map { CBOR.float(Double($0)) })
        case let array as [Data]:
            cbor = CBOR.array(array.map { CBOR.byteString(Array($0)) })
        default:
            storage = Storage()
            try value.encode(to: self)
            cbor = storage.topValue
        }
        return cbor.encode()
    }
    
    // MARK: - Internal API
    
    @usableFromInline
    internal func push(_ value: CBOR) {
        storage.push(value)
    }
    
    // Implementation of the encodeCBOR method that's referenced in the code
    fileprivate func encodeCBOR<T: Encodable>(_ value: T) throws -> CBOR {
        switch value {
        case let data as Data:
            return CBOR.byteString(Array(data))
        case let date as Date:
            return CBOR.tagged(1, CBOR.float(date.timeIntervalSince1970))
        case let url as URL:
            return CBOR.textString(url.absoluteString)
        case let array as [Int]:
            return CBOR.array(array.map { $0 < 0 ? CBOR.negativeInt(Int64(-1 - $0)) : CBOR.unsignedInt(UInt64($0)) })
        case let array as [String]:
            return CBOR.array(array.map { CBOR.textString($0) })
        case let array as [Bool]:
            return CBOR.array(array.map { CBOR.bool($0) })
        case let array as [Double]:
            return CBOR.array(array.map { CBOR.float($0) })
        case let array as [Float]:
            return CBOR.array(array.map { CBOR.float(Double($0)) })
        case let array as [Data]:
            return CBOR.array(array.map { CBOR.byteString(Array($0)) })
        default:
            // For other types, use the Encodable protocol
            let tempEncoder = CBOREncoder()
            try value.encode(to: tempEncoder)
            
            // Get the encoded CBOR value
            return tempEncoder.storage.topValue
        }
    }
}

// MARK: - Encoder Context

extension CBOREncoder: Encoder {
    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        let container = CBOREncoderKeyedContainer<Key>(codingPath: codingPath, encoder: self)
        return KeyedEncodingContainer(container)
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        return CBOREncoderUnkeyedContainer(codingPath: codingPath, encoder: self)
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        return CBOREncoderSingleValueContainer(codingPath: codingPath, encoder: self)
    }
}

// MARK: - CBOREncoderUnkeyedContainer

private struct CBOREncoderUnkeyedContainer: UnkeyedEncodingContainer {
    let codingPath: [CodingKey]
    fileprivate let encoder: CBOREncoder
    private var elements: [CBOR] = []
    
    var count: Int {
        return elements.count
    }
    
    init(codingPath: [CodingKey], encoder: CBOREncoder) {
        self.codingPath = codingPath
        self.encoder = encoder
    }
    
    // Finalize the container by pushing the array to the encoder
    private mutating func finalize() {
        encoder.push(CBOR.array(elements))
    }
    
    mutating func encodeNil() throws {
        elements.append(CBOR.null)
        finalize()
    }
    
    mutating func encode(_ value: Bool) throws {
        elements.append(CBOR.bool(value))
        finalize()
    }
    
    mutating func encode(_ value: String) throws {
        elements.append(CBOR.textString(value))
        finalize()
    }
    
    mutating func encode(_ value: Double) throws {
        elements.append(CBOR.float(value))
        finalize()
    }
    
    mutating func encode(_ value: Float) throws {
        elements.append(CBOR.float(Double(value)))
        finalize()
    }
    
    mutating func encode(_ value: Int) throws {
        if value < 0 {
            elements.append(CBOR.negativeInt(Int64(-1 - value)))
        } else {
            elements.append(CBOR.unsignedInt(UInt64(value)))
        }
        finalize()
    }
    
    mutating func encode(_ value: Int8) throws {
        try encode(Int(value))
    }
    
    mutating func encode(_ value: Int16) throws {
        try encode(Int(value))
    }
    
    mutating func encode(_ value: Int32) throws {
        try encode(Int(value))
    }
    
    mutating func encode(_ value: Int64) throws {
        if value < 0 {
            elements.append(CBOR.negativeInt(Int64(-1 - value)))
        } else {
            elements.append(CBOR.unsignedInt(UInt64(value)))
        }
        finalize()
    }
    
    mutating func encode(_ value: UInt) throws {
        elements.append(CBOR.unsignedInt(UInt64(value)))
        finalize()
    }
    
    mutating func encode(_ value: UInt8) throws {
        try encode(UInt(value))
    }
    
    mutating func encode(_ value: UInt16) throws {
        try encode(UInt(value))
    }
    
    mutating func encode(_ value: UInt32) throws {
        try encode(UInt(value))
    }
    
    mutating func encode(_ value: UInt64) throws {
        elements.append(CBOR.unsignedInt(value))
        finalize()
    }
    
    mutating func encode<T>(_ value: T) throws where T: Encodable {
        // Special case for Data
        if let data = value as? Data {
            elements.append(CBOR.byteString(Array(data)))
            finalize()
            return
        }
        
        // Special case for Date
        if let date = value as? Date {
            elements.append(CBOR.tagged(1, CBOR.float(date.timeIntervalSince1970)))
            finalize()
            return
        }
        
        // Special case for URL
        if let url = value as? URL {
            elements.append(CBOR.textString(url.absoluteString))
            finalize()
            return
        }
        
        // For other types, use the Encodable protocol
        if let cbor = try? encoder.encodeCBOR(value) {
            elements.append(cbor)
        } else {
            elements.append(CBOR.null)
        }
        finalize()
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        // Create a new encoder for the nested container
        let nestedEncoder = CBOREncoder()
        let container = CBOREncoderKeyedContainer<NestedKey>(codingPath: codingPath, encoder: nestedEncoder)
        
        // Create a new container that will finalize when it's done
        let finalizedContainer = FinalizedKeyedEncodingContainer(container: container) { [self] result in
            var mutableSelf = self
            mutableSelf.elements.append(result)
        }
        
        return KeyedEncodingContainer(finalizedContainer)
    }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        // Create a new encoder for the nested container
        let nestedEncoder = CBOREncoder()
        let container = CBOREncoderUnkeyedContainer(codingPath: codingPath, encoder: nestedEncoder)
        
        // Create a new container that will finalize when it's done
        return FinalizedUnkeyedEncodingContainer(container: container) { [self] result in
            var mutableSelf = self
            mutableSelf.elements.append(result)
        }
    }
    
    func superEncoder() -> Encoder {
        return encoder
    }
}

// MARK: - CBOREncoderKeyedContainer

private struct CBOREncoderKeyedContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
    typealias Key = K
    
    let codingPath: [CodingKey]
    fileprivate let encoder: CBOREncoder
    private var pairs: [CBORMapPair] = []
    
    init(codingPath: [CodingKey], encoder: CBOREncoder) {
        self.codingPath = codingPath
        self.encoder = encoder
    }
    
    // Finalize the container by pushing the map to the encoder
    private mutating func finalize() {
        encoder.push(CBOR.map(pairs))
    }
    
    mutating func encodeNil(forKey key: K) throws {
        let keyString = key.stringValue
        pairs.append(CBORMapPair(key: CBOR.textString(keyString), value: CBOR.null))
        finalize()
    }
    
    mutating func encode(_ value: Bool, forKey key: K) throws {
        let keyString = key.stringValue
        pairs.append(CBORMapPair(key: CBOR.textString(keyString), value: CBOR.bool(value)))
        finalize()
    }
    
    mutating func encode(_ value: String, forKey key: K) throws {
        let keyString = key.stringValue
        pairs.append(CBORMapPair(key: CBOR.textString(keyString), value: CBOR.textString(value)))
        finalize()
    }
    
    mutating func encode(_ value: Double, forKey key: K) throws {
        let keyString = key.stringValue
        pairs.append(CBORMapPair(key: CBOR.textString(keyString), value: CBOR.float(value)))
        finalize()
    }
    
    mutating func encode(_ value: Float, forKey key: K) throws {
        let keyString = key.stringValue
        pairs.append(CBORMapPair(key: CBOR.textString(keyString), value: CBOR.float(Double(value))))
        finalize()
    }
    
    mutating func encode(_ value: Int, forKey key: K) throws {
        let keyString = key.stringValue
        if value < 0 {
            pairs.append(CBORMapPair(key: CBOR.textString(keyString), value: CBOR.negativeInt(Int64(-1 - value))))
        } else {
            pairs.append(CBORMapPair(key: CBOR.textString(keyString), value: CBOR.unsignedInt(UInt64(value))))
        }
        finalize()
    }
    
    mutating func encode(_ value: Int8, forKey key: K) throws {
        try encode(Int(value), forKey: key)
    }
    
    mutating func encode(_ value: Int16, forKey key: K) throws {
        try encode(Int(value), forKey: key)
    }
    
    mutating func encode(_ value: Int32, forKey key: K) throws {
        try encode(Int(value), forKey: key)
    }
    
    mutating func encode(_ value: Int64, forKey key: K) throws {
        let keyString = key.stringValue
        if value < 0 {
            pairs.append(CBORMapPair(key: CBOR.textString(keyString), value: CBOR.negativeInt(Int64(-1 - value))))
        } else {
            pairs.append(CBORMapPair(key: CBOR.textString(keyString), value: CBOR.unsignedInt(UInt64(value))))
        }
        finalize()
    }
    
    mutating func encode(_ value: UInt, forKey key: K) throws {
        let keyString = key.stringValue
        pairs.append(CBORMapPair(key: CBOR.textString(keyString), value: CBOR.unsignedInt(UInt64(value))))
        finalize()
    }
    
    mutating func encode(_ value: UInt8, forKey key: K) throws {
        try encode(UInt(value), forKey: key)
    }
    
    mutating func encode(_ value: UInt16, forKey key: K) throws {
        try encode(UInt(value), forKey: key)
    }
    
    mutating func encode(_ value: UInt32, forKey key: K) throws {
        try encode(UInt(value), forKey: key)
    }
    
    mutating func encode(_ value: UInt64, forKey key: K) throws {
        let keyString = key.stringValue
        pairs.append(CBORMapPair(key: CBOR.textString(keyString), value: CBOR.unsignedInt(value)))
        finalize()
    }
    
    mutating func encode<T>(_ value: T, forKey key: K) throws where T: Encodable {
        let keyString = key.stringValue
        let cbor = try encoder.encodeCBOR(value)
        pairs.append(CBORMapPair(key: CBOR.textString(keyString), value: cbor))
        finalize()
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        let keyString = key.stringValue
        
        // Create a new encoder for the nested container
        let nestedEncoder = CBOREncoder()
        let container = CBOREncoderKeyedContainer<NestedKey>(codingPath: codingPath, encoder: nestedEncoder)
        
        // Create a new container that will finalize when it's done
        let finalizedContainer = FinalizedKeyedEncodingContainer(container: container) { [self] result in
            var mutableSelf = self
            mutableSelf.pairs.append(CBORMapPair(key: CBOR.textString(keyString), value: result))
        }
        
        return KeyedEncodingContainer(finalizedContainer)
    }
    
    func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        let keyString = key.stringValue
        
        // Create a new encoder for the nested container
        let nestedEncoder = CBOREncoder()
        let container = CBOREncoderUnkeyedContainer(codingPath: codingPath, encoder: nestedEncoder)
        
        // Create a new container that will finalize when it's done
        return FinalizedUnkeyedEncodingContainer(container: container) { [self] result in
            var mutableSelf = self
            mutableSelf.pairs.append(CBORMapPair(key: CBOR.textString(keyString), value: result))
        }
    }
    
    func superEncoder() -> Encoder {
        return superEncoder(forKey: Key(stringValue: "super")!)
    }
    
    func superEncoder(forKey key: K) -> Encoder {
        return encoder
    }
}

// MARK: - Finalized Containers

private class FinalizedKeyedEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
    typealias Key = K
    
    private var container: CBOREncoderKeyedContainer<K>
    private let onFinalize: (CBOR) -> Void
    
    let codingPath: [CodingKey]
    
    init(container: CBOREncoderKeyedContainer<K>, onFinalize: @escaping (CBOR) -> Void) {
        self.container = container
        self.onFinalize = onFinalize
        self.codingPath = container.codingPath
    }
    
    func encodeNil(forKey key: K) throws {
        try container.encodeNil(forKey: key)
    }
    
    func encode(_ value: Bool, forKey key: K) throws {
        try container.encode(value, forKey: key)
    }
    
    func encode(_ value: String, forKey key: K) throws {
        try container.encode(value, forKey: key)
    }
    
    func encode(_ value: Double, forKey key: K) throws {
        try container.encode(value, forKey: key)
    }
    
    func encode(_ value: Float, forKey key: K) throws {
        try container.encode(value, forKey: key)
    }
    
    func encode(_ value: Int, forKey key: K) throws {
        try container.encode(value, forKey: key)
    }
    
    func encode(_ value: Int8, forKey key: K) throws {
        try container.encode(value, forKey: key)
    }
    
    func encode(_ value: Int16, forKey key: K) throws {
        try container.encode(value, forKey: key)
    }
    
    func encode(_ value: Int32, forKey key: K) throws {
        try container.encode(value, forKey: key)
    }
    
    func encode(_ value: Int64, forKey key: K) throws {
        try container.encode(value, forKey: key)
    }
    
    func encode(_ value: UInt, forKey key: K) throws {
        try container.encode(value, forKey: key)
    }
    
    func encode(_ value: UInt8, forKey key: K) throws {
        try container.encode(value, forKey: key)
    }
    
    func encode(_ value: UInt16, forKey key: K) throws {
        try container.encode(value, forKey: key)
    }
    
    func encode(_ value: UInt32, forKey key: K) throws {
        try container.encode(value, forKey: key)
    }
    
    func encode(_ value: UInt64, forKey key: K) throws {
        try container.encode(value, forKey: key)
    }
    
    func encode<T>(_ value: T, forKey key: K) throws where T: Encodable {
        try container.encode(value, forKey: key)
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        return container.nestedContainer(keyedBy: keyType, forKey: key)
    }
    
    func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        return container.nestedUnkeyedContainer(forKey: key)
    }
    
    func superEncoder() -> Encoder {
        return container.superEncoder()
    }
    
    func superEncoder(forKey key: K) -> Encoder {
        return container.superEncoder(forKey: key)
    }
}

private class FinalizedUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    private var container: CBOREncoderUnkeyedContainer
    private let onFinalize: (CBOR) -> Void
    
    let codingPath: [CodingKey]
    let count: Int
    
    init(container: CBOREncoderUnkeyedContainer, onFinalize: @escaping (CBOR) -> Void) {
        self.container = container
        self.onFinalize = onFinalize
        self.codingPath = container.codingPath
        self.count = container.count
    }
    
    func encodeNil() throws {
        try container.encodeNil()
    }
    
    func encode(_ value: Bool) throws {
        try container.encode(value)
    }
    
    func encode(_ value: String) throws {
        try container.encode(value)
    }
    
    func encode(_ value: Double) throws {
        try container.encode(value)
    }
    
    func encode(_ value: Float) throws {
        try container.encode(value)
    }
    
    func encode(_ value: Int) throws {
        try container.encode(value)
    }
    
    func encode(_ value: Int8) throws {
        try container.encode(value)
    }
    
    func encode(_ value: Int16) throws {
        try container.encode(value)
    }
    
    func encode(_ value: Int32) throws {
        try container.encode(value)
    }
    
    func encode(_ value: Int64) throws {
        try container.encode(value)
    }
    
    func encode(_ value: UInt) throws {
        try container.encode(value)
    }
    
    func encode(_ value: UInt8) throws {
        try container.encode(value)
    }
    
    func encode(_ value: UInt16) throws {
        try container.encode(value)
    }
    
    func encode(_ value: UInt32) throws {
        try container.encode(value)
    }
    
    func encode(_ value: UInt64) throws {
        try container.encode(value)
    }
    
    func encode<T>(_ value: T) throws where T: Encodable {
        try container.encode(value)
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        return container.nestedContainer(keyedBy: keyType)
    }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return container.nestedUnkeyedContainer()
    }
    
    func superEncoder() -> Encoder {
        return container.superEncoder()
    }
}

// MARK: - Helper Types

private struct AnyCodingKey: CodingKey {
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
}

internal struct CBOREncoderSingleValueContainer: SingleValueEncodingContainer {
    let codingPath: [CodingKey]
    internal let encoder: CBOREncoder
    
    init(codingPath: [CodingKey], encoder: CBOREncoder) {
        self.codingPath = codingPath
        self.encoder = encoder
    }
    
    func encodeNil() throws {
        encoder.push(CBOR.null)
    }
    
    func encode(_ value: Bool) throws {
        encoder.push(CBOR.bool(value))
    }
    
    func encode(_ value: String) throws {
        encoder.push(CBOR.textString(value))
    }
    
    func encode(_ value: Double) throws {
        encoder.push(CBOR.float(value))
    }
    
    func encode(_ value: Float) throws {
        encoder.push(CBOR.float(Double(value)))
    }
    
    func encode(_ value: Int) throws {
        if value < 0 {
            encoder.push(CBOR.negativeInt(Int64(-1 - value)))
        } else {
            encoder.push(CBOR.unsignedInt(UInt64(value)))
        }
    }
    
    func encode(_ value: Int8) throws {
        try encode(Int(value))
    }
    
    func encode(_ value: Int16) throws {
        try encode(Int(value))
    }
    
    func encode(_ value: Int32) throws {
        try encode(Int(value))
    }
    
    func encode(_ value: Int64) throws {
        if value < 0 {
            encoder.push(CBOR.negativeInt(Int64(-1 - value)))
        } else {
            encoder.push(CBOR.unsignedInt(UInt64(value)))
        }
    }
    
    func encode(_ value: UInt) throws {
        encoder.push(CBOR.unsignedInt(UInt64(value)))
    }
    
    func encode(_ value: UInt8) throws {
        try encode(UInt(value))
    }
    
    func encode(_ value: UInt16) throws {
        try encode(UInt(value))
    }
    
    func encode(_ value: UInt32) throws {
        try encode(UInt(value))
    }
    
    func encode(_ value: UInt64) throws {
        encoder.push(CBOR.unsignedInt(value))
    }
    
    func encode<T>(_ value: T) throws where T: Encodable {
        try encoder.push(encoder.encodeCBOR(value))
    }
}
#endif