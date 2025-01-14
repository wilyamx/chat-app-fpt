//
//  LoginEntity.swift
//  ChatApp
//
//  Created by Niño Castorico on 9/9/24.
//

import Foundation

class LoginEntity: RequestableApiEntity {
    typealias ResponseEntity = LoginRespondableEntity

    static var method: BaseNetworkOperation.Method { .post }

    var path: String { "login" }
    var isIgnoreAccessTokenError: Bool { ignoreError }
    var isIgnoreLogoutErrors: Bool { ignoreError }
    var body: RequestBody? {
        LoginBody(username: username, password: password, deviceId: deviceId, deviceName: deviceName)
    }
    private var ignoreError: Bool { false }
    private let username: String
    private let password: String
    private let deviceId: String
    private let deviceName: String

    init(username: String, password: String, deviceId: String, deviceName: String) {
        self.username = username
        self.password = password
        self.deviceId = deviceId
        self.deviceName = deviceName
    }
}

struct LoginBody : RequestJsonBody {
    var encoder: JSONEncoder { JSONEncoder.snakeCaseEncoder() }

    let username: String
    let password: String
    let deviceId: String
    let deviceName: String
}

struct LoginRespondableEntity: RespondableApiEntity {
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    var accessToken: String?
    var refreshToken: String?
    var success: Int
    var error: ErrorMessage?
    var info: LoginInfoEntity?
}

struct LoginInfoEntity: Codable {
    var displayName: String
    var username: String
    var imageUrl: String?
}
