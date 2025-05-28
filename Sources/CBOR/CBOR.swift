#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif os(Windows)
import ucrt
#endif

// MARK: - CBOR Type

/// A CBOR value optimized for low-memory usage in Embedded Swift
///
/// This enum uses `ArraySlice<UInt8>` for complex types to avoid heap allocations
/// by referencing the original data instead of copying it. This makes parsing
/// efficient for memory-constrained environments.
///
/// ## Usage Examples
///
/// ### Working with byte strings:
/// ```swift
/// let cbor = CBOR.byteString(ArraySlice([0x01, 0x02, 0x03]))
/// 
/// // Zero-copy access (recommended for Embedded Swift)
/// if let slice = cbor.byteStringSlice() {
///     // Work with slice directly without copying
///     print("Length: \(slice.count)")
/// }
/// 
/// // Copy to Array when needed
/// if let bytes = cbor.byteStringValue() {
///     print("Bytes: \(bytes)")
/// }
/// ```
///
/// ### Working with text strings:
/// ```swift
/// let text = "Hello, World!"
/// let cbor = CBOR.textString(ArraySlice(text.utf8))
/// 
/// // Zero-copy access to UTF-8 bytes
/// if let slice = cbor.textStringSlice() {
///     if let string = String(bytes: slice, encoding: .utf8) {
///         print("Text: \(string)")
///     }
/// }
/// ```
///
/// ### Working with arrays and maps using iterators:
/// ```swift
/// // Use iterators to avoid allocating full arrays
/// if let iterator = try cbor.arrayIterator() {
///     for element in iterator {
///         // Process each element without loading entire array
///         print("Element: \(element)")
///     }
/// }
/// ```
public indirect enum CBOR: Equatable, Sendable {
    /// A positive unsigned integer
    case unsignedInt(UInt64)
    
    /// A negative integer
    case negativeInt(Int64)
    
    /// A byte string stored as a reference to avoid copying
    ///
    /// Uses `ArraySlice<UInt8>` to reference original data without heap allocation.
    /// Use `byteStringSlice()` for zero-copy access or `byteStringValue()` to get a copy.
    case byteString(ArraySlice<UInt8>)
    
    /// A UTF-8 text string stored as a reference to avoid copying
    ///
    /// Uses `ArraySlice<UInt8>` containing UTF-8 bytes to reference original data.
    /// Use `textStringSlice()` for zero-copy access or `textStringValue()` to get a copy.
    /// Convert to String with: `String(bytes: slice, encoding: .utf8)`
    case textString(ArraySlice<UInt8>)
    
    /// An array of CBOR values stored as encoded bytes
    ///
    /// Uses `ArraySlice<UInt8>` containing the encoded array data.
    /// Use `arrayIterator()` for memory-efficient iteration or `arrayValue()` to decode all elements.
    case array(ArraySlice<UInt8>)
    
    /// A map of CBOR key-value pairs stored as encoded bytes
    ///
    /// Uses `ArraySlice<UInt8>` containing the encoded map data.
    /// Use `mapIterator()` for memory-efficient iteration or `mapValue()` to decode all pairs.
    case map(ArraySlice<UInt8>)
    
    /// A tagged CBOR value with lazy decoding
    ///
    /// The tagged value's data is stored as `ArraySlice<UInt8>` and decoded only when accessed.
    /// Use `taggedValue()` to decode the contained value.
    case tagged(UInt64, ArraySlice<UInt8>)
    
    /// A simple value (0-255)
    case simple(UInt8)
    
    /// A boolean value
    case bool(Bool)
    
    /// A null value
    case null
    
    /// An undefined value
    case undefined
    
    /// A floating-point number
    case float(Double)
    
    /// Encodes the CBOR value to bytes
    public func encode(into output: inout [UInt8]) {
        _encode(self, into: &output)
    }

    public func encode() -> [UInt8] {
        var output: [UInt8] = []
        encode(into: &output)
        return output
    }
    
    /// Decodes a CBOR value from bytes
    ///
    /// - Parameter bytes: The bytes to decode
    /// - Returns: The decoded CBOR value
    /// - Throws: A `CBORError` if the decoding fails
    public static func decode(_ bytes: [UInt8]) throws(CBORError) -> CBOR {
        var reader = CBORReader(data: bytes)
        let value = try _decode(reader: &reader)
        
        // Check if there's any extra data
        if reader.hasMoreBytes {
            throw CBORError.extraDataFound
        }
        
        return value
    }
    
    /// Decodes a CBOR value from bytes.
    ///
    /// - Parameter bytes: The bytes to decode
    /// - Returns: The decoded CBOR value
    /// - Throws: A `CBORError` if the decoding fails
    public static func decode(_ bytes: ArraySlice<UInt8>) throws -> CBOR {
        var reader = CBORReader(data: Array(bytes))
        let value = try _decode(reader: &reader)
        
        // Check if there's any extra data
        if reader.hasMoreBytes {
            throw CBORError.extraDataFound
        }
        
        return value
    }
    
    /// Get the byte string value as ArraySlice to avoid copying (recommended for Embedded Swift)
    ///
    /// This method provides zero-copy access to the byte string data, making it ideal
    /// for memory-constrained environments. The returned slice references the original
    /// data without heap allocation.
    ///
    /// ## Example Usage:
    /// ```swift
    /// let data: [UInt8] = [0x01, 0x02, 0x03, 0x04]
    /// let cbor = CBOR.byteString(ArraySlice(data))
    /// 
    /// if let slice = cbor.byteStringSlice() {
    ///     print("Length: \(slice.count)")
    ///     print("First byte: 0x\(String(slice.first!, radix: 16))")
    ///     
    ///     // Work with slice directly - no copying
    ///     for byte in slice {
    ///         // Process each byte
    ///     }
    /// }
    /// ```
    ///
    /// - Returns: The byte string as ArraySlice<UInt8>, or nil if this is not a byte string
    /// - Note: For memory efficiency, prefer this method over `byteStringValue()` in Embedded Swift
    public func byteStringSlice() -> ArraySlice<UInt8>? {
        guard case .byteString(let bytes) = self else { return nil }
        return bytes
    }
    
    /// Get the byte string value as a copied Array
    ///
    /// This method creates a new Array by copying the byte string data. Use `byteStringSlice()`
    /// instead for zero-copy access in memory-constrained environments.
    ///
    /// ## Example Usage:
    /// ```swift
    /// let cbor = CBOR.byteString(ArraySlice([0x01, 0x02, 0x03]))
    /// 
    /// if let bytes = cbor.byteStringValue() {
    ///     // bytes is now a [UInt8] copy
    ///     let hexString = bytes.map { String(format: "%02x", $0) }.joined()
    ///     print("Hex: \(hexString)")
    /// }
    /// ```
    ///
    /// - Returns: The byte string as [UInt8], or nil if this is not a byte string
    /// - Note: This method allocates memory. Consider `byteStringSlice()` for better performance.
    public func byteStringValue() -> [UInt8]? {
        guard case .byteString(let bytes) = self else { return nil }
        return Array(bytes)
    }
    
    /// Get the text string value as UTF-8 bytes without copying (recommended for Embedded Swift)
    ///
    /// This method provides zero-copy access to the UTF-8 encoded text string data.
    /// The returned slice contains UTF-8 bytes that can be converted to a String.
    ///
    /// ## Example Usage:
    /// ```swift
    /// let text = "Hello, 世界! 🌍"
    /// let cbor = CBOR.textString(ArraySlice(text.utf8))
    /// 
    /// if let slice = cbor.textStringSlice() {
    ///     // Convert UTF-8 bytes to String
    ///     if let string = String(bytes: slice, encoding: .utf8) {
    ///         print("Text: \(string)")
    ///         print("UTF-8 byte count: \(slice.count)")
    ///     }
    ///     
    ///     // Or work with raw UTF-8 bytes directly
    ///     for byte in slice {
    ///         print("UTF-8 byte: 0x\(String(byte, radix: 16))")
    ///     }
    /// }
    /// ```
    ///
    /// - Returns: The text string as ArraySlice<UInt8> containing UTF-8 bytes, or nil if this is not a text string
    /// - Note: For memory efficiency, prefer this method over `textStringValue()` in Embedded Swift
    public func textStringSlice() -> ArraySlice<UInt8>? {
        guard case .textString(let bytes) = self else { return nil }
        return bytes
    }
    
    /// Get the text string value as copied UTF-8 bytes
    ///
    /// This method creates a new Array by copying the UTF-8 encoded text string data.
    /// Use `textStringSlice()` instead for zero-copy access in memory-constrained environments.
    ///
    /// ## Example Usage:
    /// ```swift
    /// let cbor = CBOR.textString(ArraySlice("Hello".utf8))
    /// 
    /// if let utf8Bytes = cbor.textStringValue() {
    ///     // utf8Bytes is now a [UInt8] copy
    ///     if let string = String(bytes: utf8Bytes, encoding: .utf8) {
    ///         print("Decoded text: \(string)")
    ///     }
    /// }
    /// ```
    ///
    /// - Returns: The text string as [UInt8] containing UTF-8 bytes, or nil if this is not a text string
    /// - Note: This method allocates memory. Consider `textStringSlice()` for better performance.
    public func textStringValue() -> [UInt8]? {
        guard case .textString(let bytes) = self else { return nil }
        return Array(bytes)
    }
    
    /// Returns the array value of this CBOR value
    ///
    /// - Returns: An array of CBOR values, or nil if this is not an array
    /// - Throws: CBORError if the array cannot be decoded
    public func arrayValue() throws -> [CBOR]? {
        guard case .array(let bytes) = self else {
            return nil
        }
        
        // Safety check for empty bytes
        if bytes.isEmpty {
            return []
        }
        
        // Convert ArraySlice to Array to avoid potential index issues
        let byteArray = Array(bytes)
        
        do {
            var result: [CBOR] = []
            var reader = CBORReader(data: byteArray)
            
            // Get the array length from the initial byte
            let initial = try reader.readByte()
            let major = initial >> 5
            let additional = initial & 0x1f
            
            // Ensure this is an array
            guard major == 4 else {
                throw CBORError.invalidData
            }
            
            // Get the array length
            let count = try readUIntValue(additional: additional, reader: &reader)
            
            // Read each array element
            for _ in 0..<Int(count) {
                let element = try _decode(reader: &reader)
                result.append(element)
            }
            
            return result
        } catch {
            if let cborError = error as? CBORError {
                throw cborError
            } else {
                throw CBORError.invalidData
            }
        }
    }
    
    /// Returns the map value of this CBOR value
    ///
    /// - Returns: An array of CBOR key-value pairs, or nil if this is not a map
    /// - Throws: CBORError if the map cannot be decoded
    public func mapValue() throws -> [CBORMapPair]? {
        guard case .map(let bytes) = self else {
            return nil
        }
        
        // Safety check for empty bytes
        if bytes.isEmpty {
            return []
        }
        
        // Convert ArraySlice to Array to avoid potential index issues
        let byteArray = Array(bytes)
        
        do {
            var result: [CBORMapPair] = []
            var reader = CBORReader(data: byteArray)
            
            // Get the map length from the initial byte
            let initial = try reader.readByte()
            let major = initial >> 5
            let additional = initial & 0x1f
            
            // Ensure this is a map
            guard major == 5 else {
                throw CBORError.invalidData
            }
            
            // Get the map length
            let count = try readUIntValue(additional: additional, reader: &reader)
            
            // Read each key-value pair
            for _ in 0..<Int(count) {
                let key = try _decode(reader: &reader)
                let value = try _decode(reader: &reader)
                result.append(CBORMapPair(key: key, value: value))
            }
            
            return result
        } catch {
            if let cborError = error as? CBORError {
                throw cborError
            } else {
                throw CBORError.invalidData
            }
        }
    }
    
    /// Returns the tagged value of this CBOR value
    ///
    /// - Returns: A tuple containing the tag and the tagged value, or nil if this is not a tagged value
    /// - Throws: CBORError if the tagged value cannot be decoded
    public func taggedValue() throws -> (UInt64, CBOR)? {
        guard case .tagged(let tag, let bytes) = self else {
            return nil
        }
        
        // Safety check for empty bytes
        if bytes.isEmpty {
            throw CBORError.invalidData
        }
        
        do {
            // Decode the tagged value
            let value = try CBOR.decode(bytes)
            
            return (tag, value)
        } catch {
            // If there's an error decoding the tagged value, wrap it
            if let cborError = error as? CBORError {
                throw cborError
            } else {
                throw CBORError.invalidData
            }
        }
    }
    
    /// Get an iterator for CBOR array elements to avoid heap allocations (recommended for Embedded Swift)
    ///
    /// This method provides memory-efficient iteration over array elements without loading
    /// the entire array into memory. Each element is decoded on-demand as you iterate.
    ///
    /// ## Example Usage:
    /// ```swift
    /// // Assuming you have a CBOR array
    /// if let iterator = try cbor.arrayIterator() {
    ///     var iterator = iterator // Make mutable
    ///     
    ///     // Iterate through elements one by one
    ///     while let element = iterator.next() {
    ///         switch element {
    ///         case .unsignedInt(let value):
    ///             print("Integer: \(value)")
    ///         case .textString:
    ///             if let slice = element.textStringSlice(),
    ///                let text = String(bytes: slice, encoding: .utf8) {
    ///                 print("Text: \(text)")
    ///             }
    ///         default:
    ///             print("Other element: \(element)")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Returns: A CBORArrayIterator for memory-efficient iteration, or nil if this is not an array
    /// - Throws: CBORError if the array data is malformed
    /// - Note: Prefer this over `arrayValue()` for large arrays in memory-constrained environments
    public func arrayIterator() throws -> CBORArrayIterator? {
        guard case .array(let bytes) = self else {
            return nil
        }
        return try CBORArrayIterator(bytes: bytes)
    }
    
    /// Get an iterator for CBOR map entries to avoid heap allocations (recommended for Embedded Swift)
    ///
    /// This method provides memory-efficient iteration over map key-value pairs without loading
    /// the entire map into memory. Each pair is decoded on-demand as you iterate.
    ///
    /// ## Example Usage:
    /// ```swift
    /// // Assuming you have a CBOR map
    /// if let iterator = try cbor.mapIterator() {
    ///     var iterator = iterator // Make mutable
    ///     
    ///     // Iterate through key-value pairs one by one
    ///     while let pair = iterator.next() {
    ///         print("Processing key-value pair:")
    ///         
    ///         // Handle the key
    ///         if let keySlice = pair.key.textStringSlice(),
    ///            let keyString = String(bytes: keySlice, encoding: .utf8) {
    ///             print("  Key: \(keyString)")
    ///         }
    ///         
    ///         // Handle the value
    ///         switch pair.value {
    ///         case .unsignedInt(let value):
    ///             print("  Value: \(value)")
    ///         case .bool(let flag):
    ///             print("  Value: \(flag)")
    ///         default:
    ///             print("  Value: \(pair.value)")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Returns: A CBORMapIterator for memory-efficient iteration, or nil if this is not a map
    /// - Throws: CBORError if the map data is malformed
    /// - Note: Prefer this over `mapValue()` for large maps in memory-constrained environments
    public func mapIterator() throws -> CBORMapIterator? {
        guard case .map(let bytes) = self else {
            return nil
        }
        return try CBORMapIterator(bytes: bytes)
    }
    
    // MARK: - Convenience Methods for Embedded Swift
    
    /// Convert a text string CBOR value directly to a Swift String
    ///
    /// This is a convenience method that combines `textStringSlice()` and UTF-8 decoding
    /// in one step, making it easier to work with text strings in Embedded Swift.
    ///
    /// ## Example Usage:
    /// ```swift
    /// let cbor = CBOR.textString(ArraySlice("Hello, World!".utf8))
    /// 
    /// if let text = cbor.stringValue {
    ///     print("Text: \(text)")
    /// }
    /// ```
    ///
    /// - Returns: The decoded String, or nil if this is not a text string or contains invalid UTF-8
    /// - Note: This method avoids intermediate allocations by working directly with the ArraySlice
    public var stringValue: String? {
        guard let slice = textStringSlice() else { return nil }
        return String(bytes: slice, encoding: .utf8)
    }
    
    // MARK: - Convenience Constructors
    
    /// Creates a CBOR text string from a Swift String
    public static func textString(_ string: String) -> CBOR {
        return .textString(ArraySlice(string.utf8))
    }
    
    /// Creates a CBOR array from an array of CBOR values
    public static func array(_ elements: [CBOR]) -> CBOR {
        var arrayBuffer: [UInt8] = []
        let count = UInt64(elements.count)
        let majorType: UInt8 = 4 << 5
        
        // Add array header
        if count <= 23 {
            arrayBuffer.append(majorType | UInt8(count))
        } else if count <= UInt64(UInt8.max) {
            arrayBuffer.append(majorType | 24)
            arrayBuffer.append(UInt8(count))
        } else if count <= UInt64(UInt16.max) {
            arrayBuffer.append(majorType | 25)
            arrayBuffer.append(UInt8(count >> 8))
            arrayBuffer.append(UInt8(count & 0xFF))
        } else if count <= UInt64(UInt32.max) {
            arrayBuffer.append(majorType | 26)
            arrayBuffer.append(UInt8(count >> 24))
            arrayBuffer.append(UInt8((count >> 16) & 0xFF))
            arrayBuffer.append(UInt8((count >> 8) & 0xFF))
            arrayBuffer.append(UInt8(count & 0xFF))
        } else {
            arrayBuffer.append(majorType | 27)
            arrayBuffer.append(UInt8(count >> 56))
            arrayBuffer.append(UInt8((count >> 48) & 0xFF))
            arrayBuffer.append(UInt8((count >> 40) & 0xFF))
            arrayBuffer.append(UInt8((count >> 32) & 0xFF))
            arrayBuffer.append(UInt8((count >> 24) & 0xFF))
            arrayBuffer.append(UInt8((count >> 16) & 0xFF))
            arrayBuffer.append(UInt8((count >> 8) & 0xFF))
            arrayBuffer.append(UInt8(count & 0xFF))
        }
        
        // Add each element's encoded bytes
        for element in elements {
            arrayBuffer.append(contentsOf: element.encode())
        }
        
        return .array(ArraySlice(arrayBuffer))
    }
    
    /// Creates a CBOR map from an array of key-value pairs
    public static func map(_ pairs: [CBORMapPair]) -> CBOR {
        var mapBuffer: [UInt8] = []
        let count = UInt64(pairs.count)
        let majorType: UInt8 = 5 << 5
        
        // Add map header
        if count <= 23 {
            mapBuffer.append(majorType | UInt8(count))
        } else if count <= UInt64(UInt8.max) {
            mapBuffer.append(majorType | 24)
            mapBuffer.append(UInt8(count))
        } else if count <= UInt64(UInt16.max) {
            mapBuffer.append(majorType | 25)
            mapBuffer.append(UInt8(count >> 8))
            mapBuffer.append(UInt8(count & 0xFF))
        } else if count <= UInt64(UInt32.max) {
            mapBuffer.append(majorType | 26)
            mapBuffer.append(UInt8(count >> 24))
            mapBuffer.append(UInt8((count >> 16) & 0xFF))
            mapBuffer.append(UInt8((count >> 8) & 0xFF))
            mapBuffer.append(UInt8(count & 0xFF))
        } else {
            mapBuffer.append(majorType | 27)
            mapBuffer.append(UInt8(count >> 56))
            mapBuffer.append(UInt8((count >> 48) & 0xFF))
            mapBuffer.append(UInt8((count >> 40) & 0xFF))
            mapBuffer.append(UInt8((count >> 32) & 0xFF))
            mapBuffer.append(UInt8((count >> 24) & 0xFF))
            mapBuffer.append(UInt8((count >> 16) & 0xFF))
            mapBuffer.append(UInt8((count >> 8) & 0xFF))
            mapBuffer.append(UInt8(count & 0xFF))
        }
        
        // Add each pair's encoded bytes
        for pair in pairs {
            mapBuffer.append(contentsOf: pair.key.encode())
            mapBuffer.append(contentsOf: pair.value.encode())
        }
        
        return .map(ArraySlice(mapBuffer))
    }
}

/// A key-value pair in a CBOR map
///
/// - Parameters:
///   - key: The key of the pair
///   - value: The value of the pair
public struct CBORMapPair: Equatable, Sendable {
    public let key: CBOR
    public let value: CBOR
    
    public init(key: CBOR, value: CBOR) {
        self.key = key
        self.value = value
    }
}

// MARK: - Encoding

/// Encodes a CBOR value to bytes
///
/// - Parameters:
///   - value: The CBOR value to encode
///   - output: The output buffer to write the encoded bytes to
@inline(__always)
private func _encode(_ value: CBOR, into output: inout [UInt8]) {
    switch value {
    case .unsignedInt(let u):
        encodeUnsigned(major: 0, value: u, into: &output)
    case .negativeInt(let n):
        // In CBOR, negative integers are encoded as -(n+1) where n is a non-negative integer
        // So we need to convert our negative Int64 to the correct positive UInt64 value
        if n < 0 {
            // For negative values, we encode as -(n+1)
            let positiveValue = UInt64(-1 - n)
            encodeUnsigned(major: 1, value: positiveValue, into: &output)
        } else {
            // For non-negative values, we encode as n
            encodeUnsigned(major: 1, value: UInt64(n), into: &output)
        }
    case .byteString(let bytes):
        encodeUnsigned(major: 2, value: UInt64(bytes.count), into: &output)
        output.append(contentsOf: bytes)
    case .textString(let bytes):
        encodeUnsigned(major: 3, value: UInt64(bytes.count), into: &output)
        output.append(contentsOf: bytes)
    case .array(let bytes):
        // For array, we just copy the raw bytes as they already contain the encoded array
        output.append(contentsOf: bytes)
    case .map(let bytes):
        // For map, we just copy the raw bytes as they already contain the encoded map
        output.append(contentsOf: bytes)
    case .tagged(let tag, let bytes):
        encodeUnsigned(major: 6, value: tag, into: &output)
        output.append(contentsOf: bytes)
    case .simple(let simple):
        if simple < 24 {
            output.append(0xe0 | simple)
        } else {
            output.append(0xf8)
            output.append(simple)
        }
    case .bool(let b):
        output.append(b ? 0xf5 : 0xf4)
    case .null:
        output.append(0xf6)
    case .undefined:
        output.append(0xf7)
    case .float(let f):
        // Encode as IEEE 754 double-precision float (CBOR major type 7, additional info 27)
        output.append(0xfb)
        withUnsafeBytes(of: f) { bytes in
            // Append bytes in big-endian order
            for i in (0..<8).reversed() {
                output.append(bytes[i])
            }
        }
    }
}

/// Encodes an unsigned integer with the given major type
///
/// - Parameters:
///   - major: The major type of the integer
///   - value: The unsigned integer value
///   - output: The output buffer to write the encoded bytes to
private func encodeUnsigned(major: UInt8, value: UInt64, into output: inout [UInt8]) {
    let majorByte = major << 5
    if value < 24 {
        output.append(majorByte | UInt8(value))
    } else if value <= UInt8.max {
        output.append(majorByte | 24)
        output.append(UInt8(value))
    } else if value <= UInt16.max {
        output.append(majorByte | 25)
        output.append(UInt8(value >> 8))
        output.append(UInt8(value & 0xff))
    } else if value <= UInt32.max {
        output.append(majorByte | 26)
        output.append(UInt8(value >> 24))
        output.append(UInt8((value >> 16) & 0xff))
        output.append(UInt8((value >> 8) & 0xff))
        output.append(UInt8(value & 0xff))
    } else {
        output.append(majorByte | 27)
        output.append(UInt8(value >> 56))
        output.append(UInt8((value >> 48) & 0xff))
        output.append(UInt8((value >> 40) & 0xff))
        output.append(UInt8((value >> 32) & 0xff))
        output.append(UInt8((value >> 24) & 0xff))
        output.append(UInt8((value >> 16) & 0xff))
        output.append(UInt8((value >> 8) & 0xff))
        output.append(UInt8(value & 0xff))
    }
}

// MARK: - Decoding

/// Decodes a CBOR value from the reader.
///
/// - Parameters:
///   - reader: The reader to decode from
/// - Returns: The decoded CBOR value
/// - Throws: A `CBORError` if the decoding fails
private func _decode(reader: inout CBORReader) throws(CBORError) -> CBOR {
    let initial = try reader.readByte()
    
    // Check for break marker (0xff)
    if initial == 0xff {
        throw CBORError.invalidInitialByte(initial)
    }
    
    let majorType = initial >> 5
    let additional = initial & 0x1f
    
    switch majorType {
    case 0: // unsigned integer
        let value = try readUIntValue(additional: additional, reader: &reader)
        return .unsignedInt(value)
        
    case 1: // negative integer
        let value = try readUIntValue(additional: additional, reader: &reader)
        return .negativeInt(Int64(-1 - Int64(value)))
        
    case 2: // byte string
        // Get the length of the byte string
        let length = try readUIntValue(additional: additional, reader: &reader)
        guard length <= reader.maximumStringLength else {
            throw CBORError.lengthTooLarge(length, maximum: reader.maximumStringLength)
        }
        
        let bytes = try reader.readBytes(Int(length))
        
        // Store the raw bytes
        return .byteString(bytes)
        
    case 3: // text string
        // Get the length of the text string
        let length = try readUIntValue(additional: additional, reader: &reader)
        guard length <= reader.maximumStringLength else {
            throw CBORError.lengthTooLarge(length, maximum: reader.maximumStringLength)
        }
        
        // Read the text string data
        let bytes = try reader.readBytes(Int(length))
        
        // Validate UTF-8 encoding
        guard String(bytes: bytes, encoding: .utf8) != nil else {
            throw CBORError.invalidUTF8
        }
        
        // Store the raw bytes
        return .textString(bytes)
        
    case 4: // array
        // Check for indefinite length arrays
        if additional == 31 {
            throw CBORError.indefiniteLengthNotSupported
        }
        
        // Get the array length
        let count = try readUIntValue(additional: additional, reader: &reader)
        guard count <= reader.maximumElementCount else {
            throw CBORError.lengthTooLarge(count, maximum: reader.maximumElementCount)
        }
        
        // Read each array element
        var elements: [CBOR] = []
        for _ in 0..<Int(count) {
            let element = try _decode(reader: &reader)
            elements.append(element)
        }
        
        // Create a new array with the decoded elements
        var arrayBuffer: [UInt8] = []
        // Add array header
        let majorType: UInt8 = 4 << 5
        if count <= 23 {
            arrayBuffer.append(majorType | UInt8(count))
        } else if count <= UInt64(UInt8.max) {
            arrayBuffer.append(majorType | 24)
            arrayBuffer.append(UInt8(count))
        } else if count <= UInt64(UInt16.max) {
            arrayBuffer.append(majorType | 25)
            arrayBuffer.append(UInt8(count >> 8))
            arrayBuffer.append(UInt8(count & 0xFF))
        } else if count <= UInt64(UInt32.max) {
            arrayBuffer.append(majorType | 26)
            arrayBuffer.append(UInt8(count >> 24))
            arrayBuffer.append(UInt8((count >> 16) & 0xFF))
            arrayBuffer.append(UInt8((count >> 8) & 0xFF))
            arrayBuffer.append(UInt8(count & 0xFF))
        } else {
            arrayBuffer.append(majorType | 27)
            arrayBuffer.append(UInt8(count >> 56))
            arrayBuffer.append(UInt8((count >> 48) & 0xFF))
            arrayBuffer.append(UInt8((count >> 40) & 0xFF))
            arrayBuffer.append(UInt8((count >> 32) & 0xFF))
            arrayBuffer.append(UInt8((count >> 24) & 0xFF))
            arrayBuffer.append(UInt8((count >> 16) & 0xFF))
            arrayBuffer.append(UInt8((count >> 8) & 0xFF))
            arrayBuffer.append(UInt8(count & 0xFF))
        }
        
        // Add each element's encoded bytes
        for element in elements {
            arrayBuffer.append(contentsOf: element.encode())
        }
        
        return .array(ArraySlice(arrayBuffer))
        
    case 5: // map
        // Check for indefinite length maps
        if additional == 31 {
            throw CBORError.indefiniteLengthNotSupported
        }
        
        // Get the map length
        let count = try readUIntValue(additional: additional, reader: &reader)
        guard count <= reader.maximumElementCount else {
            throw CBORError.lengthTooLarge(count, maximum: reader.maximumElementCount)
        }
        
        // Read each map key-value pair
        var pairs: [CBORMapPair] = []
        for _ in 0..<count {
            let key = try _decode(reader: &reader)
            let value = try _decode(reader: &reader)
            pairs.append(CBORMapPair(key: key, value: value))
        }
        
        // Create a new map with the decoded pairs
        var mapBuffer: [UInt8] = []
        // Add map header
        let majorType: UInt8 = 5 << 5
        if count <= 23 {
            mapBuffer.append(majorType | UInt8(count))
        } else if count <= UInt64(UInt8.max) {
            mapBuffer.append(majorType | 24)
            mapBuffer.append(UInt8(count))
        } else if count <= UInt64(UInt16.max) {
            mapBuffer.append(majorType | 25)
            mapBuffer.append(UInt8(count >> 8))
            mapBuffer.append(UInt8(count & 0xFF))
        } else if count <= UInt64(UInt32.max) {
            mapBuffer.append(majorType | 26)
            mapBuffer.append(UInt8(count >> 24))
            mapBuffer.append(UInt8((count >> 16) & 0xFF))
            mapBuffer.append(UInt8((count >> 8) & 0xFF))
            mapBuffer.append(UInt8(count & 0xFF))
        } else {
            mapBuffer.append(majorType | 27)
            mapBuffer.append(UInt8(count >> 56))
            mapBuffer.append(UInt8((count >> 48) & 0xFF))
            mapBuffer.append(UInt8((count >> 40) & 0xFF))
            mapBuffer.append(UInt8((count >> 32) & 0xFF))
            mapBuffer.append(UInt8((count >> 24) & 0xFF))
            mapBuffer.append(UInt8((count >> 16) & 0xFF))
            mapBuffer.append(UInt8((count >> 8) & 0xFF))
            mapBuffer.append(UInt8(count & 0xFF))
        }
        
        // Add each key-value pair's encoded bytes
        for pair in pairs {
            mapBuffer.append(contentsOf: pair.key.encode())
            mapBuffer.append(contentsOf: pair.value.encode())
        }
        
        return .map(ArraySlice(mapBuffer))
        
    case 6: // tagged value
        // Get the tag
        let tag = try readUIntValue(additional: additional, reader: &reader)
        
        // Create a buffer to hold the encoded tagged value
        var tagBuffer: [UInt8] = []
        
        // Add the tag header byte
        tagBuffer.append(initial)
        
        // If the tag required additional bytes, add those too
        if additional >= 24 {
            // Calculate how many bytes were used for the tag
            let bytesForTag: Int
            if additional == 24 {
                bytesForTag = 1
            } else if additional == 25 {
                bytesForTag = 2
            } else if additional == 26 {
                bytesForTag = 4
            } else if additional == 27 {
                bytesForTag = 8
            } else {
                throw CBORError.invalidAdditionalInfo(additional)
            }
            
            // Go back to read the tag bytes
            let currentPos = reader.currentPosition
            try reader.seek(to: currentPos - bytesForTag)
            let tagBytes = try reader.readBytes(bytesForTag)
            tagBuffer.append(contentsOf: tagBytes)
        }
        
        // Read the tagged value
        let valueStartPos = reader.currentPosition
        let _ = try _decode(reader: &reader)
        let valueEndPos = reader.currentPosition
        
        // Get the raw bytes for the value
        try reader.seek(to: valueStartPos)
        let valueBytes = try reader.readBytes(valueEndPos - valueStartPos)
        
        return .tagged(tag, ArraySlice(valueBytes))
        
    case 7: // simple values and floats
        switch additional {
        case 20: return .bool(false)
        case 21: return .bool(true)
        case 22: return .null
        case 23: return .undefined
        case 24:
            let simple = try reader.readByte()
            return .simple(simple)
        case 25: // IEEE 754 Half-Precision Float (16 bits)
            let bits = try reader.readBigEndianInteger(UInt16.self)
            // Convert half-precision to double
            let value = convertHalfPrecisionToDouble(bits)
            return .float(value)
        case 26: // IEEE 754 Single-Precision Float (32 bits)
            let bits = try reader.readBigEndianInteger(UInt32.self)
            let float = Float(bitPattern: bits)
            return .float(Double(float))
            
        case 27: // IEEE 754 Double-Precision Float (64 bits)
            let bits = try reader.readBigEndianInteger(UInt64.self)
            let double = Double(bitPattern: bits)
            return .float(double)
        default:
            throw CBORError.invalidAdditionalInfo(additional)
        }
    default:
        throw CBORError.invalidMajorType(majorType)
    }
}

/// Converts a half-precision float (IEEE 754) to a double
///
/// - Parameter halfPrecision: The half-precision float bits
/// - Returns: The converted double value
private func convertHalfPrecisionToDouble(_ halfPrecision: UInt16) -> Double {
    let sign = (halfPrecision & 0x8000) != 0
    let exponent = Int((halfPrecision & 0x7C00) >> 10)
    let fraction = halfPrecision & 0x03FF
    
    var value: Double
    if exponent == 0 {
        // Subnormal number
        value = Double(fraction) * pow(2, -24)
    } else if exponent == 31 {
        // Infinity or NaN
        value = fraction == 0 ? Double.infinity : Double.nan
    } else {
        // Normal number
        value = Double(fraction | 0x0400) * pow(2, Double(exponent - 25))
    }
    
    return sign ? -value : value
}

/// Reads an unsigned integer value based on the additional information.
private func readUIntValue(additional: UInt8, reader: inout CBORReader) throws(CBORError) -> UInt64 {
    switch additional {
    case 0...23:
        return UInt64(additional)
    case 24:
        return UInt64(try reader.readByte())
    case 25:
        return try UInt64(reader.readBigEndianInteger(UInt16.self))
    case 26:
        return try UInt64(reader.readBigEndianInteger(UInt32.self))
    case 27:
        return try reader.readBigEndianInteger(UInt64.self)
    case 31:
        throw CBORError.indefiniteLengthNotSupported
    default:
        throw CBORError.invalidInitialByte(additional)
    }
}

// MARK: - Iterator Types

/// Memory-efficient iterator for CBOR arrays
///
/// This iterator decodes array elements on-demand without loading the entire array
/// into memory, making it ideal for Embedded Swift and memory-constrained environments.
///
/// ## Usage:
/// ```swift
/// if let iterator = try cbor.arrayIterator() {
///     var iterator = iterator
///     while let element = iterator.next() {
///         // Process element without allocating the entire array
///     }
/// }
/// ```
///
/// - Note: Use this instead of `arrayValue()` for large arrays to minimize memory usage
public struct CBORArrayIterator: IteratorProtocol {
    private var reader: CBORReader
    private let count: Int
    private var currentIndex: Int = 0
    
    init(bytes: ArraySlice<UInt8>) throws {
        // Safety check for empty bytes
        if bytes.isEmpty {
            throw CBORError.invalidData
        }
        
        // Convert ArraySlice to Array to avoid potential index issues
        let byteArray = Array(bytes)
        self.reader = CBORReader(data: byteArray)
        
        // Get the array length from the initial byte
        let initial = try reader.readByte()
        let major = initial >> 5
        let additional = initial & 0x1f
        
        // Ensure this is an array
        guard major == 4 else {
            throw CBORError.invalidData
        }
        
        // Get the array length
        let arrayCount = try readUIntValue(additional: additional, reader: &reader)
        self.count = Int(arrayCount)
    }
    
    public mutating func next() -> CBOR? {
        guard currentIndex < count else { return nil }
        
        do {
            let element = try _decode(reader: &reader)
            currentIndex += 1
            return element
        } catch {
            return nil
        }
    }
}

/// Memory-efficient iterator for CBOR maps
///
/// This iterator decodes map key-value pairs on-demand without loading the entire map
/// into memory, making it ideal for Embedded Swift and memory-constrained environments.
///
/// ## Usage:
/// ```swift
/// if let iterator = try cbor.mapIterator() {
///     var iterator = iterator
///     while let pair = iterator.next() {
///         let key = pair.key
///         let value = pair.value
///         // Process key-value pair without allocating the entire map
///     }
/// }
/// ```
///
/// - Note: Use this instead of `mapValue()` for large maps to minimize memory usage
public struct CBORMapIterator: IteratorProtocol {
    private var reader: CBORReader
    private let count: Int
    private var currentIndex: Int = 0
    
    init(bytes: ArraySlice<UInt8>) throws {
        // Safety check for empty bytes
        if bytes.isEmpty {
            throw CBORError.invalidData
        }
        
        // Convert ArraySlice to Array to avoid potential index issues
        let byteArray = Array(bytes)
        self.reader = CBORReader(data: byteArray)
        
        // Get the map length from the initial byte
        let initial = try reader.readByte()
        let major = initial >> 5
        let additional = initial & 0x1f
        
        // Ensure this is a map
        guard major == 5 else {
            throw CBORError.invalidData
        }
        
        // Get the map length
        let mapCount = try readUIntValue(additional: additional, reader: &reader)
        self.count = Int(mapCount)
    }
    
    public mutating func next() -> CBORMapPair? {
        guard currentIndex < count else { return nil }
        
        do {
            let key = try _decode(reader: &reader)
            let value = try _decode(reader: &reader)
            currentIndex += 1
            return CBORMapPair(key: key, value: value)
        } catch {
            return nil
        }
    }
}