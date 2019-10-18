//
//  Message.swift
//  ChatApplication
//
//  Created by 변재우 on 20181007//.
//  Copyright © 2018 변재우. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    var fromId: String?
    var text: String?
    var timestamp: NSNumber?
    var toId: String?
    var imageUrl: String?
    var imageHeight: NSNumber?//
    var imageWidth: NSNumber?//
	var videoUrl: String?
    
    init(dictionary: [String: AnyObject]) {
        super.init()
        
        self.fromId = dictionary["fromId"] as? String ?? ""
        self.text = dictionary["text"] as? String //?? ""
        self.timestamp = dictionary["timestamp"] as? NSNumber
        self.toId = dictionary["toId"] as? String ?? ""
        self.imageUrl = dictionary["imageUrl"] as? String
        self.imageWidth = dictionary["imageWidth"] as? NSNumber
        self.imageHeight = dictionary["imageHeight"] as? NSNumber
		  self.videoUrl = dictionary["videoUrl"] as? String
    }
    
    func chatPartnerId() -> String? {
        return fromId == Auth.auth().currentUser?.uid ? toId : fromId
        
        // MARK: this is the same as the above ternary operator
//        if fromId == Auth.auth().currentUser?.uid {
//            return toId
//        } else {
//            return fromId
//        }
        
    }
    
}
