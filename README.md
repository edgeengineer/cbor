# CBOR

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20Linux%20|%20Windows%20|%20Android-blue.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
[![macOS](https://img.shields.io/github/actions/workflow/status/edgeengineer/cbor/swift.yml?branch=main&label=macOS)](https://github.com/edgeengineer/cbor/actions/workflows/swift.yml)
[![Linux](https://img.shields.io/github/actions/workflow/status/edgeengineer/cbor/swift.yml?branch=main&label=Linux)](https://github.com/edgeengineer/cbor/actions/workflows/swift.yml)
[![Windows](https://img.shields.io/github/actions/workflow/status/edgeengineer/cbor/swift.yml?branch=main&label=Windows)](https://github.com/edgeengineer/cbor/actions/workflows/swift.yml)
[![Documentation](https://img.shields.io/badge/Documentation-DocC-blue)](https://edgeengineer.github.io/cbor/documentation/cbor/)

CBOR is a lightweight implementation of the [CBOR](https://tools.ietf.org/html/rfc7049) (Concise Binary Object Representation) format in Swift. It allows you to encode and decode data to and from the CBOR format, work directly with the CBOR data model, and integrate with Swift's `Codable` protocol.

## Features

- **Direct CBOR Data Model:**  
  Represent CBOR values using an enum with cases for unsigned/negative integers, byte strings, text strings, arrays, maps (ordered key/value pairs), tagged values, simple values, booleans, null, undefined, and floats.

- **Memory-Optimized for Embedded Swift:**  
  Uses `ArraySlice<UInt8>` internally to avoid heap allocations by referencing original data instead of copying. Includes zero-copy access methods and memory-efficient iterators for arrays and maps.

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
  - Cross-platform date handling (ISO8601 format on Apple platforms)

- **Error Handling:**  
  Detailed error types (`CBORError`) to help you diagnose encoding/decoding issues.

## Table of Contents

- [Features](#features)
- [Documentation](#documentation)
- [Installation](#installation)
- [Quick Start](#quick-start)
  - [Working Directly with CBOR Values](#1-working-directly-with-cbor-values)
  - [Using Codable](#2-using-codable)
  - [Working with Complex CBOR Structures](#3-working-with-complex-cbor-structures)
  - [Error Handling](#4-error-handling)
  - [Advanced Codable Examples](#5-advanced-codable-examples)
  - [Working with Sets](#6-working-with-sets)
  - [Working with Optionals and Nested Optionals](#7-working-with-optionals-and-nested-optionals)
  - [Non-String Dictionary Keys](#8-non-string-dictionary-keys)
- [Memory-Efficient Usage (Embedded Swift)](#memory-efficient-usage-embedded-swift)
  - [Working with Byte Strings (Zero-Copy)](#9-working-with-byte-strings-zero-copy)
  - [Working with Text Strings (Zero-Copy UTF-8)](#10-working-with-text-strings-zero-copy-utf-8)
  - [Memory-Efficient Array Iteration](#11-memory-efficient-array-iteration)
  - [Memory-Efficient Map Iteration](#12-memory-efficient-map-iteration)
  - [Performance Comparison: Slice vs Value Methods](#13-performance-comparison-slice-vs-value-methods)
  - [Decoding from Original Data](#14-decoding-from-original-data)
- [License](#license)

## Documentation

Comprehensive documentation is available via DocC:

- [Online Documentation](https://edgeengineer.github.io/cbor/documentation/cbor/)
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
        .package(url: "https://github.com/edgeengineer/cbor.git", from: "0.0.2")
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

## Memory-Efficient Usage (Embedded Swift)

This CBOR library is optimized for memory-constrained environments like Embedded Swift. It uses `ArraySlice<UInt8>` internally to avoid unnecessary heap allocations by referencing original data instead of copying it.

### 9. Working with Byte Strings (Zero-Copy)

```swift
import CBOR

// Create a byte string from raw data
let rawData: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05]
let cbor = CBOR.byteString(ArraySlice(rawData))

// Zero-copy access (recommended for Embedded Swift)
if let slice = cbor.byteStringSlice() {
    print("Length: \(slice.count)")
    print("First byte: 0x\(String(slice.first!, radix: 16))")
    
    // Process bytes without copying
    for byte in slice {
        print("Byte: 0x\(String(byte, radix: 16))")
    }
}

// Copy to Array only when needed (allocates memory)
if let bytes = cbor.byteStringValue() {
    let hexString = bytes.map { String(format: "%02x", $0) }.joined()
    print("Hex: \(hexString)")
}
```

### 10. Working with Text Strings (Zero-Copy UTF-8)

```swift
import CBOR

// Create a text string with Unicode content
let text = "Hello, 世界! 🌍"
let cbor = CBOR.textString(ArraySlice(text.utf8))

// Zero-copy access to UTF-8 bytes
if let slice = cbor.textStringSlice() {
    print("UTF-8 byte count: \(slice.count)")
    
    // Convert to String without intermediate allocation
    if let string = String(bytes: slice, encoding: .utf8) {
        print("Text: \(string)")
    }
    
    // Or examine raw UTF-8 bytes
    for byte in slice {
        print("UTF-8 byte: 0x\(String(byte, radix: 16))")
    }
}

// Convenience method for direct String conversion
if let text = cbor.stringValue {
    print("Decoded text: \(text)")
}
```

### 11. Memory-Efficient Array Iteration

```swift
import CBOR

// Decode CBOR data containing an array
let encodedArray: [UInt8] = [0x83, 0x01, 0x62, 0x68, 0x69, 0xf5] // [1, "hi", true]
let cbor = try CBOR.decode(encodedArray)

// Use iterator to avoid loading entire array into memory
if let iterator = try cbor.arrayIterator() {
    var iterator = iterator // Make mutable
    var index = 0
    
    while let element = iterator.next() {
        print("Element \(index):")
        
        switch element {
        case .unsignedInt(let value):
            print("  Integer: \(value)")
        case .textString:
            // Use zero-copy access for strings
            if let text = element.stringValue {
                print("  Text: \(text)")
            }
        case .bool(let flag):
            print("  Boolean: \(flag)")
        default:
            print("  Other: \(element)")
        }
        
        index += 1
    }
}

// Compare with traditional approach (allocates full array)
if let elements = try cbor.arrayValue() {
    print("Traditional approach loaded \(elements.count) elements into memory")
}
```

### 12. Memory-Efficient Map Iteration

```swift
import CBOR

// Decode CBOR data containing a map
let encodedMap: [UInt8] = [0xa2, 0x64, 0x6e, 0x61, 0x6d, 0x65, 0x64, 0x4a, 0x6f, 0x68, 0x6e, 0x63, 0x61, 0x67, 0x65, 0x18, 0x1e]
// {"name": "John", "age": 30}
let cbor = try CBOR.decode(encodedMap)

// Use iterator to process key-value pairs without loading entire map
if let iterator = try cbor.mapIterator() {
    var iterator = iterator // Make mutable
    
    while let pair = iterator.next() {
        print("Processing key-value pair:")
        
        // Handle the key (zero-copy for strings)
        if let keyText = pair.key.stringValue {
            print("  Key: \(keyText)")
        }
        
        // Handle the value
        switch pair.value {
        case .unsignedInt(let value):
            print("  Value: \(value)")
        case .textString:
            if let valueText = pair.value.stringValue {
                print("  Value: \(valueText)")
            }
        default:
            print("  Value: \(pair.value)")
        }
    }
}

// Compare with traditional approach (allocates full map)
if let pairs = try cbor.mapValue() {
    print("Traditional approach loaded \(pairs.count) pairs into memory")
}
```

### 13. Performance Comparison: Slice vs Value Methods

```swift
import CBOR

// Create a large byte string
let largeData = [UInt8](repeating: 0xFF, count: 10000)
let cbor = CBOR.byteString(ArraySlice(largeData))

// ✅ Memory-efficient: Zero-copy access
if let slice = cbor.byteStringSlice() {
    // No memory allocation - just references original data
    let sum = slice.reduce(0, +)
    print("Sum using slice: \(sum)")
}

// ⚠️ Memory-intensive: Copies data
if let bytes = cbor.byteStringValue() {
    // Allocates 10KB of memory for the copy
    let sum = bytes.reduce(0, +)
    print("Sum using copy: \(sum)")
}
```

### 14. Decoding from Original Data

```swift
import CBOR

// When you decode CBOR from external data
let networkData: [UInt8] = [0x65, 0x48, 0x65, 0x6c, 0x6c, 0x6f] // "Hello"
let cbor = try CBOR.decode(networkData)

// The decoded CBOR references the original networkData
if let slice = cbor.textStringSlice() {
    // slice points into networkData - no copying!
    print("Text length: \(slice.count)")
    
    // As long as networkData stays alive, slice is valid
    if let text = String(bytes: slice, encoding: .utf8) {
        print("Decoded: \(text)")
    }
}
```

### Memory Usage Guidelines

- **Prefer slice methods** (`byteStringSlice()`, `textStringSlice()`) over value methods for better memory efficiency
- **Use iterators** (`arrayIterator()`, `mapIterator()`) for large collections to avoid loading everything into memory
- **Keep original data alive** when using slices, as they reference the original data
- **Use `stringValue`** convenience property for direct String conversion without intermediate allocations

## Platform Compatibility

This CBOR library is designed to work across all Swift-supported platforms:

- **Apple platforms** (macOS, iOS, tvOS, watchOS, visionOS): Full feature support including ISO8601 date formatting
- **Linux**: Full feature support except ISO8601 date formatting (dates are still supported through other formats)
- **Windows**: Full feature support except ISO8601 date formatting (dates are still supported through other formats)
- **Android**: Cross-platform compatibility maintained

### Date Handling Notes

The library provides automatic date encoding/decoding support through the `Codable` interface:
- On **Apple platforms**: Dates are automatically formatted using `ISO8601DateFormatter` when encoded as text strings
- On **Linux/Windows**: Date text string formatting is not available, but dates can still be encoded/decoded using other CBOR representations (tagged values, numeric timestamps, etc.)

This ensures your code remains fully functional across all platforms while taking advantage of platform-specific optimizations where available.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
