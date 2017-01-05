//
//  ViewController.swift
//  CameraRG_Demo
//
//  Created by wangkan on 2017/1/4.
//  Copyright © 2017年 rockgarden. All rights reserved.
//

import UIKit
import CameraRG
import AVFoundation

enum ModeCapture {
    case Photo
    case Video
}

public let isVersionOrLater10: Bool = (UIDevice().systemVersion as NSString).floatValue >= 10.0

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    fileprivate var cameraEngine = CameraEngine.sharedInstance
    fileprivate var mode: ModeCapture = .Photo
    fileprivate var cameraLayer: AVCaptureVideoPreviewLayer!
    fileprivate var focusView: UIView?
    
    //TODO: add var previewViewContainer: UIView! for cameraLayer is better
    
    @IBOutlet weak var buttonMode: UIButton!
    @IBOutlet weak var labelMode: UILabel!
    @IBOutlet weak var buttonTrigger: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.cameraEngine.startSession()
        //initFocusView()
    }
    
    func initFocusView() {
        focusView = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
        let tapRecognizer = UITapGestureRecognizer(target: self, action:#selector(focus(_:)))
        tapRecognizer.delegate = self
        self.view.addGestureRecognizer(tapRecognizer)
    }
    
    /*
     FIXME: 在这里 insertCameraLayer() 的好处, 可解决旋屏后 CameraLayer 重绘
     1、init初始化不会触发layoutSubviews
     2、addSubview会触发layoutSubviews
     3、设置view的Frame会触发layoutSubviews，当然前提是frame的值设置前后发生了变化
     4、滚动一个UIScrollView会触发layoutSubviews
     5、旋转Screen会触发父UIView上的layoutSubviews事件
     6、改变一个UIView大小的时候也会触发父UIView上的layoutSubviews事件
     */
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //insertCameraLayer()
    }
    
    func insertCameraLayer() {
        guard let layer = cameraEngine.previewLayer else { return }
        cameraLayer = layer
        cameraLayer.frame = self.view.bounds
        self.view.layer.insertSublayer(cameraLayer, at: 0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //self.cameraEngine.rotationCamera = true
    }
    
    @IBAction func setModeCapture(_ sender: AnyObject) {
        let alertController = UIAlertController(title: "set mode capture", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Photo", style: .default, handler: {  _ in
            self.labelMode.text = "Photo"
            self.buttonTrigger.setTitle("take picture", for: .normal)
            self.mode = .Photo
        }))
        alertController.addAction(UIAlertAction(title: "Video", style: .default, handler: {  _ in
            self.labelMode.text = "Video"
            self.buttonTrigger.setTitle("start recording", for: .normal)
            self.mode = .Video
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func encoderSettingsPresset(_ sender: AnyObject) {
        let alertController = UIAlertController(title: "Encoder settings", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Preset640x480", style: .default, handler: { _ in
            self.cameraEngine.videoEncoderPresset = .Preset640x480
        }))
        alertController.addAction(UIAlertAction(title: "Preset960x540", style: .default, handler: { _ in
            self.cameraEngine.videoEncoderPresset = .Preset960x540
        }))
        alertController.addAction(UIAlertAction(title: "Preset1280x720", style: .default, handler: { _ in
            self.cameraEngine.videoEncoderPresset = .Preset1280x720
        }))
        alertController.addAction(UIAlertAction(title: "Preset1920x1080", style: .default, handler: { _ in
            self.cameraEngine.videoEncoderPresset = .Preset1920x1080
        }))
        alertController.addAction(UIAlertAction(title: "Preset3840x2160", style: .default, handler: { _ in
            self.cameraEngine.videoEncoderPresset = .Preset3840x2160
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func setZoomCamera(_ sender: AnyObject) { }
    
    @IBAction func setFocus(_ sender: AnyObject) {
        let alertController = UIAlertController(title: "set focus settings", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Locked", style: .default) { _ in
            self.cameraEngine.cameraFocus = CameraEngineCameraFocus.locked
        })
        alertController.addAction(UIAlertAction(title: "auto focus", style: .default) { _ in
            self.cameraEngine.cameraFocus = CameraEngineCameraFocus.autoFocus
        })
        alertController.addAction(UIAlertAction(title: "continious auto focus", style: .default) { _ in
            self.cameraEngine.cameraFocus = CameraEngineCameraFocus.continuousAutoFocus
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func switchCamera(_ sender: AnyObject) {
        _ = cameraEngine.switchCurrentDevice()
    }
    
    @IBAction func takePhoto(_ sender: AnyObject) {
        
        func alartLocal(t: String) {
            let alertController =  UIAlertController(title: t, message: nil, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
        
        switch self.mode {
        case .Photo:
            self.cameraEngine.capturePhoto { (image , error) -> (Void) in
                if let image = image {
                    CameraEngineFileManager.savePhoto(image) {(success, error) -> (Void) in
                        if success {
                            alartLocal(t: "Success, image saved !")
                        }
                    }
                }
            }
        case .Video:
            if !cameraEngine.isRecording {
                if let url = CameraEngineFileManager.temporaryPath("video.mp4") {
                    self.buttonTrigger.setTitle("stop recording", for: .normal)
                    cameraEngine.startRecordingVideo(url) {(url, error) -> (Void) in
                        if let url = url {
                            DispatchQueue.main.async {
                                self.buttonTrigger.setTitle("start recording", for: .normal)
                                CameraEngineFileManager.saveVideo(url) {(success, error) -> (Void) in
                                    if success {
                                        alartLocal(t: "Success, video saved !")
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                self.cameraEngine.stopRecordingVideo()
            }
        }
    }
    
    @objc func focus(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: self.view)
        let viewsize = self.view.bounds.size
        let newPoint = CGPoint(x: point.y/viewsize.height, y: 1.0-point.x/viewsize.width)
        
        _ = cameraEngine.focus(newPoint)
        
        focusView?.alpha = 0.0
        focusView?.center = point
        focusView?.backgroundColor = UIColor.clear
        focusView?.layer.borderColor = UIColor.green.cgColor
        focusView?.layer.borderWidth = 1.0
        focusView!.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        self.view.addSubview(focusView!)
        
        UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 6.0, options: .curveEaseIn, // UIViewAnimationOptions.BeginFromCurrentState
            animations: {
                self.focusView!.alpha = 1.0
                self.focusView!.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }, completion: { _ in
            self.focusView!.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            debugPrint(self.view)
            debugPrint(self.focusView!.superview as Any)
            self.focusView!.removeFromSuperview()
        })
    }

    var croppingEnabled: Bool = false
    var libraryEnabled: Bool = true
    @IBAction func openCamera(_ sender: AnyObject) {
        let cameraViewController = CameraVC(croppingEnabled: croppingEnabled, allowsLibraryAccess: libraryEnabled) { [weak self] image, asset in
            //self?.imageView.image = image
            self?.dismiss(animated: true, completion: nil)
        }

        present(cameraViewController, animated: true, completion: nil)
    }
}

