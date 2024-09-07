import Vapor
import Fluent
import Crypto

final class UserController: Sendable {
    
    func setupRoutes(app: Application) {
            app.post("register", use: register)
            app.post("login", use: login)
            app.delete("delete", ":username", use: deleteUser)
        }
    
    @Sendable
    private func register(req: Request) async throws -> Response {
        let user = try req.content.decode(User.self) //let or var?

        // Hash da senha antes de salvar o usuário
        user.password = try Bcrypt.hash(user.password)
        
        try await user.create(on: req.db)
        
        let response = Response(status: .created)
        response.body = .init(string: "User registered")
        response.headers.replaceOrAdd(name: .contentType, value: "text/plain")
        
        return response
    }
    
    @Sendable
    func login(req: Request) async throws -> Response {
        let loginData = try req.content.decode(LoginData.self)

        guard let user = try await User.query(on: req.db)
                .filter(\.$username == loginData.username)
                .first(),
              try Bcrypt.verify(loginData.password, created: user.password) else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }

        // Definindo a data de expiração (por exemplo, 1 hora a partir do momento atual)
        let expirationTime = Date().addingTimeInterval(3600) // 1 hora (3600 segundos)

        // Gerando o token JWT com a expiração
        let claims = JWTClaims(username: user.username, exp: .init(value: expirationTime))
        let token = try req.jwt.sign(claims)

        let response = Response(status: .ok)
        response.body = .init(string: token)
        response.headers.replaceOrAdd(name: .contentType, value: "text/plain")

        return response
    }
    
    @Sendable
    func deleteUser(req: Request) async throws -> Response {
            guard let username = req.parameters.get("username") else {
                throw Abort(.badRequest, reason: "Username parameter is missing")
            }

            guard let user = try await User.query(on: req.db)
                    .filter(\.$username == username)
                    .first() else {
                throw Abort(.notFound, reason: "User not found")
            }

            try await user.delete(on: req.db)

            let response = Response(status: .ok)
            response.body = .init(string: "User \(username) deleted")
            response.headers.replaceOrAdd(name: .contentType, value: "text/plain")

            return response
        }
}
