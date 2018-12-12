
import Foundation
import Firebase

struct Constants {
    static let userIdKey = "userId"
    static let userNameKey = "username"

    static let lastMessageKey = "last_message"
    static let lastSyncKey = "last_sync"
    static let messagesKey = "messages"
}

class User {
    var name: String!
    var id: Int!
}

class Message {
    var sentAt: Int!
    var body: String!
    var type: String!
    var senderId: String!
    var firId: String!

    //  for adding to the convo
    static let bodyKey = "body"
    static let senderKey = "s_id"
    static let sentAtKey = "sent"
    static let typeKey = "type"

    //  this is used when the user is writing a message so the service will set the sender id
    init(body: String) {
        self.body = body
        self.type = "string"
        self.sentAt = Int(Date().timeIntervalSince1970)
    }

    init?(data: NSDictionary) {
        guard let body = data[Message.bodyKey] as? String,
            let senderId = data[Message.senderKey] as? String,
            let type = data[Message.typeKey] as? String,
            let sentAt = data[Message.sentAtKey] as? Int else {
                print("failed to init message", data)
                return nil
        }

        self.body = body
        self.senderId = senderId
        self.sentAt = sentAt
        self.type = type
    }

    init?(snapShot: DataSnapshot) {
        guard let data = snapShot.value as? NSDictionary,
            let body = data[Message.bodyKey] as? String,
            let senderId = data[Message.senderKey] as? String,
            let type = data[Message.typeKey] as? String,
            let sentAt = data[Message.sentAtKey] as? Int else {
                print("failed to init message here", snapShot.value as! NSDictionary)
                return nil
        }

        self.body = body
        self.senderId = senderId
        self.sentAt = sentAt
        self.type = type
    }

    var firData: NSDictionary {
        get {
            return [
                Message.bodyKey: self.body,
                Message.senderKey : self.senderId,
                Message.sentAtKey: self.sentAt,
                Message.typeKey: self.type
            ]
        }
    }
}

class Conversation {
    var backendId: String!
    var lastMessage: Message!
    var messages: [Message] = []
    var lastSync: Int!

    init(backendId: String) {
        self.backendId = backendId
    }

    init(backendId: String, lastMessage: Message) {
        self.backendId = backendId
        self.lastMessage = lastMessage
    }

    init(_ cacheData: NSDictionary, id: String) {
        guard let lastSync = cacheData[Constants.lastSyncKey] as? Int,
            let messages = cacheData[Constants.messagesKey] as? NSDictionary
        else {
            fatalError()
        }

        self.lastSync = lastSync

        for (messageId, messageData) in messages {
            guard let data = messageData as? NSDictionary,
                let message = Message(data: data)
            else {
                print("we are fucked")
                continue
            }

            message.firId = messageId as! String
            self.messages.append(message)
        }

        self.lastMessage = self.messages.last!
    }
}
