//
//  PlacesViewController.swift
//  Gallery
//
//  Created by Joe on 10/21/17.
//  Copyright © 2017 mossaka. All rights reserved.
//

import UIKit
import MapKit
import GoogleMaps
import GooglePlacePicker
import Firebase
import GeoFire
import GoogleSignIn

class PlacesViewController: UIViewController, GMSMapViewDelegate {
    // Add a pair of UILabels in Interface Builder, and connect the outlets to these variables.
    
    @IBAction func tapped(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            GIDSignIn.sharedInstance().disconnect()
            performSegue(withIdentifier: "logoutFromExplore", sender: self)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    var placesClient: GMSPlacesClient!
    var locManager = CLLocationManager()
    var currentLocation: CLLocation!
    var geoFire: GeoFire!
    var ref: DatabaseReference!
    var mapView: GMSMapView!
    // Add a UIButton in Interface Builder, and connect the action to this function.
    override func loadView() {
        ref = Database.database().reference()
        
        geoFire = GeoFire(firebaseRef: ref)
        // Create a GMSCameraPosition that tells the map to display the
        // coordinate -33.86,151.20 at zoom level 6.
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            currentLocation = locManager.location
            
            print(currentLocation.coordinate.latitude)
            print(currentLocation.coordinate.longitude)
        
        }
        let camera = GMSCameraPosition.camera(withLatitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude, zoom: 6.0)
        
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.isMyLocationEnabled = true
        view = mapView
        
        let refreshButton = UIButton()
        let btnImage = UIImage(named: "refresh")
        refreshButton.setImage(btnImage, for: .normal)
        refreshButton.frame = CGRect(x: 30, y: 60, width: 40, height: 40)
        self.view.addSubview(refreshButton)
        
        refreshButton.addTarget(self, action: #selector(click), for: UIControlEvents.touchUpInside)
        mapView.delegate = self
    }
    
    @objc
    func click(sender: UIButton) {
        print("haha")
        let userID = Auth.auth().currentUser?.uid
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
                    CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            currentLocation = locManager.location
            if let center = currentLocation {
                let circleQuery = geoFire.query(at: center, withRadius: 0.65)
                circleQuery?.observe(.keyEntered, with: { (key: String!, location: CLLocation!) in
                    print("Key '\(key!)' entered the search area and is at location '\(location.coordinate.longitude)' and '\(location.coordinate.latitude)'")
                    // from key to get the name of the gallery
                    var name = String()
                    self.ref.child("galleries").child("\(key)").child("name").observe(DataEventType.value, with: { (snapshot) in
                        name = snapshot.value as? String ?? "Portal"
                        print("the gallery's name is \(name)")
                    })
                    let marker = GMSMarker()
                    marker.position = location.coordinate
                    
                    marker.title = name
                    marker.snippet = key
                    marker.map = self.mapView
                })
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placesClient = GMSPlacesClient.shared()
        
        locManager.requestWhenInUseAuthorization()
        // Do any additional setup after loading the view.
        
        
    }
    
    var galleryKey: String?
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if let key = marker.snippet {
            galleryKey = key
            performSegue(withIdentifier: "mapToAR", sender: self)
            return true
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mapToAR" {
            if let controller = segue.destination as? ExploreGalleryViewController {
                controller.galleryKey = self.galleryKey
            }
        }
    }
    
//    // Add a UIButton in Interface Builder, and connect the action to this function.
//    @IBAction func getCurrentPlace(_ sender: UIButton) {
//
//        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
//            if let error = error {
//                print("Pick Place error: \(error.localizedDescription)")
//                return
//            }
//
//            self.nameLabel.text = "No current place"
//            self.addressLabel.text = ""
//
//            if let placeLikelihoodList = placeLikelihoodList {
//                let place = placeLikelihoodList.likelihoods.first?.place
//                if let place = place {
//                    self.nameLabel.text = place.name
//                    self.addressLabel.text = place.formattedAddress?.components(separatedBy: ", ")
//                        .joined(separator: "\n")
//                }
//            }
//        })
//    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
