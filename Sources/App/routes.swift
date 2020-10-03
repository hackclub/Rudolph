import Fluent
import Vapor

func routes(_ app: Application) throws {

    app.post("slack", "events") { req -> String in
        let contentType = try req.content.decode(SlackEventType.self)
        guard contentType.token == Environment.get("VERIFICATION_TOKEN") else { throw Abort(.imATeapot) }
        if contentType.type == "url_verification" {
            let content = try req.content.decode(SlackEventVerification.self)
            return content.challenge
        } else if contentType.type == "reaction_added" {
            // reaction added
            return ""
        } else {
            return ""
        }
    }
}
