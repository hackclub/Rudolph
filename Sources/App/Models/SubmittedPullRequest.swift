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
    var githubPrID: Int
    
    @Field(key: "slackTs")
    var slackTs: String

    @Field(key: "reason")
    var reason: String

    @Field(key: "gpGiven")
    var gpGiven: Int

    @OptionalField(key: "events")
    var events: [UUID]?
    
    @Field(key: "reviewTs")
    var reviewTs: String

    init() { }

    init(id: UUID? = UUID(), slackID: String, isValid: Bool, isApproved: Bool, githubPrOrg: String, githubPrRepoName: String, githubPrID: Int, slackTs: String, reason: String, gpGiven: Int, events: [UUID]?, reviewTs: String) {
        self.id = id
        self.slackID = slackID
        self.isValid = isValid
        self.isApproved = isApproved
        self.githubPrOrg = githubPrOrg
        self.githubPrRepoName = githubPrRepoName
        self.githubPrID = githubPrID
        self.slackTs = slackTs
        self.reason = reason
        self.gpGiven = gpGiven
        self.events = events
        self.reviewTs = reviewTs
    }
}

