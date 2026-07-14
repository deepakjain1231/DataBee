//
//  Models.swift
//  DataBee
//

import Foundation

// MARK: - Company Authentication (GetAuthToken)

struct AuthToken: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let name: String
    let isFurnServe: String?
    let posURL: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case name = "Name"
        case isFurnServe = "IsFurnServe"
        case posURL = "Pos_Url"
    }
}

// MARK: - User Login (Wms/UserLogin)

struct LoginUser: Codable {
    let contactID: String
    let name: String
    let role: String?
    let salesPersonID: String?
    let gsm: String?
    let emailID: String?
    let stores: [Store]
    let companies: [Company]
    let regionStores: [RegionStore]
    let regions: [Region]

    enum CodingKeys: String, CodingKey {
        case contactID = "ContactID"
        case name = "Name"
        case role = "Role"
        case salesPersonID = "SalesPersonID"
        case gsm = "GSM"
        case emailID = "EmailID"
        case stores = "Stores"
        case companies = "Companies"
        case regionStores = "RegionStores"
        case regions = "Regions"
    }
}

struct Store: Codable {
    let storeName: String
    let storeID: String
    let companyID: String

    enum CodingKeys: String, CodingKey {
        case storeName = "StoreName"
        case storeID = "StoreID"
        case companyID = "CompanyID"
    }
}

struct Company: Codable {
    let companyName: String
    let companyID: String

    enum CodingKeys: String, CodingKey {
        case companyName = "CompanyName"
        case companyID = "CompanyID"
    }
}

struct RegionStore: Codable {
    let companyID: String
    let centerName: String
    let centerID: String
    let regionID: String
    let regionName: String

    enum CodingKeys: String, CodingKey {
        case companyID = "CompanyID"
        case centerName = "CenterName"
        case centerID = "CenterID"
        case regionID = "RegionID"
        case regionName = "RegionName"
    }
}

struct Region: Codable {
    let regionName: String
    let regionID: String

    enum CodingKeys: String, CodingKey {
        case regionName = "RegionName"
        case regionID = "RegionID"
    }
}

// MARK: - Chat (Chat/getChatMessageInfo)

struct ChatInfo: Codable {
    let chatId: Int
    let chatContent: String
    let messages: [ChatMessage]

    enum CodingKeys: String, CodingKey {
        case chatId = "ChatId"
        case chatContent = "Chat_Content"
        case messages = "Messages"
    }

    /// Title shown in the History list: the chat content if present,
    /// otherwise the first non-empty message, otherwise a fallback.
    var title: String {
        let content = chatContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if !content.isEmpty { return content }
        if let first = messages.first(where: { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            return first.content
        }
        return "Chat \(chatId)"
    }
}

struct ChatMessage: Codable {
    let messageId: Int
    let content: String
    let attributes: String

    enum CodingKeys: String, CodingKey {
        case messageId = "MessageId"
        case content = "Content"
        case attributes = "Attributes"
    }
}
