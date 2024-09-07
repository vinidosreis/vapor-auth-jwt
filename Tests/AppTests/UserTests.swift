//
//  UserTests.swift
//
//
//  Created by Vinícius dos Reis on 06/09/24.
//

import XCTest
import XCTVapor
@testable import App

final class UserTests: XCTestCase {
    
    var app: Application!
    
    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        try await configure(app)
        try await app.autoMigrate()
    }
    
    override func tearDown() async throws {
        try await app.autoRevert()
        try await self.app.asyncShutdown()
        self.app = nil
    }
    
    func testRegisterUser() async throws {
        try await self.app.test(.POST, "register", beforeRequest: { req async in
            let user = try! User(username: "testuser", password: "password123")
            try! req.content.encode(user)
        }, afterResponse: { res in
            // Verificar o status de resposta
            XCTAssertEqual(res.status, .created)

            // Verificar o corpo da resposta como texto simples, caso seja essa a resposta
            let responseBody = res.body.string
            XCTAssertEqual(responseBody, "User registered")
        })
    }
    
    func testDeleteUser() async throws {
            // Primeiro, registre um usuário para garantir que há um usuário a ser deletado
            let user = try! User(username: "testuser", password: try Bcrypt.hash("password123"))
            try await user.create(on: app.db)

            // Agora, envie uma requisição DELETE para a rota de deleção
            try await app.test(.DELETE, "delete/testuser", afterResponse: { res async in
                XCTAssertEqual(res.status, .ok) // Verifica se o status é 200 OK
                let responseBody = try? res.content.decode(String.self)
                XCTAssertEqual(responseBody, "User testuser deleted") // Verifica a mensagem de sucesso
            })
        }
}
