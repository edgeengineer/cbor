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
        // Test various categories of invalid UTF-8 sequences in text strings
        // Based on RFC 8949 and RFC 3629
        
        // MARK: - Category 1: Simple invalid bytes
        // Test with simple invalid UTF-8 bytes (0xFF is never valid in UTF-8)
        let simpleInvalidUTF8: [UInt8] = [
            0x63, // Text string of length 3
            0xFF, 0xFF, 0xFF // Invalid UTF-8 bytes
        ]
        
        do {
            let _ = try CBOR.decode(simpleInvalidUTF8)
            Issue.record("Expected decoding to fail with CBORError for simple invalid UTF-8")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error) for simple invalid UTF-8")
        }
        
        // MARK: - Category 2: Overlong encodings
        // Test with overlong encodings (using more bytes than necessary)
        // Per RFC 3629, the sequence C0 80 is an overlong encoding of U+0000 (NUL)
        let overlongUTF8: [UInt8] = [
            0x62, // Text string of length 2
            0xC0, 0x80 // Overlong encoding of NUL character
        ]
        
        do {
            let _ = try CBOR.decode(overlongUTF8)
            Issue.record("Expected decoding to fail with CBORError for overlong UTF-8")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error) for overlong UTF-8")
        }
        
        // Another overlong encoding example: E0 80 80 is an overlong encoding of U+0000
        let overlongUTF8_2: [UInt8] = [
            0x63, // Text string of length 3
            0xE0, 0x80, 0x80 // 3-byte overlong encoding of NUL character
        ]
        
        do {
            let _ = try CBOR.decode(overlongUTF8_2)
            Issue.record("Expected decoding to fail with CBORError for 3-byte overlong UTF-8")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error) for 3-byte overlong UTF-8")
        }
        
        // MARK: - Category 3: Surrogate code points
        // Test with surrogate code points (U+D800 to U+DFFF)
        // These are reserved for UTF-16 and invalid in UTF-8
        // ED A0 80 is the UTF-8 encoding of U+D800 (first surrogate code point)
        let surrogateUTF8: [UInt8] = [
            0x63, // Text string of length 3
            0xED, 0xA0, 0x80 // UTF-8 encoding of U+D800 (surrogate)
        ]
        
        do {
            let _ = try CBOR.decode(surrogateUTF8)
            Issue.record("Expected decoding to fail with CBORError for surrogate code point")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error) for surrogate code point")
        }
        
        // ED B0 80 is the UTF-8 encoding of U+DC00 (low surrogate)
        let lowSurrogateUTF8: [UInt8] = [
            0x63, // Text string of length 3
            0xED, 0xB0, 0x80 // UTF-8 encoding of U+DC00 (low surrogate)
        ]
        
        do {
            let _ = try CBOR.decode(lowSurrogateUTF8)
            Issue.record("Expected decoding to fail with CBORError for low surrogate code point")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error) for low surrogate code point")
        }
        
        // MARK: - Category 4: Incomplete sequences
        // Test with incomplete UTF-8 sequences
        let incompleteUTF8: [UInt8] = [
            0x62, // Text string of length 2
            0xE2, 0x82 // Incomplete 3-byte sequence (missing third byte)
        ]
        
        do {
            let _ = try CBOR.decode(incompleteUTF8)
            Issue.record("Expected decoding to fail with CBORError for incomplete UTF-8 sequence")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error) for incomplete UTF-8 sequence")
        }
        
        // MARK: - Category 5: Invalid continuation bytes
        // Test with invalid continuation bytes
        let invalidContinuationUTF8: [UInt8] = [
            0x63, // Text string of length 3
            0xE2, 0x28, 0x82 // Second byte is not a valid continuation byte (should be 0x80-0xBF)
        ]
        
        do {
            let _ = try CBOR.decode(invalidContinuationUTF8)
            Issue.record("Expected decoding to fail with CBORError for invalid continuation byte")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error) for invalid continuation byte")
        }
        
        // MARK: - Category 6: Code points beyond U+10FFFF
        // Test with code points beyond U+10FFFF (the highest valid Unicode code point)
        // F5 80 80 80 would encode a code point beyond U+10FFFF
        let beyondMaxUTF8: [UInt8] = [
            0x64, // Text string of length 4
            0xF5, 0x80, 0x80, 0x80 // Encoding a code point beyond U+10FFFF
        ]
        
        do {
            let _ = try CBOR.decode(beyondMaxUTF8)
            Issue.record("Expected decoding to fail with CBORError for code point beyond U+10FFFF")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error) for code point beyond U+10FFFF")
        }
        
        // MARK: - Category 7: Mixed valid and invalid sequences
        // Test with a mix of valid and invalid UTF-8 sequences
        let mixedUTF8: [UInt8] = [
            0x65, // Text string of length 5
            0x41, // Valid ASCII 'A'
            0xC2, 0xA9, // Valid UTF-8 for copyright symbol 
            0xED, 0xA0 // Invalid surrogate (incomplete)
        ]
        
        do {
            let _ = try CBOR.decode(mixedUTF8)
            Issue.record("Expected decoding to fail with CBORError for mixed valid/invalid UTF-8")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error) for mixed valid/invalid UTF-8")
        }
        
        // MARK: - Category 8: Unexpected continuation bytes
        // Test with unexpected continuation bytes
        let unexpectedContinuationUTF8: [UInt8] = [
            0x63, // Text string of length 3
            0x41, // Valid ASCII 'A'
            0x80, 0x80 // Unexpected continuation bytes without a leading byte
        ]
        
        do {
            let _ = try CBOR.decode(unexpectedContinuationUTF8)
            Issue.record("Expected decoding to fail with CBORError for unexpected continuation bytes")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error) for unexpected continuation bytes")
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
    
    // MARK: - Additional Error Tests
    
    @Test
    func testInvalidAdditionalInfoError() {
        // Test invalid additional info for specific major types
        
        // Invalid additional info for Major Type 7 (simple values/floats)
        // Note: This test uses a value that should be invalid according to the CBOR spec
        // but the implementation might be handling it differently
        let invalidSimpleValue: [UInt8] = [
            0xF8, // Simple value with 1-byte additional info
            0xFF  // Invalid simple value (outside valid range)
        ]
        
        // We'll check if the implementation either throws an error or returns a value
        // that we can verify is correctly interpreted
        do {
            let decoded = try CBOR.decode(invalidSimpleValue)
            // If it doesn't throw, we should at least verify it's a simple value
            if case .simple(let value) = decoded {
                #expect(value == 0xFF, "Expected simple value 0xFF, got \(value)")
            } else {
                Issue.record("Expected simple value, got \(decoded)")
            }
        } catch {
            // An error is also acceptable since this is technically invalid CBOR
            // No need to record an issue
        }
        
        // Invalid additional info for Major Type 0 (unsigned int)
        let invalidUnsignedIntAdditionalInfo: [UInt8] = [
            0x1F  // Unsigned int with invalid additional info 31 (reserved for indefinite length)
        ]
        
        do {
            let _ = try CBOR.decode(invalidUnsignedIntAdditionalInfo)
            Issue.record("Expected decoding to fail with CBORError for invalid unsigned int additional info")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error)")
        }
    }
    
    @Test
    func testUnexpectedBreak() {
        // Test unexpected break code (0xFF) outside of indefinite length context
        let unexpectedBreak: [UInt8] = [
            0xFF  // Break code outside of indefinite length context
        ]
        
        do {
            let _ = try CBOR.decode(unexpectedBreak)
            Issue.record("Expected decoding to fail with CBORError for unexpected break code")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error)")
        }
        
        // Test unexpected break in the middle of an array
        let unexpectedBreakInArray: [UInt8] = [
            0x82,  // Array of 2 items
            0x01,  // First item
            0xFF,  // Unexpected break
            0x02   // Second item (should never be reached)
        ]
        
        do {
            let _ = try CBOR.decode(unexpectedBreakInArray)
            Issue.record("Expected decoding to fail with CBORError for unexpected break in array")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error)")
        }
    }
    
    @Test
    func testMissingKeyError() {
        // Test decoding a struct with a required key that's missing using CBORDecoder
        struct RequiredKeyStruct: Decodable {
            let requiredKey: String
            let optionalKey: Int?
        }
        
        // Create a CBOR map with only the optional key
        let mapPairs: [CBORMapPair] = [
            CBORMapPair(key: .textString("optionalKey"), value: .unsignedInt(42))
        ]
        let encoded = CBOR.map(mapPairs).encode()
        
        // Try to decode it (should fail with key not found)
        let decoder = CBORDecoder()
        do {
            let _ = try decoder.decode(RequiredKeyStruct.self, from: Data(encoded))
            Issue.record("Expected decoding to fail with DecodingError.keyNotFound")
        } catch let error as DecodingError {
            switch error {
            case .keyNotFound:
                // This is the expected error
                break
            default:
                Issue.record("Expected DecodingError.keyNotFound but got \(error)")
            }
        } catch {
            Issue.record("Expected DecodingError but got \(error)")
        }
    }
    
    @Test
    func testLengthTooLargeError() {
        // Test string with length that exceeds available memory
        let lengthTooLarge: [UInt8] = [
            0x5B,  // Byte string with 8-byte length
            0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF  // Length of UInt64.max (way too large)
        ]
        
        do {
            let _ = try CBOR.decode(lengthTooLarge)
            Issue.record("Expected decoding to fail with CBORError for length too large")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error)")
        }
        
        // Test array with length that exceeds available memory
        let arrayTooLarge: [UInt8] = [
            0x9B,  // Array with 8-byte length
            0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF  // Length of UInt64.max (way too large)
        ]
        
        do {
            let _ = try CBOR.decode(arrayTooLarge)
            Issue.record("Expected decoding to fail with CBORError for array length too large")
        } catch is CBORError {
            // This is the expected error
        } catch {
            Issue.record("Expected CBORError but got \(error)")
        }
    }
    
    @Test
    func testValueConversionError() {
        // Test converting between incompatible CBOR types
        
        // Try to convert a CBOR array to a string
        let array = CBOR.array([CBOR.unsignedInt(1), CBOR.unsignedInt(2)])
        
        // Check if we can extract a string from an array (should not be possible)
        if case .textString = array {
            Issue.record("CBOR array should not match textString pattern")
        }
        
        // Try to convert a CBOR map to an integer
        let mapPairs: [CBORMapPair] = [
            CBORMapPair(key: .textString("key"), value: .unsignedInt(42))
        ]
        let map = CBOR.map(mapPairs)
        
        // Check if we can extract an int from a map (should not be possible)
        if case .unsignedInt = map {
            Issue.record("CBOR map should not match unsignedInt pattern")
        }
        
        // Try to decode a string as an int
        let stringCBOR = CBOR.textString("not an integer")
        let encoded = stringCBOR.encode()
        
        let decoder = CBORDecoder()
        do {
            let _ = try decoder.decode(Int.self, from: Data(encoded))
            Issue.record("Expected decoding a string as Int to fail")
        } catch is DecodingError {
            // This is the expected error
        } catch {
            Issue.record("Expected DecodingError but got \(error)")
        }
    }
}
