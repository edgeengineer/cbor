# CBOR

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20Linux%20|%20Windows%20|%20Android-blue.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
[![Build](https://github.com/apache-edge/cbor/actions/workflows/swift.yml/badge.svg)](https://github.com/apache-edge/cbor/actions/workflows/swift.yml)
[![Documentation](https://img.shields.io/badge/Documentation-DocC-blue)](https://apache-edge.github.io/cbor/documentation/cbor/)

CBOR is a lightweight implementation of the [CBOR](https://tools.ietf.org/html/rfc7049) (Concise Binary Object Representation) format in Swift. It allows you to encode and decode data to and from the CBOR format, work directly with the CBOR data model, and integrate with Swift's `Codable` protocol.

## Features

- **Direct CBOR Data Model:**  
  Represent CBOR values using an enum with cases for unsigned/negative integers, byte strings, text strings, arrays, maps (ordered key/value pairs), tagged values, simple values, booleans, null, undefined, and floats.

- **Encoding & Decoding:**  
  Easily convert between CBOR values and byte arrays.

- **Full Codable Support:**  
  Use `CBOREncoder` and `CBORDecoder` for complete support of Swift's `Codable` protocol, including:
  - Single value encoding/decoding
  - Keyed containers (for dictionaries and objects)
  - Unkeyed containers (for arrays)
  - Nested containers
  - Custom encoding/decoding
  - Sets and other collection types
  - Optionals and deeply nested optionals
  - Non-String dictionary keys

- **Error Handling:**  
  Detailed error types (`CBORError`) to help you diagnose encoding/decoding issues.

## Documentation

Comprehensive documentation is available via DocC:

- [Online Documentation](https://apache-edge.github.io/cbor/documentation/cbor/)
- Generate locally with: `swift package --allow-writing-to-directory ./docs generate-documentation --target CBOR`

## Installation

### Swift Package Manager

Add the CBOR package to your Swift package dependencies:

```swift
// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "YourProject",
    dependencies: [
        .package(url: "https://github.com/apache-edge/cbor.git", from: "0.0.2")
    ],
    targets: [
        .target(
            name: "YourTarget",
            dependencies: [
                .product(name: "CBOR", package: "cbor")
            ]
        )
    ]
)
```

## Quick Start 

### 1. Working Directly with CBOR Values

```swift
import CBOR

// Create a CBOR value (an unsigned integer)
let cborValue: CBOR = .unsignedInt(42)

// Encode the CBOR value to a byte array
let encodedBytes = cborValue.encode()
print("Encoded bytes:", encodedBytes)

// Decode the bytes back into a CBOR value
do {
    let decodedValue = try CBOR.decode(encodedBytes)
    print("Decoded CBOR value:", decodedValue)
} catch {
    print("Decoding error:", error)
}
```

### 2. Using Codable

```swift
import CBOR
import Foundation

// Define your data structures
struct Person: Codable {
    let name: String
    let age: Int
    let addresses: [Address]
    let metadata: [String: String]
}

struct Address: Codable {
    let street: String
    let city: String
}

// Create an instance
let person = Person(
    name: "Alice",
    age: 30,
    addresses: [
        Address(street: "123 Main St", city: "Wonderland"),
        Address(street: "456 Side Ave", city: "Fantasialand")
    ],
    metadata: [
        "occupation": "Engineer",
        "department": "R&D"
    ]
)

// Encode to CBOR
do {
    let encoder = CBOREncoder()
    let cborData = try encoder.encode(person)
    print("Encoded CBOR Data:", cborData as NSData)
    
    // Decode back from CBOR
    let decoder = CBORDecoder()
    let decodedPerson = try decoder.decode(Person.self, from: cborData)
    print("Decoded Person:", decodedPerson)
} catch {
    print("Error:", error)
}
```

### 3. Working with Complex CBOR Structures

```swift
// Create an array of CBOR values
let arrayCBOR: CBOR = .array([
    .unsignedInt(1),
    .textString("hello"),
    .bool(true)
])

// Create a map (ordered key/value pairs)
let mapCBOR: CBOR = .map([
    CBORMapPair(key: .textString("name"), value: .textString("SwiftCBOR")),
    CBORMapPair(key: .textString("version"), value: .unsignedInt(1))
])

// Combine them into a nested structure
let nestedCBOR: CBOR = .map([
    CBORMapPair(key: .textString("data"), value: arrayCBOR),
    CBORMapPair(key: .textString("info"), value: mapCBOR)
])
```

### 4. Error Handling

```swift
do {
    let cbor = try CBOR.decode([0xff, 0x00]) // Example invalid CBOR data
} catch let error as CBORError {
    switch error {
    case .invalidCBOR:
        print("Invalid CBOR data")
    case .typeMismatch(let expected, let actual):
        print("Type mismatch: expected \(expected), found \(actual)")
    case .prematureEnd:
        print("Unexpected end of data")
    default:
        print("Other CBOR error:", error.description)
    }
} catch {
    print("Unexpected error:", error)
}
```

### 5. Advanced Codable Examples

```swift
// Example of nested containers and arrays
struct Team: Codable {
    let name: String
    let members: [Member]
    let stats: Statistics
    let tags: Set<String>
}

struct Member: Codable {
    let id: Int
    let name: String
    let roles: [Role]
    
    enum Role: String, Codable {
        case developer
        case designer
        case manager
    }
}

struct Statistics: Codable {
    let projectsCompleted: Int
    let averageRating: Double
    let activeYears: [Int]
}

// Create and encode a team
let team = Team(
    name: "Dream Team",
    members: [
        Member(id: 1, name: "Alice", roles: [.developer, .manager]),
        Member(id: 2, name: "Bob", roles: [.designer])
    ],
    stats: Statistics(
        projectsCompleted: 12,
        averageRating: 4.8,
        activeYears: [2020, 2021, 2022]
    ),
    tags: ["innovative", "agile", "productive"]
)

let encoder = CBOREncoder()
let cborData = try encoder.encode(team)
```

### 6. Working with Sets

```swift
import CBOR

// Define a struct with Set properties
struct SetContainer: Codable, Equatable {
    let stringSet: Set<String>
    let intSet: Set<Int>
}

// Create an instance with sets
let setExample = SetContainer(
    stringSet: Set(["apple", "banana", "cherry"]),
    intSet: Set([1, 2, 3, 4, 5])
)

// Encode to CBOR
let encoder = CBOREncoder()
let encoded = try encoder.encode(setExample)

// Decode from CBOR
let decoder = CBORDecoder()
let decoded = try decoder.decode(SetContainer.self, from: encoded)

// Verify sets are preserved
assert(decoded.stringSet.contains("apple"))
assert(decoded.intSet.contains(3))
```

### 7. Working with Optionals and Nested Optionals

```swift
import CBOR

// Define a struct with optional and nested optional properties
struct OptionalExample: Codable, Equatable {
    let simpleOptional: String?
    let nestedOptional: Int??
    let optionalArray: [Double?]?
    let optionalDict: [String: Bool?]?
}

// Create an instance with various optional values
let optionalExample = OptionalExample(
    simpleOptional: "present",
    nestedOptional: nil,
    optionalArray: [1.0, nil, 3.0],
    optionalDict: ["yes": true, "no": false, "maybe": nil]
)

// Encode to CBOR
let encoder = CBOREncoder()
let encoded = try encoder.encode(optionalExample)

// Decode from CBOR
let decoder = CBORDecoder()
let decoded = try decoder.decode(OptionalExample.self, from: encoded)

// Verify optionals are preserved
assert(decoded.simpleOptional == "present")
assert(decoded.nestedOptional == nil)
assert(decoded.optionalArray?[1] == nil)
assert(decoded.optionalDict?["maybe"] == nil)
```

### 8. Non-String Dictionary Keys

```swift
import CBOR

// Define an enum to use as dictionary keys
enum Color: String, Codable, Hashable {
    case red
    case green
    case blue
}

struct EnumKeyDict: Codable, Equatable {
    let colorValues: [Color: Int]
}

// Create an instance with enum keys
let colorDict = EnumKeyDict(colorValues: [
    .red: 1,
    .green: 2,
    .blue: 3
])

// Encode to CBOR
let encoder = CBOREncoder()
let encoded = try encoder.encode(colorDict)

// Decode from CBOR
let decoder = CBORDecoder()
let decoded = try decoder.decode(EnumKeyDict.self, from: encoded)

// Verify dictionary with enum keys is preserved
assert(decoded.colorValues[.red] == 1)
assert(decoded.colorValues[.green] == 2)
assert(decoded.colorValues[.blue] == 3)
```

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
