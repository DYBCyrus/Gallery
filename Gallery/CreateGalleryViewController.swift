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

class CreateGalleryViewController: UIViewController, ARSCNViewDelegate, UIImagePickerControllerDelegate,
UINavigationControllerDelegate {

    @IBOutlet weak var planeDetected: UIVisualEffectView!
    @IBOutlet var sceneView: ARSCNView!
	
	var allNodes: [SCNNode] = []
    var imageData: [Data] = []
    let storageRef = Storage.storage().reference()
    var ref: DatabaseReference!
    // Create a session configuration
    let configuration = ARWorldTrackingConfiguration()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        self.configuration.planeDetection = .horizontal
		// Run the view's session
		sceneView.session.run(configuration)
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        // Create a new scene
		//let scene = SCNScene()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
		self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.planeDetected.isHidden = true
        ref = Database.database().reference()
        // Set the scene to the view
		//sceneView.scene = scene
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
		print(hitTestResult.isEmpty)
		if !hitTestResult.isEmpty {
            self.addPortal(hitTestResult: hitTestResult.first!)
        }
		let nodeResults = sceneView.hitTest(touchLocation, options: nil)
		for result in nodeResults {
			if allNodes.contains(result.node) {
				targetNode = result.node
				sceneView.session.pause()
				pickImage()
			}
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
        self.addWall(nodeName: "back", portalName: portalNode, imageName: "back.png")
        self.addWall(nodeName: "right", portalName: portalNode, imageName: "sideB.png")
        self.addWall(nodeName: "left", portalName: portalNode, imageName: "sideA.png")
		self.addWall(nodeName: "SideGreen", portalName: portalNode, imageName: "sideDoorA.png")
        self.addWall(nodeName: "SideRed", portalName: portalNode, imageName: "sideDoorB.png")
		self.addFrame(nodeName: "backFrames", portalName: portalNode)
		self.addFrame(nodeName: "leftFrames", portalName: portalNode)
		self.addFrame(nodeName: "rightFrames", portalName: portalNode)
        self.addPlane(nodeName: "roof", portalName: portalNode, imageName: "top.png")
        self.addPlane(nodeName: "low", portalName: portalNode, imageName: "bottom.png")
		self.addLamp(nodeName: "lamp", portalName: portalNode)
    }
	
	func addLamp(nodeName: String, portalName: SCNNode) {
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
	
	func pickImage() {
		let image = UIImagePickerController()
		image.delegate = self
		image.sourceType = UIImagePickerControllerSourceType.photoLibrary
		image.allowsEditing = true
		self.present(image, animated: true)
	}
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
			// set node image
			targetNode?.geometry?.firstMaterial?.diffuse.contents = image
            imageData.append(UIImageJPEGRepresentation(image, 0.8)!)
		}
		self.dismiss(animated: true, completion: nil)
		sceneView.session.run(configuration)
	}
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		self.dismiss(animated: false, completion: nil)
		sceneView.session.run(configuration)
	}
    
    @IBAction func saveTapped(_ sender: UIButton) {
//        print("tapped")
//        print("length of imagedata is \(self.imageData.count)")
        
        
        // ask the user to name the gallery
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let gallery_id = String().randomString(length: 20)
        if let user = Auth.auth().currentUser {
            for imgdata in self.imageData {
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
                    
                    self.ref.child("galleries").child("\(gallery_id)").child("imageURLs").childByAutoId().setValue(downloadURL)
                }
                
                // save the generated random string into firebase database
                
            }
            // save the gallery to user
            ref.child("users").child(user.uid).child("galleries").childByAutoId().setValue(gallery_id)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
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
