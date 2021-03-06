//
//  FTChatMessageImageSize.swift
//  ChatMessageDemoProject
//
//  Created by liufengting on 16/8/19.
//  Copyright © 2016年 liufengting ( https://github.com/liufengting ). All rights reserved.
//

import UIKit

extension URLSession {
    /// Return data from synchronous URL request
    public static func requestSynchronousData(request: NSURLRequest) -> NSData? {
        var data: NSData? = nil
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {
            taskData, _, error -> () in
            data = taskData as NSData?
            if data == nil, let error = error {print(error)}
            semaphore.signal();
        })
        task.resume()
        let _ = semaphore.wait(timeout: .distantFuture)
        return data
    }
    public static func requestSynchronousDataWithURLString(requestString: String) -> NSData? {
        guard let url = NSURL(string:requestString) else {return nil}
        let request = NSURLRequest(url: url as URL)
        return URLSession.requestSynchronousData(request: request)
    }
}
class FTChatMessageImageSize: NSObject {
    
    // MARK: - getImageSize
    fileprivate class func getImageSize(_ imageURL:String) ->CGSize {
        var URL:Foundation.URL?
        if imageURL.isKind(of: NSString.self) {
            URL = Foundation.URL(string: imageURL)
        }
        if URL == nil {
            return  CGSize.zero
        }
        let request = NSMutableURLRequest(url: URL!)
        let pathExtendsion = URL?.pathExtension.lowercased()
        
        var size = CGSize.zero
        if pathExtendsion == "png" {
            size = self.getPNGImageSize(request)
        } else if pathExtendsion == "gif" {
            size = self.getGIFImageSize(request)
        } else {
            size = self.getJPGImageSize(request)
        }
        if CGSize.zero.equalTo(size) {
            guard let data = URLSession.requestSynchronousData(request: request) else {
                return size
            }
            let image = UIImage(data: data as Data)
            if image != nil {
                size = (image?.size)!
            }
        }
        return size
    }
    
    // MARK: - getPNGImageSize
    fileprivate class func getPNGImageSize(_ request:NSMutableURLRequest) -> CGSize {
        request.setValue("bytes=16-23", forHTTPHeaderField: "Range")
        guard let data: Data = URLSession.requestSynchronousData(request: request) as Data? else {
            return CGSize.zero
        }
        if data.count == 8 {
            var w1:Int = 0
            var w2:Int = 0
            var w3:Int = 0
            var w4:Int = 0
            (data as NSData).getBytes(&w1, range: NSMakeRange(0, 1))
            (data as NSData).getBytes(&w2, range: NSMakeRange(1, 1))
            (data as NSData).getBytes(&w3, range: NSMakeRange(2, 1))
            (data as NSData).getBytes(&w4, range: NSMakeRange(3, 1))
            
            let w = (w1 << 24) + (w2 << 16) + (w3 << 8) + w4
            var h1:Int = 0
            var h2:Int = 0
            var h3:Int = 0
            var h4:Int = 0
            (data as NSData).getBytes(&h1, range: NSMakeRange(4, 1))
            (data as NSData).getBytes(&h2, range: NSMakeRange(5, 1))
            (data as NSData).getBytes(&h3, range: NSMakeRange(6, 1))
            (data as NSData).getBytes(&h4, range: NSMakeRange(7, 1))
            let h = (h1 << 24) + (h2 << 16) + (h3 << 8) + h4
            
            return CGSize(width: CGFloat(w), height: CGFloat(h));
        }
        return CGSize.zero;
    }
   
    // MARK: - getGIFImageSize
    fileprivate class func getGIFImageSize(_ request:NSMutableURLRequest) -> CGSize {
        request.setValue("bytes=6-9", forHTTPHeaderField: "Range")
        guard let data: Data = URLSession.requestSynchronousData(request: request) as Data? else {
            return CGSize.zero
        }
        if data.count == 4 {
            var w1:Int = 0
            var w2:Int = 0
            
            (data as NSData).getBytes(&w1, range: NSMakeRange(0, 1))
            (data as NSData).getBytes(&w2, range: NSMakeRange(1, 1))
            
            let w = w1 + (w2 << 8)
            var h1:Int = 0
            var h2:Int = 0
            
            (data as NSData).getBytes(&h1, range: NSMakeRange(2, 1))
            (data as NSData).getBytes(&h2, range: NSMakeRange(3, 1))
            let h = h1 + (h2 << 8)
            
            return CGSize(width: CGFloat(w), height: CGFloat(h));
        }
        return CGSize.zero;
    }
    
    // MARK: - getJPGImageSize
    fileprivate class func getJPGImageSize(_ request:NSMutableURLRequest) -> CGSize {
        request.setValue("bytes=0-209", forHTTPHeaderField: "Range")
        guard let data: Data = URLSession.requestSynchronousData(request: request) as Data? else {
            return CGSize.zero
        }
        if data.count <= 0x58 {
            return CGSize.zero
            
        }
        if data.count < 210 {
            var w1:Int = 0
            var w2:Int = 0
            
            (data as NSData).getBytes(&w1, range: NSMakeRange(0x60, 0x1))
            (data as NSData).getBytes(&w2, range: NSMakeRange(0x61, 0x1))
            
            let w = (w1 << 8) + w2
            var h1:Int = 0
            var h2:Int = 0
            
            (data as NSData).getBytes(&h1, range: NSMakeRange(0x5e, 0x1))
            (data as NSData).getBytes(&h2, range: NSMakeRange(0x5f, 0x1))
            let h = (h1 << 8) + h2
            
            return CGSize(width: CGFloat(w), height: CGFloat(h));
            
        } else {
            var word = 0x0
            (data as NSData).getBytes(&word, range: NSMakeRange(0x15, 0x1))
            if word == 0xdb {
                (data as NSData).getBytes(&word, range: NSMakeRange(0x5a, 0x1))
                if word == 0xdb {
                    var w1:Int = 0
                    var w2:Int = 0
                    
                    (data as NSData).getBytes(&w1, range: NSMakeRange(0xa5, 0x1))
                    (data as NSData).getBytes(&w2, range: NSMakeRange(0xa6, 0x1))
                    
                    let w = (w1 << 8) + w2
                    var h1:Int = 0
                    var h2:Int = 0
                    
                    (data as NSData).getBytes(&h1, range: NSMakeRange(0xa3, 0x1))
                    (data as NSData).getBytes(&h2, range: NSMakeRange(0xa4, 0x1))
                    let h = (h1 << 8) + h2
                    
                    return CGSize(width: CGFloat(w), height: CGFloat(h));
                } else {
                    var w1:Int = 0
                    var w2:Int = 0
                    
                    (data as NSData).getBytes(&w1, range: NSMakeRange(0x60, 0x1))
                    (data as NSData).getBytes(&w2, range: NSMakeRange(0x61, 0x1))
                    
                    let w = (w1 << 8) + w2
                    var h1:Int = 0
                    var h2:Int = 0
                    
                    (data as NSData).getBytes(&h1, range: NSMakeRange(0x5e, 0x1))
                    (data as NSData).getBytes(&h2, range: NSMakeRange(0x5f, 0x1))
                    let h = (h1 << 8) + h2
                    
                    return CGSize(width: CGFloat(w), height: CGFloat(h));
                }
            } else {
                return CGSize.zero;
            }
        }
    }
}


extension FTChatMessageImageSize {
    
    internal class func getImageSizeForMessageBubbleFromURL(_ imageURL:String) ->CGSize {
        return self.convertSizeForMessageBubble(size: self.getImageSize(imageURL))
    }
    
    internal class func convertSizeForMessageBubble(size :CGSize) -> CGSize {
        var convertedSize : CGSize = CGSize.zero
        if size.width == 0 || size.height == 0 {
            return CGSize(width: FTDefaultMessageBubbleImageWidth,height: FTDefaultMessageBubbleImageHeight)
        }
        if size.width < FTDefaultMessageBubbleImageWidth/2 {
            convertedSize.height = (size.height * FTDefaultMessageBubbleImageWidth/2) / size.width
            convertedSize.width = FTDefaultMessageBubbleImageWidth/2
        }else{
            convertedSize.height = (size.height * FTDefaultMessageBubbleImageWidth) / size.width
            convertedSize.width = FTDefaultMessageBubbleImageWidth;
        }
        convertedSize.height = min(convertedSize.height, FTDefaultMessageBubbleImageWidth*2)
        return convertedSize
    }
}


