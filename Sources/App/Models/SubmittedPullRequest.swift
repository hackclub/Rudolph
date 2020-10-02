import Fluent
import Vapor

final class SubmittedPullRequest: Model, Content {
    static let schema = "submittedpullrequest"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "slackID")
    var slackID: String

    @Field(key: "isValid")
    var isValid: Bool

    @Field(key: "isApproved")
    var isApproved: Bool
    
    @Field(key: "githubPrOrg")
    var githubPrOrg: String
    
    @Field(key: "githubPrRepoName")
    var githubPrRepoName: String
    
    @Field(key: "githubPrID")
    var githubPrID: String

    @Field(key: "reason")
    var reason: String

    @Field(key: "gpGiven")
    var gpGiven: Int

    @OptionalField(key: "events")
    var events: [UUID]?

    init() { }

    init(id: UUID? = nil, slackID: String, isValid: Bool, isApproved: Bool, url: URL, reason: String, gpGiven: Int, events: [UUID]?, githubPrID: String, githubPrOrg: String, githubPrRepoName: String) {
        self.id = id
        self.slackID = slackID
        self.isValid = isValid
        self.isApproved = isApproved
        self.reason = reason
        self.gpGiven = gpGiven
        self.events = events
        self.githubPrID = githubPrID
        self.githubPrOrg = githubPrOrg
        self.githubPrRepoName = githubPrRepoName
    }
}

