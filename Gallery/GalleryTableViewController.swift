//
//  GalleryTableViewController.swift
//  Gallery
//
//  Created by Joe on 10/21/17.
//  Copyright © 2017 mossaka. All rights reserved.
//

import UIKit

import Firebase
import GoogleSignIn
import FirebaseStorage
import FirebaseDatabase
class GalleryTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var ref: DatabaseReference!
    var galleryIDList : [String] = []
    @IBAction func signoutTapped(_ sender: UIButton) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            GIDSignIn.sharedInstance().disconnect()
            performSegue(withIdentifier: "logout", sender: self)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        ref = Database.database().reference()

        if let userID = Auth.auth().currentUser?.uid {

            ref.child("users").child(userID).child("galleries").observe(.childAdded, with: {(snapshot) in
                let result = snapshot.value as? String
                if let galleryID = result {

                    self.galleryIDList.append(galleryID)
                }
                self.tableView.reloadData()
            })
        }
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editGallery", let destination = segue.destination as? CreateGalleryViewController {
            if let cell = sender as? GalleryTableViewCell, let indexPath = tableView.indexPath(for: cell) {
                destination.existingGallery = cell.getInfo()
            }
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }*/
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath as IndexPath) as? GalleryTableViewCell
            else {
                fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        cell.id = galleryIDList[indexPath.row]

        
        ref.child("galleries").child(cell.id!).observeSingleEvent(of: .value, with: {(snapshot) in
            let result = snapshot.value as? NSDictionary

            cell.name.text = result?["name"] as? String ?? ""
        })
        cell.photo.image = UIImage(named: "art1")
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return galleryIDList.count
    }
    
    
}
