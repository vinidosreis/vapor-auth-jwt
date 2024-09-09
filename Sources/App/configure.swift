import FluentPostgresDriver
import Vapor

public func configure(_ app: Application) async throws {
    
    app.jwt.signers.use(.hs256(key: "your-secret-key"), kid: "your-key-id")
    
    app.databases.use(.postgres(configuration: .init(
        hostname: "localhost",
        username: "postgres",
        database: "authdb",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)
    
    app.migrations.add(CreateUser())

    try await app.autoMigrate().get()
    
    try routes(app)
}
