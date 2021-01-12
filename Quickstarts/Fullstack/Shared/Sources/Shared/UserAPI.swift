import Papyrus

public final class UserAPI: EndpointGroup {
    @GET("/user")
    public var getUser: Endpoint<Empty, UserDTO>
    
    @GET("/user/tag")
    public var getTags: Endpoint<Empty, [TagDTO]>
    
    @POST("/user/tag")
    public var createTag: Endpoint<TagCreateRequest, TagDTO>
    
    @POST("/logout")
    public var logout: Endpoint<Empty, Empty>
}

extension UserAPI {
    
    // MARK: - UserAPI Requests
    
    /// Request data for creating a new tag.
    public struct TagCreateRequest: EndpointRequest {
        public struct DTO: Codable {
            public let name: String
            public let color: TagDTO.Color
            
            public init(name: String, color: TagDTO.Color) {
                self.name = name
                self.color = color
            }
        }
        
        @Body
        public var dto: DTO
        
        public init(dto: DTO) {
            self.dto = dto
        }
    }
    
    // MARK: - UserAPI DTOs
    
    /// A user.
    public struct UserDTO: Codable, Identifiable {
        public let id: Int
        public let name: String
        public let email: String
        
        public init(id: Int, name: String, email: String) {
            self.id = id
            self.name = name
            self.email = email
        }
    }
    
    /// A tag.
    public struct TagDTO: Codable, Identifiable {
        public enum Color: Int, Codable {
            case red, green, blue, orange, purple
        }
        
        public let id: Int
        public let name: String
        public let color: Color
        
        public init(id: Int, name: String, color: Color) {
            self.id = id
            self.name = name
            self.color = color
        }
    }
}
