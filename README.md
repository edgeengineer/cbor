# CBOR

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20Linux%20|%20Windows%20|%20Android-blue.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build](https://github.com/apache-edge/cbor/actions/workflows/swift.yml/badge.svg)](https://github.com/apache-edge/cbor/actions/workflows/swift.yml)

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

- **Error Handling:**  
  Detailed error types (`CBORError`) to help you diagnose encoding/decoding issues.

## Installation

### Swift Package Manager

Add the CBOR package to your Swift package dependencies:

```swift
// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "YourProject",
    dependencies: [
        .package(url: "https://github.com/apache-edge/cbor.git", from: "0.0.1")
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
    let activeProjects: [Project]
}

struct Project: Codable {
    let name: String
    let deadline: Date
    let milestones: [String: Date]
}

// Create a complex instance
let team = Team(
    name: "Dream Team",
    members: [
        Member(
            id: 1,
            name: "Alice",
            roles: [.developer, .manager]
        ),
        Member(
            id: 2,
            name: "Bob",
            roles: [.designer]
        )
    ],
    stats: Statistics(
        projectsCompleted: 10,
        averageRating: 4.8,
        activeProjects: [
            Project(
                name: "CBOR Implementation",
                deadline: Date(),
                milestones: [
                    "Design": Date(),
                    "Implementation": Date()
                ]
            )
        ]
    ),
    tags: ["innovative", "agile", "productive"]
)

// Encode and decode
do {
    let encoder = CBOREncoder()
    let encoded = try encoder.encode(team)
    
    let decoder = CBORDecoder()
    let decoded = try decoder.decode(Team.self, from: encoded)
    
    // Verify the round trip
    print("Team name: \(decoded.name)")
    print("Number of members: \(decoded.members.count)")
    print("First member roles: \(decoded.members[0].roles)")
    print("Active projects: \(decoded.stats.activeProjects.map { $0.name })")
    print("Team tags: \(decoded.tags)")
} catch {
    print("Error: \(error)")
}
```

### 6. Tagged Values and Simple Values

```swift 
// A tagged value (e.g., tagging a date string)
let taggedValue: CBOR = .tagged(0, .textString("2025-02-13T12:34:56Z"))
let taggedEncoded = taggedValue.encode()

// A simple value
let simpleValue: CBOR = .simple(16)
let simpleEncoded = simpleValue.encode()
```

The library provides a complete implementation of the CBOR format (RFC 8949) with full support for Swift's Codable protocol, making it suitable for both direct CBOR manipulation and seamless integration with Swift's type system.
