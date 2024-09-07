import Fluent
import Vapor
import struct Foundation.UUID

final class User: Model, Content, @unchecked Sendable {
    
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "username")
    var username: String

    @Field(key: "password")
    var password: String
    
    init() {}
    
    init(id: UUID? = nil, username: String, password: String) throws {
        self.id = id
        self.username = username
        self.password = try Bcrypt.hash(password)
    }
}
