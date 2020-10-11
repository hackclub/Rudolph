//
//  File.swift
//  
//
//  Created by Linus Skucas on 9/30/20.
//

import Foundation

protocol SpecialEvent {
    var id: UUID { get }
    var name: String { get }
    var gpAdded: Int { get }

    func validationForPullRequest(_ pullRequestNumber: String, repositoryName: String, repositoryOrganization: String) -> Bool
}
