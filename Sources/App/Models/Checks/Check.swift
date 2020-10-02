//
//  File.swift
//  
//
//  Created by Linus Skucas on 10/1/20.
//

import Foundation

protocol Check {
    var id: UUID { get }
    var name: String { get }

    func validationForPullRequest(_ pullRequestId: String, repositoryName: String, repositoryOrganization: String) -> Bool
}
