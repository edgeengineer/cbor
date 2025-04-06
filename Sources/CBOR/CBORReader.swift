#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

/// A helper struct for reading CBOR data byte by byte
struct CBORReader {
    private let data: [UInt8]
    private(set) var index: Int
    
    init(data: [UInt8]) {
        self.data = data
        self.index = 0
    }
    
    /// Read a single byte from the input
    mutating func readByte() throws(CBORError) -> UInt8 {
        guard index < data.count else {
            throw CBORError.prematureEnd
        }
        let byte = data[index]
        index += 1
        return byte
    }
    
    /// Read a specified number of bytes from the input
    mutating func readBytes(_ count: Int) throws(CBORError) -> [UInt8] {
        guard index + count <= data.count else {
            throw CBORError.prematureEnd
        }
        let result = Array(data[index..<index + count])
        index += count
        return result
    }
    
    /// Check if there are more bytes to read
    var hasMoreBytes: Bool {
        return index < data.count
    }
    
    /// Get the current position in the byte array
    var currentPosition: Int {
        return index
    }
    
    /// Get the total number of bytes
    var totalBytes: Int {
        return data.count
    }
    
    /// Skip a specified number of bytes
    mutating func skip(_ count: Int) throws {
        guard index + count <= data.count else {
            throw CBORError.prematureEnd
        }
        index += count
    }
}
