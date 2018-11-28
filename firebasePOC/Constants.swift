
import Foundation

struct Constants {
    static let userIdKey = "userId"
    static let userNameKey = "username"
    //  messages
    static let lastMessageKey = "last_message"
    static let messageBodyKey = "body"
    static let senderKey = "s_id"
    static let sentAtKey = "sent"
    static let typeKey = "type"
}

class User {
    var name: String!
    var id: Int!
}

class Message {
    var body: String!
    var senderId: String!
    var sentAt: Date!

    init(body: String, senderId: String, sentAt: Date) {
        self.body = body
        self.senderId = senderId
        self.sentAt = sentAt
    }
}

class Conversation {
    var backendId: String!
    var lastMessage: Message!

    init(backendId: String, lastMessage: Message) {
        self.backendId = backendId
        self.lastMessage = lastMessage
    }
}
