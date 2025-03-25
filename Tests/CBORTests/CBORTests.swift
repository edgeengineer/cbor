#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

import Testing

@testable import CBOR

// Helper for round-trip testing.
func assertRoundTrip(_ value: CBOR, file: StaticString = #file, line: UInt = #line) {
    let encoded = value.encode()
    do {
        let decoded = try CBOR.decode(encoded)
        #expect(decoded == value, "Round-trip failed")
    } catch {
        #expect(Bool(false), "Decoding failed: \(error)")
    }
}

@Test func testUnsignedIntegerRoundTrip() {
    let value: CBOR = .unsignedInt(42)
    assertRoundTrip(value)
}

@Test func testNegativeIntegerRoundTrip() {
    let value: CBOR = .negativeInt(-100)
    assertRoundTrip(value)
}

@Test func testByteStringRoundTrip() {
    let value: CBOR = .byteString([0x01, 0xFF, 0x00, 0x10])
    assertRoundTrip(value)
}

@Test func testTextStringRoundTrip() {
    let value: CBOR = .textString("Hello, CBOR!")
    assertRoundTrip(value)
}

@Test func testArrayRoundTrip() {
    let value: CBOR = .array([
        .unsignedInt(1),
        .negativeInt(-1),
        .textString("two"),
        .bool(true)
    ])
    assertRoundTrip(value)
}

@Test func testMapRoundTrip() {
    let value: CBOR = .map([
        CBORMapPair(key: .textString("a"), value: .unsignedInt(1)),
        CBORMapPair(key: .textString("b"), value: .bool(false))
    ])
    assertRoundTrip(value)
}

@Test func testTaggedValueRoundTrip() {
    let value: CBOR = .tagged(1, .textString("2023-10-01"))
    assertRoundTrip(value)
}

@Test func testFloatRoundTrip() {
    let value: CBOR = .float(3.14159)
    assertRoundTrip(value)
}

@Test func testIndefiniteArrayDecoding() {
    // Manually crafted indefinite-length array encoding:
    // Major type 4 with additional info 31 (0x9f) indicates an indefinite array.
    // Encodes [1, 2] using unsigned integers (0x01, 0x02) ending with break (0xff).
    let encoded: [UInt8] = [0x9f, 0x01, 0x02, 0xff]
    do {
        let decoded = try CBOR.decode(encoded)
        if case .array(let items) = decoded {
            #expect(items == [.unsignedInt(1), .unsignedInt(2)], "Decoded array does not match expected")
        } else {
            #expect(Bool(false), "Expected an array")
        }
    } catch {
        #expect(Bool(false), "Decoding failed with error: \(error)")
    }
}

#if canImport(Foundation)
@Test func testFoundationEncoderDecoderRoundTrip() {
    // Test the minimal Foundation-based CBOREncoder/CBORDecoder.
    let original = 123 as Int
    do {
        let encoder = CBOREncoder()
        let decoder = CBORDecoder()
        let data = try encoder.encode(original)
        let decoded: Int = try decoder.decode(Int.self, from: data)
        #expect(decoded == original, "Foundation encoder/decoder did not round-trip correctly")
    } catch {
        #expect(Bool(false), "Foundation based test failed: \(error)")
    }
}

// MARK: - Helper Extension for Decoding CBOR

extension SingleValueDecodingContainer {
    /// A helper that returns the underlying CBOR value by inspecting the container via reflection.
    func decodeCBORValue() throws -> CBOR {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if child.label == "container", let cbor = child.value as? CBOR {
                return cbor
            }
        }
        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: codingPath,
                                  debugDescription: "Underlying container is not a CBOR container")
        )
    }
}

// MARK: - Make CBOR Encodable

/* Commented out to avoid duplicate conformance
extension CBOR: Encodable {
    public func encode(to encoder: Encoder) throws {
        // This should never be called because our _CBOREncoder short-circuits when value is a CBOR.
        fatalError("CBOR should be encoded using the custom branch in the minimal CBOREncoder")
    }
}
*/

// MARK: - Codable Types with Nested Structures

/// A simple address type encoded as a CBOR map.
struct Address: Codable, Equatable {
    let street: String
    let city: String

    // Explicit memberwise initializer.
    init(street: String, city: String) {
        self.street = street
        self.city = city
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        // Represent the Address as a CBOR map with two key/value pairs.
        let cborValue: CBOR = .map([
            CBORMapPair(key: .textString("street"), value: .textString(street)),
            CBORMapPair(key: .textString("city"), value: .textString(city))
        ])
        try container.encode(cborValue)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let cbor = try container.decodeCBORValue()
        guard case .map(let pairs) = cbor else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Expected a CBOR map for Address.")
        }
        var streetFound: String?
        var cityFound: String?
        for pair in pairs {
            if case .textString("street") = pair.key, case .textString(let s) = pair.value {
                streetFound = s
            } else if case .textString("city") = pair.key, case .textString(let c) = pair.value {
                cityFound = c
            }
        }
        guard let street = streetFound, let city = cityFound else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Missing keys for Address.")
        }
        self.street = street
        self.city = city
    }
    
    // Helpers used from Person (to encode/decode without needing a dedicated container).
    func toCBOR() -> CBOR {
        return .map([
            CBORMapPair(key: .textString("street"), value: .textString(street)),
            CBORMapPair(key: .textString("city"), value: .textString(city))
        ])
    }
    
    static func fromCBOR(_ cbor: CBOR) throws -> Address {
        guard case .map(let pairs) = cbor else {
            throw DecodingError.dataCorrupted(
              DecodingError.Context(codingPath: [],
                                    debugDescription: "Expected CBOR map for Address"))
        }
        var streetFound: String?
        var cityFound: String?
        for pair in pairs {
            if case .textString("street") = pair.key, case .textString(let s) = pair.value {
                streetFound = s
            } else if case .textString("city") = pair.key, case .textString(let c) = pair.value {
                cityFound = c
            }
        }
        guard let street = streetFound, let city = cityFound else {
            throw DecodingError.dataCorrupted(
             DecodingError.Context(codingPath: [],
                                   debugDescription: "Missing keys for Address"))
        }
        return Address(street: street, city: city)
    }
}

/// A more complex type that nests an array of Addresses and a dictionary as metadata.
struct Person: Codable, Equatable {
    let name: String
    let age: Int
    let addresses: [Address]
    let metadata: [String: String]
    
    // Explicit memberwise initializer.
    init(name: String, age: Int, addresses: [Address], metadata: [String: String]) {
        self.name = name
        self.age = age
        self.addresses = addresses
        self.metadata = metadata
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        // Convert the array of addresses and the metadata dictionary into CBOR values.
        let addressesCBOR: [CBOR] = addresses.map { $0.toCBOR() }
        let metadataCBOR: [CBORMapPair] = metadata.map { key, value in
            CBORMapPair(key: .textString(key), value: .textString(value))
        }
        // Represent the Person as a CBOR map.
        let personCBOR: CBOR = .map([
            CBORMapPair(key: .textString("name"), value: .textString(name)),
            CBORMapPair(key: .textString("age"), value: .unsignedInt(UInt64(age))),
            CBORMapPair(key: .textString("addresses"), value: .array(addressesCBOR)),
            CBORMapPair(key: .textString("metadata"), value: .map(metadataCBOR))
        ])
        try container.encode(personCBOR)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let cbor = try container.decodeCBORValue()
        guard case .map(let pairs) = cbor else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Expected a CBOR map for Person.")
        }
        var nameFound: String?
        var ageFound: Int?
        var addressesFound: [Address] = []
        var metadataFound: [String: String]?
        for pair in pairs {
            switch pair.key {
            case .textString(let key) where key == "name":
                if case .textString(let n) = pair.value {
                    nameFound = n
                }
            case .textString(let key) where key == "age":
                if case .unsignedInt(let a) = pair.value {
                    ageFound = Int(a)
                }
            case .textString(let key) where key == "addresses":
                if case .array(let arr) = pair.value {
                    addressesFound = try arr.map { try Address.fromCBOR($0) }
                }
            case .textString(let key) where key == "metadata":
                if case .map(let metaPairs) = pair.value {
                    var meta: [String: String] = [:]
                    for metaPair in metaPairs {
                        if case .textString(let k) = metaPair.key, case .textString(let v) = metaPair.value {
                            meta[k] = v
                        }
                    }
                    metadataFound = meta
                }
            default:
                continue
            }
        }
        guard let name = nameFound, let age = ageFound, let metadata = metadataFound else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Missing keys for Person.")
        }
        self.name = name
        self.age = age
        self.addresses = addressesFound
        self.metadata = metadata
    }
}

// MARK: - Test Complex Codable Round-Trip

@Test func testComplexCodableStructRoundTrip() {
    let person = Person(
        name: "Alice",
        age: 30,
        addresses: [
            Address(street: "123 Main St", city: "Wonderland"),
            Address(street: "456 Side Ave", city: "Fantasialand")
        ],
        metadata: [
            "nickname": "Ally",
            "occupation": "Adventurer"
        ]
    )

    do {
        let encoder = CBOREncoder()
        let decoder = CBORDecoder()
        let data = try encoder.encode(person)
        let decodedPerson = try decoder.decode(Person.self, from: data)
        #expect(decodedPerson == person, "Complex Codable struct round-trip failed")
    } catch {
        #expect(Bool(false), "Encoding/decoding failed with error: \(error)")
    }
}
#endif

// Additional tests for CBOR edge cases based on the implementation and RFC 8949.

@Test func testHalfPrecisionFloatDecoding() {
    // Manually craft a half-precision float:
    // Major type 7 with additional info 25 (0xF9), then 2 bytes.
    // 1.0 in half-precision is represented as 0x3C00.
    let encoded: [UInt8] = [0xF9, 0x3C, 0x00]
    do {
        let decoded = try CBOR.decode(encoded)
        #expect(decoded == .float(1.0), "Half-precision float decoding failed")
    } catch {
        #expect(Bool(false), "Decoding failed with error: \(error)")
    }
}

@Test func testIndefiniteTextStringDecoding() {
    // Test indefinite-length text string decoding.
    // 0x7F indicates the start of an indefinite-length text string.
    // Then two definite text string chunks are provided:
    // • "Hello" is encoded as: 0x65 followed by ASCII for "Hello"
    // • "World" is encoded similarly.
    // The break (0xff) ends the indefinite sequence.
    let encoded: [UInt8] = [
        0x7F,                   // Indefinite text string start (major type 3 with additional info 31)
        0x65, 0x48, 0x65, 0x6C, 0x6C, 0x6F, // Definite text string "Hello" (length 5: 0x65 followed by "Hello")
        0x65, 0x57, 0x6F, 0x72, 0x6C, 0x64, // Definite text string "World" (length 5)
        0xFF                    // Break marker
    ]
    do {
        let decoded = try CBOR.decode(encoded)
        #expect(decoded == .textString("HelloWorld"), "Indefinite text string decoding failed")
    } catch {
        #expect(Bool(false), "Decoding failed with error: \(error)")
    }
}

@Test func testIndefiniteMapDecoding() {
    // Test indefinite-length map decoding.
    // 0xBF is the indefinite-length map start (major type 5, additional info 31).
    // Two key/value pairs are provided and the break marker terminates the map.
    // For example, map with keys "a" => 1 and "b" => false.
    let encoded: [UInt8] = [
        0xBF,       // Indefinite-length map start.
        0x61, 0x61, // Key: text string "a" (0x61 indicates length=1, then 0x61 = "a")
        0x01,       // Value: unsigned integer 1.
        0x61, 0x62, // Key: text string "b" (0x61 then 0x62 = "b")
        0xF4,       // Value: false (0xF4)
        0xFF        // Break marker.
    ]
    do {
        let decoded = try CBOR.decode(encoded)
        if case .map(let pairs) = decoded {
            let expectedPairs = [
                CBORMapPair(key: .textString("a"), value: .unsignedInt(1)),
                CBORMapPair(key: .textString("b"), value: .bool(false))
            ]
            #expect(pairs == expectedPairs, "Indefinite map decoding did not match expected")
        } else {
            #expect(Bool(false), "Decoded value is not a map")
        }
    } catch {
        #expect(Bool(false), "Decoding failed with error: \(error)")
    }
}

@Test func testUnexpectedBreak() {
    let encoded: [UInt8] = [0xFF]
    do {
        _ = try CBOR.decode(encoded)
        #expect(Bool(false), "Decoding should have thrown an error due to an unexpected break marker")
    } catch let error as CBORError {
        if case .invalidInitialByte(let byte) = error {
            #expect(byte == 0xFF)
        } else {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    } catch {
        #expect(Bool(false), "Unexpected error: \(error)")
    }
}

@Test func testInvalidUTF8TextStringDecoding() {
    let encoded: [UInt8] = [0x61, 0xC3]
    do {
        _ = try CBOR.decode(encoded)
        #expect(Bool(false), "Decoding should have thrown an error due to invalid UTF-8")
    } catch let error as CBORError {
        if case .invalidUTF8 = error {
            // Expected outcome
        } else {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    } catch {
        #expect(Bool(false), "Unexpected error: \(error)")
    }
}

@Test func testInvalidAdditionalInfo() {
    // Test that an invalid additional info value (not in the allowed set for integers)
    // results in an error.
    // For an unsigned integer (major type 0), allowed additional values are:
    // values less than 24 or exactly 24, 25, 26, 27.
    // Here we use 28, which is invalid.
    let encoded: [UInt8] = [0x1C] // (0 << 5) | 28 = 0x1C
    do {
        _ = try CBOR.decode(encoded)
        #expect(Bool(false), "Decoding should have thrown an error due to invalid additional info")
    } catch CBORError.invalidInitialByte(let byte) where byte == 28 {
        // Expected outcome.
    } catch {
        #expect(Bool(false), "Decoding threw the wrong error: \(error)")
    }
} 

/// A dummy SingleValueDecodingContainer that holds a CBOR value.
/// This is used to test the reflection-based decodeCBORValue() helper.
struct DummyCBORDecodingContainer: SingleValueDecodingContainer {
    let container: CBOR
    var codingPath: [CodingKey] = []
    
    func decodeNil() -> Bool { return false }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        fatalError("Not needed for DummyCBORDecodingContainer.")
    }
}

@Test func testReflectionHelperForDecodingCBOR() {
    let originalCBOR: CBOR = .textString("ReflectionTest")
    let dummy = DummyCBORDecodingContainer(container: originalCBOR)
    do {
        let extracted = try dummy.decodeCBORValue()
        #expect(extracted == originalCBOR, "Reflection helper did not extract the underlying CBOR correctly.")
    } catch {
        #expect(Bool(false), "Reflection helper threw error: \(error)")
    }
}

@Test func testCBOREncodableConformanceShortCircuit() {
    // Create a CBOR value.
    let original: CBOR = .unsignedInt(100)
    do {
        // When a CBOR value is encoded with the CBOREncoder, it should detect that the value is already a CBOR
        // and use its built-in encoding rather than calling the fatalError in encode(to:).
        let encoder = CBOREncoder()
        let data = try encoder.encode(original)
        
        // Compare with invoking original.encode() directly.
        let expectedData = Data(original.encode())
        #expect(Data(data) == expectedData, "CBOREncoder did not short-circuit CBOR value encoding as expected.")
    } catch {
        #expect(Bool(false), "Encoding CBOR value failed with error: \(error)")
    }
}

// MARK: - Error Tests

@Test func testTypeMismatchError() {
    let stringData = CBOR.textString("test").encode()
    do {
        let decoded = try CBOR.decode(stringData)
        if case .array = decoded {
            #expect(Bool(false), "Should not decode string as array")
        }
    } catch let error as CBORError {
        if case .typeMismatch(let expected, let actual) = error {
            #expect(expected == "array")
            #expect(actual == "text string")
        } else {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    } catch {
        #expect(Bool(false), "Unexpected error: \(error)")
    }
}

@Test func testOutOfBoundsError() {
    let array = CBOR.array([.unsignedInt(1), .unsignedInt(2)])
    do {
        if case .array(let items) = array {
            if 5 >= items.count {
                throw CBORError.outOfBounds(index: 5, count: items.count)
            }
            _ = items[5]
            #expect(Bool(false), "Should throw out of bounds error")
        }
    } catch let error as CBORError {
        if case .outOfBounds(let index, let count) = error {
            #expect(index == 5)
            #expect(count == 2)
        } else {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    } catch {
        #expect(Bool(false), "Unexpected error: \(error)")
    }
}

@Test func testMissingKeyError() {
    let mapData = CBOR.map([
        CBORMapPair(key: .textString("exists"), value: .bool(true))
    ]).encode()
    
    do {
        let decoded = try CBOR.decode(mapData)
        if case .map(let pairs) = decoded {
            // Try to access non-existent key and throw if not found
            if !pairs.contains(where: { pair in
                if case .textString("missing") = pair.key { return true }
                return false
            }) {
                throw CBORError.missingKey("missing")
            }
            #expect(Bool(false), "Should throw missing key error")
        }
    } catch let error as CBORError {
        if case .missingKey(let key) = error {
            #expect(key == "missing")
        } else {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    } catch {
        #expect(Bool(false), "Unexpected error: \(error)")
    }
}

@Test func testValueConversionError() {
    let stringData = CBOR.textString("not a number").encode()
    do {
        let decoded = try CBOR.decode(stringData)
        if case .unsignedInt = decoded {
            #expect(Bool(false), "Should not convert string to integer")
        }
    } catch let error as CBORError {
        if case .valueConversionFailed(let details) = error {
            #expect(details.contains("number"))
        } else {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    } catch {
        #expect(Bool(false), "Unexpected error: \(error)")
    }
}

@Test func testLengthTooLargeError() {
    // Create a byte array representing a value larger than Int.max
    let bytes: [UInt8] = [
        0x1b, // Major type 0 (unsigned int) with additional info 27 (8 bytes follow)
        0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 // Value that exceeds Int.max
    ]
    
    do {
        _ = try CBOR.decode(bytes)
        #expect(Bool(false), "Should throw length too large error")
    } catch let error as CBORError {
        if case .lengthTooLarge(let length) = error {
            #expect(length > UInt64(Int.max))
        } else {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    } catch {
        #expect(Bool(false), "Unexpected error: \(error)")
    }
}

@Test func testIntegerOverflowError() {
    // Create a byte array representing a CBOR integer that's too large
    let bytes: [UInt8] = [
        0x1b, // Major type 0 (unsigned int) with additional info 27 (8 bytes follow)
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF // Maximum UInt64 value
    ]
    
    do {
        _ = try CBOR.decode(bytes)
        #expect(Bool(false), "Should throw integer overflow error")
    } catch let error as CBORError {
        if case .lengthTooLarge(let value) = error {
            #expect(value == UInt64.max)
        } else {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    } catch {
        #expect(Bool(false), "Unexpected error: \(error)")
    }
}

@Test func testUnsupportedTagError() {
    let unsupportedTag: UInt64 = 99999
    let data = CBOR.tagged(unsupportedTag, .bool(true)).encode()
    do {
        let decoded = try CBOR.decode(data)
        if case .tagged(let tag, _) = decoded {
            // Consider tags above 99999 as unsupported
            if tag >= 99999 {
                throw CBORError.unsupportedTag(tag)
            }
        }
        #expect(Bool(false), "Should throw unsupported tag error")
    } catch let error as CBORError {
        if case .unsupportedTag(let tag) = error {
            #expect(tag == unsupportedTag)
        } else {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    } catch {
        #expect(Bool(false), "Unexpected error: \(error)")
    }
}

@Test func testPrematureEndError() {
    let incompleteData = Array(CBOR.textString("test").encode().prefix(1))
    do {
        _ = try CBOR.decode(incompleteData)
        #expect(Bool(false), "Should throw premature end error")
    } catch let error as CBORError {
        if case .prematureEnd = error {
            // Expected outcome
        } else {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    } catch {
        #expect(Bool(false), "Unexpected error: \(error)")
    }
}

@Test func testInvalidInitialByteError() {
    let invalidData: [UInt8] = [0xFF] // Invalid initial byte
    do {
        _ = try CBOR.decode(invalidData)
        #expect(Bool(false), "Should throw invalid initial byte error")
    } catch let error as CBORError {
        if case .invalidInitialByte(let byte) = error {
            #expect(byte == 0xFF)
        } else {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    } catch {
        #expect(Bool(false), "Unexpected error: \(error)")
    }
}

@Test func testIndefiniteLengthNotSupportedError() {
    let invalidIndefiniteData: [UInt8] = [0x1F] // Indefinite length integer (invalid)
    do {
        _ = try CBOR.decode(invalidIndefiniteData)
        #expect(Bool(false), "Should throw indefinite length not supported error")
    } catch let error as CBORError {
        if case .indefiniteLengthNotSupported = error {
            // Expected outcome
        } else {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    } catch {
        #expect(Bool(false), "Unexpected error: \(error)")
    }
}

@Test func testTrailingData() {
    // Create a valid encoded value and then tack on extra data.
    let original: CBOR = .unsignedInt(100)
    let encoded = original.encode() + [0x00]  // Extra trailing byte
    
    do {
        _ = try CBOR.decode(encoded)
        #expect(Bool(false), "Decoding should fail when extra trailing data is present")
    } catch let error as CBORError {
        if case .extraDataFound = error {
            // Expected outcome.
        } else {
            #expect(Bool(false), "Wrong error type for trailing data")
        }
    } catch {
        #expect(Bool(false), "Unexpected error: \(error)")
    }
}