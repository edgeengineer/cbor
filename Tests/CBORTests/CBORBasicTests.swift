import Testing
import Foundation
import XCTest
@testable import CBOR

struct CBORBasicTests {
    // MARK: - Unsigned Integer Tests
    
    @Test
    func testUnsignedInt() {
        let testCases: [(UInt64, [UInt8])] = [
            (0, [0x00]),
            (1, [0x01]),
            (10, [0x0a]),
            (23, [0x17]),
            (24, [0x18, 0x18]),
            (25, [0x18, 0x19]),
            (100, [0x18, 0x64]),
            (1000, [0x19, 0x03, 0xe8]),
            (1000000, [0x1a, 0x00, 0x0f, 0x42, 0x40]),
            (1000000000000, [0x1b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x10, 0x00]),
            (UInt64.max, [0x1b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff])
        ]
        
        for (value, expectedBytes) in testCases {
            let cbor = CBOR.unsignedInt(value)
            let encoded = cbor.encode()
            #expect(encoded == expectedBytes, "Failed to encode \(value)")
            
            do {
                let decoded = try CBOR.decode(encoded)
                if case let .unsignedInt(decodedValue) = decoded {
                    #expect(decodedValue == value, "Failed to decode \(value)")
                } else {
                    #expect(false, "Expected unsignedInt, got \(decoded)")
                }
            } catch {
                #expect(false, "Failed to decode \(value): \(error)")
            }
        }
    }
    
    // MARK: - Negative Integer Tests
    
    @Test
    func testNegativeInt() {
        let testCases: [(Int64, [UInt8])] = [
            (-1, [0x20]),
            (-10, [0x29]),
            (-24, [0x37]),
            (-25, [0x38, 0x18]),
            (-100, [0x38, 0x63]),
            (-1000, [0x39, 0x03, 0xe7]),
            (-1000000, [0x3a, 0x00, 0x0f, 0x42, 0x3f]),
            (-1000000000000, [0x3b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x0f, 0xff]),
            (Int64.min, [0x3b, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff])
        ]
        
        for (value, expectedBytes) in testCases {
            let cbor = CBOR.negativeInt(value)
            let encoded = cbor.encode()
            #expect(encoded == expectedBytes, "Failed to encode \(value)")
            
            do {
                let decoded = try CBOR.decode(encoded)
                if case let .negativeInt(decodedValue) = decoded {
                    #expect(decodedValue == value, "Failed to decode \(value)")
                } else {
                    #expect(false, "Expected negativeInt, got \(decoded)")
                }
            } catch {
                #expect(false, "Failed to decode \(value): \(error)")
            }
        }
    }
    
    // MARK: - Byte String Tests
    
    @Test
    func testByteString() {
        let testCases: [([UInt8], [UInt8])] = [
            ([], [0x40]),
            ([0x01, 0x02, 0x03, 0x04], [0x44, 0x01, 0x02, 0x03, 0x04]),
            (Array(repeating: 0x42, count: 25), [0x58, 0x19] + Array(repeating: 0x42, count: 25))
        ]
        
        for (value, expectedBytes) in testCases {
            let cbor = CBOR.byteString(value)
            let encoded = cbor.encode()
            #expect(encoded == expectedBytes, "Failed to encode byte string of length \(value.count)")
            
            do {
                let decoded = try CBOR.decode(encoded)
                if case let .byteString(decodedValue) = decoded {
                    #expect(decodedValue == value, "Failed to decode byte string")
                } else {
                    #expect(false, "Expected byteString, got \(decoded)")
                }
            } catch {
                #expect(false, "Failed to decode byte string: \(error)")
            }
        }
    }
    
    // MARK: - Text String Tests
    
    @Test
    func testTextString() {
        let testCases: [(String, [UInt8])] = [
            ("", [0x60]),
            ("a", [0x61, 0x61]),
            ("IETF", [0x64, 0x49, 0x45, 0x54, 0x46]),
            ("\"\\", [0x62, 0x22, 0x5c]),
            ("ü", [0x62, 0xc3, 0xbc]),
            ("水", [0x63, 0xe6, 0xb0, 0xb4]),
            ("Hello, world!", [0x6d, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x2c, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64, 0x21])
        ]
        
        for (value, expectedBytes) in testCases {
            let cbor = CBOR.textString(value)
            let encoded = cbor.encode()
            #expect(encoded == expectedBytes, "Failed to encode \"\(value)\"")
            
            do {
                let decoded = try CBOR.decode(encoded)
                if case let .textString(decodedValue) = decoded {
                    #expect(decodedValue == value, "Failed to decode \"\(value)\"")
                } else {
                    #expect(false, "Expected textString, got \(decoded)")
                }
            } catch {
                #expect(false, "Failed to decode \"\(value)\": \(error)")
            }
        }
    }
    
    // MARK: - Array Tests
    
    @Test
    func testArray() {
        // Empty array
        do {
            let cbor = CBOR.array([])
            let encoded = cbor.encode()
            #expect(encoded == [0x80])
            
            let decoded = try CBOR.decode(encoded)
            if case let .array(decodedValue) = decoded {
                #expect(decodedValue.count == 0)
            } else {
                #expect(false, "Expected array, got \(decoded)")
            }
        } catch {
            #expect(false, "Failed to decode empty array: \(error)")
        }
        
        // Array with mixed types
        do {
            let array: [CBOR] = [
                .unsignedInt(1),
                .negativeInt(-2),
                .textString("three"),
                .array([.bool(true), .bool(false)]),
                .map([CBORMapPair(key: .textString("key"), value: .textString("value"))])
            ]
            
            let cbor = CBOR.array(array)
            let encoded = cbor.encode()
            
            let expectedBytes: [UInt8] = [
                0x85, // array of 5 items
                0x01, // 1
                0x21, // -2
                0x65, 0x74, 0x68, 0x72, 0x65, 0x65, // "three"
                0x82, 0xf5, 0xf4, // [true, false]
                0xa1, 0x63, 0x6b, 0x65, 0x79, 0x65, 0x76, 0x61, 0x6c, 0x75, 0x65 // {"key": "value"}
            ]
            
            #expect(encoded == expectedBytes)
            
            let decoded = try CBOR.decode(encoded)
            if case let .array(decodedValue) = decoded {
                #expect(decodedValue.count == array.count)
                
                // Check first element
                if case let .unsignedInt(value) = decodedValue[0] {
                    #expect(value == 1)
                } else {
                    #expect(false, "Expected unsignedInt, got \(decodedValue[0])")
                }
                
                // Check second element
                if case let .negativeInt(value) = decodedValue[1] {
                    #expect(value == -2)
                } else {
                    #expect(false, "Expected negativeInt, got \(decodedValue[1])")
                }
                
                // Check third element
                if case let .textString(value) = decodedValue[2] {
                    #expect(value == "three")
                } else {
                    #expect(false, "Expected textString, got \(decodedValue[2])")
                }
                
                // Check fourth element (nested array)
                if case let .array(nestedArray) = decodedValue[3] {
                    #expect(nestedArray.count == 2)
                    if case let .bool(value1) = nestedArray[0], case let .bool(value2) = nestedArray[1] {
                        #expect(value1 == true)
                        #expect(value2 == false)
                    } else {
                        #expect(false, "Expected [bool, bool], got \(nestedArray)")
                    }
                } else {
                    #expect(false, "Expected array, got \(decodedValue[3])")
                }
                
                // Check fifth element (map)
                if case let .map(mapPairs) = decodedValue[4] {
                    #expect(mapPairs.count == 1)
                    let pair = mapPairs[0]
                    if case let .textString(key) = pair.key, case let .textString(value) = pair.value {
                        #expect(key == "key")
                        #expect(value == "value")
                    } else {
                        #expect(false, "Expected {textString: textString}, got \(pair)")
                    }
                } else {
                    #expect(false, "Expected map, got \(decodedValue[4])")
                }
            } else {
                #expect(false, "Expected array, got \(decoded)")
            }
        } catch {
            #expect(false, "Failed to decode array: \(error)")
        }
    }
    
    // MARK: - Map Tests
    
    @Test
    func testMap() {
        // Empty map
        do {
            let cbor = CBOR.map([])
            let encoded = cbor.encode()
            #expect(encoded == [0xa0])
            
            let decoded = try CBOR.decode(encoded)
            if case let .map(decodedValue) = decoded {
                #expect(decodedValue.isEmpty)
            } else {
                #expect(false, "Expected map, got \(decoded)")
            }
        } catch {
            #expect(false, "Failed to decode empty map: \(error)")
        }
        
        // Map with mixed types
        do {
            let map: [CBORMapPair] = [
                CBORMapPair(key: .unsignedInt(1), value: .negativeInt(-1)),
                CBORMapPair(key: .textString("string"), value: .textString("value")),
                CBORMapPair(key: .bool(true), value: .array([.unsignedInt(1), .unsignedInt(2), .unsignedInt(3)])),
                CBORMapPair(key: .textString("nested"), value: .map([
                    CBORMapPair(key: .textString("a"), value: .unsignedInt(1)),
                    CBORMapPair(key: .textString("b"), value: .unsignedInt(2))
                ]))
            ]
            
            let cbor = CBOR.map(map)
            let encoded = cbor.encode()
            
            let decoded = try CBOR.decode(encoded)
            if case let .map(decodedPairs) = decoded {
                #expect(decodedPairs.count == map.count)
                
                // Find and check each key-value pair
                
                // Pair 1: 1 => -1
                let pair1 = decodedPairs.first { pair in
                    if case .unsignedInt(1) = pair.key {
                        return true
                    }
                    return false
                }
                #expect(pair1 != nil)
                if let pair1 = pair1, case let .negativeInt(value) = pair1.value {
                    #expect(value == -1)
                } else if let pair1 = pair1 {
                    #expect(false, "Expected negativeInt, got \(pair1.value)")
                }
                
                // Pair 2: "string" => "value"
                let pair2 = decodedPairs.first { pair in
                    if case .textString("string") = pair.key {
                        return true
                    }
                    return false
                }
                #expect(pair2 != nil)
                if let pair2 = pair2, case let .textString(value) = pair2.value {
                    #expect(value == "value")
                } else if let pair2 = pair2 {
                    #expect(false, "Expected textString, got \(pair2.value)")
                }
                
                // Pair 3: true => [1, 2, 3]
                let pair3 = decodedPairs.first { pair in
                    if case .bool(true) = pair.key {
                        return true
                    }
                    return false
                }
                #expect(pair3 != nil)
                if let pair3 = pair3, case let .array(value) = pair3.value {
                    #expect(value.count == 3)
                    if case let .unsignedInt(v1) = value[0], case let .unsignedInt(v2) = value[1], case let .unsignedInt(v3) = value[2] {
                        #expect(v1 == 1)
                        #expect(v2 == 2)
                        #expect(v3 == 3)
                    } else {
                        #expect(false, "Expected [unsignedInt, unsignedInt, unsignedInt], got \(value)")
                    }
                } else if let pair3 = pair3 {
                    #expect(false, "Expected array, got \(pair3.value)")
                }
                
                // Pair 4: "nested" => {"a": 1, "b": 2}
                let pair4 = decodedPairs.first { pair in
                    if case .textString("nested") = pair.key {
                        return true
                    }
                    return false
                }
                #expect(pair4 != nil)
                if let pair4 = pair4, case let .map(nestedMap) = pair4.value {
                    #expect(nestedMap.count == 2)
                    
                    let nestedPair1 = nestedMap.first { pair in
                        if case .textString("a") = pair.key {
                            return true
                        }
                        return false
                    }
                    #expect(nestedPair1 != nil)
                    if let nestedPair1 = nestedPair1, case let .unsignedInt(value) = nestedPair1.value {
                        #expect(value == 1)
                    } else if let nestedPair1 = nestedPair1 {
                        #expect(false, "Expected unsignedInt, got \(nestedPair1.value)")
                    }
                    
                    let nestedPair2 = nestedMap.first { pair in
                        if case .textString("b") = pair.key {
                            return true
                        }
                        return false
                    }
                    #expect(nestedPair2 != nil)
                    if let nestedPair2 = nestedPair2, case let .unsignedInt(value) = nestedPair2.value {
                        #expect(value == 2)
                    } else if let nestedPair2 = nestedPair2 {
                        #expect(false, "Expected unsignedInt, got \(nestedPair2.value)")
                    }
                } else if let pair4 = pair4 {
                    #expect(false, "Expected map, got \(pair4.value)")
                }
            } else {
                #expect(false, "Expected map, got \(decoded)")
            }
        } catch {
            #expect(false, "Failed to decode map: \(error)")
        }
    }
    
    // MARK: - Tagged Value Tests
    
    @Test
    func testTaggedValue() {
        // Test date/time (tag 1)
        do {
            let timestamp = 1363896240.5
            let cbor = CBOR.taggedValue(1, .double(timestamp))
            let encoded = cbor.encode()
            
            let expectedBytes: [UInt8] = [
                0xc1, // tag 1
                0xfb, 0x41, 0xd4, 0x52, 0xd9, 0xec, 0x20, 0x00, 0x00 // 1363896240.5
            ]
            
            #expect(encoded == expectedBytes)
            
            let decoded = try CBOR.decode(encoded)
            if case let .tagged(tag, value) = decoded {
                #expect(tag == 1)
                
                if case let .double(decodedTimestamp) = value {
                    #expect(decodedTimestamp == timestamp)
                } else {
                    #expect(false, "Expected double, got \(value)")
                }
            } else {
                #expect(false, "Expected tagged value, got \(decoded)")
            }
        } catch {
            #expect(false, "Failed to decode tagged value: \(error)")
        }
    }
    
    // MARK: - Simple Values Tests
    
    @Test
    func testSimpleValues() {
        // Test false
        do {
            let cbor = CBOR.bool(false)
            let encoded = cbor.encode()
            #expect(encoded == [0xf4])
            
            let decoded = try CBOR.decode(encoded)
            if case let .bool(value) = decoded {
                #expect(value == false)
            } else {
                #expect(false, "Expected bool, got \(decoded)")
            }
        } catch {
            #expect(false, "Failed to decode bool(false): \(error)")
        }
        
        // Test true
        do {
            let cbor = CBOR.bool(true)
            let encoded = cbor.encode()
            #expect(encoded == [0xf5])
            
            let decoded = try CBOR.decode(encoded)
            if case let .bool(value) = decoded {
                #expect(value == true)
            } else {
                #expect(false, "Expected bool, got \(decoded)")
            }
        } catch {
            #expect(false, "Failed to decode bool(true): \(error)")
        }
        
        // Test null
        do {
            let cbor = CBOR.null
            let encoded = cbor.encode()
            #expect(encoded == [0xf6])
            
            let decoded = try CBOR.decode(encoded)
            if case .null = decoded {
                // Success
            } else {
                #expect(false, "Expected null, got \(decoded)")
            }
        } catch {
            #expect(false, "Failed to decode null: \(error)")
        }
        
        // Test undefined
        do {
            let cbor = CBOR.undefined
            let encoded = cbor.encode()
            #expect(encoded == [0xf7])
            
            let decoded = try CBOR.decode(encoded)
            if case .undefined = decoded {
                // Success
            } else {
                #expect(false, "Expected undefined, got \(decoded)")
            }
        } catch {
            #expect(false, "Failed to decode undefined: \(error)")
        }
    }
    
    // MARK: - Float Tests
    
    @Test
    func testFloats() {
        let testCases: [(Double, [UInt8])] = [
            (0.0, [0xfb, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
            (1.0, [0xfb, 0x3f, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
            (-1.0, [0xfb, 0xbf, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
            (1.1, [0xfb, 0x3f, 0xf1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9a]),
            (1.5, [0xfb, 0x3f, 0xf8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
            (3.4028234663852886e+38, [0xfb, 0x47, 0xef, 0xff, 0xff, 0xe0, 0x00, 0x00, 0x00]), // Max Float32
            (1.7976931348623157e+308, [0xfb, 0x7f, 0xef, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]) // Max Float64
        ]
        
        for (value, expectedBytes) in testCases {
            let cbor = CBOR.float(value)
            let encoded = cbor.encode()
            #expect(encoded == expectedBytes, "Failed to encode \(value)")
            
            do {
                let decoded = try CBOR.decode(encoded)
                if case let .float(decodedValue) = decoded {
                    #expect(decodedValue == value, "Failed to decode \(value)")
                } else {
                    #expect(false, "Expected float, got \(decoded)")
                }
            } catch {
                #expect(false, "Failed to decode \(value): \(error)")
            }
        }
    }
    
    // MARK: - Error Tests
    
    @Test
    func testInvalidCBOR() {
        // Test premature end
        do {
            let bytes: [UInt8] = [0x18] // Unsigned int with additional info 24, but missing the value byte
            do {
                let _ = try CBOR.decode(bytes)
                XCTFail("Expected error for premature end")
            } catch {
                // Expected error
            }
        }
        
        // Test invalid initial byte
        do {
            let bytes: [UInt8] = [0xff, 0x00] // 0xff is a break marker, not a valid initial byte
            do {
                let _ = try CBOR.decode(bytes)
                XCTFail("Expected error for invalid initial byte")
            } catch {
                // Expected error
            }
        }
        
        // Test extra data
        do {
            let bytes: [UInt8] = [0x01, 0x02] // 0x01 is a valid CBOR item (unsigned int 1), but there's an extra byte
            do {
                let _ = try CBOR.decode(bytes)
                XCTFail("Expected error for extra data")
            } catch {
                // Expected error
            }
        }
    }
}
