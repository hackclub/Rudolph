import Foundation
import Vapor

struct SlackMessageResponse: Content {
    var ts: String

    enum CodingKeys: String, CodingKey {
        case ts
    }
}
