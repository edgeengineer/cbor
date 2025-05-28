/// A helper struct for reading CBOR data byte by byte
struct CBORReader {
    private let data: [UInt8]
    private(set) var index: Int
    internal var maximumStringLength: UInt64 = 65_536
    internal var maximumElementCount: UInt64 = 16_384
    
    /// Creates a reader with the given data
    ///
    /// - Parameter data: The data to read
    init(data: [UInt8]) {
        self.data = data
        self.index = 0
    }
    
    /// Whether there are more bytes to read
    var hasMoreBytes: Bool {
        return index < data.count
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
    mutating func readBytes(_ count: Int) throws(CBORError) -> ArraySlice<UInt8> {
        guard index + count <= data.count else {
            throw CBORError.prematureEnd
        }
        let result = data[index..<index + count]
        index += count
        return result
    }

    mutating func readBigEndianInteger<F: FixedWidthInteger>(_ type: F.Type) throws(CBORError) -> F {
        let bytes = try readBytes(MemoryLayout<F>.size)
        var value: F = 0
        return bytes.withUnsafeBytes { buffer in
            withUnsafeMutableBytes(of: &value) { valuePtr in
                valuePtr.copyMemory(from: buffer)
            }
            return value.bigEndian
        }
    }
    
    /// Get the current position in the byte array
    var currentPosition: Int {
        return index
    }
    
    /// Skip a specified number of bytes
    mutating func skip(_ count: Int) throws(CBORError) {
        guard index + count <= data.count else {
            throw CBORError.prematureEnd
        }
        index += count
    }
    
    /// Seek to a specific position in the data
    mutating func seek(to position: Int) throws(CBORError) {
        guard position >= 0 && position <= data.count else {
            throw CBORError.invalidPosition
        }
        index = position
    }
}
