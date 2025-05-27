#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

/// A reader for CBOR data
public struct CBORReader {
    /// The data being read
    private let data: ArraySlice<UInt8>
    /// The current index in the data
    private var index: Int
    
    /// Creates a reader with the given data
    ///
    /// - Parameter data: The data to read
    public init(data: [UInt8]) {
        self.data = ArraySlice(data)
        self.index = self.data.startIndex
    }
    
    /// Creates a reader with the given data slice
    ///
    /// - Parameter data: The data slice to read
    public init(data: ArraySlice<UInt8>) {
        self.data = data
        self.index = self.data.startIndex
    }
    
    /// Creates a reader with the given bytes
    ///
    /// - Parameter bytes: The bytes to read
    public init(bytes: ArraySlice<UInt8>) {
        self.data = bytes
        self.index = self.data.startIndex
    }
    
    /// Whether there are more bytes to read
    public var hasMoreBytes: Bool {
        return index < data.endIndex
    }
    
    /// Reads a single byte
    ///
    /// - Returns: The byte read
    /// - Throws: CBORError.endOfData if there are no more bytes to read
    public mutating func readByte() throws -> UInt8 {
        guard hasMoreBytes else {
            throw CBORError.endOfData
        }
        
        let byte = data[index]
        index += 1
        return byte
    }
    
    /// Reads a specified number of bytes
    ///
    /// - Parameter count: The number of bytes to read
    /// - Returns: The bytes read
    /// - Throws: CBORError.endOfData if there are not enough bytes to read
    ///           CBORError.invalidLength if count is negative
    public mutating func readBytes(_ count: Int) throws -> ArraySlice<UInt8> {
        guard count >= 0 else {
            throw CBORError.invalidLength
        }
        
        // Handle empty request specially to avoid potential index issues
        if count == 0 {
            return ArraySlice<UInt8>()
        }
        
        guard index + count <= data.endIndex else {
            throw CBORError.endOfData
        }
        
        let startIndex = index
        index += count
        
        // Create a new ArraySlice to avoid potential index issues
        return ArraySlice(data[startIndex..<index])
    }
    
    /// Peeks at the next byte without advancing the reader
    ///
    /// - Returns: The next byte, or nil if there are no more bytes
    public func peekByte() -> UInt8? {
        guard hasMoreBytes else {
            return nil
        }
        
        return data[index]
    }
    
    /// Get the current position in the byte array
    public var currentPosition: Int {
        return index - data.startIndex
    }
    
    /// Get the total number of bytes
    public var totalBytes: Int {
        return data.count
    }
    
    /// Skip a specified number of bytes
    public mutating func skip(_ count: Int) throws {
        guard count >= 0 else {
            throw CBORError.invalidLength
        }
        
        guard index + count <= data.endIndex else {
            throw CBORError.endOfData
        }
        
        index += count
    }
    
    /// Seek to a specific position in the data
    public mutating func seek(to position: Int) throws {
        // Calculate the absolute position relative to the start index of the data
        let targetPosition = data.startIndex + position
        
        // Ensure the position is valid
        guard targetPosition >= data.startIndex && targetPosition <= data.endIndex else {
            throw CBORError.invalidPosition
        }
        
        // Set the index to the new position
        index = targetPosition
    }
}

// MARK: - Safe Collection Extension

/// Extension to provide safe subscripting for collections
extension Collection {
    /// Returns the element at the specified index if it exists, otherwise nil
    ///
    /// - Parameter index: The index to access
    /// - Returns: The element at the index, or nil if the index is out of bounds
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
