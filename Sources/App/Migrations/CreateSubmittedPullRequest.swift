import Fluent

struct CreateSubmittedPullRequest: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("submittedpullrequest")
            .id()
            .field("slackID", .string, .required)
            .field("isValid", .bool, .required)
            .field("isApproved", .bool, .required)
            .field("githubPrOrg", .string, .required)
            .field("githubPrRepoName", .string, .required)
            .field("githubPrID", .int, .required)
            .field("reason", .string, .required)
            .field("gpGiven", .int, .required)
            .field("events", .array(of: .makeOptionalType(.string)), .required)
            .field("slackTs", .string, .required)
            .field("reviewTs", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("submittedpullrequest").delete()
    }
}
