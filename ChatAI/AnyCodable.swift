//
//  AnyCodable.swift
//  ChatAI
//
//  A lightweight Codable wrapper for heterogeneous values used in
//  dictionary payloads like [String: AnyCodable].
//
//  This implementation supports:
//  - null
//  - Bool
//  - Integer types (Int, Int8/16/32/64, UInt, UInt8/16/32/64)
//  - Double / Float
//  - String
//  - [AnyCodable]
//  - [String: AnyCodable]
//  - URL, Date, UUID (encoding supported; decoding will produce the raw
//    representation as emitted by the encoder’s strategies)
//

import Foundation

public struct AnyCodable: Codable, Equatable {
    public let value: Any?

    public init(_ value: Any?) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = nil
            return
        }

        // Try common primitives
        if let bool = try? container.decode(Bool.self) {
            self.value = bool
            return
        }
        if let int = try? container.decode(Int.self) {
            self.value = int
            return
        }
        if let int64 = try? container.decode(Int64.self) {
            self.value = int64
            return
        }
        if let uint64 = try? container.decode(UInt64.self) {
            self.value = uint64
            return
        }
        if let double = try? container.decode(Double.self) {
            self.value = double
            return
        }
        if let string = try? container.decode(String.self) {
            self.value = string
            return
        }

        // Arrays and dictionaries (recursive)
        if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
            return
        }
        if let dict = try? container.decode([String: AnyCodable].self) {
            var out: [String: Any?] = [:]
            for (k, v) in dict { out[k] = v.value }
            self.value = out
            return
        }

        // Fallback: attempt common Foundation types
        if let url = try? container.decode(URL.self) {
            self.value = url
            return
        }
        if let date = try? container.decode(Date.self) {
            self.value = date
            return
        }
        if let uuid = try? container.decode(UUID.self) {
            self.value = uuid
            return
        }

        // As a last resort, throw a dataCorrupted error
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported AnyCodable value")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        guard let value = self.value else {
            try container.encodeNil()
            return
        }

        switch value {
        case let v as Bool:
            try container.encode(v)
        case let v as Int:
            try container.encode(v)
        case let v as Int8:
            try container.encode(v)
        case let v as Int16:
            try container.encode(v)
        case let v as Int32:
            try container.encode(v)
        case let v as Int64:
            try container.encode(v)
        case let v as UInt:
            try container.encode(v)
        case let v as UInt8:
            try container.encode(v)
        case let v as UInt16:
            try container.encode(v)
        case let v as UInt32:
            try container.encode(v)
        case let v as UInt64:
            try container.encode(v)
        case let v as Double:
            try container.encode(v)
        case let v as Float:
            try container.encode(v)
        case let v as String:
            try container.encode(v)
        case let v as URL:
            try container.encode(v)
        case let v as Date:
            try container.encode(v)
        case let v as UUID:
            try container.encode(v)
        case let v as [Any?]:
            let wrapped = v.map { AnyCodable($0) }
            try container.encode(wrapped)
        case let v as [AnyCodable]:
            try container.encode(v)
        case let v as [String: Any?]:
            let wrapped = v.mapValues { AnyCodable($0) }
            try container.encode(wrapped)
        case let v as [String: AnyCodable]:
            try container.encode(v)
        default:
            // Attempt to encode values that are Encodable without exposing them
            // If this fails, throw a helpful error
            if let enc = value as? Encodable {
                // Box into an encoder-friendly wrapper
                try enc.encode(to: encoder)
            } else {
                let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported AnyCodable value: \(type(of: value))")
                throw EncodingError.invalidValue(value, context)
            }
        }
    }

    // MARK: - Equatable
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (nil, nil): return true
        case let (l as Bool, r as Bool): return l == r
        case let (l as Int, r as Int): return l == r
        case let (l as Int8, r as Int8): return l == r
        case let (l as Int16, r as Int16): return l == r
        case let (l as Int32, r as Int32): return l == r
        case let (l as Int64, r as Int64): return l == r
        case let (l as UInt, r as UInt): return l == r
        case let (l as UInt8, r as UInt8): return l == r
        case let (l as UInt16, r as UInt16): return l == r
        case let (l as UInt32, r as UInt32): return l == r
        case let (l as UInt64, r as UInt64): return l == r
        case let (l as Double, r as Double): return l == r
        case let (l as Float, r as Float): return l == r
        case let (l as String, r as String): return l == r
        case let (l as URL, r as URL): return l == r
        case let (l as Date, r as Date): return l == r
        case let (l as UUID, r as UUID): return l == r
        case let (l as [Any?], r as [Any?]):
            // Compare lengths then pairwise using AnyCodable wrapper
            guard l.count == r.count else { return false }
            return zip(l, r).allSatisfy { AnyCodable($0) == AnyCodable($1) }
        case let (l as [String: Any?], r as [String: Any?]):
            guard l.count == r.count else { return false }
            for (k, lv) in l {
                guard let rv = r[k], AnyCodable(lv) == AnyCodable(rv) else { return false }
            }
            return true
        default:
            // Fallback to string descriptions of types
            return String(describing: lhs.value) == String(describing: rhs.value)
        }
    }
}
