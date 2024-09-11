import Vapor
import Fluent
import Crypto

final class UserController: Sendable {
    
    func setupRoutes(app: Application) {
        app.post("register", use: register)
        app.post("login", use: login)
        app.delete("delete", use: deleteUser)
    }
    
    @Sendable
    private func register(req: Request) async throws -> Response {
        let user = try req.content.decode(User.self)

        user.password = try hashPassword(user.password)
        
        try await user.create(on: req.db)
        
        return  jsonResponse(status: .created, message: "User registred")
    }
    
    @Sendable
    func login(req: Request) async throws -> Response {
        let loginData = try req.content.decode(LoginData.self)

        guard let user = try await User.query(on: req.db)
                .filter(\.$username == loginData.username)
                .first(),
              try verifyPassword(loginData.password, against: user.password) else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }
        
        let token = try createJWTToken(for: user, req: req)
        
        return  jsonResponse(status: .ok, message: token)
    }
    
    @Sendable
    func deleteUser(req: Request) async throws -> Response {
        let loginData = try req.content.decode(LoginData.self)

        guard let user = try await User.query(on: req.db)
                .filter(\.$username == loginData.username)
                .first(),
              try Bcrypt.verify(loginData.password, created: user.password) else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }

        try await user.delete(on: req.db)

        return jsonResponse(status: .ok, message: "User \(loginData.username) deleted")
    }

    private func createJWTToken(for user: User, req: Request) throws -> String {
        let expirationTime = Date().addingTimeInterval(3600) // 1 hora
        let claims = JWTClaims(username: user.username, exp: .init(value: expirationTime))
        
        return try req.jwt.sign(claims)
    }

    private func hashPassword(_ password: String) throws -> String {
        try Bcrypt.hash(password)
    }

    private func verifyPassword(_ password: String, against hashed: String) throws -> Bool {
        try Bcrypt.verify(password, created: hashed)
    }

    private func jsonResponse(status: HTTPResponseStatus, message: String) -> Response {
        let response = Response(status: status)
        let jsonBody: [String: String] = ["token": message]
        let jsonData: Data
        
        do {
            jsonData = try JSONEncoder().encode(jsonBody)
        } catch {
            jsonData = Data()
        }
        
        response.body = .init(data: jsonData)
        response.headers.replaceOrAdd(name: .contentType, value: "application/json")
        
        return response
    }
}
