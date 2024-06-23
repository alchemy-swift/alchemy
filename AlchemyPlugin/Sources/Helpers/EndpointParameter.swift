import SwiftSyntax

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
