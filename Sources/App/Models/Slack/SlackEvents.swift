//
//  File.swift
//  
//
//  Created by Linus Skucas on 10/3/20.
//

import Vapor

struct SlackEventType: Content {
    var type: String
    var token: String
    var event: SlackEventReactionAdded? = nil  // todo: support other events
    
    enum CodingKeys: String, CodingKey {
        case type
        case token
        case event
    }
}

struct SlackEventVerification: Content {
    var challenge: String
    
    enum CodingKeys: String, CodingKey {
        case challenge
    }
}


struct SlackEventReactionAdded: Content {
    var item_user: String
    var reaction: String
    var item: [String: String]
    var type: String
    
    enum CodingKeys: String, CodingKey {
        case item_user
        case reaction
        case item
        case type
    }
}
