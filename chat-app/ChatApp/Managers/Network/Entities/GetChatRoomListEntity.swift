//
//  GetChatroomListEntity.swift
//  ChatApp
//
//  Created by Ramon Jr Bahio on 8/19/24.
//

import Foundation

class GetChatRoomListEntity: RequestableApiEntity {
    typealias ResponseEntity = GetChatRoomListRespondableEntity

    static var method: BaseNetworkOperation.Method { .get }
    var path: String { "rooms?device_id=\(AppConstant.shared.deviceId ?? "")" }
}


// MARK: Defining response
struct GetChatRoomListRespondableEntity: RespondableApiEntity {
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    var success: Int
    var error: ErrorMessage?
    var chatRooms: [ChatRoomEntity]
}

struct ChatRoomEntity: Codable {
    var roomId: Int
    var authorId: String
    var authorName: String
    var preview: String
    var isJoined: Bool
    var currentRoomUserId: Int?
    var hasPassword: Bool
    var chatName: String
    var chatImageUrl: String
    var memberDetails: [MemberDetailEntity]
}

struct MemberDetailEntity: Codable {
    var name: String
    var isAdmin: Bool
    var userImageUrl: String
    var roomUserId: Int
}
