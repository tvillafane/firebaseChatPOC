
import UIKit
import Firebase

protocol ChatDataSource {
    init (chatId: String, delegate: ChatDataDelegate)
    var delegate: ChatDataDelegate { get }
    func writeMessage(body: String, completion: @escaping (Bool) -> ())
    func syncConversation(chatId: String, timestamp: Int?, completion: @escaping (Conversation) -> ())
}

protocol ChatDataDelegate {
    func newChatMessage(message: Message)
}

class ChatTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ChatDataDelegate {

    @IBOutlet weak var textViewConstraint: NSLayoutConstraint!
    
    var conversation: Conversation!
    var messages: [Message] = []
    var dataSource: ChatDataSource!
  
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textfield: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = FirebaseChatHelper(chatId: self.conversation.backendId, delegate: self)
        self.navigationItem.title = "Chat"
        self.tableView.tableFooterView = UIView()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        self.dataSource.syncConversation(chatId: self.conversation.backendId, timestamp: nil) { (convo) in
            print(convo)
        }
    }

    @IBAction func sendMessage(_ sender: Any) {
        if let text = self.textfield.text {
            self.dataSource.writeMessage(body: text, completion: { [weak self] (success) in
                print("attempted to do things:", success)

                if success {
                    self?.textfield.text = ""
                }
            })
        }
    }

    func newChatMessage(message: Message) {
        DispatchQueue.main.async {
            self.messages.append(message)
            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)

            self.tableView.beginUpdates()
            self.tableView.insertRows(at: [indexPath], with: .none)
            self.tableView.endUpdates()

            self.scrollToBottom()
        }
    }

    func scrollToBottom() {
        let row = self.messages.count - 1
        let path = IndexPath(row: row, section: 0)

        if row < 0 {
            return
        }

        self.tableView.scrollToRow(at: path, at: .bottom, animated: true)
    }

    @objc func keyboardWillHide(_ sender: Notification) {
        if let userInfo = sender.userInfo {
            let _ = (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.size.height
            self.textViewConstraint.constant = 2
            UIView.animate(withDuration: 0.25, animations: { [weak self] () -> Void in
                self?.view.layoutIfNeeded()
            })
        }
    }

    @objc func keyboardWillShow(_ sender: Notification) {
        if let userInfo = sender.userInfo {
            var keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.size.height
            //  bug fix - 44px extra from the safe area
            if #available(iOS 11.0, *) {
                keyboardHeight -= self.view.safeAreaInsets.bottom
            }

            self.textViewConstraint.constant += keyboardHeight

            UIView.animate(withDuration: 0.00, animations: { [weak self] () -> Void in
                self?.view.layoutIfNeeded()
            })

            self.scrollToBottom()
        }
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatTableViewCell
        let message = self.messages[indexPath.row]
        
        cell.nameLabel.text = message.senderId
        cell.messageLabel.text = message.body

        return cell
    }
}
