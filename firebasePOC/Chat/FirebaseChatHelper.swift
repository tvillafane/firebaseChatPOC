
import Foundation
import Firebase
import FirebaseDatabase
import FirebaseAuth

class FirebaseChatHelper: ChatDataSource {
    var messageQuery: DatabaseQuery?

    var lastSyncedAt: Int! {
        didSet {
            self.listenForNewMessages()
        }
    }

    var delegate: ChatDataDelegate
    var chatId: String

    required init(chatId: String, delegate: ChatDataDelegate) {
        self.chatId = chatId
        self.delegate = delegate
    }

    deinit {
        self.messageQuery?.removeAllObservers()
    }

    func syncConversation(chatId: String, timestamp: Int? = nil, completion: @escaping (Conversation) -> ()) {
        //  get the whole fking thing
        if let data = UserDefaults.standard.dictionary(forKey: chatId) {
            let convo = Conversation(data as NSDictionary, id: chatId)
            completion(convo)
            self.lastSyncedAt = convo.lastMessage.sentAt
        } else { //  get the whole fucking thing
             Database.database().reference().child("connections").child("\(self.chatId)/messages").observeSingleEvent(of: .value) { (snapShot) in
                let convo = Conversation(backendId: chatId)
                let currentTimestamp = Int(Date().timeIntervalSince1970)
                let messages = NSMutableDictionary()

                let convoDict: NSMutableDictionary = [
                    Constants.lastSyncKey: currentTimestamp,
                    Constants.messagesKey: messages
                ]

                convo.lastSync = currentTimestamp

                for childSnap in snapShot.children {
                    if let snap = childSnap as? DataSnapshot, let message = Message(snapShot: snap) {
                        convo.messages.append(message)
                        messages[snap.key] = snap.value as! NSDictionary
                    }
                }

                UserDefaults.standard.set(convoDict, forKey: self.chatId)
                completion(convo)
                self.lastSyncedAt = Int(Date().timeIntervalSince1970)
            }
        }
    }

    func listenForNewMessages() {
        let ref = Database.database().reference().child("connections").child("\(self.chatId)/messages")

        if (self.messageQuery == nil) {
            self.messageQuery = ref.queryOrdered(byChild: Message.sentAtKey).queryStarting(atValue: self.lastSyncedAt, childKey: Message.sentAtKey)
        }

        self.messageQuery!.observe(.childAdded) { (snapShot) in
            guard let message = Message(snapShot: snapShot) else {
                print("ish wasn't parsed well")
                return
            }

            let chat = UserDefaults.standard.dictionary(forKey: self.chatId)! as NSDictionary
            let convoDict = chat.mutableCopy() as! NSMutableDictionary

            let messages = (convoDict[Constants.messagesKey]! as! NSDictionary).mutableCopy() as! NSMutableDictionary
            messages.setValue(snapShot.value, forKey: snapShot.key)
            convoDict.setValue(messages, forKey: Constants.messagesKey)

            UserDefaults.standard.set(convoDict, forKey: self.chatId)
            self.delegate.newChatMessage(message: message)
        }
    }

    func writeMessage(body: String, completion: @escaping (Bool) -> ()) {
        let senderId = UserDefaults.standard.string(forKey: Constants.userIdKey)!

        let messageData: NSDictionary = [
            Message.senderKey: "u_\(senderId)",
            Message.bodyKey: body,
            Message.sentAtKey: Int(Date().timeIntervalSince1970),
            Message.typeKey: "string"
        ]

        let convoRef = Database.database().reference().child("connections").child("\(self.chatId)/messages")
        
        convoRef.childByAutoId().setValue(messageData) { (err, ref) in
            let success = err == nil
            completion(success)
        }
    }
}

