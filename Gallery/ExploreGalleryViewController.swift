//
//  CreateARGalleryViewController.swift
//  Gallery
//
//  Created by Joe on 10/21/17.
//  Copyright © 2017 mossaka. All rights reserved.
//

import UIKit
import ARKit
import FirebaseStorage
import FirebaseDatabase
import Firebase
class ExploreGalleryViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var planeDetected: UIVisualEffectView!
    @IBOutlet var sceneView: ARSCNView!
    var galleryKey: String!
    let configuration = ARWorldTrackingConfiguration()
    var imagePositions : [(UIImage,String)] = []

    var ref: DatabaseReference!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the view's delegate
        sceneView.delegate = self
        
        self.configuration.planeDetection = .horizontal
        // Show statistics such as fps and timing information
        
        sceneView.session.run(configuration)
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        // Create a new scene
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        // Set the scene to the view
        ref = Database.database().reference()
        self.planeDetected.isHidden = true
        if galleryKey != nil {
            if let userID = Auth.auth().currentUser?.uid {
                
                ref.child("galleries").child(galleryKey).child("imageURLs").observe(.childAdded, with: {(snapshot) in
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
            self.addPortal(hitTestResult: hitTestResult.first!)
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
        // Dispose of any resources that can be recreated.
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

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        DispatchQueue.main.async {
            self.planeDetected.isHidden = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+3) {
            self.planeDetected.isHidden = true
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
