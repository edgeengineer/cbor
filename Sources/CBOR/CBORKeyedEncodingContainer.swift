#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: - CBOR Keyed Encoding Container

// This file contains an extension to CBOREncoder that was previously defined
// The actual implementation is now in CBOREncoder.swift
// This file is kept for reference but its contents are not used

/*
extension CBOREncoder {
    struct CBORKeyedEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
        var codingPath: [CodingKey]
        private let encoder: _CBOREncoderImpl
        
        private var pairs: [CBORMapPair] = []
        
        init(encoder: _CBOREncoderImpl, codingPath: [CodingKey]) {
            self.encoder = encoder
            self.codingPath = codingPath
        }
        
        var value: CBOR {
            return .map(pairs)
        }
        
        mutating func encodeNil(forKey key: K) throws {
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .null))
        }
        
        mutating func encode(_ value: Bool, forKey key: K) throws {
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .bool(value)))
        }
        
        mutating func encode(_ value: String, forKey key: K) throws {
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .textString(value)))
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
        
        mutating func encode<T>(_ value: T, forKey key: K) throws where T: Encodable {
            // Special case for Data
            if let data = value as? Data {
                pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .byteString([UInt8](data))))
                return
            }
            
            // Special case for Date
            if let date = value as? Date {
                let timeInterval = date.timeIntervalSince1970
                pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .tagged(1, .float(timeInterval))))
                return
            }
            
            // Special case for URL
            if let url = value as? URL {
                pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .textString(url.absoluteString)))
                return
            }
            
            // For other Encodable types, use a nested encoder
            let nestedPath = codingPath + [key]
            let nestedEncoder = _CBOREncoderImpl(codingPath: nestedPath)
            
            try value.encode(to: nestedEncoder)
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: nestedEncoder.storage.topValue))
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            let nestedPath = codingPath + [key]
            let nestedEncoder = _CBOREncoderImpl(codingPath: nestedPath)
            let container = CBORKeyedEncodingContainer<NestedKey>(encoder: nestedEncoder, codingPath: nestedPath)
            
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .map([])))
            
            return KeyedEncodingContainer(container)
        }
        
        mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
            let nestedPath = codingPath + [key]
            let nestedEncoder = _CBOREncoderImpl(codingPath: nestedPath)
            let container = CBORUnkeyedEncodingContainer(encoder: nestedEncoder, codingPath: nestedPath)
            
            pairs.append(CBORMapPair(key: .textString(key.stringValue), value: .array([])))
            
            return container
        }
        
        mutating func superEncoder() -> Encoder {
            return _CBOREncoderImpl(codingPath: codingPath)
        }
        
        mutating func superEncoder(forKey key: K) -> Encoder {
            let nestedPath = codingPath + [key]
            return _CBOREncoderImpl(codingPath: nestedPath)
        }
    }
}
*/
