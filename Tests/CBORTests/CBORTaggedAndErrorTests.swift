import Testing
@testable import CBOR
import Foundation

@Suite("CBOR Tagged and Error Tests")
struct CBORTaggedAndErrorTests {
    
    // MARK: - Tagged Value Tests
    
    @Test
    func testTaggedValueEncoding() {
        // Test tagged value encoding directly without round-trip testing
        
        // Simple tagged value: tag 1 (epoch timestamp) with value 1000
        let timestamp = CBOR.unsignedInt(1000)
        let taggedTimestamp = CBOR.tagged(1, ArraySlice(timestamp.encode()))
        
        // Verify encoding produces a non-empty result
        let encoded = taggedTimestamp.encode()
        #expect(encoded.count > 0, "Tagged value should encode successfully")
        
        // Verify the first byte is correct (major type 6, value 1)
        #expect(encoded[0] == 0xC1, "First byte should be 0xC1 for tag 1")
    }
    
    @Test
    func testTaggedValueDecoding() {
        // Create a simple tagged value manually
        // Tag 1 (epoch timestamp) with a simple integer value
        let taggedBytes: [UInt8] = [0xC1, 0x01] // Tag 1 with value 1
        
        do {
            // Try to decode the tagged value
            let decoded = try CBOR.decode(taggedBytes)
            
            // Verify it's a tagged value
            if case .tagged = decoded {
                #expect(Bool(true), "Successfully decoded a tagged value")
            } else {
                Issue.record("Expected a tagged value, got \(decoded)")
            }
        } catch {
            Issue.record("Failed to decode tagged value: \(error)")
        }
    }
    
    @Test
    func testTaggedValueMethod() {
        // Test the taggedValue() method
        
        // Create a tagged value
        let tag: UInt64 = 1 // Standard timestamp tag
        let innerValue = CBOR.textString(ArraySlice("2023-01-01T00:00:00Z".utf8))
        let innerEncoded = innerValue.encode()
        
        // Create tagged value bytes
        var taggedBytes: [UInt8] = [0xC1] // Tag 1
        taggedBytes.append(contentsOf: innerEncoded)
        
        do {
            let decoded = try CBOR.decode(taggedBytes)
            if let (decodedTag, decodedValue) = try decoded.taggedValue() {
                #expect(decodedTag == tag, "Tag should be \(tag), got \(decodedTag)")
                #expect(decodedValue == innerValue, "Value should be \(innerValue), got \(decodedValue)")
            } else {
                Issue.record("taggedValue() returned nil")
            }
        } catch {
            Issue.record("Failed to decode or get tagged value: \(error)")
        }
    }
    
    @Test
    func testNestedTags() {
        // Create a nested tagged value: tag 1 containing tag 0 containing a date string
        let innerValue = CBOR.textString(ArraySlice("2023-01-01T00:00:00Z".utf8))
        let innerTag: UInt64 = 0 // RFC 3339 date string
        let outerTag: UInt64 = 1 // Epoch timestamp
        
        // Create the inner tagged value
        let innerTagged = CBOR.tagged(innerTag, ArraySlice(innerValue.encode()))
        
        // Create the outer tagged value
        let outerTagged = CBOR.tagged(outerTag, ArraySlice(innerTagged.encode()))
        
        // Encode the nested tagged value
        let encodedNested = outerTagged.encode()
        
        do {
            // Decode the nested tagged value
            let decoded = try CBOR.decode(encodedNested)
            
            // Verify it's a tagged value
            guard case let .tagged(decodedOuterTag, outerBytes) = decoded else {
                Issue.record("Expected outer tagged value, got \(decoded)")
                return
            }
            
            // Verify the outer tag
            #expect(decodedOuterTag == outerTag, "Outer tag should be \(outerTag), got \(decodedOuterTag)")
            
            // Decode the inner tagged value
            let innerDecoded = try CBOR.decode(Array(outerBytes))
            
            // Verify it's a tagged value
            guard case let .tagged(decodedInnerTag, innerBytes) = innerDecoded else {
                Issue.record("Expected inner tagged value, got \(innerDecoded)")
                return
            }
            
            // Verify the inner tag
            #expect(decodedInnerTag == innerTag, "Inner tag should be \(innerTag), got \(decodedInnerTag)")
            
            // Decode the inner value
            let valueDecoded = try CBOR.decode(Array(innerBytes))
            
            // Verify the inner value
            #expect(valueDecoded == innerValue, "Inner value should be \(innerValue), got \(valueDecoded)")
        } catch {
            Issue.record("Failed to decode nested tags: \(error)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Test
    func testInvalidCBOR() {
        // Test invalid CBOR data
        let invalidBytes: [[UInt8]] = [
            [0xFF], // Invalid initial byte
            [0x1F], // Invalid additional information for unsigned integer
            [0x3F]  // Invalid additional information for text string
        ]
        
        for bytes in invalidBytes {
            do {
                let _ = try CBOR.decode(bytes)
                Issue.record("Expected to throw for invalid CBOR \(bytes)")
            } catch {
                // Expected to throw
                #expect(Bool(true), "Should throw for invalid CBOR")
            }
        }
    }
    
    @Test
    func testPrematureEnd() {
        // Test CBOR data that ends prematurely
        let prematureBytes: [[UInt8]] = [
            [0x18], // Unsigned integer with 1-byte value, but no value byte
            [0x19, 0x01], // Unsigned integer with 2-byte value, but only 1 value byte
            [0x42, 0x01] // Byte string of length 2, but only 1 data byte
        ]
        
        for bytes in prematureBytes {
            do {
                let _ = try CBOR.decode(bytes)
                Issue.record("Expected to throw for premature end \(bytes)")
            } catch {
                // Expected to throw
                #expect(Bool(true), "Should throw for premature end")
            }
        }
    }
    
    @Test
    func testExtraData() {
        // Test extra data after a valid CBOR value
        let extraData: [[UInt8]] = [
            [0x01, 0x02], // Valid unsigned int 1, followed by extra byte
            [0x61, 0x61, 0x02], // Valid text string "a", followed by extra byte
            [0x80, 0x02], // Valid empty array, followed by extra byte
            [0xA0, 0x02], // Valid empty map, followed by extra byte
            [0xF4, 0x02], // Valid false, followed by extra byte
            [0xF5, 0x02], // Valid true, followed by extra byte
            [0xF6, 0x02], // Valid null, followed by extra byte
            [0xF7, 0x02] // Valid undefined, followed by extra byte
        ]
        
        for data in extraData {
            do {
                let _ = try CBOR.decode(data)
                Issue.record("Expected to throw for data with extra bytes \(data)")
            } catch let error {
                // Check if the error is related to extra data
                #expect(error.description.contains("extra") || error.description.contains("Extra"), 
                       "Error should mention extra data, got: \(error.description)")
            }
        }
    }
    
    @Test
    func testInvalidUTF8() {
        // Test invalid UTF-8 in text strings
        let invalidUTF8: [[UInt8]] = [
            [0x62, 0xC3, 0x28], // Invalid UTF-8 sequence
            [0x62, 0xA0, 0xA1], // Invalid UTF-8 sequence
            [0x62, 0xF0, 0x28, 0x8C], // Invalid UTF-8 sequence
            [0x62, 0xF8, 0xA1, 0xA1, 0xA1], // Invalid UTF-8 sequence (5-byte UTF-8)
            [0x62, 0xFC, 0xA1, 0xA1, 0xA1, 0xA1] // Invalid UTF-8 sequence (6-byte UTF-8)
        ]
        
        for data in invalidUTF8 {
            do {
                let decoded = try CBOR.decode(data)
                
                // If we get here, we need to check if it's a text string and try to convert it to a String
                if case let .textString(bytes) = decoded {
                    // Try to convert to a String - this should fail for invalid UTF-8
                    do {
                        let _ = try CBORDecoder.bytesToString(bytes)
                        Issue.record("Expected to throw for invalid UTF-8 \(data)")
                    } catch {
                        // This is expected - the conversion to String should fail
                        #expect(Bool(true), "Successfully caught invalid UTF-8 during string conversion")
                    }
                } else {
                    // If it's not a text string, that's unexpected
                    Issue.record("Expected textString, got \(decoded)")
                }
            } catch {
                // Any error is acceptable here - either during decoding or during string conversion
                #expect(Bool(true), "Successfully caught error: \(error)")
            }
        }
    }
}
