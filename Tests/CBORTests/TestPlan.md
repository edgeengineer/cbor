# CBOR Edge Case Test Plan

This document outlines a plan for testing edge cases in the Swift CBOR library to ensure robustness and comprehensive coverage.

## 1. Primitive Types Edge Cases

### 1.1 Unsigned Integers (`UInt`)
- [ ] `0` (Smallest value)
- [ ] `23` (Largest value fitting in the initial byte)
- [ ] `24` (Smallest value requiring 1 extra byte)
- [ ] `255` (Largest value fitting in 1 extra byte)
- [ ] `256` (Smallest value requiring 2 extra bytes)
- [ ] `65535` (Largest value fitting in 2 extra bytes)
- [ ] `65536` (Smallest value requiring 4 extra bytes)
- [ ] `UInt32.max` (Largest value fitting in 4 extra bytes)
- [ ] `UInt32.max + 1` (Smallest value requiring 8 extra bytes)
- [ ] `UInt64.max` (Largest value fitting in 8 extra bytes)

### 1.2 Negative Integers (`Int`)
- [ ] `-1` (Smallest absolute value)
- [ ] `-24` (Largest absolute value fitting in the initial byte)
- [ ] `-25` (Smallest absolute value requiring 1 extra byte)
- [ ] `-256` (Largest absolute value fitting in 1 extra byte)
- [ ] `-257` (Smallest absolute value requiring 2 extra bytes)
- [ ] `-65536` (Largest absolute value fitting in 2 extra bytes)
- [ ] `-65537` (Smallest absolute value requiring 4 extra bytes)
- [ ] `-(UInt32.max + 1)` (Largest absolute value fitting in 4 extra bytes)
- [ ] `-(UInt32.max + 2)` (Smallest absolute value requiring 8 extra bytes)
- [ ] `Int64.min` (Smallest value, largest absolute value fitting in 8 extra bytes)

### 1.3 Byte Strings (`byteString`)
- [ ] Empty byte string (`[]`)
- [ ] Byte string with length `0` to `23`
- [ ] Byte string with length `24` (requires 1 extra byte for length)
- [ ] Byte string with length `255`
- [ ] Byte string with length `256` (requires 2 extra bytes for length)
- [ ] Byte string with length `65535`
- [ ] Byte string with length `65536` (requires 4 extra bytes for length)
- [ ] Byte string with length `UInt32.max` (if feasible memory-wise)
- [ ] Indefinite length byte string (empty, single chunk, multiple chunks)
- [ ] Malformed indefinite length byte string (missing break stop code)

### 1.4 Text Strings (`textString`)
- [ ] Empty string (`""`)
- [ ] String with length `0` to `23`
- [ ] String with length `24`
- [ ] String with length `255`
- [ ] String with length `256`
- [ ] String with length `65535`
- [ ] String with length `65536`
- [ ] String with length `UInt32.max` (if feasible memory-wise)
- [ ] Strings containing various Unicode characters (including multi-byte characters, emojis)
- [ ] Strings containing invalid UTF-8 sequences (should error)
- [ ] Indefinite length text string (empty, single chunk, multiple chunks)
- [ ] Malformed indefinite length text string (missing break stop code)
- [ ] Indefinite length text string with invalid UTF-8 chunks

### 1.5 Floating Point Numbers (`Float`, `Double`)
- [ ] `0.0`, `-0.0`
- [ ] Smallest positive/largest negative normal/subnormal numbers (Float16, Float32, Float64)
- [ ] Largest finite positive/negative numbers (Float16, Float32, Float64)
- [ ] `Infinity`, `-Infinity` (Float16, Float32, Float64)
- [ ] `NaN` (Quiet/Signaling, various payloads) (Float16, Float32, Float64)

### 1.6 Simple Values & Booleans
- [ ] `false`
- [ ] `true`
- [ ] `nil` / `null`
- [ ] `undefined`
- [ ] Simple values `0` to `19`
- [ ] Simple values `24` to `31` (Reserved/Unassigned)
- [ ] Simple values `32` to `255`

## 2. Container Types Edge Cases

### 2.1 Arrays (`array`)
- [ ] Empty array (`[]`)
- [ ] Array with length `0` to `23`
- [ ] Array with length `24`
- [ ] Array with length `255`
- [ ] Array with length `256`
- [ ] Array with length `65535`
- [ ] Array with length `65536`
- [ ] Array with length `UInt32.max` (if feasible)
- [ ] Arrays containing mixed primitive types
- [ ] Nested arrays (various depths)
- [ ] Arrays containing maps
- [ ] Indefinite length array (empty, single element, multiple elements)
- [ ] Malformed indefinite length array (missing break stop code)
- [ ] Indefinite length array containing nested indefinite structures

### 2.2 Maps (`map`)
- [ ] Empty map (`[:]`)
- [ ] Map with size `0` to `23`
- [ ] Map with size `24`
- [ ] Map with size `255`
- [ ] Map with size `256`
- [ ] Map with size `65535`
- [ ] Map with size `65536`
- [ ] Map with size `UInt32.max` (if feasible)
- [ ] Maps with keys of different primitive types (Int, String, etc.)
- [ ] Maps with values of different primitive/container types
- [ ] Nested maps (various depths)
- [ ] Maps containing arrays
- [ ] Duplicate keys (last one should win according to RFC, but check behavior)
- [ ] Indefinite length map (empty, single pair, multiple pairs)
- [ ] Malformed indefinite length map (missing break stop code, odd number of items)
- [ ] Indefinite length map containing nested indefinite structures

## 3. Tagged Values Edge Cases

- [ ] Standard date/time tag (Tag 0, Tag 1) with valid/invalid data
- [ ] Bignum tags (Tag 2, Tag 3) with empty/valid/invalid byte strings
- [ ] Decimal Fraction tag (Tag 4) with valid/invalid array structure
- [ ] Bigfloat tag (Tag 5) with valid/invalid array structure
- [ ] Expected conversion tags (Tag 21-23) with non-string/byte-string content
- [ ] URI tag (Tag 32) with valid/invalid strings
- [ ] Regex tag (Tag 35) with valid/invalid strings
- [ ] Self-described CBOR tag (Tag 55799) with valid/invalid CBOR data
- [ ] Tags with non-standard values (e.g., large tag numbers)
- [ ] Nested tagged values

## 4. Error Handling Edge Cases

- [ ] Decoding insufficient data (premature end of data)
- [ ] Decoding invalid initial byte (e.g., reserved major types/additional info)
- [ ] Decoding data with trailing garbage bytes
- [ ] Length mismatch (e.g., declared length longer than available data)
- [ ] Invalid UTF-8 in text strings
- [ ] Maximum nesting depth exceeded during decoding (if applicable)
- [ ] Integer overflow/underflow during decoding (e.g., negative integer value too large for Int64)
- [ ] Invalid simple values (reserved range)
- [ ] Invalid boolean/null encodings
- [ ] Malformed indefinite length containers/strings (missing break code, incorrect structure)

## 5. Encoding Edge Cases

- [ ] Ensure canonical encoding where applicable (e.g., shortest integer form)
- [ ] Encoding extremely large arrays/maps/strings (resource limits)
- [ ] Encoding deeply nested structures (resource limits)

