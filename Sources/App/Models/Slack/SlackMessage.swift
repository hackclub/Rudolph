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

struct SlackMessageResponse: Content {
    var ts: String

    enum CodingKeys: String, CodingKey {
        case ts
    }
}

public struct NetworkInterface {
    static let shared = NetworkInterface()

    private let badApiUrl = "https://slack.com/api/"
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
