import Foundation
import SwiftSyntax

struct Routes {
    struct Endpoint {
        /// Attributes to be applied to this endpoint. These take precedence
        /// over attributes at the API scope.
        let method: String
        let path: String
        let pathParameters: [String]
        let options: String?
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
    let endpoints: [Endpoint]
}

extension Routes {
    static func parse(_ decl: some DeclSyntaxProtocol) throws -> Routes {
        guard let type = decl.as(StructDeclSyntax.self) else {
            throw AlchemyMacroError("@Routes must be applied to structs for now")
        }

        return Routes(
            name: type.name.text,
            endpoints: try type.functions.compactMap( { try Endpoint.parse($0) })
        )
    }
}

extension Routes.Endpoint {
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

    static func parse(_ function: FunctionDeclSyntax) throws -> Routes.Endpoint? {
        guard let (method, path, pathParameters, options) = parseMethodAndPath(function) else {
            return nil
        }

        return Routes.Endpoint(
            method: method,
            path: path,
            pathParameters: pathParameters,
            options: options,
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
    ) -> (method: String, path: String, pathParameters: [String], options: String?)? {
        var method, path, options: String?
        for attribute in function.functionAttributes {
            if case let .argumentList(list) = attribute.arguments {
                let name = attribute.attributeName.trimmedDescription
                switch name {
                case "GET", "DELETE", "PATCH", "POST", "PUT", "OPTIONS", "HEAD", "TRACE", "CONNECT":
                    method = name
                    path = list.first?.expression.description.withoutQuotes
                    options = list.dropFirst().first?.expression.description.withoutQuotes
                case "HTTP":
                    method = list.first.map { "RAW(value: \($0.expression.description))" }
                    path = list.dropFirst().first?.expression.description.withoutQuotes
                    options = list.dropFirst().dropFirst().first?.expression.description.withoutQuotes
                default:
                    continue
                }
            }
        }

        guard let method, let path else {
            return nil
        }

        return (method, path, path.papyrusPathParameters, options)
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
    let validation: String?

    init(_ parameter: FunctionParameterSyntax, httpMethod: String, pathParameters: [String]) {
        self.label = parameter.label
        self.name = parameter.name
        self.type = parameter.typeName
        self.validation = parameter.parameterAttributes
            .first { $0.name == "Validate" }
            .map { $0.trimmedDescription }

        let attributeNames = parameter.parameterAttributes.map(\.name)
        self.kind =
            if attributeNames.contains("Path") { .path }
            else if attributeNames.contains("Body") { .body }
            else if attributeNames.contains("Header") { .header }
            else if attributeNames.contains("Field") { .field }
            else if attributeNames.contains("URLQuery") { .query }
            // if name matches a path param, infer this belongs in path
            else if pathParameters.contains(name) { .path }
            // if method is GET, HEAD, DELETE, infer query
            else if ["GET", "HEAD", "DELETE"].contains(httpMethod) { .query }
            // otherwise infer it's a body field
            else { .field }
    }
}

extension StructDeclSyntax {
    var functions: [FunctionDeclSyntax] {
        memberBlock
            .members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
    }
}

extension FunctionDeclSyntax {

    // MARK: Function effects & attributes

    var functionName: String {
        name.text
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

    var returnType: String? {
        signature.returnClause?.type.trimmedDescription
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
        trimmed.type.trimmedDescription
    }

    var parameterAttributes: [AttributeSyntax] {
        attributes.compactMap { $0.as(AttributeSyntax.self) }
    }
}

extension AttributeSyntax {
    var name: String {
        attributeName.trimmedDescription
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
