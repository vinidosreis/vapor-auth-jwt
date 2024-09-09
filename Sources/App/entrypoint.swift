import Vapor
import Logging

@main
enum Entrypoint {
    
    static func main() async throws {
        let env = try Environment.detect()
        let app = try await Application.make(env)

        do {
            try await configure(app)
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        
        try await app.execute()
        try await app.asyncShutdown()
    }
}
