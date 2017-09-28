//
//  ViewController.swift
//  Ikea
//
//  Created by Fomin Nickolai on 25.09.17.
//  Copyright © 2017 Fomin Nickolai. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    @IBOutlet weak var planeDetected: UILabel!
    
    let configuration = ARWorldTrackingConfiguration()
    
    let itemsArray: [String] = ["cup", "vase", "boxing", "table"]
    var selectedItem: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration, options: [])
        self.sceneView.delegate = self
        registerGestureRecognizers()
        
        self.sceneView.autoenablesDefaultLighting = true
        
    }

    func registerGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped(sender:)))
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch(sender:)))
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(rotate(sender:)))
        longPressGestureRecognizer.minimumPressDuration = 0.1
        
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    /// Rotate object in scene
    ///
    /// - Parameter sender: UILongPressGestureRecognizer
    @objc func rotate(sender: UILongPressGestureRecognizer) {
        
        let sceneView = sender.view as! ARSCNView
        let holdLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(holdLocation)
        
        if !hitTest.isEmpty {
            
            let results = hitTest.first
            
            if sender.state == .began {
                
                let rotate = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 1)
                let forever = SCNAction.repeatForever(rotate)
                results?.node.runAction(forever)
                
                
                print("Holding")
            } else if sender.state == .ended {
                
                results?.node.removeAllActions()
                
                print("release finger")
            }
            
            
            
        }
        
    }
   
    /// Scale object on scene
    ///
    /// - Parameter sender: UIPinchGestureRecognizer
    @objc func pinch(sender: UIPinchGestureRecognizer) {
        
        let sceneView = sender.view as! ARSCNView
        let pinchLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(pinchLocation)
    
        if !hitTest.isEmpty {
            
            let results = hitTest.first
            let node = results?.node
            
            let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
            node?.runAction(pinchAction)
            sender.scale = 1.0
            
        }
        
    }

    @objc
    func tapped(sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        //empty if no tapped on plane
        let hitTest = sceneView.hitTest(tapLocation, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
        if !hitTest.isEmpty {
            self.addItem(hitTestResult: hitTest.first!)
            print("touch a horizontal surface")
        } else {
            print("no match")
        }
    }
    
    func addItem(hitTestResult: ARHitTestResult) {
        if let selectedItem = self.selectedItem {
            let scene = SCNScene(named: "Models.scnassets/\(selectedItem).scn")
            let node = (scene?.rootNode.childNode(withName: selectedItem, recursively: false))!
            let transform = hitTestResult.worldTransform
            let thirdColumn = transform.columns.3
            node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
            if selectedItem == "table" {
                self.centerPivot(for: node)
            }
            self.sceneView.scene.rootNode.addChildNode(node)
        }
        
    }
    
    //Fix for centering table object
    func centerPivot(for node: SCNNode) {
        let min = node.boundingBox.min
        let max = node.boundingBox.max
        node.pivot = SCNMatrix4MakeTranslation(
            min.x + (max.x - min.x) / 2,
            min.y + (max.y - min.y) / 2,
            min.z + (max.z - min.z) / 2)
    }

}

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = itemsCollectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ItemCell
        cell.labelText.text = self.itemsArray[indexPath.row]
        return cell
    }
    
}

extension ViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        self.selectedItem = itemsArray[indexPath.row]
        cell?.backgroundColor = .green
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = .orange
    }
    
}

extension ViewController: ARSCNViewDelegate {
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard anchor is ARPlaneAnchor else { return }
        DispatchQueue.main.async {
            self.planeDetected.isHidden = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.planeDetected.isHidden = true
            }
        }
    }
    
    
}

extension Int {
    var degreesToRadians: Double {
        return Double(self) * .pi / 180
    }
}










