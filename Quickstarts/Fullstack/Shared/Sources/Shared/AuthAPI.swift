import Papyrus

public final class AuthAPI: EndpointGroup {
    @POST("/signup")
    public var signup: Endpoint<SignupRequest, TokenDTO>
    
    @POST("/login")
    public var login: Endpoint<LoginRequest, TokenDTO>
}

extension AuthAPI {
    
    // MARK: - AuthAPI Requests

    /// Request data for creating a new user.
    public struct SignupRequest: EndpointRequest {
        public struct DTO: Codable {
            public let name: String
            public let email: String
            public let password: String
            
            public init(name: String, email: String, password: String) {
                self.name = name
                self.email = email
                self.password = password
            }
        }
        
        @Body
        public var dto: DTO
        
        public init(_ dto: DTO) {
            self.dto = dto
        }
    }
    
    /// Request data for logging in.
    public struct LoginRequest: EndpointRequest {
        public struct DTO: Codable {
            public let email: String
            public let password: String
            
            public init(email: String, password: String) {
                self.email = email
                self.password = password
            }
        }
        
        @Body
        public var dto: DTO
        
        public init(dto: DTO) {
            self.dto = dto
        }
    }
    
    // MARK: - AuthAPI DTOs
    
    /// An auth token to include in an "Authorization: Bearer ..."
    /// header.
    public struct TokenDTO: Codable {
        public let value: String
        
        public init(value: String) {
            self.value = value
        }
    }
}
