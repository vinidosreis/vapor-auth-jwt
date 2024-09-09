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
        app = try await Application.make(.testing)
        try await configure(app)
        try await app.autoMigrate()
    }
    
    override func tearDown() async throws {
        try await app.autoRevert()
        try await app.asyncShutdown()
        app = nil
    }
    
    func testRegisterUser() async throws {
        try await app.test(.POST, "register", beforeRequest: { req async in
            let user = try! User(username: "testuser", password: "password123")
            
            try! req.content.encode(user)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .created)
            
            let responseBody = res.body.string
            XCTAssertEqual(responseBody, "message: User registred")
        })
    }
    
    func testLogin() async throws {
        let user = try! User(username: "testuser", password: "")
        let loginData = LoginData(username: "testuser", password: "")
        
        try await user.save(on: app.db)
        
        try await app.test(.POST, "login", beforeRequest: { req async in
            try! req.content.encode(loginData)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok, "Login should be successful")
            
            let token = res.body.string
            XCTAssertNotNil(token, "Token should be returned upon successful login")
        })
    }
    
    func testLoginWithInvalidcredentials() async throws {
        let user = try! User(username: "testuser", password: "")
        let loginData = LoginData(username: "wronguser", password: "")
        
        try await user.save(on: app.db)
        
        try await app.test(.POST, "login", beforeRequest: { req async in
            try! req.content.encode(loginData)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .unauthorized, "Login should be unauthorized")
        })
    }
    
    func testDeleteUser() async throws {
        let user = try! User(username: "testuser", password: "password123")
        
        try await user.create(on: app.db)
        
        try await app.test(.DELETE, "delete/testuser", afterResponse: { res async in
            XCTAssertEqual(res.status, .ok)
        })
    }
    
    func testDeleteUserWithWrongUsername() async throws {
        let user = try! User(username: "testuser", password: "password123")
        
        try await user.create(on: app.db)
        
        try await app.test(.DELETE, "delete/wronguser", afterResponse: { res async in
            XCTAssertEqual(res.status, .notFound)
        })
    }
}
