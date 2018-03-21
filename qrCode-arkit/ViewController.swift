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
    
    var discoveredQRCodes = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = self
        sceneView.showsStatistics = true
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
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
                add3DModel(fromURL: url!)
            }
        }
    }
}

extension ViewController {
    func add3DModel(fromURL url: URL) {
        downloadExhibitDetails(fromUrl: url) { (exhibit) in
            if let exhibitJSON = exhibit {
                let modelURL = self.returnFullDomainURL(fromURL: url) + exhibitJSON["model_3d"].string!
                let textureURL = self.returnFullDomainURL(fromURL: url) + exhibitJSON["texture"].string!
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
                print("Error \(error)")
            }
        }
    }
}













