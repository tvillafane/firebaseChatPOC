
import UIKit
import Firebase
import FirebaseAuth

class ViewController: UIViewController {

    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var textField: UITextField!

    @IBOutlet weak var userNameField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Sign in"

        //  lel
        if let _ = UserDefaults.standard.string(forKey: Constants.userIdKey) {
            self.performSegue(withIdentifier: "ShowChatList", sender: nil)
        }
    }

    private func authenticate(id: String, completion: @escaping (String?) -> ()) {
        let parameters = ["user_id": "\(id)"]
        let url = URL(string: "http://www.chatPOC-dev.us-west-2.elasticbeanstalk.com/auth")! //change the url

        //now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
        }

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

            if error != nil || data == nil {
                completion(nil)
            }

            do {
                if
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: String],
                    let token = json["token"] {
                        completion(token)
                } else {
                    completion(nil)
                }
            } catch let error {
                print(error.localizedDescription)
                completion(nil)
            }
        })

        task.resume()
    }

    @IBAction func login(_ sender: Any) {
        let button = sender as! UIButton
        button.isEnabled = false

        guard let userId = self.textField.text, let username = self.userNameField.text else {
            return
        }

        self.errorLabel.isHidden = true

        self.authenticate(id: userId) { (token) in
            if let token = token {
                Auth.auth().signIn(withCustomToken: token) { (user, error) in
                    button.isEnabled = true

                    if let _ = error {
                        self.errorLabel.isHidden = false
                    } else {
                        UserDefaults.standard.set(userId, forKey: Constants.userIdKey)
                        UserDefaults.standard.set(username, forKey: Constants.userNameKey)

                        DispatchQueue.main.async {
                            self.userNameField.text = ""
                            self.textField.text = ""
                            self.performSegue(withIdentifier: "ShowChatList", sender: nil)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    button.isEnabled = true
                }
            }
        }
    }

}

