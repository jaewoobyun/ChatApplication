//
//  Extensions.swift
//  ChatApplication
//
//  Created by 변재우 on 20181004//.
//  Copyright © 2018 변재우. All rights reserved.
//

import UIKit

//let imageCache = NSCache<AnyObject, AnyObject>()
let imageCache = NSCache<NSString, UIImage>()

extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(_ urlString: String) {
        
        self.image = nil
        
        //check cache for image first
        if let cachedImage = imageCache.object(forKey: urlString as NSString) {
            self.image = cachedImage
            return
        }
        
        //otherwise fire off a new download
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            
            //download hit an error so lets return out
            if error != nil {
                print(error ?? "")
                return
            }
            DispatchQueue.main.async {
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: urlString as NSString)
//                    self.image = UIImage(data: data!)
                    self.image = downloadedImage
                    }
                }
            
        }.resume()
    }
}
