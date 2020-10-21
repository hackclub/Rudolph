//
// NetworkInterface.swift
//
// Adapted from SlackKit: http://github.com/pvzig/SlackKit
//
// Copyright © 2017 Peter Zignego. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
#if os(Linux)
    import Dispatch
#endif
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif
import Foundation
import Vapor

public struct NetworkInterface {
    static let shared = NetworkInterface()

    private let badApiUrl = "https://slack.com/api/"
    private let catApiUrl = "https://api.github.com/graphql"
    #if canImport(FoundationNetworking)
        private let session = FoundationNetworking.URLSession(configuration: .default)
    #else
        private let session = URLSession(configuration: .default)
    #endif

    func sendMessage(text: String, channel: String, ts: String?, completion: ((String?) -> Void)?) {
        var parameters = ["token": Environment.get("SLACK_TOKEN")!, "text": text, "channel": channel]
        if let ts = ts {
            parameters["thread_ts"] = ts
        }
        guard let url = requestURL(for: "chat.postMessage", parameters: parameters) else {
            return
        }
        let request = URLRequest(url: url)

        session.dataTask(with: request) { data, _, publicError in
            guard publicError == nil else {
                if let completion = completion {
                    completion(nil)
                }
                return
            }
            if let completion = completion {
                let jsonDecoder = JSONDecoder()
                completion(try! jsonDecoder.decode(SlackMessageResponse.self, from: data!).ts)
            }
        }.resume()
    }

    func getMessage(channel: String, ts: String, completion: @escaping (String?) -> Void) {
        let parameters = ["token": Environment.get("SLACK_TOKEN")!, "channel": channel, "latest": ts, "limit": "1", "inclusive": "true"]
        guard let url = requestURL(for: "conversations.history", parameters: parameters) else {
            return
        }
        let request = URLRequest(url: url)

        session.dataTask(with: request) { data, _, publicError in
            guard publicError == nil else {
                completion(nil)
                return
            }
            let jsonDecoder = JSONDecoder()
            completion(try! jsonDecoder.decode(SlackHistoryContentResponse.self, from: data!).messages.first!.text)

        }.resume()
    }

    func getPrStatus(githubOwner: String, githubRepoName: String, githubPrNumber: Int, completion: @escaping (GithubLabelsResponse?) -> Void) {
        let query = "{\"query\": \"query{repository(name:\\\"\(githubRepoName)\\\",owner:\\\"\(githubOwner)\\\"){pullRequest(number:\(githubPrNumber)){state author{login}labels(first:10){nodes{name}}}}}\"}" // This is me being mean to your eyes
        let url = URL(string: "\(catApiUrl)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("bearer \(Environment.get("GITHUBAPI_TOKEN")!)", forHTTPHeaderField: "Authorization")
        request.httpBody = query.data(using: .utf8, allowLossyConversion: true)
        session.dataTask(with: request) { data, _, error in
            guard error == nil else {
                completion(nil)
                return
            }
            let jsonDecoder = JSONDecoder()
            completion(try? jsonDecoder.decode(GithubLabelsResponse.self, from: data!))
        }.resume()
    }

    func sendGp(sendId: String, reason: String, amount: Int) {
        let url = URL(string: "https://bankerapi.glitch.me/give")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let bodyObject: [String: Any] = [
            "send_id": sendId,
            "reason": reason,
            "gp": amount,
            "token": Environment.get("BANKER_TOKEN")!,
            "bot_id": "U01C6M4TFUZ",
        ]
        request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        session.dataTask(with: request, completionHandler: { (data: Data?, _: URLResponse?, error: Error?) -> Void in
            let dataString = String(data: data!, encoding: .utf8)!
            if error != nil || dataString != "OK" {
                NetworkInterface.shared.sendMessage(text: ":skull-ios: I couldn't send gp to <@\(sendId)>. They were supposed to get \(amount), for \(reason). :hankey: The error was \(error?.localizedDescription ?? "no error") and the data was \(dataString) :roblox_oof:", channel: "G01BU5Y0EAE", ts: nil, completion: nil)
            }
        }).resume()
    }

    internal init() {}

    private func requestURL(for endpoint: String, parameters: [String: Any?]) -> URL? {
        var components = URLComponents(string: "\(badApiUrl)\(endpoint)")
        if parameters.count > 0 {
            components?.queryItems = parameters.compactMapValues({ $0 }).map { URLQueryItem(name: $0.0, value: "\($0.1)") }
        }

        // As discussed http://www.openradar.me/24076063 and https://stackoverflow.com/a/37314144/407523, Apple considers
        // a + and ? as valid characters in a URL query string, but Slack has recently started enforcing that they be
        // encoded when included in a query string. As a result, we need to manually apply the encoding after Apple's
        // default encoding is applied.
        var encodedQuery = components?.percentEncodedQuery
        encodedQuery = encodedQuery?.replacingOccurrences(of: ">", with: "%3E")
        encodedQuery = encodedQuery?.replacingOccurrences(of: "<", with: "%3C")
        encodedQuery = encodedQuery?.replacingOccurrences(of: "@", with: "%40")

        encodedQuery = encodedQuery?.replacingOccurrences(of: "?", with: "%3F")
        encodedQuery = encodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        components?.percentEncodedQuery = encodedQuery

        return components?.url
    }
}
