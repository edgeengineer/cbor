import Testing
#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif
@testable import CBOR

struct CBORErrorTests {
    // MARK: - Decoding Error Tests
    
    @Test
    func testInvalidCBORData() {
        // Test completely invalid data
        let invalidData: [UInt8] = [0xFF, 0xFF, 0xFF]
        do {
            let _ = try CBOR.decode(invalidData)
            Issue.record("Expected decoding to fail with CBORError")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error)")
        }
    }
    
    @Test
    func testPrematureEndError() {
        // Test data that ends prematurely
        let incompleteData: [UInt8] = [
            0x82, // Array of 2 items
            0x01  // Only 1 item provided
        ]
        
        do {
            let _ = try CBOR.decode(incompleteData)
            Issue.record("Expected decoding to fail with CBORError")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error)")
        }
    }
    
    @Test
    func testExtraDataError() {
        // Test data with extra bytes after valid CBOR
        let dataWithExtra: [UInt8] = [
            0x01, // Valid CBOR (unsigned int 1)
            0x02  // Extra byte
        ]
        
        do {
            let _ = try CBOR.decode(dataWithExtra)
            Issue.record("Expected decoding to fail with CBORError")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error)")
        }
    }
    
    @Test
    func testInvalidUTF8Error() {
        // Test invalid UTF-8 in text string
        let invalidUTF8: [UInt8] = [
            0x63, // Text string of length 3
            0xFF, 0xFF, 0xFF // Invalid UTF-8 bytes
        ]
        
        do {
            let _ = try CBOR.decode(invalidUTF8)
            Issue.record("Expected decoding to fail with CBORError")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error)")
        }
    }
    
    @Test
    func testIntegerOverflowError() {
        // Create a CBOR unsigned int that's too large for Int
        // No encoder needed for this test
        let maxUInt64 = UInt64.max
        let cbor = CBOR.unsignedInt(maxUInt64)
        let encoded = cbor.encode()
        
        // Try to decode it as Int (should fail with overflow)
        let decoder = CBORDecoder()
        do {
            let _ = try decoder.decode(Int.self, from: Data(encoded))
            Issue.record("Expected decoding to fail with DecodingError")
        } catch is DecodingError {
            // This is the expected error
        } catch {
            Issue.record("Expected DecodingError but got \(error)")
        }
    }
    
    @Test
    func testTypeMismatchError() {
        // Create a CBOR string
        let cbor = CBOR.textString("test")
        let encoded = cbor.encode()
        
        // Try to decode it as Int (should fail with type mismatch)
        let decoder = CBORDecoder()
        do {
            let _ = try decoder.decode(Int.self, from: Data(encoded))
            Issue.record("Expected decoding to fail with DecodingError")
        } catch is DecodingError {
            // This is the expected error
        } catch {
            Issue.record("Expected DecodingError but got \(error)")
        }
    }
    
    @Test
    func testDecodingErrors() throws {
        // Test decoding a struct with a required key that's missing
        struct RequiredKeyStruct: Decodable {
            let requiredKey: String
        }
        
        // Create a CBOR map without the required key
        let encoded = CBOR.map([]).encode()
        
        // Try to decode it (should fail with key not found)
        let decoder = CBORDecoder()
        do {
            let _ = try decoder.decode(RequiredKeyStruct.self, from: Data(encoded))
            Issue.record("Expected decoding to fail with DecodingError")
        } catch is DecodingError {
            // This is the expected error
        } catch {
            Issue.record("Expected DecodingError but got \(error)")
        }
    }
    
    @Test
    func testValueConversionFailedError() throws {
        // Test decoding an invalid URL
        let cbor = CBOR.textString("not a valid url with spaces and special chars: %%^&")
        let encoded = cbor.encode()
        
        // Try to decode it as URL (should fail with data corrupted)
        let decoder = CBORDecoder()
        do {
            let _ = try decoder.decode(URL.self, from: Data(encoded))
            Issue.record("Expected decoding to fail with DecodingError")
        } catch is DecodingError {
            // This is the expected error
        } catch {
            Issue.record("Expected DecodingError but got \(error)")
        }
    }
    
    @Test
    func testInvalidCBORError() throws {
        // Test decoding invalid CBOR data
        let incompleteData: [UInt8] = [
            0x82, // Array of length 2
            0x01, // First element (1)
            // Missing second element
        ]
        
        do {
            let _ = try CBOR.decode(incompleteData)
            Issue.record("Expected decoding to fail with CBORError")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error)")
        }
        
        // Test decoding CBOR with extra data
        let dataWithExtra: [UInt8] = [
            0x01, // Single value (1)
            0x02, // Extra data
        ]
        
        do {
            let _ = try CBOR.decode(dataWithExtra)
            Issue.record("Expected decoding to fail with CBORError")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error)")
        }
    }
    
    // MARK: - CBORError Description Tests
    
    @Test
    func testCBORErrorDescriptions() {
        // Test that all CBORError cases have meaningful descriptions
        let errors: [CBORError] = [
            .invalidCBOR,
            .typeMismatch(expected: "String", actual: "Int"),
            .outOfBounds(index: 5, count: 3),
            .missingKey("requiredKey"),
            .valueConversionFailed("Could not convert to Int"),
            .invalidUTF8,
            .integerOverflow,
            .unsupportedTag(123),
            .prematureEnd,
            .invalidInitialByte(0xFF),
            .lengthTooLarge(UInt64.max),
            .indefiniteLengthNotSupported,
            .extraDataFound
        ]
        
        for error in errors {
            let description = error.description
            #expect(!description.isEmpty, "Description for \(error) is empty")
            #expect(description != "Unknown error", "Description for \(error) is generic")
        }
    }
    
    // MARK: - Encoder Error Tests
    
    @Test
    func testEncodingErrors() throws {
        // Test encoding a value that can't be encoded
        struct Unencodable: Encodable {
            let value: Any
            
            func encode(to encoder: Encoder) throws {
                // This will fail because we can't encode Any
                // Using underscore to avoid unused variable warning
                let _ = encoder.singleValueContainer()
                // This line would cause a compiler error, so we throw manually
                throw EncodingError.invalidValue(value, EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Cannot encode value of type Any"
                ))
            }
        }
        
        let unencodable = Unencodable(value: ["key": Date()])
        let encoder = CBOREncoder()
        
        do {
            let _ = try encoder.encode(unencodable)
            Issue.record("Expected encoding to fail with EncodingError")
        } catch is EncodingError {
            // This is the expected error
        } catch {
            Issue.record("Expected EncodingError but got \(error)")
        }
    }
    
    // MARK: - Reader Error Tests
    
    @Test
    func testCBORReaderErrors() throws {
        // Test reading beyond the end of the data
        var shortReader = CBORReader(data: [0x01])
        
        // First read should succeed
        let byte = try shortReader.readByte()
        #expect(byte == 0x01, "Byte read is not 0x01")
        
        do {
            let _ = try shortReader.readByte() // This should fail (no more data)
            Issue.record("Expected reading to fail with CBORError")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error)")
        }
        
        // Test reading multiple bytes
        var multiByteReader = CBORReader(data: [0x01, 0x02, 0x03])
        do {
            let byte1 = try multiByteReader.readByte()
            let byte2 = try multiByteReader.readByte()
            let byte3 = try multiByteReader.readByte()
            
            #expect(byte1 == 0x01, "Byte 1 read is not 0x01")
            #expect(byte2 == 0x02, "Byte 2 read is not 0x02")
            #expect(byte3 == 0x03, "Byte 3 read is not 0x03")
            
            do {
                let _ = try multiByteReader.readByte() // Should fail after reading all bytes
                Issue.record("Expected reading to fail with CBORError")
            } catch is CBORError {
                // This is the expected error
            } catch {
                Issue.record("Expected CBORError but got \(error)")
            }
        } catch {
            Issue.record("Failed to read bytes: \(error)")
        }
    }
    
    // MARK: - Nested Error Tests
    
    @Test
    func testNestedErrors() {
        // Test errors in nested structures
        
        // Array with invalid item
        let invalidArrayItem: [UInt8] = [
            0x81, // Array of 1 item
            0x7F  // Invalid indefinite length string (not properly terminated)
        ]
        
        do {
            let _ = try CBOR.decode(invalidArrayItem)
            Issue.record("Expected decoding to fail with CBORError")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error)")
        }
        
        // Map with invalid value
        let invalidMapValue: [UInt8] = [
            0xA1, // Map with 1 pair
            0x01, // Key: 1
            0x7F  // Invalid indefinite length string (not properly terminated)
        ]
        
        do {
            let _ = try CBOR.decode(invalidMapValue)
            Issue.record("Expected decoding to fail with CBORError")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error)")
        }
    }
}
