//
//  ViewController.swift
//  Gallery
//
//  Created by Jiaxiao Zhou on 10/20/17.
//  Copyright © 2017 mossaka. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import FirebaseStorage
import FirebaseDatabase
import Firebase
import GoogleSignIn
import GeoFire
import MapKit
import MobileCoreServices
import AVKit


class CreateGalleryViewController: UIViewController, ARSCNViewDelegate, UIImagePickerControllerDelegate,
UINavigationControllerDelegate {
    @IBOutlet weak var planeDetected: UIVisualEffectView!
    @IBOutlet var sceneView: ARSCNView!
    var locManager = CLLocationManager()
    var currentLocation: CLLocation!

    var portalCreated = false
    var allNodes: [SCNNode] = []
    var imageData: [Data] = []
    var nodeNames: [String] = []
    let storageRef = Storage.storage().reference()
    var ref: DatabaseReference!
    // Create a session configuration
    let configuration = ARWorldTrackingConfiguration()
    var geoFire: GeoFire!
    var existingGallery : [String] = []
    var imagePositions : [(UIImage,String)] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the view's delegate
        sceneView.delegate = self
        
        self.configuration.planeDetection = .horizontal
		// Run the view's session
		sceneView.session.run(configuration)
        sceneView.showsStatistics = false
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        // Create a new scene
		//let scene = SCNScene()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
		self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.planeDetected.isHidden = true
        ref = Database.database().reference()
        geoFire = GeoFire(firebaseRef: ref)
        locManager.requestWhenInUseAuthorization()
        // Set the scene to the view
		//sceneView.scene = scene
        
        
        
        if existingGallery != [] {
            let galID = existingGallery[0]
            if let userID = Auth.auth().currentUser?.uid {
                
                ref.child("galleries").child(galID).child("imageURLs").observe(.childAdded, with: {(snapshot) in
                    if let nodeName = snapshot.key as? String {
                        let actualURL = snapshot.value as? String
                        let url = URL(string:actualURL!)
                        let data = try? Data(contentsOf: url!)
                        let image: UIImage = UIImage(data: data!)!
                        self.imagePositions.append((image,nodeName))
                    }
                })
            }
            
        }
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
		print(hitTestResult.isEmpty)
		if !hitTestResult.isEmpty {
            if !portalCreated {
                self.addPortal(hitTestResult: hitTestResult.first!)
                portalCreated = true
            }
        }
		let nodeResults = sceneView.hitTest(touchLocation, options: nil)
		for result in nodeResults {
			if allNodes.contains(result.node) && result.node.name != "video" {
				targetNode = result.node
				sceneView.session.pause()
				chooseImageSource()
			} else if allNodes.contains(result.node) && result.node.name == "video" {
				targetNode = result.node
				sceneView.session.pause()
				if videoURL == nil {
					chooseVideoSource()
				} else {
					playVideo(url: videoURL!)
				}
			}
		}
    }
	
	@objc func playerDidFinishPlaying(note: NSNotification) {
		sceneView.session.run(configuration)
	}
	
	func playVideo(url: NSURL) {
		let item = AVPlayerItem(url: url as URL)
		NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
		let newPlayer = AVPlayer(playerItem: item)
		let playerViewController = AVPlayerViewController()
		playerViewController.player = newPlayer
		self.present(playerViewController, animated: true) {
			playerViewController.player!.play()
		}
	}
	
	var targetNode: SCNNode?
    
    func addPortal(hitTestResult: ARHitTestResult) {
        let portalScene = SCNScene(named: "Portal.scnassets/Portal/Portal.scn")
        let portalNode = portalScene!.rootNode.childNode(withName: "Portal", recursively: false)!
        let transform = hitTestResult.worldTransform
        let planeXposition = transform.columns.3.x
        let planeYposition = transform.columns.3.y
        let planeZposition = transform.columns.3.z
        portalNode.position = SCNVector3(planeXposition,planeYposition,planeZposition)
        self.sceneView.scene.rootNode.addChildNode(portalNode)
        self.addWall(nodeName: "back", portalName: portalNode, imageName: "WallFront.png")
        self.addWall(nodeName: "right", portalName: portalNode, imageName: "rightWall.png")
        self.addWall(nodeName: "left", portalName: portalNode, imageName: "SideWall.png")
		self.addWall(nodeName: "SideGreen", portalName: portalNode, imageName: "wall.png")
        self.addWall(nodeName: "SideRed", portalName: portalNode, imageName: "wall.png")
		self.addFrame(nodeName: "backFrames", portalName: portalNode)
		self.addFrame(nodeName: "leftFrames", portalName: portalNode)
		self.addFrame(nodeName: "rightFrames", portalName: portalNode)
        self.addPlane(nodeName: "roof", portalName: portalNode, imageName: "ceiling.png")
        self.addPlane(nodeName: "low", portalName: portalNode, imageName: "floor.png")
		self.addModel(nodeName: "lamp", portalName: portalNode)
		self.addModel(nodeName: "table", portalName: portalNode)
        if !imagePositions.isEmpty{
            for each in imagePositions {
                self.addimages(image: each.0, nodeName: each.1, portalName: portalNode)
            }
        }
    }

    func addimages(image: UIImage, nodeName: String, portalName: SCNNode) {
        let child = portalName.childNode(withName: nodeName, recursively: true)
        print(child?.name)
        child?.geometry?.firstMaterial?.diffuse.contents = image
    }

	
	func addModel(nodeName: String, portalName: SCNNode) {
		let child = portalName.childNode(withName: nodeName, recursively: false)
		child?.renderingOrder = 200
		for nodes in (child?.childNodes)! {
			nodes.renderingOrder = 200
		}
	}
	
	func addFrame(nodeName: String, portalName: SCNNode) {
		let child = portalName.childNode(withName: nodeName, recursively: false)
		child?.renderingOrder = 200
		for nodes in (child?.childNodes)! {
			nodes.renderingOrder = 200
			allNodes.append(nodes)
		}
	}
	
	func addWall(nodeName: String, portalName: SCNNode, imageName: String) {
        let child = portalName.childNode(withName: nodeName, recursively: false)
        child?.renderingOrder = 200
		child?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "Portal.scnassets/\(imageName).png")
        if let mask = child?.childNode(withName: "mask", recursively: false) {
			mask.renderingOrder = 0
            mask.geometry?.firstMaterial?.transparency = 0.000001
        }
		if let window = child?.childNode(withName: "window", recursively: false) {
			window.renderingOrder = 0
			window.geometry?.firstMaterial?.transparency = 0.000001
		}
    }
    
	func addPlane(nodeName: String, portalName: SCNNode, imageName: String) {
        let child = portalName.childNode(withName: nodeName, recursively: false)
        child?.renderingOrder = 200
		child?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "Portal.scnassets/\(imageName).png")
    }
	
	func chooseImageSource() {
		let image = UIImagePickerController()
		image.delegate = self
		let actionSheet = UIAlertController(title: "Photo Source", message: "Please select a source", preferredStyle: .actionSheet)
		actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: {(action: UIAlertAction) in
			image.sourceType = .photoLibrary
			image.allowsEditing = true
			self.present(image, animated: true, completion: nil)
		}))
		actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {(action: UIAlertAction) in
			image.sourceType = .camera
			image.allowsEditing = true
			self.present(image, animated: true, completion: nil)
		}))
		actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		self.present(actionSheet, animated: true, completion: nil)
		sceneView.session.run(configuration)
	}
	
	func chooseVideoSource() {
		let image = UIImagePickerController()
		image.delegate = self
		let actionSheet = UIAlertController(title: "Video Source", message: "Please select a source", preferredStyle: .actionSheet)
		actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: {(action: UIAlertAction) in
			image.sourceType = .photoLibrary
			image.mediaTypes = [kUTTypeMovie as String]
			image.allowsEditing = false
			self.present(image, animated: true, completion: nil)
		}))
		actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		self.present(actionSheet, animated: true, completion: nil)
		sceneView.session.run(configuration)
	}
	
	var videoURL: NSURL?
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
			// set node image
			targetNode?.geometry?.firstMaterial?.diffuse.contents = image
            imageData.append(UIImageJPEGRepresentation(image, 0.8)!)
            nodeNames.append((targetNode?.name)!)
		}
		if let video = info[UIImagePickerControllerMediaURL] as? NSURL {
			videoURL = video
		}
		self.dismiss(animated: true, completion: nil)
		sceneView.session.run(configuration)
	}
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		self.dismiss(animated: true, completion: nil)
		sceneView.session.run(configuration)
	}
    
    var galleryName : String? {
        didSet{
            // ask the user to name the gallery
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            let gallery_id = String().randomString(length: 20)
            if let user = Auth.auth().currentUser {
                
                self.ref.child("galleries").child("\(gallery_id)").setValue(["user": user.uid])
                self.ref.child("galleries").child("\(gallery_id)").child("name").setValue(galleryName)
                for (index, imgdata) in self.imageData.enumerated() {
                    let imageID = String().randomString(length: 20)
                    // save the image to firebase storage
                    storageRef.child("\(user.uid)/images/\(imageID)").putData(imgdata, metadata: metadata) { (metadata, error) in
                        guard let metadata = metadata else {
                            // Uh-oh, an error occurred!
                            print("uhoh an error occured")
                            return
                        }
                        // Metadata contains file metadata such as size, content-type, and download URL.
                        print("URL is \(metadata.downloadURL()?.absoluteString ?? "")")
                        print("content type is \(metadata.contentType)")
                        let downloadURL = metadata.downloadURL()?.absoluteString ?? ""
                        
                        self.ref.child("galleries").child("\(gallery_id)").child("imageURLs").child(self.nodeNames[index]).setValue(downloadURL)
                    }
                    
                    // save the generated random string into firebase database
                    
                }
                // save the gallery to user
                ref.child("users").child(user.uid).child("galleries").childByAutoId().setValue(gallery_id)
                
                // save the geo location to the gallery
                geoFire.setLocation(currentLocation, forKey: "\(gallery_id)") { (error) in
                    if (error != nil) {
                        print("An error occured: \(error)")
                    } else {
                        print("Saved location successfully!")
                    }
                }
                portalCreated = false
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
//        print("tapped")
//        print("length of imagedata is \(self.imageData.count)")
        if portalCreated {
            if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
                CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
                currentLocation = locManager.location
                
                print(currentLocation.coordinate.latitude)
                print(currentLocation.coordinate.longitude)
            }
            if existingGallery.isEmpty {
                let alert = UIAlertController(title: "What's your new gallery called?", message: "", preferredStyle: .alert)
            
                //2. Add the text field. You can configure it however you need.
                alert.addTextField { (textField) in
                    textField.text = ""
                }
            
                // 3. Grab the value from the text field, and print it when the user clicks OK.
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                    let textField = alert!.textFields![0] // Force unwrapping because we know it exists.
                    self.galleryName = textField.text!
                }))
            
                // 4. Present the alert.
                self.present(alert, animated: true, completion: nil)
            }
            else {
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"

                if let user = Auth.auth().currentUser {
                    for (index, imgdata) in self.imageData.enumerated() {
                        let imageID = String().randomString(length: 20)
                        // save the image to firebase storage
                        storageRef.child("\(user.uid)/images/\(imageID)").putData(imgdata, metadata: metadata) { (metadata, error) in
                            guard let metadata = metadata else {
                                // Uh-oh, an error occurred!
                                print("uhoh an error occured")
                                return
                            }
                            // Metadata contains file metadata such as size, content-type, and download URL.
                            print("URL is \(metadata.downloadURL()?.absoluteString ?? "")")
                            print("content type is \(metadata.contentType)")
                            let downloadURL = metadata.downloadURL()?.absoluteString ?? ""
                            
                            self.ref.child("galleries").child("\(self.existingGallery[0])").child("imageURLs").child(self.nodeNames[index]).setValue(downloadURL)
                        }
                        
                        // save the generated random string into firebase database
                        
                    }

                    // save the geo location to the gallery

                    portalCreated = false
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.run(configuration)

        //        // Create a session configuration
        //        let configuration = ARWorldTrackingConfiguration()
        //
        //        // Run the view's session
        //        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - ARSCNViewDelegate
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
	

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        DispatchQueue.main.async {
            self.planeDetected.isHidden = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+3) {
            self.planeDetected.isHidden = true
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overla

        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        
    }
//    @IBAction func dummyTest(_ sender: UIButton) {
//        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
//        CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
//            currentLocation = locManager.location
//            let center = currentLocation
//            // Query locations at [37.7832889, -122.4056973] with a radius of 600 meters
//            var circleQuery = geoFire.query(at: center, withRadius: 0.6)
//            circleQuery?.observe(.keyEntered, with: { (key: String!, location: CLLocation!) in
//                print("Key '\(key!)' entered the search area and is at location '\(location.coordinate.longitude)' and '\(location.coordinate.latitude)'")
//            })
//        }
//
//        //        // Query location by region
//        //        let span = MKCoordinateSpanMake(0.001, 0.001)
//        //        let region = MKCoordinateRegionMake(center.coordinate, span)
//        //        var regionQuery = geoFire.queryWithRegion(region)
//    }
}

extension String {
    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
}
