import SwiftSyntax

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

extension Endpoint {
    static func parse(_ function: FunctionDeclSyntax) throws -> Endpoint? {
        guard let (method, path, pathParameters, options) = parseMethodAndPath(function) else {
            return nil
        }

        return Endpoint(
            method: method,
            path: path,
            pathParameters: pathParameters,
            options: options,
            name: function.functionName,
            parameters: function.parameters.compactMap {
                EndpointParameter($0, httpMethod: method, pathParameters: pathParameters)
            },
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

        return (method, path, path.pathParameters, options)
    }
}

extension String {
    fileprivate var pathParameters: [String] {
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
