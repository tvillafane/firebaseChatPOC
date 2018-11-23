

import UIKit
import FirebaseDatabase


protocol ChatListDataSource {
    init (userId: String, delegate: ChatListDataDelegate)
    var delegate: ChatListDataDelegate { get }
}

protocol ChatListDataDelegate {
    func newMessageReceived(_ message: Message, connectionId: String)
    func newConversationReceived(_ convo: Conversation)
}

class ChatsTableViewController: UITableViewController, ChatListDataDelegate {
    var dataSource: ChatListDataSource!
    var conversations: [Conversation] = []

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Your chats"
        self.navigationItem.hidesBackButton = true

        self.tableView.tableFooterView = UIView()
        let userId = UserDefaults.standard.string(forKey: Constants.userIdKey)
        self.dataSource = FirebaseChatListHelper(userId: userId!, delegate: self)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.conversations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell", for: indexPath) as! ChatsTableViewCell
        let convo = self.conversations[indexPath.row]

        cell.bodyLabel.text = convo.lastMessage.body
        cell.senderLabel.text = convo.lastMessage.senderId

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "ShowChat", sender: indexPath.row)
    }

    //  delegate
    func newMessageReceived(_ message: Message, connectionId: String) {
        DispatchQueue.main.async {
            guard let index = self.conversations.index(where: { (convo) -> Bool in
                convo.backendId == connectionId
            }) else {
                return
            }

            let convo = self.conversations[index]
            convo.lastMessage = message

            self.conversations.remove(at: index)
            self.conversations.insert(convo, at: 0)

            self.updateTable()
        }
    }
    
    func newConversationReceived(_ convo: Conversation) {
        DispatchQueue.main.async {
            self.conversations.insert(convo, at: 0)
            self.updateTable()
        }
    }

    func updateTable() {
        self.tableView.beginUpdates()
        let indexPath = IndexPath(row: 0, section: 0)
        self.tableView.insertRows(at: [indexPath], with: .automatic)
        self.tableView.endUpdates()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let index = sender as! Int
        let convo = self.conversations[index]
        let chatVC = segue.destination as! ChatTableViewController
        chatVC.conversation = convo
    }
}
