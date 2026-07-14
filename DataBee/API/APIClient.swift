//
//  APIClient.swift
//  DataBee
//

import Foundation
import Alamofire

enum API {
    static let baseURL = "https://posapi.iconnectgroup.com/Api/"
    static let getAuthToken = "GetAuthToken"
    static let userLogin = "Wms/UserLogin"
    static let getChatMessageInfo = "Chat/getChatMessageInfo"
    static let saveChatMessageInfo = "Chat/saveChatMessageInfo"
    /// The AI query backend lives on a different host.
    static let queryURL = "https://apiai.iconnectgroup.com/api/query"
}

enum APIError: LocalizedError {
    case noInternet
    case invalidResponse
    case server(message: String)

    var errorDescription: String? {
        switch self {
        case .noInternet:
            return "No Internet Connection, Please Check Your Internet Connection."
        case .invalidResponse:
            return "Something went wrong. Please try again."
        case .server(let message):
            return message
        }
    }
}

/// Error payload the server returns inside a 200 response,
/// e.g. {"Code": -3, "Message": "Password is Incorrect!"}
private struct APIMessage: Decodable {
    let code: Int?
    let message: String

    enum CodingKeys: String, CodingKey {
        case code = "Code"
        case message = "Message"
    }
}

final class APIClient {

    static let shared = APIClient()
    private init() {}

    // MARK: - Endpoints

    /// Company authentication: exchanges the company code for a bearer token.
    func authenticateCompany(code: String) async throws -> AuthToken {
        try await request(API.getAuthToken,
                          parameters: ["grant_type": "password", "AuthCode": code],
                          encoding: URLEncoding.httpBody,
                          authorized: false)
    }

    /// User login. Requires the bearer token from `authenticateCompany`.
    func login(userName: String, password: String) async throws -> LoginUser {
        try await request(API.userLogin,
                          parameters: ["UserName": userName, "Password": password],
                          encoding: JSONEncoding.default)
    }

    /// All chats (with their messages) for a user, shown in the History menu.
    func getChatMessages(userId: String) async throws -> [ChatInfo] {
        try await request(API.getChatMessageInfo,
                          method: .get,
                          parameters: ["userId": userId],
                          encoding: URLEncoding.queryString)
    }

    /// Asks the AI backend a question. Returns the raw JSON reply string —
    /// the chat screen renders it and it is stored verbatim as the bot
    /// message's attributes, exactly like the web app does.
    func query(question: String, userId: String, chatId: Int, dbName: String) async throws -> String {
        // Verified: the AI host accepts the same bearer token as posapi.
        var headers = HTTPHeaders()
        if let token = Session.shared.accessToken {
            headers.add(.authorization(bearerToken: token))
        }
        let parameters: Parameters = ["question": question,
                                      "UserId": userId,
                                      "ChatId": chatId,
                                      "DbName": dbName]
        logRequest(url: API.queryURL, method: .post, parameters: parameters, headers: headers)

        // The AI can take a while to answer; give it a generous timeout.
        let response = await AF.request(API.queryURL,
                                        method: .post,
                                        parameters: parameters,
                                        encoding: JSONEncoding.default,
                                        headers: headers,
                                        requestModifier: { $0.timeoutInterval = 180 })
            .serializingData()
            .response

        logResponse(url: API.queryURL, response: response)

        switch response.result {
        case .failure(let afError):
            if let urlError = afError.underlyingError as? URLError,
               urlError.code == .notConnectedToInternet {
                throw APIError.noInternet
            }
            throw APIError.invalidResponse
        case .success(let data):
            guard let statusCode = response.response?.statusCode,
                  (200...299).contains(statusCode),
                  let string = String(data: data, encoding: .utf8) else {
                throw APIError.invalidResponse
            }
            return string
        }
    }

    /// Persists one chat message (user question or bot reply) on the server.
    func saveChatMessage(chatId: Int, userId: String, messageContent: String, attributes: String) async throws {
        var headers = HTTPHeaders()
        if let token = Session.shared.accessToken {
            headers.add(.authorization(bearerToken: token))
        }
        let parameters: Parameters = ["chatId": chatId,
                                      "userId": userId,
                                      "messageContent": messageContent,
                                      "attributes": attributes]
        let url = API.baseURL + API.saveChatMessageInfo
        logRequest(url: url, method: .post, parameters: parameters, headers: headers)

        let response = await AF.request(url,
                                        method: .post,
                                        parameters: parameters,
                                        encoding: JSONEncoding.default,
                                        headers: headers,
                                        requestModifier: { $0.timeoutInterval = 30 })
            .serializingData()
            .response

        logResponse(url: url, response: response)

        guard case .success = response.result,
              let statusCode = response.response?.statusCode,
              (200...299).contains(statusCode) else {
            throw APIError.invalidResponse
        }
    }

    // MARK: - Request

    private func request<T: Decodable>(_ path: String,
                                       method: HTTPMethod = .post,
                                       parameters: Parameters,
                                       encoding: ParameterEncoding,
                                       authorized: Bool = true,
                                       allowTokenRefresh: Bool = true) async throws -> T {
        var headers = HTTPHeaders()
        if authorized, let token = Session.shared.accessToken {
            headers.add(.authorization(bearerToken: token))
        }

        logRequest(url: API.baseURL + path, method: method, parameters: parameters, headers: headers)

        let response = await AF.request(API.baseURL + path,
                                        method: method,
                                        parameters: parameters,
                                        encoding: encoding,
                                        headers: headers,
                                        requestModifier: { $0.timeoutInterval = 30 })
            .serializingData()
            .response

        logResponse(url: API.baseURL + path, response: response)

        switch response.result {
        case .failure(let afError):
            if let urlError = afError.underlyingError as? URLError,
               urlError.code == .notConnectedToInternet {
                throw APIError.noInternet
            }
            throw APIError.invalidResponse

        case .success(let data):
            guard let statusCode = response.response?.statusCode else {
                throw APIError.invalidResponse
            }

            let decoder = JSONDecoder()

            guard (200...299).contains(statusCode) else {
                // The bearer token has an expiry; re-authenticate with the saved
                // company code once and retry, so a relaunched app keeps working.
                if statusCode == 401, authorized, allowTokenRefresh,
                   let companyCode = Session.shared.companyCode,
                   let token = try? await authenticateCompany(code: companyCode) {
                    Session.shared.accessToken = token.accessToken
                    return try await request(path,
                                             method: method,
                                             parameters: parameters,
                                             encoding: encoding,
                                             authorized: authorized,
                                             allowTokenRefresh: false)
                }
                if let apiMessage = try? decoder.decode(APIMessage.self, from: data) {
                    throw APIError.server(message: apiMessage.message)
                }
                throw APIError.invalidResponse
            }

            if let value = try? decoder.decode(T.self, from: data) {
                return value
            }
            // A 200 response can still carry an error payload.
            if let apiMessage = try? decoder.decode(APIMessage.self, from: data) {
                throw APIError.server(message: apiMessage.message)
            }
            throw APIError.invalidResponse
        }
    }

    // MARK: - Logging

    private func logRequest(url: String, method: HTTPMethod, parameters: Parameters, headers: HTTPHeaders) {
        print("""

        ┌─────────────────── API REQUEST ───────────────────
        │ URL: \(url)
        │ Method: \(method.rawValue)
        │ Headers: \(headers.isEmpty ? "[:]" : headers.dictionary.description)
        │ Params: \(parameters)
        └───────────────────────────────────────────────────
        """)
    }

    /// Bodies above this size are logged truncated — pretty-printing and
    /// dumping megabytes to the console stalls the app for seconds in debug.
    private static let logBodyLimit = 4096

    private func logResponse(url: String, response: DataResponse<Data, AFError>) {
        let statusCode = response.response?.statusCode.description ?? "N/A"
        var body = "N/A"
        if let data = response.data {
            if data.count > Self.logBodyLimit {
                let preview = String(data: data.prefix(Self.logBodyLimit), encoding: .utf8) ?? ""
                body = preview + "\n… <truncated, full response is \(data.count) bytes>"
            } else if let json = try? JSONSerialization.jsonObject(with: data),
                      let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
                      let string = String(data: pretty, encoding: .utf8) {
                body = string
            } else {
                body = String(data: data, encoding: .utf8) ?? "<non-text response, \(data.count) bytes>"
            }
        }
        if case .failure(let error) = response.result {
            body += "\nError: \(error.localizedDescription)"
        }
        print("""

        ┌─────────────────── API RESPONSE ──────────────────
        │ URL: \(url)
        │ Status Code: \(statusCode)
        │ Response: \(body)
        └───────────────────────────────────────────────────
        """)
    }
}
