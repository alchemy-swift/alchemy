import Foundation
import SwiftSyntax

struct Routes {
    struct Route {
        /// Attributes to be applied to this endpoint. These take precedence
        /// over attributes at the API scope.
        let method: String
        let path: String
        let pathParameters: [String]
        /// The name of the function defining this endpoint.
        let name: String
        let parameters: [EndpointParameter]
        let isAsync: Bool
        let isThrows: Bool
        let responseType: String?
    }

    /// The name of the type defining the API.
    let name: String
    /// Attributes to be applied to every endpoint of this API.
    let routes: [Route]
}

extension Routes {
    static func parse(_ decl: some DeclSyntaxProtocol) throws -> Routes {
        guard let type = decl.as(StructDeclSyntax.self) else {
            throw AlchemyMacroError("@Routes must be applied to structs for now")
        }

        return Routes(
            name: type.name.text,
            routes: try type.functions.compactMap( { try parse($0) })
        )
    }

    private static func parse(_ function: FunctionDeclSyntax) throws -> Routes.Route? {
        guard let (method, path, pathParameters) = parseMethodAndPath(function) else {
            return nil
        }

        return Routes.Route(
            method: method,
            path: path,
            pathParameters: pathParameters,
            name: function.functionName,
            parameters: try function.parameters.compactMap {
                EndpointParameter($0, httpMethod: method, pathParameters: pathParameters)
            }.validated(),
            isAsync: function.isAsync,
            isThrows: function.isThrows,
            responseType: function.returnType
        )
    }

    private static func parseMethodAndPath(
        _ function: FunctionDeclSyntax
    ) -> (method: String, path: String, pathParameters: [String])? {
        var method, path: String?
        for attribute in function.functionAttributes {
            if case let .argumentList(list) = attribute.arguments {
                let name = attribute.attributeName.trimmedDescription
                switch name {
                case "GET", "DELETE", "PATCH", "POST", "PUT", "OPTIONS", "HEAD", "TRACE", "CONNECT":
                    method = name
                    path = list.first?.expression.description.withoutQuotes
                case "HTTP":
                    method = list.first?.expression.description.withoutQuotes
                    path = list.dropFirst().first?.expression.description.withoutQuotes
                default:
                    continue
                }
            }
        }

        guard let method, let path else {
            return nil
        }

        return (method, path, path.papyrusPathParameters)
    }
}

extension Routes.Route {
    var functionSignature: String {
        let parameters = parameters.map {
            let name = [$0.label, $0.name]
                .compactMap { $0 }
                .joined(separator: " ")
            return "\(name): \($0.type)"
        }

        let returnType = responseType.map { " -> \($0)" } ?? ""
        return parameters.joined(separator: ", ").inParentheses + " async throws" + returnType
    }
}

extension [EndpointParameter] {
    fileprivate func validated() throws -> [EndpointParameter] {
        let bodies = filter { $0.kind == .body }
        let fields = filter { $0.kind == .field }

        guard fields.count == 0 || bodies.count == 0 else {
            throw AlchemyMacroError("Can't have Body and Field!")
        }

        guard bodies.count <= 1 else {
            throw AlchemyMacroError("Can only have one Body!")
        }

        return self
    }
}

/// Parsed from function parameters; indicates parts of the request.
struct EndpointParameter {
    enum Kind {
        case body
        case field
        case query
        case header
        case path
    }

    let label: String?
    let name: String
    let type: String
    let kind: Kind

    init(_ parameter: FunctionParameterSyntax, httpMethod: String, pathParameters: [String]) {
        self.label = parameter.label
        self.name = parameter.name
        self.type = parameter.typeName
        self.kind =
            if type.hasPrefix("Path<") {
                .path
            } else if type.hasPrefix("Body<") {
                .body
            } else if type.hasPrefix("Header<") {
                .header
            } else if type.hasPrefix("Field<") {
                .field
            } else if type.hasPrefix("Query<") {
                .query
            } else if pathParameters.contains(name) {
                // if name matches a path param, infer this belongs in path
                .path
            } else if ["GET", "HEAD", "DELETE"].contains(httpMethod) {
                // if method is GET, HEAD, DELETE, infer query
                .query
            } else {
                // otherwise infer it's a body field
                .field
            }
    }
}

extension StructDeclSyntax {
    var functions: [FunctionDeclSyntax] {
        memberBlock
            .members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
    }
}

extension ProtocolDeclSyntax {
    var protocolName: String {
        name.text
    }

    var access: String? {
        modifiers.first?.trimmedDescription
    }

    var functions: [FunctionDeclSyntax] {
        memberBlock
            .members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
    }

    var protocolAttributes: [AttributeSyntax] {
        attributes.compactMap { $0.as(AttributeSyntax.self) }
    }
}

extension FunctionDeclSyntax {

    // MARK: Function effects & attributes

    var functionName: String {
        name.text
    }

    var effects: [String] {
        [signature.effectSpecifiers?.asyncSpecifier, signature.effectSpecifiers?.throwsSpecifier]
            .compactMap { $0 }
            .map { $0.text }
    }

    var parameters: [FunctionParameterSyntax] {
        signature
            .parameterClause
            .parameters
            .compactMap { FunctionParameterSyntax($0) }
    }

    var functionAttributes: [AttributeSyntax] {
        attributes.compactMap { $0.as(AttributeSyntax.self) }
    }

    // MARK: Return Data

    var returnsResponse: Bool {
        returnType == "Response"
    }

    var returnType: String? {
        signature.returnClause?.type.trimmedDescription
    }

    var returnsVoid: Bool {
        guard let returnType else {
            return true
        }

        return returnType == "Void"
    }
}

extension FunctionParameterSyntax {
    var label: String? {
        secondName != nil ? firstName.text : nil
    }

    var name: String {
        (secondName ?? firstName).text
    }

    var typeName: String {
        trimmed.type.description
    }
}

extension AttributeSyntax {
    var name: String {
        attributeName.trimmedDescription
    }

    var labeledArguments: [(label: String?, value: String)] {
        guard case let .argumentList(list) = arguments else {
            return []
        }

        return list.map {
            ($0.label?.text, $0.expression.description)
        }
    }
}

extension String {
    var withoutQuotes: String {
        filter { $0 != "\"" }
    }

    var inQuotes: String {
        "\"\(self)\""
    }

    var inParentheses: String {
        "(\(self))"
    }

    var papyrusPathParameters: [String] {
        components(separatedBy: "/").compactMap(\.extractParameter)
    }

    private var extractParameter: String? {
        if hasPrefix(":") {
            String(dropFirst())
        } else if hasPrefix("{") && hasSuffix("}") {
            String(dropFirst().dropLast())
        } else {
            nil
        }
    }
}
