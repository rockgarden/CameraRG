//
//  CameraEngineFileManager.swift
//  CameraEngine2
//
//  Created by Remi Robert on 11/02/16.
//  Copyright © 2016 Remi Robert. All rights reserved.
//  Modified by wangkan on 2016/12/30
//

import UIKit
import Photos
import ImageIO

public typealias blockCompletionSaveMedia = (_ success: Bool, _ error: Error?) -> (Void)

public class CameraEngineFileManager {
    
    public class func savePhoto(_ image: UIImage, blockCompletion: blockCompletionSaveMedia?) {
        PHPhotoLibrary.shared().performChanges({ () -> Void in
            PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: blockCompletion)
    }

    public class func savePhotoInFolder(_ image: UIImage, fileName: String = UUID().uuidString, pathName: String = "Photos", blockCompletion: blockCompletionSaveMedia?) {
        do {
            let fm = FileManager()
            let docsurl = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let folder = docsurl.appendingPathComponent(pathName)
            do {
                try fm.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                blockCompletion!(false, error)
            }
            let originalImagePathURL = folder.appendingPathComponent(fileName)
            if let originalImageData = UIImageJPEGRepresentation(image, 1.0) {
                do {
                    try originalImageData.write(to: originalImagePathURL, options: [.atomic])
                    blockCompletion!(true, nil)
                    debugPrint("Photo URL: ",originalImagePathURL)
                } catch {
                    blockCompletion!(false, error)
                    debugPrint("[Camera engine] Error save image!")
                }
            }
        } catch {
            blockCompletion!(false, error)
        }
    }

    public class func savePhotoInDocument(_ image: UIImage, fileName: String = UUID().uuidString, blockCompletion: blockCompletionSaveMedia?) {
        let manager = FileManager.default
        if let documentsPath = manager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let originalImagePathURL = documentsPath.appendingPathComponent(fileName)
            if let originalImageData = UIImageJPEGRepresentation(image, 1.0) {
                //TODO: 如何 保存 photo 原始数据 与 附加信息 用 UIImagePNGRepresentation ?
                do {
                    try originalImageData.write(to: originalImagePathURL, options: [.atomic])
                    blockCompletion!(true, nil)
                    debugPrint("Photo URL: ",originalImagePathURL)
                } catch let err {
                    blockCompletion!(false, err)
                    debugPrint("[Camera engine] Error save image!")
                }
            }
        }
    }

    ///Non class func
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths.first! //paths[0]
        return documentsDirectory
    }

    public class func getPhotoInfo(_ url: URL) -> NSDictionary? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else {return nil}
        guard let resultCF = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) else {return nil}
        let result = resultCF as NSDictionary
        _ = result[kCGImagePropertyPixelWidth] as! CGFloat
        _ = result[kCGImagePropertyPixelHeight] as! CGFloat
        debugPrint("Photo info: ",result)
        return result
    }

    public class func getThumbnailPhoto(_ url: URL, thumbSize: CGFloat) -> UIImage? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else {return nil}
        let scale = UIScreen.main.scale
        let w = thumbSize * scale
        let d : NSDictionary = [
            kCGImageSourceShouldAllowFloat : true ,
            kCGImageSourceCreateThumbnailWithTransform : true ,
            kCGImageSourceCreateThumbnailFromImageAlways : true ,
            kCGImageSourceThumbnailMaxPixelSize : w
        ]
        guard let imref = CGImageSourceCreateThumbnailAtIndex(src, 0, d) else {return nil}
        let im = UIImage(cgImage: imref, scale: scale, orientation: .up)
        return im
    }

    public class func saveVideo(_ url: URL, blockCompletion: blockCompletionSaveMedia?) {
        PHPhotoLibrary.shared().performChanges({ () -> Void in
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }, completionHandler: blockCompletion)
    }
    
    public class func savePhotoVideo(_ image: UIImage, blockCompletion: blockCompletionSaveMedia?) {
        PHPhotoLibrary.shared().performChanges({ () -> Void in
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: blockCompletion)
    }

    public class func documentPath() -> String? {
        if let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last {
            return path
        }
        return nil
    }
    
    public class func temporaryPath() -> String {
        return NSTemporaryDirectory()
    }
    
    public class func documentPath(_ file: String) -> URL? {
        if let path = self.documentPath() {
            return URL(fileURLWithPath: self.appendPath(path, pathFile: file))
        }
        return nil
    }
    
    public class func temporaryPath(_ file: String) -> URL? {
        return URL(fileURLWithPath: appendPath(self.temporaryPath(), pathFile: file))
    }

    private class func appendPath(_ rootPath: String, pathFile: String) -> String {
        let destinationPath = rootPath + "/\(pathFile)"
        self.removeItemAtPath(destinationPath)
        return destinationPath
    }

    private class func removeItemAtPath(_ path: String) {
        let filemanager = FileManager.default
        if filemanager.fileExists(atPath: path) {
            do {
                try filemanager.removeItem(atPath: path)
            } catch {
                print("[Camera engine] Error remove path :\(path)")
            }
        }
    }
}
