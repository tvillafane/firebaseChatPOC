
import Foundation
import Firebase
import FirebaseDatabase

class FirebaseChatHelper: ChatDataSource {
    var reference: DatabaseReference!

    required init(chatId: String, delegate: ChatDataDelegate) {
        self.chatId = chatId
        self.delegate = delegate

        self.reference = Database.database().reference().child("messages").child("connection_\(self.chatId)")
        self.listenForNewMessages()
    }

    deinit {
        self.reference.removeAllObservers()
    }

    var delegate: ChatDataDelegate
    var chatId: String

    func listenForNewMessages() {
        self.reference.observe(.childAdded) { (snapShot) in
            if
                let messageData = snapShot.value as? NSDictionary,
                let messageBody = messageData[Constants.messageBodyKey] as? String,
                let sender = messageData[Constants.senderKey] as? String
            {
                let message = Message(body: messageBody, senderId: "\(sender)", sentAt: Date())
                self.delegate.newChatMessage(message: message)
            }
        }
    }

    func writeMessage(body: String, completion: @escaping (Bool) -> ()) {
        let username = UserDefaults.standard.string(forKey: Constants.userNameKey)!

        let messageData = [
            Constants.senderKey: username,
            Constants.messageBodyKey: body,
            Constants.sentAtKey: "\(Int(Date().timeIntervalSince1970))"
        ]

        self.reference.childByAutoId().setValue(messageData) { (err, ref) in
            let success = err == nil
            completion(success)
        }
    }
}

