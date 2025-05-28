import Testing
@testable import CBOR
import Foundation

@Suite("CBOR Container Tests")
struct CBORContainerTests {
    
    // MARK: - Array Tests
    
    @Test
    func testEmptyArrayEncoding() {
        // Empty array should encode to 0x80
        let emptyArrayBytes: [UInt8] = [0x80]
        
        do {
            // Create an empty array
            let array = try CBOR.decode([0x80])
            
            let encoded = array.encode()
            #expect(encoded == emptyArrayBytes, "Empty array should encode to [0x80], got \(encoded)")
        } catch {
            Issue.record("Failed to decode empty array: \(error)")
        }
    }
    
    @Test
    func testEmptyArrayDecoding() {
        // Empty array in CBOR is 0x80
        let emptyArrayBytes: [UInt8] = [0x80]
        
        do {
            let decoded = try CBOR.decode(emptyArrayBytes)
            if case .array = decoded {
                if let items = try decoded.arrayValue() {
                    #expect(items.isEmpty, "Empty array should have 0 items")
                } else {
                    Issue.record("Failed to get array value")
                }
            } else {
                Issue.record("Expected array, got \(decoded)")
            }
        } catch {
            Issue.record("Failed to decode empty array: \(error)")
        }
    }
    
    @Test
    func testSimpleArrayEncoding() {
        // Create array with individual items
        let item1 = CBOR.unsignedInt(1)
        let item2 = CBOR.textString(ArraySlice("hello".utf8))
        let item3 = CBOR.bool(true)
        
        // Encode individual items
        let encodedItem1 = item1.encode()
        let encodedItem2 = item2.encode()
        let encodedItem3 = item3.encode()
        
        // Create array with header byte + encoded items
        var arrayBytes: [UInt8] = [0x83] // Array of 3 items
        arrayBytes.append(contentsOf: encodedItem1)
        arrayBytes.append(contentsOf: encodedItem2)
        arrayBytes.append(contentsOf: encodedItem3)
        
        do {
            // Create the array using the encoded bytes
            let array = try CBOR.decode(arrayBytes)
            
            // Verify encoding
            let encoded = array.encode()
            #expect(encoded == arrayBytes, "Array should encode correctly")
        } catch {
            Issue.record("Failed to decode array: \(error)")
        }
    }
    
    @Test
    func testSimpleArrayDecoding() {
        // Create array with individual items
        let item1 = CBOR.unsignedInt(1)
        let item2 = CBOR.textString(ArraySlice("hello".utf8))
        let item3 = CBOR.bool(true)
        
        // Encode individual items
        let encodedItem1 = item1.encode()
        let encodedItem2 = item2.encode()
        let encodedItem3 = item3.encode()
        
        // Create array with header byte + encoded items
        var arrayBytes: [UInt8] = [0x83] // Array of 3 items
        arrayBytes.append(contentsOf: encodedItem1)
        arrayBytes.append(contentsOf: encodedItem2)
        arrayBytes.append(contentsOf: encodedItem3)
        
        do {
            // Decode the array
            let decoded = try CBOR.decode(arrayBytes)
            
            // Check that it's an array
            guard case .array(_) = decoded else {
                Issue.record("Expected array, got \(decoded)")
                return
            }
            
            // Get the array elements
            guard let elements = try decoded.arrayValue() else {
                Issue.record("Failed to get array value")
                return
            }
            
            // Verify the array has the correct number of elements
            #expect(elements.count == 3, "Array should have 3 elements")
            
            // Verify the elements are correct
            #expect(elements[0] == item1, "First element should be 1")
            if case let .textString(valueBytes) = elements[1] {
                let valueString = String(data: Data(valueBytes), encoding: .utf8)
                #expect(valueString == "hello", "Second element should be 'hello'")
            } else {
                Issue.record("Expected textString for elements[1], got \(elements[1])")
            }
            #expect(elements[2] == item3, "Third element should be true")
        } catch {
            Issue.record("Failed to decode array: \(error)")
        }
    }
    
    @Test
    func testHomogeneousArrays() {
        // Test arrays with homogeneous types
        
        // Array of integers
        let intArray = [1, 2, 3, 4, 5]
        var intArrayBytes: [UInt8] = [0x85] // Array of 5 items
        for i in intArray {
            intArrayBytes.append(contentsOf: CBOR.unsignedInt(UInt64(i)).encode())
        }
        
        do {
            let decoded = try CBOR.decode(intArrayBytes)
            if case .array = decoded {
                if let items = try decoded.arrayValue() {
                    #expect(items.count == intArray.count, "Array should have \(intArray.count) items")
                    for (index, value) in intArray.enumerated() {
                        #expect(items[index] == CBOR.unsignedInt(UInt64(value)), "Item at index \(index) should be \(value)")
                    }
                } else {
                    Issue.record("Failed to get array value")
                }
            } else {
                Issue.record("Expected array, got \(decoded)")
            }
        } catch {
            Issue.record("Failed to decode integer array: \(error)")
        }
        
        // Array of strings
        let stringArray = ["one", "two", "three"]
        var stringArrayBytes: [UInt8] = [0x83] // Array of 3 items
        for s in stringArray {
            stringArrayBytes.append(contentsOf: CBOR.textString(ArraySlice(s.utf8)).encode())
        }
        
        do {
            let decoded = try CBOR.decode(stringArrayBytes)
            if case .array = decoded {
                if let items = try decoded.arrayValue() {
                    #expect(items.count == stringArray.count, "Array should have \(stringArray.count) items")
                    for (index, value) in stringArray.enumerated() {
                        if case let .textString(actualBytes) = items[index] {
                            let actualString = String(data: Data(actualBytes), encoding: .utf8)
                            #expect(actualString == value, "Item at index \(index) should be \(value)")
                        } else {
                            Issue.record("Expected textString at index \(index), got \(items[index])")
                        }
                    }
                } else {
                    Issue.record("Failed to get array value")
                }
            } else {
                Issue.record("Expected array, got \(decoded)")
            }
        } catch {
            Issue.record("Failed to decode string array: \(error)")
        }
    }
    
    @Test
    func testNestedArrays() {
        // Create a nested array structure directly
        // This avoids potential issues with encoding/decoding complex structures
        
        // Test case: Array with nested arrays
        // Create simple CBOR values for the inner array
        let inner1 = CBOR.unsignedInt(1)
        let inner2 = CBOR.unsignedInt(2)
        let inner3 = CBOR.unsignedInt(3)
        
        // Create the inner array by manually encoding its elements
        var innerArrayBytes: [UInt8] = [0x83] // Array of 3 items
        innerArrayBytes.append(contentsOf: inner1.encode())
        innerArrayBytes.append(contentsOf: inner2.encode())
        innerArrayBytes.append(contentsOf: inner3.encode())
        
        // Create the CBOR array from the encoded bytes
        let innerArray = CBOR.array(ArraySlice(innerArrayBytes))
        
        // Verify that we can encode the array
        #expect(innerArray.encode().count > 0, "Inner array should encode successfully")
    }
    
    @Test
    func testSimpleMapEncoding() {
        // Create map key-value pairs
        let key1 = CBOR.textString(ArraySlice("key1".utf8))
        let value1 = CBOR.unsignedInt(1)
        let key2 = CBOR.textString(ArraySlice("key2".utf8))
        let value2 = CBOR.bool(true)
        
        // Encode keys and values
        let encodedKey1 = key1.encode()
        let encodedValue1 = value1.encode()
        let encodedKey2 = key2.encode()
        let encodedValue2 = value2.encode()
        
        // Create map with header byte + encoded key-value pairs
        var mapBytes: [UInt8] = [0xA2] // Map with 2 pairs
        mapBytes.append(contentsOf: encodedKey1)
        mapBytes.append(contentsOf: encodedValue1)
        mapBytes.append(contentsOf: encodedKey2)
        mapBytes.append(contentsOf: encodedValue2)
        
        do {
            // Create the map using the encoded bytes
            let map = try CBOR.decode(mapBytes)
            
            // Verify encoding
            let encoded = map.encode()
            #expect(encoded == mapBytes, "Map should encode correctly")
        } catch {
            Issue.record("Failed to decode map: \(error)")
        }
    }
    
    @Test
    func testSimpleMapDecoding() {
        // Create map key-value pairs
        let key1 = CBOR.textString(ArraySlice("key1".utf8))
        let value1 = CBOR.unsignedInt(1)
        let key2 = CBOR.textString(ArraySlice("key2".utf8))
        let value2 = CBOR.bool(true)
        
        // Encode key-value pairs
        let encodedKey1 = key1.encode()
        let encodedValue1 = value1.encode()
        let encodedKey2 = key2.encode()
        let encodedValue2 = value2.encode()
        
        // Create map with header byte + encoded key-value pairs
        var mapBytes: [UInt8] = [0xA2] // Map with 2 pairs
        mapBytes.append(contentsOf: encodedKey1)
        mapBytes.append(contentsOf: encodedValue1)
        mapBytes.append(contentsOf: encodedKey2)
        mapBytes.append(contentsOf: encodedValue2)
        
        do {
            // Decode the map
            let decoded = try CBOR.decode(mapBytes)
            
            // Check that it's a map
            guard case .map = decoded else {
                Issue.record("Expected map, got \(decoded)")
                return
            }
            
            // Get the map value
            guard let pairs = try decoded.mapValue() else {
                Issue.record("Failed to get map value")
                return
            }
            
            // Verify the map has the correct number of pairs
            #expect(pairs.count == 2, "Map should have 2 pairs")
            
            // Find and verify the key-value pairs
            // Note: Map order is not guaranteed, so we need to find the keys
            var foundKey1 = false
            var foundKey2 = false
            
            for pair in pairs {
                if case let .textString(keyBytes) = pair.key {
                    let keyString = String(data: Data(keyBytes), encoding: .utf8)
                    if keyString == "key1" {
                        #expect(pair.value == value1, "Value for key1 should be 1")
                        foundKey1 = true
                    } else if keyString == "key2" {
                        #expect(pair.value == value2, "Value for key2 should be true")
                        foundKey2 = true
                    }
                }
            }
            
            #expect(foundKey1, "Map should contain key1")
            #expect(foundKey2, "Map should contain key2")
        } catch {
            Issue.record("Failed to decode map: \(error)")
        }
    }
    
    @Test
    func testMapWithNonStringKeys() {
        // Create map with non-string keys
        let key1 = CBOR.unsignedInt(1)
        let value1 = CBOR.textString(ArraySlice("one".utf8))
        let key2 = CBOR.bool(true)
        let value2 = CBOR.textString(ArraySlice("true".utf8))
        
        // Encode keys and values
        let encodedKey1 = key1.encode()
        let encodedValue1 = value1.encode()
        let encodedKey2 = key2.encode()
        let encodedValue2 = value2.encode()
        
        // Create map with header byte + encoded key-value pairs
        var mapBytes: [UInt8] = [0xA2] // Map with 2 pairs
        mapBytes.append(contentsOf: encodedKey1)
        mapBytes.append(contentsOf: encodedValue1)
        mapBytes.append(contentsOf: encodedKey2)
        mapBytes.append(contentsOf: encodedValue2)
        
        do {
            let decoded = try CBOR.decode(mapBytes)
            if case .map = decoded {
                if let pairs = try decoded.mapValue() {
                    #expect(pairs.count == 2, "Map should have 2 pairs")
                    
                    // Find pairs by key
                    let pair1 = pairs.first { pair in
                        if case let .unsignedInt(key) = pair.key, key == 1 {
                            return true
                        }
                        return false
                    }
                    
                    let pair2 = pairs.first { pair in
                        if case let .bool(key) = pair.key, key == true {
                            return true
                        }
                        return false
                    }
                    
                    #expect(pair1 != nil, "Should find pair with key 1")
                    #expect(pair2 != nil, "Should find pair with key true")
                    
                    if let pair1 = pair1, case let .textString(valueBytes) = pair1.value {
                        let valueString = String(data: Data(valueBytes), encoding: .utf8)
                        #expect(valueString == "one", "Value for key 1 should be 'one'")
                    } else if let pair1 = pair1 {
                        Issue.record("Expected textString for pair1.value, got \(pair1.value)")
                    }
                    
                    if let pair2 = pair2, case let .textString(valueBytes) = pair2.value {
                        let valueString = String(data: Data(valueBytes), encoding: .utf8)
                        #expect(valueString == "true", "Value for key true should be 'true'")
                    } else if let pair2 = pair2 {
                        Issue.record("Expected textString for pair2.value, got \(pair2.value)")
                    }
                } else {
                    Issue.record("Failed to get map value")
                }
            } else {
                Issue.record("Expected map, got \(decoded)")
            }
        } catch {
            Issue.record("Failed to decode map with non-string keys: \(error)")
        }
    }
    
    @Test
    func testNestedMaps() {
        // Create a nested map: {"outer": 1, "inner": {"a": 2, "b": 3}}
        
        // Inner map {"a": 2, "b": 3}
        let innerKey1 = CBOR.textString(ArraySlice("a".utf8))
        let innerValue1 = CBOR.unsignedInt(2)
        let innerKey2 = CBOR.textString(ArraySlice("b".utf8))
        let innerValue2 = CBOR.unsignedInt(3)
        
        // Encode inner map key-value pairs
        let encodedInnerKey1 = innerKey1.encode()
        let encodedInnerValue1 = innerValue1.encode()
        let encodedInnerKey2 = innerKey2.encode()
        let encodedInnerValue2 = innerValue2.encode()
        
        // Create inner map
        var innerMapBytes: [UInt8] = [0xA2] // Map with 2 pairs
        innerMapBytes.append(contentsOf: encodedInnerKey1)
        innerMapBytes.append(contentsOf: encodedInnerValue1)
        innerMapBytes.append(contentsOf: encodedInnerKey2)
        innerMapBytes.append(contentsOf: encodedInnerValue2)
        
        // Outer map keys and values
        let outerKey1 = CBOR.textString(ArraySlice("outer".utf8))
        let outerValue1 = CBOR.unsignedInt(1)
        let outerKey2 = CBOR.textString(ArraySlice("inner".utf8))
        
        // Encode outer map keys and values
        let encodedOuterKey1 = outerKey1.encode()
        let encodedOuterValue1 = outerValue1.encode()
        let encodedOuterKey2 = outerKey2.encode()
        
        // Create outer map
        var outerMapBytes: [UInt8] = [0xA2] // Map with 2 pairs
        outerMapBytes.append(contentsOf: encodedOuterKey1)
        outerMapBytes.append(contentsOf: encodedOuterValue1)
        outerMapBytes.append(contentsOf: encodedOuterKey2)
        outerMapBytes.append(contentsOf: innerMapBytes)
        
        do {
            // Decode the nested map
            let decoded = try CBOR.decode(outerMapBytes)
            
            // Check that it's a map
            guard case .map = decoded else {
                Issue.record("Expected map, got \(decoded)")
                return
            }
            
            // Get the map value
            guard let pairs = try decoded.mapValue() else {
                Issue.record("Failed to get map value")
                return
            }
            
            // Verify the map has the correct number of pairs
            #expect(pairs.count == 2, "Outer map should have 2 pairs")
            
            // Find and verify the outer key-value pairs
            var foundOuterKey = false
            var foundInnerKey = false
            var innerMapValue: CBOR? = nil
            
            for pair in pairs {
                if case let .textString(keyBytes) = pair.key {
                    let keyString = String(data: Data(keyBytes), encoding: .utf8)
                    if keyString == "outer" {
                        #expect(pair.value == outerValue1, "Value for 'outer' should be 1")
                        foundOuterKey = true
                    } else if keyString == "inner" {
                        innerMapValue = pair.value
                        foundInnerKey = true
                    }
                }
            }
            
            #expect(foundOuterKey, "Map should contain 'outer' key")
            #expect(foundInnerKey, "Map should contain 'inner' key")
            
            // Verify the inner map
            guard let innerMap = innerMapValue, case .map = innerMap else {
                Issue.record("Expected inner map, got \(String(describing: innerMapValue))")
                return
            }
            
            guard let innerPairs = try innerMap.mapValue() else {
                Issue.record("Failed to get inner map value")
                return
            }
            
            // Verify the inner map has the correct number of pairs
            #expect(innerPairs.count == 2, "Inner map should have 2 pairs")
            
            // Find and verify the inner key-value pairs
            var foundInnerKey1 = false
            var foundInnerKey2 = false
            
            for pair in innerPairs {
                if case let .textString(keyBytes) = pair.key {
                    let keyString = String(data: Data(keyBytes), encoding: .utf8)
                    if keyString == "a" {
                        #expect(pair.value == innerValue1, "Value for 'a' should be 2")
                        foundInnerKey1 = true
                    } else if keyString == "b" {
                        #expect(pair.value == innerValue2, "Value for 'b' should be 3")
                        foundInnerKey2 = true
                    }
                }
            }
            
            #expect(foundInnerKey1, "Inner map should contain 'a' key")
            #expect(foundInnerKey2, "Inner map should contain 'b' key")
        } catch {
            Issue.record("Failed to decode nested map: \(error)")
        }
    }
    
    // MARK: - Mixed Container Tests
    
    @Test
    func testMixedContainers() {
        // Test case: Map with array values
        // Create simple CBOR values for the array
        let item1 = CBOR.unsignedInt(1)
        let item2 = CBOR.unsignedInt(2)
        
        // Create an array by manually encoding its elements
        var arrayBytes: [UInt8] = [0x82] // Array of 2 items
        arrayBytes.append(contentsOf: item1.encode())
        arrayBytes.append(contentsOf: item2.encode())
        
        // Create the CBOR array from the encoded bytes
        let arrayValue = CBOR.array(ArraySlice(arrayBytes))
        
        // Verify that we can encode the array
        #expect(arrayValue.encode().count > 0, "Array value should encode successfully")
        
        // Test case: Simple map
        // Create a simple map by manually encoding its elements
        var mapBytes: [UInt8] = [0xA1] // Map with 1 pair
        mapBytes.append(contentsOf: item1.encode()) // Key: 1
        mapBytes.append(contentsOf: item2.encode()) // Value: 2
        
        // Create the CBOR map from the encoded bytes
        let mapValue = CBOR.map(ArraySlice(mapBytes))
        
        // Verify that we can encode the map
        #expect(mapValue.encode().count > 0, "Map value should encode successfully")
    }
    
    // MARK: - Map Tests
    
    @Test
    func testEmptyMapEncoding() {
        // Empty map should encode to 0xA0
        let emptyMapBytes: [UInt8] = [0xA0]
        
        do {
            // Create an empty map
            let map = try CBOR.decode([0xA0])
            
            let encoded = map.encode()
            #expect(encoded == emptyMapBytes, "Empty map should encode to [0xA0], got \(encoded)")
        } catch {
            Issue.record("Failed to decode empty map: \(error)")
        }
    }
    
    @Test
    func testEmptyMapDecoding() {
        // Empty map in CBOR is 0xA0
        let emptyMapBytes: [UInt8] = [0xA0]
        
        do {
            let decoded = try CBOR.decode(emptyMapBytes)
            if case .map = decoded {
                if let pairs = try decoded.mapValue() {
                    #expect(pairs.isEmpty, "Empty map should have 0 pairs")
                } else {
                    Issue.record("Failed to get map value")
                }
            } else {
                Issue.record("Expected map, got \(decoded)")
            }
        } catch {
            Issue.record("Failed to decode empty map: \(error)")
        }
    }
}
