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
import AVKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var discoveredQRCodes = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let image = CIImage(cvPixelBuffer: frame.capturedImage)
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: nil)
        let features = detector!.features(in: image)
        
        for feature in features as! [CIQRCodeFeature] {
            if !discoveredQRCodes.contains(feature.messageString!) {
                discoveredQRCodes.append(feature.messageString!)
                let url = URL(string: feature.messageString!)
                let position = SCNVector3(frame.camera.transform.columns.3.x,
                                          frame.camera.transform.columns.3.y,
                                          frame.camera.transform.columns.3.z)
//                add3DModel(fromURL: url!, toPosition: getPositionBasedOnQRCode(frame: frame, position: "df"))
                print(position)
                add3dInstance(fromURL: url!, toPosition: position)
            }
        }
    }
}

extension ViewController {
    func add3dInstance(fromURL url: URL, toPosition position: SCNVector3) {
        downloadExhibitDetails(fromUrl: url) { (result) in
            if let exhibitJSON = result {
                if let model3dUrl = exhibitJSON["model_3d"].string {
                    print(model3dUrl)
                }
                if let text = exhibitJSON["text"].string {
                    print(position)
                    self.add3DText(text: text, toPosition: position)
                }
                if let image = exhibitJSON["image"].string {
                    let urlString = "http://195.134.67.227:8000" + image
                    print(urlString)
                    self.add3dImage(from: URL(string: urlString)! , toPosition: position)
                }
                if let video = exhibitJSON["video"].string {
                    let urlString = "http://www.ebookfrenzy.com/ios_book/movie/movie.mov"
//                    let urlString =  "http://195.134.67.227:8000" + video
                    print(urlString)
                    let videoURL = URL(string: urlString)!
                    let player = AVPlayer(url: videoURL)
                    let playerViewController = AVPlayerViewController()
                    playerViewController.player = player
                    self.present(playerViewController, animated: true) {
                        playerViewController.player!.play()
                    }
                }
            }
        }
    }
    
    func add3dImage(from url: URL, toPosition position: SCNVector3) {
        downloadTexture(fromUrl: url) { (result) in
            if let image = result {
                let plane = SCNPlane(width: 0.1, height: 0.1)
                let material = SCNMaterial()
                material.diffuse.contents = image
                plane.materials = [material]
                let node = SCNNode(geometry: plane)
                node.position = position
                self.sceneView.scene.rootNode.addChildNode(node)
            }
        }
    }
    
    func add3DText(text: String, toPosition position: SCNVector3) {
//        let cube = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01)
        let cube = SCNText(string: "A", extrusionDepth: 0.0)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        cube.materials = [material]
        let node = SCNNode(geometry: cube)
//        node.position = SCNVector3(x: -0.2, y: 0.1, z: -0.5)
        node.position = position
        print(position)
        self.sceneView.scene.rootNode.addChildNode(node)
        print("HELLO")
    }
    
    func add3DModel(fromURL url: URL, toPosition position: SCNVector3) {
        downloadExhibitDetails(fromUrl: url) { (exhibit) in
            if let exhibitJSON = exhibit {
                let modelURL = self.returnFullDomainURL(fromURL: url) + exhibitJSON["model_3d"].string!
                let textureURL = self.returnFullDomainURL(fromURL: url) + exhibitJSON["texture"].string!
                do {
                    let scene = try SCNScene(url: URL(string: modelURL)!, options: nil)
                    self.downloadTexture(fromUrl: URL(string: textureURL)!, { (texture) in
                        let shipnode = scene.rootNode.childNode(withName: "shipMesh", recursively: true)
                        if let textureImage = texture {
                            //let shipNode = scene.rootNode.childNodes.first?.childNodes.first
                            let material = SCNMaterial()
                            material.diffuse.contents = textureImage
                            shipnode?.geometry?.materials = [material]
                            shipnode?.position = position
                            self.sceneView.scene.rootNode.addChildNode(shipnode!)
                        } else {
                            self.sceneView.scene.rootNode.addChildNode(shipnode!)
                        }
                    })
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func returnFullDomainURL(fromURL url: URL) -> String {
        return url.scheme! + "://" + url.host! + ":" + String(url.port!)
    }
    
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
                completion(nil)
                print("Error \(error)")
            }
        }
    }
}













