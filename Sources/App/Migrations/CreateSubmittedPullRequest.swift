import Fluent

struct CreateSubmittedPullRequest: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("submittedpullrequest")
            .id()
            .field("slackID", .string, .required)
            .field("isValid", .bool, .required)
            .field("isApproved", .bool, .required)
            .field("url", .data, .required)
            .field("githubPrID", .string, .required)
            .field("reason", .string, .required)
            .field("gpGiven", .int, .required)
            .field("events", .array(of: .string), .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("submittedpullrequest").delete()
    }
}
