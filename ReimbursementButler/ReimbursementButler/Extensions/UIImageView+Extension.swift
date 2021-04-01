//
//  FirebaseHelper.swift
//
import UIKit
import Firebase

import Foundation

let imageCache = NSCache<NSString,UIImage>()

extension UIImageView {

    func readCachedImage(_ urlStr: String?) -> UIImage {
        return imageCache.object(forKey: urlStr! as NSString)!
    }
    
    func loadImage(_ urlStr: String?) {
        if let profileURL = urlStr, let urlComponents = URLComponents(string: profileURL) {
            if let cachedImage = imageCache.object(forKey: profileURL as NSString) {
                DispatchQueue.main.async {
                    self.image = cachedImage
                }
                return
            }

            let session = URLSession(configuration: .default)
            guard let url = urlComponents.url else { return }

            let datatask = session.dataTask(with: url) { (data, response, error) in
                if error == nil {
                    if let downloadedImage = UIImage(data: data!) {
                        imageCache.setObject(downloadedImage, forKey: profileURL as NSString)
                        DispatchQueue.main.async {
                            self.image = downloadedImage
                        }
                    }
                } else {
                    print(error!.localizedDescription)
                }
            }
            datatask.resume()
        }
    }
}

