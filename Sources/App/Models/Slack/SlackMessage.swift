//
//  File.swift
//
//
//  Created by Linus Skucas on 10/5/20.
//

import Foundation
import Vapor

struct SlackMessageResponse: Content {
    var ts: String

    enum CodingKeys: String, CodingKey {
        case ts
    }
}

class NetworkController {
    static let shared = NetworkController()

    func sendMessage(text: String, channel: String, ts: String?, completion: ((String) -> Void)?) { // TODO: FOR NICE CODE RETURN NIL
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        let url = URL(string: "https://slack.com/api/chat.postMessage")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        var bodyParameters = [
            "token": Environment.get("SLACK_TOKEN")!,
            "text": text,
            "channel": channel,
        ]
        if let ts = ts {
            bodyParameters["thread_ts"] = ts
        }
        let bodyString = bodyParameters.queryParameters
        request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)

        let task = session.dataTask(with: request, completionHandler: { (data: Data?, _: URLResponse?, error: Error?) -> Void in
            if error == nil {
                if let completion = completion {
                    let jsonDecoder = JSONDecoder()
                    completion(try! jsonDecoder.decode(SlackMessageResponse.self, from: data!).ts)
                }
            } else {
                if let completion = completion {
                    completion("")
                }
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }

    func getMessage(channel: String, ts: String, completion: @escaping (String) -> Void) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        let url = URL(string: "https://slack.com/api/conversations.history")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let bodyParameters = [
            "token": Environment.get("SLACK_TOKEN")!,
            "channel": channel,
            "limit": "1",
            "latest": ts,
            "inclusive": "true",
        ]
        let bodyString = bodyParameters.queryParameters
        request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
        let task = session.dataTask(with: request) { data, _, error in
            if error == nil {
                let jsonDecoder = JSONDecoder()
                let message = try! jsonDecoder.decode(SlackHistoryContentResponse.self, from: data!).messages.first!.text
                completion(message)
            } else {
                completion("")
            }
        }
        task.resume()
        session.finishTasksAndInvalidate()
    }
}

protocol URLQueryParameterStringConvertible {
    var queryParameters: String { get }
}

extension Dictionary: URLQueryParameterStringConvertible {
    /**
      This computed property returns a query parameters string from the given NSDictionary. For
      example, if the input is @{@"day":@"Tuesday", @"month":@"January"}, the output
      string will be @"day=Tuesday&month=January".
      @return The computed parameters string.
     */
    var queryParameters: String {
        var parts: [String] = []
        for (key, value) in self {
            let part = String(format: "%@=%@",
                              String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
                              String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            parts.append(part as String)
        }
        return parts.joined(separator: "&")
    }
}

extension URL {
    /**
      Creates a new URL by adding the given query parameters.
      @param parametersDictionary The query parameter dictionary to add.
      @return A new URL.
     */
    func appendingQueryParameters(_ parametersDictionary: Dictionary<String, String>) -> URL {
        let URLString: String = String(format: "%@?%@", absoluteString, parametersDictionary.queryParameters)
        return URL(string: URLString)!
    }
}
