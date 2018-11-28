
import Foundation
import Firebase
import FirebaseDatabase
import FirebaseAuth

class FirebaseChatListHelper: ChatListDataSource {
    var delegate: ChatListDataDelegate
    let userId: String

    required init(userId: String, delegate: ChatListDataDelegate) {
        self.userId = userId
        self.delegate = delegate

        self.listenForNewMessages()
        self.listenForNewConversations()
    }

    func listenForNewMessages() {
        let messageRef = Database.database().reference().child("users").child("u_\(self.userId)").child("connections")

        messageRef.observe(.childChanged) { (snapShot) in
            if
                let lastMessage = snapShot.childSnapshot(forPath: Constants.lastMessageKey).value as? NSDictionary,
                let messageBody = lastMessage[Constants.messageBodyKey] as? String,
                let sender = lastMessage[Constants.senderKey] as? String
            {
                let convoId = snapShot.key.replacingOccurrences(of: "c_", with: "", options: .literal, range: nil)
                let message = Message(body: messageBody, senderId: "\(sender)", sentAt: Date())
                self.delegate.newMessageReceived(message, connectionId: convoId)
            }
        }
    }

    func listenForNewConversations() {
        let convoRef = Database.database().reference().child("users").child("u_\(self.userId)").child("connections")

        convoRef.observe(.childAdded) { (snapShot) in
            if
                let lastMessage = snapShot.childSnapshot(forPath: Constants.lastMessageKey).value as? NSDictionary,
                let messageBody = lastMessage[Constants.messageBodyKey] as? String,
                let sender = lastMessage[Constants.senderKey] as? String {
                    let message = Message(body: messageBody, senderId: "\(sender)", sentAt: Date())
                    let backendId = snapShot.key.replacingOccurrences(of: "c_", with: "", options: .literal, range: nil)
                    let convo = Conversation(backendId: backendId, lastMessage: message)

                    self.delegate.newConversationReceived(convo)
            }
        }
    }
}
