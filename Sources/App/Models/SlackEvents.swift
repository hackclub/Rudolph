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
    
    enum CodingKeys: String, CodingKey {
        case type
        case token
    }
}

struct SlackEventVerification: Content {
    var challenge: String
    
    enum CodingKeys: String, CodingKey {
        case challenge
    }
}
