
import UIKit

class ProfileViewController: UIViewController {

    @IBOutlet private var profileImageView: UIView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var usernameLabel: UILabel!
   @IBOutlet private var infoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func logoutButton(_ sender: Any) {
    }
}
