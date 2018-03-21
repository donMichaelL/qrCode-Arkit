//
//  ViewController.swift
//  qrCode-arkit
//
//  Created by Michael Loukeris on 19/03/2018.
//  Copyright © 2018 Michael Loukeris. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        downloadExhibitDetails(fromUrl: URL(string: "http://195.134.67.227:8000/api/details/6")!) { (exhibit) in
            if let exhibitJSON = exhibit {
                let modelURL = "http://195.134.67.227:8000" + exhibitJSON["model_3d"].string!
                let textureURL = "http://195.134.67.227:8000" + exhibitJSON["texture"].string!
                do {
                    let scene = try SCNScene(url: URL(string: modelURL)!, options: nil)
                    self.downloadTexture(fromUrl: URL(string: textureURL)!, { (texture) in
                        if let textureImage = texture {
                            let shipnode = scene.rootNode.childNode(withName: "shipMesh", recursively: true)
                            //let shipNode = scene.rootNode.childNodes.first?.childNodes.first
                            let material = SCNMaterial()
                            material.diffuse.contents = textureImage
                            shipnode?.geometry?.materials = [material]
                            self.sceneView.scene = scene
                        }
                    })
                    

                } catch {
                    print(error)
                }
                
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
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

extension ViewController {
    func downloadExhibitDetails(fromUrl url: URL,_ completion: @escaping (JSON?)->()) {
        Alamofire.request(url, method: .get, parameters: nil).responseJSON { (response) in
            if response.result.isSuccess {
                let exhibitJSON: JSON = JSON(response.result.value!)
                completion(exhibitJSON)
            } else {
                completion(nil)
            }
        }
    }
    
    func downloadTexture(fromUrl url: URL,_ completion: @escaping (UIImage?)->()) {
        DispatchQueue.global().async {
            do {
                let data = try Data(contentsOf: url)
                DispatchQueue.main.async {
                    completion(UIImage(data: data))
                }
            } catch {
                print("Error \(error)")
            }
        }
    }
}













