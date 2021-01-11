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
    
    public struct TagCreateRequest: EndpointRequest {
        /// A DTO containing info needed for creating a tag.
        public struct DTO: Codable {
            public let name: String
            public let color: TagDTO.Color
            
            public init(name: String, color: TagDTO.Color) {
                self.name = name
                self.color = color
            }
        }
        
        @Body
        var dto: DTO
        
        public init(dto: DTO) {
            self.dto = dto
        }
    }
    
    // MARK: - UserAPI DTOs
    
    public struct UserDTO: Codable {
        public let id: Int
        public let name: String
        public let email: String
        
        public init(id: Int, name: String, email: String) {
            self.id = id
            self.name = name
            self.email = email
        }
    }
    
    public struct TagDTO: Codable {
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
