/// Given a `Codable` swift object, what is the best way to abstract the database storing, loading, schema
/// creation, schema migration?

/// Idea 1: Put the storing and loading inside a custom `Decoder` & `Encoder`. IBM seems to do it here & here
/// https://github.com/IBM-Swift/Swift-Kuery-ORM/blob/master/Sources/SwiftKueryORM/DatabaseDecoder.swift
/// https://github.com/IBM-Swift/Swift-Kuery-ORM/blob/master/Sources/SwiftKueryORM/DatabaseEncoder.swift
