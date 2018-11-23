
import UIKit


class ViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!

    @IBOutlet weak var userNameField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Sign in"

        //  lel
        if let userId = UserDefaults.standard.string(forKey: Constants.userIdKey) {
            self.performSegue(withIdentifier: "ShowChatList", sender: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func login(_ sender: Any) {
        guard let userId = self.textField.text, let username = self.userNameField.text else {
            return
        }

        UserDefaults.standard.set(userId, forKey: Constants.userIdKey)
        UserDefaults.standard.set(username, forKey: Constants.userNameKey)
        
        self.performSegue(withIdentifier: "ShowChatList", sender: nil)
    }
}

