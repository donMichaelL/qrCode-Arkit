//
//  Services.swift
//  qrCode-arkit
//
//  Created by Michael Loukeris on 27/03/2018.
//  Copyright © 2018 Michael Loukeris. All rights reserved.
//

import Foundation
import ARKit
import Alamofire
import SwiftyJSON


func downloadExhibitDetails(fromUrl url: URL,_ completion: @escaping (JSON?)->()) {
    Alamofire.request(url, method: .get, parameters: nil).responseJSON { (response) in
        if response.result.isSuccess {
            let exhibitJSON: JSON = JSON(response.result.value!)
            print(exhibitJSON)
            completion(exhibitJSON)
        } else {
            completion(nil)
        }
    }
}


func returnPosition(ofFrame frame: ARFrame, withPosition position: String) -> SCNVector3 {
    return SCNVector3(frame.camera.transform.columns.3.x,
                      frame.camera.transform.columns.3.y,
                      frame.camera.transform.columns.3.z)
}


func returnFullDomainURL(fromURL url: URL) -> String {
    return url.scheme! + "://" + url.host! + ":" + String(url.port!)
}

