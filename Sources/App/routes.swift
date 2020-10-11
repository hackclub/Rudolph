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
            guard event.reaction == emoji else { return "" } // TODO: Create custom emoji
            guard event.item["channel"]! == "G01C9MTKXU1" || event.item["channel"]! == "C01504DCLVD" else { return "" } // If we're in the testing or scrapbook channel TODO; Should we make this available anywhere on slack?
            let slackTss = SubmittedPullRequest.query(on: req.db).all(\.$slackTs)
            slackTss.whenSuccess { tss in
                guard !tss.contains(event.item["ts"]!) else { return }
                // Check for a GitHub link, if it doesn't match notify
                let pattern = #"(https|http):\/\/github\.com\/(?<owner>.*)\/(?<repo>.*)\/pull\/(?<number>\d*)"# // TODO: refactor networking out
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
                    let owner = message[ownerRange]
                    let repo = message[repoRange]
                    let number = message[numberRange]
                    // Start up the 🥁 Grand Central Dispatch
                    let queue = DispatchQueue(label: "Santa's Slay")
                    queue.async {
                        // post message to slack
                        NetworkInterface.shared.sendMessage(text: "Woohoo! :yay: I'm going to chew on your PR for a little while to make sure it tastes good, but if all goes well you'll get some GP!", channel: event.item["channel"]!, ts: event.item["ts"]!, completion: nil)
                        let submittedPullRequest = SubmittedPullRequest()
                        submittedPullRequest.id = UUID()
                        submittedPullRequest.slackID = event.item_user
                        submittedPullRequest.isValid = false
                        submittedPullRequest.isApproved = false
                        submittedPullRequest.githubPrOrg = String(owner)
                        submittedPullRequest.githubPrRepoName = String(repo)
                        submittedPullRequest.githubPrID = String(number)
                        submittedPullRequest.slackTs = event.item["ts"]!
                        submittedPullRequest.reason = ""
                        submittedPullRequest.gpGiven = 15
                        submittedPullRequest.events = []
                        let creation = submittedPullRequest.create(on: req.db)
                        // TODO: Calculate gp
                        specialEvents.forEach { specialEvent in
                            if specialEvent.validationForPullRequest(submittedPullRequest.githubPrID, repositoryName: submittedPullRequest.githubPrRepoName, repositoryOrganization: submittedPullRequest.githubPrOrg) {
                                submittedPullRequest.gpGiven += specialEvent.gpAdded
                                    submittedPullRequest.events?.append(specialEvent.id)
                            }
                        }
//                      let creation = submittedPullRequest.create(on: req.db)
                        submittedPullRequest.create(on: req.db)
                        // TODO: Run Checks
                        // TODO: Send to review channel
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
