import Foundation
import SwiftSyntax

struct EndpointGroup {
    /// The name of the type defining the API.
    let name: String
    /// Attributes to be applied to every endpoint of this API.
    let endpoints: [Endpoint]
}

extension EndpointGroup {
    static func parse(_ decl: some DeclSyntaxProtocol) throws -> EndpointGroup {
        guard let type = decl.as(StructDeclSyntax.self) else {
            throw AlchemyMacroError("@Routes must be applied to structs for now")
        }

        return EndpointGroup(
            name: type.name.text,
            endpoints: try type.functions.compactMap( { try Endpoint.parse($0) })
        )
    }
}
