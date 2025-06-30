// CBORReader+SpanExtensions.swift
// Extensions to CBORReader for Swift 6.2's Span support

#if compiler(>=6.2)

// Note: Span requires platform availability even with Swift 6.2
// Using macOS 15.0+ as that's when Span became stable in Swift
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, *)
@available(swift 6.2)
extension CBORReader {
    /// Creates a reader with Span data for better performance
    init(span: Span<UInt8>) {
        // Convert span to array for now - will optimize later
        var data = [UInt8]()
        data.reserveCapacity(span.count)
        for i in span.indices {
            data.append(span[i])
        }
        self.init(data: data)
    }
}

#endif