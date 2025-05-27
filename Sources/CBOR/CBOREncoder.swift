#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: - CBOR Encoder

public class CBOREncoder {
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
    
    public func encode<T: Encodable>(_ value: T) throws -> Data {
        // Special case for Data
        if let data = value as? Data {
            let bytes = [UInt8](data)
            let cbor = CBOR.byteString(ArraySlice(bytes))
            return Data(cbor.encode())
        }
        
        // Special case for Date
        if let date = value as? Date {
            // For tagged values, we need to encode the inner value first and then use the bytes
            let innerValue = CBOR.float(date.timeIntervalSince1970)
            let innerBytes = innerValue.encode()
            let cbor = CBOR.tagged(1, ArraySlice(innerBytes))
            return Data(cbor.encode())
        }
        
        // Special case for URL
        if let url = value as? URL {
            // Convert the URL string to UTF-8 bytes
            if let utf8Data = url.absoluteString.data(using: .utf8) {
                let bytes = [UInt8](utf8Data)
                let cbor = CBOR.textString(ArraySlice(bytes))
                return Data(cbor.encode())
            } else {
                throw EncodingError.invalidValue(url, EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid UTF-8 data in URL string"
                ))
            }
        }
        
        // Special case for arrays of primitive types
        if let array = value as? [Int] {
            // For arrays, we need to encode each element and then combine them
            var encodedBytes: [UInt8] = []
            // Add array header
            encodeUnsigned(major: 4, value: UInt64(array.count), into: &encodedBytes)
            
            // Add each element
            for item in array {
                if item < 0 {
                    let cbor = CBOR.negativeInt(Int64(item))
                    encodedBytes.append(contentsOf: cbor.encode())
                } else {
                    let cbor = CBOR.unsignedInt(UInt64(item))
                    encodedBytes.append(contentsOf: cbor.encode())
                }
            }
            
            return Data(encodedBytes)
        }
        
        if let array = value as? [String] {
            // For arrays, we need to encode each element and then combine them
            var encodedBytes: [UInt8] = []
            // Add array header
            encodeUnsigned(major: 4, value: UInt64(array.count), into: &encodedBytes)
            
            // Add each element
            for item in array {
                // Convert each string to UTF-8 bytes
                if let utf8Data = item.data(using: .utf8) {
                    let bytes = [UInt8](utf8Data)
                    let cbor = CBOR.textString(ArraySlice(bytes))
                    encodedBytes.append(contentsOf: cbor.encode())
                } else {
                    throw EncodingError.invalidValue(item, EncodingError.Context(
                        codingPath: [],
                        debugDescription: "Invalid UTF-8 data in string array item"
                    ))
                }
            }
            
            return Data(encodedBytes)
        }
        
        if let array = value as? [Bool] {
            // For arrays, we need to encode each element and then combine them
            var encodedBytes: [UInt8] = []
            // Add array header
            encodeUnsigned(major: 4, value: UInt64(array.count), into: &encodedBytes)
            
            // Add each element
            for item in array {
                let cbor = CBOR.bool(item)
                encodedBytes.append(contentsOf: cbor.encode())
            }
            
            return Data(encodedBytes)
        }
        
        if let array = value as? [Double] {
            // For arrays, we need to encode each element and then combine them
            var encodedBytes: [UInt8] = []
            // Add array header
            encodeUnsigned(major: 4, value: UInt64(array.count), into: &encodedBytes)
            
            // Add each element
            for item in array {
                let cbor = CBOR.float(item)
                encodedBytes.append(contentsOf: cbor.encode())
            }
            
            return Data(encodedBytes)
        }
        
        if let array = value as? [Float] {
            // For arrays, we need to encode each element and then combine them
            var encodedBytes: [UInt8] = []
            // Add array header
            encodeUnsigned(major: 4, value: UInt64(array.count), into: &encodedBytes)
            
            // Add each element
            for item in array {
                let cbor = CBOR.float(Double(item))
                encodedBytes.append(contentsOf: cbor.encode())
            }
            
            return Data(encodedBytes)
        }
        
        if let array = value as? [Data] {
            // For arrays, we need to encode each element and then combine them
            var encodedBytes: [UInt8] = []
            // Add array header
            encodeUnsigned(major: 4, value: UInt64(array.count), into: &encodedBytes)
            
            // Add each element
            for item in array {
                let bytes = [UInt8](item)
                let cbor = CBOR.byteString(ArraySlice(bytes))
                encodedBytes.append(contentsOf: cbor.encode())
            }
            
            return Data(encodedBytes)
        }
        
        // For other types, use the Encodable protocol
        storage = Storage() // Reset storage
        try value.encode(to: self)
        
        // Get the encoded CBOR value and convert it to Data
        let cbor = storage.topValue
        return Data(cbor.encode())
    }
    
    // MARK: - Internal API
    
    fileprivate func push(_ value: CBOR) {
        storage.push(value)
    }
    
    // Implementation of the encodeCBOR method that's referenced in the code
    fileprivate func encodeCBOR<T: Encodable>(_ value: T) throws -> CBOR {
        // Special case for Data
        if let data = value as? Data {
            return CBOR.byteString(ArraySlice([UInt8](data)))
        }
        
        // Special case for Date
        if let date = value as? Date {
            // For tagged values, we need to encode the inner value first and then use the bytes
            let floatValue = CBOR.float(date.timeIntervalSince1970)
            let encodedBytes = floatValue.encode()
            return CBOR.tagged(1, ArraySlice(encodedBytes))
        }
        
        // Special case for URL
        if let url = value as? URL {
            // Convert the URL string to UTF-8 bytes
            if let utf8Data = url.absoluteString.data(using: .utf8) {
                let bytes = [UInt8](utf8Data)
                return CBOR.textString(ArraySlice(bytes))
            } else {
                throw EncodingError.invalidValue(url, EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid UTF-8 data in URL string"
                ))
            }
        }
        
        // Special case for arrays of primitive types
        if let array = value as? [Int] {
            // For arrays, we need to encode each element and then combine them
            var encodedBytes: [UInt8] = []
            // Add array header
            encodeUnsigned(major: 4, value: UInt64(array.count), into: &encodedBytes)
            
            // Add each element
            for item in array {
                if item < 0 {
                    let cbor = CBOR.negativeInt(Int64(item))
                    encodedBytes.append(contentsOf: cbor.encode())
                } else {
                    let cbor = CBOR.unsignedInt(UInt64(item))
                    encodedBytes.append(contentsOf: cbor.encode())
                }
            }
            
            return CBOR.byteString(ArraySlice(encodedBytes))
        }
        if let array = value as? [String] {
            // For arrays, we need to encode each element and then combine them
            var encodedBytes: [UInt8] = []
            // Add array header
            encodeUnsigned(major: 4, value: UInt64(array.count), into: &encodedBytes)
            
            // Add each element
            for item in array {
                // Convert each string to UTF-8 bytes
                if let utf8Data = item.data(using: .utf8) {
                    let bytes = [UInt8](utf8Data)
                    let cbor = CBOR.textString(ArraySlice(bytes))
                    encodedBytes.append(contentsOf: cbor.encode())
                } else {
                    throw EncodingError.invalidValue(item, EncodingError.Context(
                        codingPath: [],
                        debugDescription: "Invalid UTF-8 data in string array item"
                    ))
                }
            }
            
            return CBOR.byteString(ArraySlice(encodedBytes))
        }
        if let array = value as? [Bool] {
            // For arrays, we need to encode each element and then combine them
            var encodedBytes: [UInt8] = []
            // Add array header
            encodeUnsigned(major: 4, value: UInt64(array.count), into: &encodedBytes)
            
            // Add each element
            for item in array {
                let cbor = CBOR.bool(item)
                encodedBytes.append(contentsOf: cbor.encode())
            }
            
            return CBOR.byteString(ArraySlice(encodedBytes))
        }
        if let array = value as? [Double] {
            // For arrays, we need to encode each element and then combine them
            var encodedBytes: [UInt8] = []
            // Add array header
            encodeUnsigned(major: 4, value: UInt64(array.count), into: &encodedBytes)
            
            // Add each element
            for item in array {
                let cbor = CBOR.float(item)
                encodedBytes.append(contentsOf: cbor.encode())
            }
            
            return CBOR.byteString(ArraySlice(encodedBytes))
        }
        if let array = value as? [Float] {
            // For arrays, we need to encode each element and then combine them
            var encodedBytes: [UInt8] = []
            // Add array header
            encodeUnsigned(major: 4, value: UInt64(array.count), into: &encodedBytes)
            
            // Add each element
            for item in array {
                let cbor = CBOR.float(Double(item))
                encodedBytes.append(contentsOf: cbor.encode())
            }
            
            return CBOR.byteString(ArraySlice(encodedBytes))
        }
        if let array = value as? [Data] {
            // For arrays, we need to encode each element and then combine them
            var encodedBytes: [UInt8] = []
            // Add array header
            encodeUnsigned(major: 4, value: UInt64(array.count), into: &encodedBytes)
            
            // Add each element
            for item in array {
                let bytes = [UInt8](item)
                let cbor = CBOR.byteString(ArraySlice(bytes))
                encodedBytes.append(contentsOf: cbor.encode())
            }
            
            return CBOR.byteString(ArraySlice(encodedBytes))
        }
        
        // For other types, use the Encodable protocol
        let tempEncoder = CBOREncoder()
        try value.encode(to: tempEncoder)
        
        // Get the encoded CBOR value
        return tempEncoder.storage.topValue
    }
    
    /// Encodes an unsigned integer with the given major type
    ///
    /// - Parameters:
    ///   - major: The major type of the integer
    ///   - value: The unsigned integer value
    ///   - output: The output buffer to write the encoded bytes to
    fileprivate func encodeUnsigned(major: UInt8, value: UInt64, into output: inout [UInt8]) {
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
        // For arrays, we need to encode each element and then combine them
        var encodedBytes: [UInt8] = []
        // Add array header
        encoder.encodeUnsigned(major: 4, value: UInt64(elements.count), into: &encodedBytes)
        
        // Add each element
        for element in elements {
            encodedBytes.append(contentsOf: element.encode())
        }
        
        encoder.push(CBOR.array(ArraySlice(encodedBytes)))
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
    
    mutating func encodeNil() throws {
        elements.append(CBOR.null)
        finalize()
    }
    
    mutating func encode(_ value: Bool) throws {
        elements.append(CBOR.bool(value))
        finalize()
    }
    
    mutating func encode(_ value: String) throws {
        // Convert the string to UTF-8 bytes
        if let utf8Data = value.data(using: .utf8) {
            let bytes = [UInt8](utf8Data)
            elements.append(CBOR.textString(ArraySlice(bytes)))
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(
                codingPath: codingPath,
                debugDescription: "Unable to encode string as UTF-8"
            ))
        }
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
            elements.append(CBOR.byteString(ArraySlice([UInt8](data))))
            finalize()
            return
        }
        
        // Special case for Date
        if let date = value as? Date {
            // For tagged values, we need to encode the inner value first and then use the bytes
            let innerValue = CBOR.float(date.timeIntervalSince1970)
            let innerBytes = innerValue.encode()
            elements.append(CBOR.tagged(1, ArraySlice(innerBytes)))
            finalize()
            return
        }
        
        // Special case for URL
        if let url = value as? URL {
            // Convert the URL string to UTF-8 bytes
            if let utf8Data = url.absoluteString.data(using: .utf8) {
                let bytes = [UInt8](utf8Data)
                elements.append(CBOR.textString(ArraySlice(bytes)))
                finalize()
                return
            } else {
                throw EncodingError.invalidValue(url, EncodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Invalid UTF-8 data in URL string"
                ))
            }
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
    
    // Helper method to convert a string to a CBOR text string
    private func textStringCBOR(_ string: String) -> CBOR {
        if let utf8Data = string.data(using: .utf8) {
            let bytes = [UInt8](utf8Data)
            return CBOR.textString(ArraySlice(bytes))
        } else {
            // This should never happen with valid strings, but we need to handle it
            return CBOR.textString(ArraySlice<UInt8>())
        }
    }
    
    // Finalize the container by pushing the map to the encoder
    private mutating func finalize() {
        // For map, we need to encode the pairs
        var encodedBytes: [UInt8] = []
        // Add map header
        encodeUnsigned(major: 5, value: UInt64(pairs.count), into: &encodedBytes)
        
        // Add each key-value pair
        for pair in pairs {
            encodedBytes.append(contentsOf: pair.key.encode())
            encodedBytes.append(contentsOf: pair.value.encode())
        }
        
        encoder.push(CBOR.map(ArraySlice(encodedBytes)))
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
    
    mutating func encodeNil(forKey key: K) throws {
        let keyString = key.stringValue
        pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.null))
        finalize()
    }
    
    mutating func encode(_ value: Bool, forKey key: K) throws {
        let keyString = key.stringValue
        pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.bool(value)))
        finalize()
    }
    
    mutating func encode(_ value: String, forKey key: K) throws {
        // Convert the string to UTF-8 bytes
        if let utf8Data = value.data(using: .utf8) {
            let bytes = [UInt8](utf8Data)
            let keyString = key.stringValue
            pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.textString(ArraySlice(bytes))))
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(
                codingPath: codingPath,
                debugDescription: "Unable to encode string as UTF-8"
            ))
        }
        finalize()
    }
    
    mutating func encode(_ value: Double, forKey key: K) throws {
        let keyString = key.stringValue
        pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.float(value)))
        finalize()
    }
    
    mutating func encode(_ value: Float, forKey key: K) throws {
        let keyString = key.stringValue
        pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.float(Double(value))))
        finalize()
    }
    
    mutating func encode(_ value: Int, forKey key: K) throws {
        let keyString = key.stringValue
        if value < 0 {
            pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.negativeInt(Int64(-1 - value))))
        } else {
            pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.unsignedInt(UInt64(value))))
        }
        finalize()
    }
    
    mutating func encode(_ value: Int8, forKey key: K) throws {
        let keyString = key.stringValue
        if value < 0 {
            pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.negativeInt(Int64(-1 - Int64(value)))))
        } else {
            pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.unsignedInt(UInt64(value))))
        }
        finalize()
    }
    
    mutating func encode(_ value: Int16, forKey key: K) throws {
        let keyString = key.stringValue
        if value < 0 {
            pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.negativeInt(Int64(-1 - Int64(value)))))
        } else {
            pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.unsignedInt(UInt64(value))))
        }
        finalize()
    }
    
    mutating func encode(_ value: Int32, forKey key: K) throws {
        let keyString = key.stringValue
        if value < 0 {
            pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.negativeInt(Int64(-1 - Int64(value)))))
        } else {
            pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.unsignedInt(UInt64(value))))
        }
        finalize()
    }
    
    mutating func encode(_ value: Int64, forKey key: K) throws {
        let keyString = key.stringValue
        if value < 0 {
            pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.negativeInt(value)))
        } else {
            pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.unsignedInt(UInt64(value))))
        }
        finalize()
    }
    
    mutating func encode(_ value: UInt, forKey key: K) throws {
        let keyString = key.stringValue
        pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.unsignedInt(UInt64(value))))
        finalize()
    }
    
    mutating func encode(_ value: UInt8, forKey key: K) throws {
        let keyString = key.stringValue
        pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.unsignedInt(UInt64(value))))
        finalize()
    }
    
    mutating func encode(_ value: UInt16, forKey key: K) throws {
        let keyString = key.stringValue
        pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.unsignedInt(UInt64(value))))
        finalize()
    }
    
    mutating func encode(_ value: UInt32, forKey key: K) throws {
        let keyString = key.stringValue
        pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.unsignedInt(UInt64(value))))
        finalize()
    }
    
    mutating func encode(_ value: UInt64, forKey key: K) throws {
        let keyString = key.stringValue
        pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: CBOR.unsignedInt(value)))
        finalize()
    }
    
    mutating func encode<T>(_ value: T, forKey key: K) throws where T: Encodable {
        let keyString = key.stringValue
        let cbor = try encoder.encodeCBOR(value)
        pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: cbor))
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
            mutableSelf.pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: result))
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
            mutableSelf.pairs.append(CBORMapPair(key: textStringCBOR(keyString), value: result))
        }
    }
    
    func superEncoder() -> Encoder {
        return encoder
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

private struct CBOREncoderSingleValueContainer: SingleValueEncodingContainer {
    let codingPath: [CodingKey]
    private let encoder: CBOREncoder
    
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
        // Convert the string to UTF-8 bytes
        if let utf8Data = value.data(using: .utf8) {
            let bytes = [UInt8](utf8Data)
            encoder.push(CBOR.textString(ArraySlice(bytes)))
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(
                codingPath: codingPath,
                debugDescription: "Unable to encode string as UTF-8"
            ))
        }
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
