//
//  JWTClaimsTests.swift
//  
//
//  Created by Vinícius dos Reis on 08/09/24.
//

import XCTest
import XCTVapor
import JWTKit
@testable import App

final class JWTClaimsTests: XCTestCase {

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

    func testJWTTokenGenerationAndVerification() throws {
        // Dados do token
        let username = "testuser"
        let expirationTime = Date().addingTimeInterval(3600) // Expira em 1 hora

        // Criação dos claims
        let claims = JWTClaims(username: username, exp: .init(value: expirationTime))

        // Geração do token
        let token = try self.app.jwt.signers.sign(claims)

        // Verifique se o token foi gerado
        XCTAssertNotNil(token)

        // Decodificação e verificação do token
        let decodedClaims = try self.app.jwt.signers.verify(token, as: JWTClaims.self)

        // Verifica se os dados do token são corretos
        XCTAssertEqual(decodedClaims.username, username)
        
        // Verifica se o token ainda é válido
        XCTAssertNoThrow(try decodedClaims.verify(using: self.app.jwt.signers.get()!))
    }

    func testJWTTokenExpiration() throws {
        // Dados do token
        let username = "testuser"
        
        // Definir o tempo de expiração para 2 segundos no futuro
        let expirationTime = Date().addingTimeInterval(1) // Expira em 2 segundos

        // Criação dos claims
        let claims = JWTClaims(username: username, exp: .init(value: expirationTime))

        // Geração do token
        let token = try self.app.jwt.signers.sign(claims)

        // Verifique se o token foi gerado
        XCTAssertNotNil(token)

        // Decodificação e verificação do token
        let decodedClaims = try self.app.jwt.signers.verify(token, as: JWTClaims.self)

        // Verifica se os dados do token são corretos
        XCTAssertEqual(decodedClaims.username, username)
        
        // Verifica se o token ainda é válido
        XCTAssertNoThrow(try decodedClaims.verify(using: self.app.jwt.signers.get()!))

        // Espera até o token expirar (mais de 2 segundos)
        sleep(2)

        // Tentativa de verificar o token novamente, o que deve falhar agora, pois está expirado
        XCTAssertThrowsError(try self.app.jwt.signers.verify(token, as: JWTClaims.self)) { error in
            // Checa se o erro é do tipo JWTError.claimVerificationFailure
            if let jwtError = error as? JWTError {
                switch jwtError {
                case .claimVerificationFailure(let name, let reason):
                    XCTAssertEqual(name, "exp")
                    XCTAssertEqual(reason, "expired")
                default:
                    XCTFail("Erro inesperado: \(jwtError)")
                }
            } else {
                XCTFail("Erro inesperado: \(error)")
            }
        }
    }
}

