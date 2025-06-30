// SpanExample.swift
// Example of using Span with CBOR in Swift 6.2+

#if compiler(>=6.2)
import CBOR
import Foundation

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, *)
@available(swift 6.2)
func demonstrateSpanUsage() throws {
    print("Swift 6.2 Span Integration Example")
    print("==================================")
    
    // Example 1: Decode CBOR from byte array
    let data: [UInt8] = [
        0x83, // Array of length 3
        0x01, // Unsigned integer 1
        0x02, // Unsigned integer 2
        0x03  // Unsigned integer 3
    ]
    
    // Standard decoding
    let cbor1 = try CBOR.decode(data)
    print("Standard decode: \(cbor1)")
    
    // Using the array extension (which internally can use Span)
    let cbor2 = try data.decodeCBOR()
    print("Array extension decode: \(cbor2)")
    
    // Example 2: When Span initialization becomes available in future Swift versions
    // This demonstrates the API we've prepared:
    
    // Future usage (when lifetime annotations are available):
    // data.withSpan { span in
    //     let cbor = try CBOR.decode(from: span)
    //     // or for better performance:
    //     let cbor = try CBOR.decodeUsingBuffer(from: span)
    // }
    
    print("\nNote: Direct Span initialization from arrays requires lifetime")
    print("annotations which will be available in future Swift versions.")
    print("The CBOR library is ready to support Span when those features arrive.")
}

// Run the example if this is the main file
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, *)
@available(swift 6.2)
@main
struct SpanExample {
    static func main() throws {
        try demonstrateSpanUsage()
    }
}

#else
// Fallback for earlier Swift versions
@main
struct SpanExample {
    static func main() {
        print("This example requires Swift 6.2 or later")
    }
}
#endif