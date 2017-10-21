//
//  SignInViewController.swift
//  Gallery
//
//  Created by Joe on 10/21/17.
//  Copyright © 2017 mossaka. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class SignInViewController: UIViewController, GIDSignInUIDelegate {

    @IBOutlet weak var signinButton: GIDSignInButton!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var signoutButton: UIButton!
    @IBAction func signoutTouched(_ sender: UIButton) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            GIDSignIn.sharedInstance().disconnect()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    @IBAction func signinTouched(_ sender: GIDSignInButton) {
        //GIDSignIn.sharedInstance().signInSilently()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        GIDSignIn.sharedInstance().uiDelegate = self
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        Auth.auth().addStateDidChangeListener{ (auth, user) in
            if let user = user {
                self.welcomeLabel.text = "Welcome,\(user.displayName!)"
                self.signoutButton.isHidden = false
                self.performSegue(withIdentifier: "fromSigninToTab", sender: self)
            } else {
                self.welcomeLabel.text = "Please Sign In"
                self.signoutButton.isHidden = true
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "fromSigninToTab" {
            if let tabViewController = segue.destination as? UITableViewController {
                let galleryTableViewController = tabViewController.childViewControllers[0] as? GalleryTableViewController
                print("ha")
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
