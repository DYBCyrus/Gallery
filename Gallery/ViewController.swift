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

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    // Create a session configuration
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        // Set the view's delegate
        sceneView.delegate = self
        
        self.configuration.planeDetection = .horizontal
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        // Create a new scene
		//let scene = SCNScene()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
		self.sceneView.addGestureRecognizer(tapGestureRecognizer)

        // Set the scene to the view
		//sceneView.scene = scene
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        print("tapped")
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
		print(hitTestResult.isEmpty)
		if !hitTestResult.isEmpty {
            print("add")
            self.addPortal(hitTestResult: hitTestResult.first!)
        } else {
            
        }
    }
    
    func addPortal(hitTestResult: ARHitTestResult) {
        let portalScene = SCNScene(named: "Portal.scnassets/Portal.scn")
        let portalNode = portalScene!.rootNode.childNode(withName: "Portal", recursively: false)!
        let transform = hitTestResult.worldTransform
        let planeXposition = transform.columns.3.x
        let planeYposition = transform.columns.3.y
        let planeZposition = transform.columns.3.z
        portalNode.position = SCNVector3(planeXposition,planeYposition,planeZposition)
        self.sceneView.scene.rootNode.addChildNode(portalNode)
        self.addWall(nodeName: "back", portalName: portalNode)
        self.addWall(nodeName: "right", portalName: portalNode)
        self.addWall(nodeName: "left", portalName: portalNode)
        self.addWall(nodeName: "SideGreen", portalName: portalNode)
        self.addWall(nodeName: "SideRed", portalName: portalNode)
        self.addPlane(nodeName: "roof", portalName: portalNode)
        self.addPlane(nodeName: "low", portalName: portalNode)
    }
    
    func addWall(nodeName: String, portalName: SCNNode) {
        let child = portalName.childNode(withName: nodeName, recursively: true)
        child?.renderingOrder = 200
        if let mask = child?.childNode(withName: "mask", recursively: false) {
            print("transparency!")
            mask.geometry?.firstMaterial?.transparency = 0.000001
        }
    }
    
    func addPlane(nodeName: String, portalName: SCNNode) {
        let child = portalName.childNode(withName: nodeName, recursively: true)
        child?.renderingOrder = 200
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
