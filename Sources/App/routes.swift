import Vapor

func routes(_ app: Application) throws { 
    let userController = UserController()
    userController.setupRoutes(app: app)
}
