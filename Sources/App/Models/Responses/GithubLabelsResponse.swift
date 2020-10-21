//
//  File.swift
//
// TODO: This is pretty dirty, could someone clean it up?
//
//  Created by Linus Skucas on 10/15/20.
//

import Foundation

struct GithubLabelsResponse: Decodable {
    let data: GithubLabelsRepoResponse
}

struct GithubLabelsRepoResponse: Decodable {
    let repository: GithubLabelsPrResponse
}

struct GithubLabelsPrResponse: Decodable {
    let pullRequest: GithubLabelsPrContentResponse
}

struct GithubLabelsPrContentResponse: Decodable {
    let state: GithubLabelsPrState
    let labels: GithubLabelsPrLabelsResponse
    let author: GithubLabelsPrAuthorResponse
}

struct GithubLabelsPrAuthorResponse: Decodable {
    let login: String
}

struct GithubLabelsPrLabelsResponse: Decodable {
    let nodes: [[String: String]?]
}

enum GithubLabelsPrState: String, Decodable {
    case merged = "MERGED"
    case open = "OPEN"
    case closed = "CLOSED"
}
