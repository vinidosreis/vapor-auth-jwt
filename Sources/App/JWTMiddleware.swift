//
//  JWTMiddleware.swift
//  
//
//  Created by Vinícius dos Reis on 13/09/24.
//

import Vapor

struct JWTMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // Verifica se o header contém o token Bearer
        guard let token = request.headers.bearerAuthorization else {
            throw Abort(.unauthorized, reason: "No token provided")
        }
        
        do {
            // Tenta verificar o token JWT e obter o payload
            let payload = try request.jwt.verify(token.token, as: JWTClaims.self)
            
            // Se o token for válido, autentica o payload
            request.auth.login(payload)
            
            // Passa a requisição para o próximo middleware ou rota
            return try await next.respond(to: request)
        } catch {
            throw Abort(.unauthorized, reason: "Invalid token")
        }
    }
}
