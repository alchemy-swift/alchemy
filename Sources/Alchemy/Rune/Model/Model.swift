import Foundation
import NIO

public protocol Model: DatabaseCodable, RelationAllowed { }
