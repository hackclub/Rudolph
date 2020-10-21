//
//  File.swift
//  
//
//  Created by Linus Skucas on 10/4/20.
//

import Foundation
import Vapor

struct SlackHistoryContentResponse: Content {
    var messages: [SlackHistoryContentResponseMessages]
    enum CodingKeys: String, CodingKey {
        case messages
    }
}

struct SlackHistoryContentResponseMessages: Content {
    var text: String
    
    enum CodingKeys: String, CodingKey {
        case text
    }
}
