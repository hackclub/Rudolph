import CryptoSwift
import Fluent
import Vapor

let emoji = "deer"

func routes(_ app: Application) throws {
    app.post("slack", "events") { req -> String in
        guard verifySignature(for: req) else { throw Abort(.imATeapot) }
        let contentType = try req.content.decode(SlackEventType.self)

        if contentType.type == "url_verification" {
            let content = try req.content.decode(SlackEventVerification.self)
            return content.challenge
        } else if contentType.type == "event_callback" {
            // reaction added
            let event = contentType.event!
            guard event.type == "reaction_added" else { return "" }
            if event.item["channel"]! == "G01C9MTKXU1" || event.item["channel"]! == "C01504DCLVD" { // If we're in the testing or scrapbook channel TODO; Should we make this available anywhere on slack?
                guard event.reaction == emoji else { return "" } // TODO: Create custom emoji
                let slackTss = SubmittedPullRequest.query(on: req.db).all(\.$slackTs)
                slackTss.whenSuccess { tss in
                    guard !tss.contains(event.item["ts"]!) else { return }
                    // Check for a GitHub link, if it doesn't match notify
                    let pattern = #"(https|http):\/\/github\.com\/(?<owner>.*)\/(?<repo>.*)\/pull\/(?<number>\d*)"#
                    NetworkInterface.shared.getMessage(channel: event.item["channel"]!, ts: event.item["ts"]!) { message in
                        guard let message = message else { return }
                        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                        guard let match = regex?.firstMatch(in: message, options: [], range: NSRange(location: 0, length: message.utf16.count)) else {
                            NetworkInterface.shared.sendMessage(text: "Waaaa.... that doesn't look like a github link to me! Make sure you're linking the pull request!", channel: event.item["channel"]!, ts: event.item["ts"]!, completion: nil)
                            return
                        }
                        guard let ownerRange = Range(match.range(withName: "owner"), in: message),
                            let repoRange = Range(match.range(withName: "repo"), in: message),
                            let numberRange = Range(match.range(withName: "number"), in: message) else {
                            NetworkInterface.shared.sendMessage(text: "Waaaa.... that doesn't look like a github link to meeee! Make sure you're linking the pull request!", channel: event.item["channel"]!, ts: event.item["ts"]!, completion: nil)
                            return
                        }
                        let ownerSubstring = message[ownerRange]
                        let repoSubstring = message[repoRange]
                        let numberSubstring = message[numberRange]
                        // Start up the 🥁 Grand Central Dispatch
                        let queue = DispatchQueue(label: "Santa's Slay")
                        let owner = String(ownerSubstring)
                        let repo = String(repoSubstring)
                        let number = Int(numberSubstring)!
                        queue.async {
                            // post message to slack
                            NetworkInterface.shared.sendMessage(text: "Woohoo! :yay: I'm going to chew on your PR for a little while to make sure it tastes good, but if all goes well you'll get some GP!", channel: event.item["channel"]!, ts: event.item["ts"]!, completion: nil)
                            let submittedPullRequest = SubmittedPullRequest()
                            submittedPullRequest.id = UUID()
                            submittedPullRequest.slackID = event.item_user
                            submittedPullRequest.isValid = false
                            submittedPullRequest.isApproved = false
                            submittedPullRequest.githubPrOrg = owner
                            submittedPullRequest.githubPrRepoName = repo
                            submittedPullRequest.githubPrID = number
                            submittedPullRequest.slackTs = event.item["ts"]!
                            submittedPullRequest.reason = ""
                            submittedPullRequest.gpGiven = 15
                            submittedPullRequest.reviewTs = ""
                            submittedPullRequest.events = []
                            submittedPullRequest.create(on: req.db)
                            // Calculate gp
                            specialEvents.forEach { specialEvent in
                                if specialEvent.validationForPullRequest(submittedPullRequest.githubPrID, repositoryName: submittedPullRequest.githubPrRepoName, repositoryOrganization: submittedPullRequest.githubPrOrg) {
                                    submittedPullRequest.gpGiven += specialEvent.gpAdded
                                    submittedPullRequest.events?.append(specialEvent.id)
                                }
                            }
                            // Run Checks
                            NetworkInterface.shared.getPrStatus(githubOwner: owner, githubRepoName: repo, githubPrNumber: number) { githubResp in
                                guard let githubResp = githubResp else { return failWithMessage("Couldn't parse the repsitory: Are you sure it's a public Pull Request?", sendId: event.item_user) }
                                guard !githubResp.data.repository.pullRequest.labels.nodes.contains(["name": "invalid"]) && !githubResp.data.repository.pullRequest.labels.nodes.contains(["name": "spam"]) else {
                                    NetworkInterface.shared.sendMessage(text: ":rotating_light: :rotating_light: <@\(event.item_user)>'s pull request is marked as spam/invalid, go check it out! https://github.com/\(owner)/\(repo)/pull/\(number)", channel: "G01BU5Y0EAE", ts: nil, completion: nil)
                                    return failWithMessage("That pull request was marked as spam/invalid. *DO NOT* spam pull requests in order to get fake internet points.", sendId: event.item_user)
                                }
                                guard githubResp.data.repository.pullRequest.state == .merged else { return failWithMessage("That Pull Request you sent doesn't look merged! Go get it merged then come to me for gp!", sendId: event.item_user) }
                                guard githubResp.data.repository.pullRequest.author.login != owner else { return failWithMessage("oops. You can only get gp for contributing to open source projects that are outside your GitHub account!", sendId: event.item_user) }
                                submittedPullRequest.isValid = true
                                submittedPullRequest.save(on: req.db)
                                // Send to review channel
                                NetworkInterface.shared.sendMessage(text: ":carrot: :carrot: There's a new PR from <@\(event.item_user)>! :cool: Check it out: https://github.com/\(owner)/\(repo)/pull/\(number) If it looks good react with :true: , if it's :hankey:, react with :x:", channel: "G01BU5Y0EAE", ts: nil) { reviewTs in
                                    guard let reviewTs = reviewTs else { return }
                                    submittedPullRequest.reviewTs = reviewTs
                                    submittedPullRequest.save(on: req.db)
                                }
                            }
                        }
                    }
                }
            } else if event.item["channel"]! == "G01BU5Y0EAE" { // Check if we're in the review channel
                // TODO: Check if the PR is accepted based on the reaction
                let event = contentType.event!
                guard event.type == "reaction_added" else { return "" }
                // get the db entry
                let reviewingPullRequest = SubmittedPullRequest.query(on: req.db)
                    .filter(\.$reviewTs == event.item["ts"]!)
                    .first()
                reviewingPullRequest.whenSuccess { reviewingPullRequest in
                    guard let reviewingPullRequest = reviewingPullRequest else { return }
                    if event.reaction == "x" {
                        failWithMessage("Your Pull Request #\(reviewingPullRequest.githubPrID), \(reviewingPullRequest.githubPrOrg)/\(reviewingPullRequest.githubPrRepoName) was rejected. DM <@U011CFN98K1> if you have any questions.", sendId: reviewingPullRequest.slackID)
                    } else if event.reaction == "true" {
                        NetworkInterface.shared.sendGp(sendId: reviewingPullRequest.slackID, reason: "Good job, your Pull Request was accepted!", amount: reviewingPullRequest.gpGiven)
                        reviewingPullRequest.isApproved = true
                        reviewingPullRequest.save(on: req.db)
                    }
                }
            }
        }
        return ""
    }
}

func verifySignature(for request: Request) -> Bool {
    let timestamp = request.headers["X-Slack-Request-Timestamp"].first!
    let hmacConcate = "v0:\(timestamp):\(request.body.string!)"
    let key = Environment.get("SIGNING_SECRET")!
    let localSignature = "v0=\(try! HMAC(key: key, variant: .sha256).authenticate(hmacConcate.bytes).toHexString())"
    if localSignature == request.headers["X-Slack-Signature"].first! {
        return true
    } else {
        return false
    }
}

func failWithMessage(_ message: String, sendId: String) {
    NetworkInterface.shared.sendGp(sendId: sendId, reason: "Rudolph couldn't send you gp :kermit_scream: \(message)", amount: 0)
}
