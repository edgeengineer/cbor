import Testing
#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif
@testable import CBOR

struct CBORCodableTests {
    // MARK: - Test Structs
    
    struct Person: Codable, Equatable {
        let name: String
        let age: Int
        let email: String?
        let isActive: Bool
        
        static func == (lhs: Person, rhs: Person) -> Bool {
            return lhs.name == rhs.name &&
                   lhs.age == rhs.age &&
                   lhs.email == rhs.email &&
                   lhs.isActive == rhs.isActive
        }
    }
    
    struct Team: Codable, Equatable {
        let name: String
        let members: [Person]
        let founded: Date
        let website: URL?
        let data: Data
        
        static func == (lhs: Team, rhs: Team) -> Bool {
            return lhs.name == rhs.name &&
                   lhs.members == rhs.members &&
                   abs(lhs.founded.timeIntervalSince(rhs.founded)) < 0.001 && // Allow small floating point differences
                   lhs.website == rhs.website &&
                   lhs.data == rhs.data
        }
    }
    
    enum Status: String, Codable, Equatable {
        case active
        case inactive
        case pending
    }
    
    struct Project: Codable, Equatable {
        let id: Int
        let name: String
        let status: Status
        let team: Team?
        
        static func == (lhs: Project, rhs: Project) -> Bool {
            return lhs.id == rhs.id &&
                   lhs.name == rhs.name &&
                   lhs.status == rhs.status &&
                   lhs.team == rhs.team
        }
    }
    
    // MARK: - Basic Codable Tests
    
    @Test
    func testEncodeDecode() throws {
        let person = Person(name: "John Doe", age: 30, email: "john@example.com", isActive: true)
        
        // Encode
        let encoder = CBOREncoder()
        let data = try encoder.encode(person)
        
        // Decode
        let decoder = CBORDecoder()
        let decodedPerson = try decoder.decode(Person.self, from: data)
        
        // Verify
        #expect(decodedPerson == person)
    }
    
    @Test
    func testEncodeDecodeWithNil() throws {
        let person = Person(name: "Jane Doe", age: 25, email: nil, isActive: false)
        
        // Encode
        let encoder = CBOREncoder()
        let data = try encoder.encode(person)
        
        // Decode
        let decoder = CBORDecoder()
        let decodedPerson = try decoder.decode(Person.self, from: data)
        
        // Verify
        #expect(decodedPerson == person)
        #expect(decodedPerson.email == nil)
    }
    
    // MARK: - Complex Codable Tests
    
    @Test
    func testEncodeDecodeComplex() throws {
        let person1 = Person(name: "Alice", age: 28, email: "alice@example.com", isActive: true)
        let person2 = Person(name: "Bob", age: 32, email: nil, isActive: false)
        
        let team = Team(
            name: "Development",
            members: [person1, person2],
            founded: Date(timeIntervalSince1970: 1609459200), // 2021-01-01
            website: URL(string: "https://example.com"),
            data: Data([0x01, 0x02, 0x03, 0x04])
        )
        
        // Encode
        let encoder = CBOREncoder()
        let data = try encoder.encode(team)
        
        // Decode
        let decoder = CBORDecoder()
        let decodedTeam = try decoder.decode(Team.self, from: data)
        
        // Verify
        #expect(decodedTeam == team)
        #expect(decodedTeam.members.count == 2)
        #expect(decodedTeam.members[0] == person1)
        #expect(decodedTeam.members[1] == person2)
        #expect(decodedTeam.website?.absoluteString == "https://example.com")
        #expect(decodedTeam.data == Data([0x01, 0x02, 0x03, 0x04]))
    }
    
    @Test
    func testEncodeDecodeEnum() throws {
        let project = Project(
            id: 123,
            name: "CBOR Library",
            status: .active,
            team: nil
        )
        
        // Encode
        let encoder = CBOREncoder()
        let data = try encoder.encode(project)
        
        // Decode
        let decoder = CBORDecoder()
        let decodedProject = try decoder.decode(Project.self, from: data)
        
        // Verify
        #expect(decodedProject == project)
        #expect(decodedProject.status == .active)
        #expect(decodedProject.team == nil)
    }
    
    @Test
    func testEncodeDecodeFullProject() throws {
        let person1 = Person(name: "Alice", age: 28, email: "alice@example.com", isActive: true)
        let person2 = Person(name: "Bob", age: 32, email: nil, isActive: false)
        
        let team = Team(
            name: "Development",
            members: [person1, person2],
            founded: Date(timeIntervalSince1970: 1609459200), // 2021-01-01
            website: URL(string: "https://example.com"),
            data: Data([0x01, 0x02, 0x03, 0x04])
        )
        
        let project = Project(
            id: 123,
            name: "CBOR Library",
            status: .active,
            team: team
        )
        
        // Encode
        let encoder = CBOREncoder()
        let data = try encoder.encode(project)
        
        // Decode
        let decoder = CBORDecoder()
        let decodedProject = try decoder.decode(Project.self, from: data)
        
        // Verify
        #expect(decodedProject == project)
        #expect(decodedProject.status == .active)
        #expect(decodedProject.team != nil)
        #expect(decodedProject.team?.members.count == 2)
    }
    
    // MARK: - Array and Dictionary Tests
    
    @Test
    func testEncodeDecodeArray() throws {
        let people = [
            Person(name: "Alice", age: 28, email: "alice@example.com", isActive: true),
            Person(name: "Bob", age: 32, email: nil, isActive: false),
            Person(name: "Charlie", age: 45, email: "charlie@example.com", isActive: true)
        ]
        
        // Encode
        let encoder = CBOREncoder()
        let data = try encoder.encode(people)
        
        // Decode
        let decoder = CBORDecoder()
        let decodedPeople = try decoder.decode([Person].self, from: data)
        
        // Verify
        #expect(decodedPeople.count == people.count)
        for (index, person) in people.enumerated() {
            #expect(decodedPeople[index] == person)
        }
    }
    
    @Test
    func testEncodeDecodeDictionary() throws {
        let peopleDict: [String: Person] = [
            "alice": Person(name: "Alice", age: 28, email: "alice@example.com", isActive: true),
            "bob": Person(name: "Bob", age: 32, email: nil, isActive: false),
            "charlie": Person(name: "Charlie", age: 45, email: "charlie@example.com", isActive: true)
        ]
        
        // Encode
        let encoder = CBOREncoder()
        let data = try encoder.encode(peopleDict)
        
        // Decode
        let decoder = CBORDecoder()
        let decodedPeopleDict = try decoder.decode([String: Person].self, from: data)
        
        // Verify
        #expect(decodedPeopleDict.count == peopleDict.count)
        for (key, person) in peopleDict {
            #expect(decodedPeopleDict[key] == person)
        }
    }
    
    // MARK: - Primitive Type Tests
    
    @Test
    func testEncodeDecodePrimitives() throws {
        // Test Int
        do {
            let value = 42
            let encoder = CBOREncoder()
            let data = try encoder.encode(value)
            let decoder = CBORDecoder()
            let decodedValue = try decoder.decode(Int.self, from: data)
            #expect(decodedValue == value)
        }
        
        // Test String
        do {
            let value = "Hello, CBOR!"
            let encoder = CBOREncoder()
            let data = try encoder.encode(value)
            let decoder = CBORDecoder()
            let decodedValue = try decoder.decode(String.self, from: data)
            #expect(decodedValue == value)
        }
        
        // Test Bool
        do {
            let value = true
            let encoder = CBOREncoder()
            let data = try encoder.encode(value)
            let decoder = CBORDecoder()
            let decodedValue = try decoder.decode(Bool.self, from: data)
            #expect(decodedValue == value)
        }
        
        // Test Double
        do {
            let value = 3.14159
            let encoder = CBOREncoder()
            let data = try encoder.encode(value)
            let decoder = CBORDecoder()
            let decodedValue = try decoder.decode(Double.self, from: data)
            #expect(decodedValue == value)
        }
        
        // Test Data
        do {
            let value = Data([0x01, 0x02, 0x03, 0x04, 0x05])
            let encoder = CBOREncoder()
            let data = try encoder.encode(value)
            print("Encoded Data: \(data.map { String(format: "%02X", $0) }.joined(separator: " "))")
            
            // Decode the raw CBOR to see what's being encoded
            let rawCBOR = try CBOR.decode([UInt8](data))
            print("Raw CBOR: \(rawCBOR)")
            
            let decoder = CBORDecoder()
            
            // Try to decode as [Int] to see what's happening
            do {
                let arrayValue = try decoder.decode([Int].self, from: data)
                print("Decoded as [Int] array: \(arrayValue)")
            } catch {
                print("Failed to decode as [Int] array: \(error)")
            }
            
            let decodedValue = try decoder.decode(Data.self, from: data)
            #expect(decodedValue == value)
        }
        
        // Test Date
        do {
            let value = Date(timeIntervalSince1970: 1609459200) // 2021-01-01
            let encoder = CBOREncoder()
            let data = try encoder.encode(value)
            let decoder = CBORDecoder()
            let decodedValue = try decoder.decode(Date.self, from: data)
            #expect(abs(decodedValue.timeIntervalSince1970 - value.timeIntervalSince1970) < 0.001)
        }
        
        // Test URL
        do {
            let value = URL(string: "https://example.com/path?query=value")!
            let encoder = CBOREncoder()
            let data = try encoder.encode(value)
            let decoder = CBORDecoder()
            let decodedValue = try decoder.decode(URL.self, from: data)
            #expect(decodedValue == value)
        }
    }
    
    // MARK: - Error Tests
    
    @Test
    func testDecodingErrors() throws {
        // Test decoding wrong type
        do {
            let person = Person(name: "John Doe", age: 30, email: "john@example.com", isActive: true)
            let encoder = CBOREncoder()
            let data = try encoder.encode(person)
            
            let decoder = CBORDecoder()
            #expect(throws: DecodingError.self) {
                try decoder.decode(Team.self, from: data)
            }
        }
        
        // Test decoding invalid data
        do {
            let invalidData = Data([0xFF, 0xFF, 0xFF]) // Invalid CBOR data
            let decoder = CBORDecoder()
            #expect(throws: CBORError.self) {
                try decoder.decode(Person.self, from: invalidData)
            }
        }
    }
}
