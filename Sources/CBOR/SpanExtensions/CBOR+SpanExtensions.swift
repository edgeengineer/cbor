// CBOR+SpanExtensions.swift
// Extensions to CBOR for Swift 6.2's Span support

#if compiler(>=6.2)

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, *)
@available(swift 6.2)
extension CBOR {
    /// Create CBOR from byte span
    static func byteString(span: Span<UInt8>) -> CBOR {
        var data = [UInt8]()
        data.reserveCapacity(span.count)
        for i in span.indices {
            data.append(span[i])
        }
        return .byteString(ArraySlice(data))
    }
    
    /// Create CBOR from text span
    static func textString(span: Span<UInt8>) -> CBOR {
        var data = [UInt8]()
        data.reserveCapacity(span.count)
        for i in span.indices {
            data.append(span[i])
        }
        return .textString(ArraySlice(data))
    }
}

// Extension to provide Span-based parsing
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, *)
@available(swift 6.2)
extension CBOR {
    /// Parse CBOR from a Span
    static func decode(from span: Span<UInt8>) throws(CBORError) -> CBOR {
        // Convert span to array and use existing decode method
        var data = [UInt8]()
        data.reserveCapacity(span.count)
        for i in span.indices {
            data.append(span[i])
        }
        return try decode(data)
    }
    
    /// Uses Span's withUnsafeBufferPointer for better performance
    static func decodeUsingBuffer(from span: Span<UInt8>) throws(CBORError) -> CBOR {
        var result: CBOR?
        var caughtError: CBORError?
        
        span.withUnsafeBufferPointer { buffer in
            do {
                result = try decode(Array(buffer))
            } catch let error as CBORError {
                caughtError = error
            } catch {
                // This should never happen since decode only throws CBORError
                fatalError("Unexpected error type: \(error)")
            }
        }
        
        if let error = caughtError {
            throw error
        }
        
        guard let cbor = result else {
            fatalError("Neither result nor error was set")
        }
        
        return cbor
    }
}

#endif