//
//  CameraView.swift
//  CameraRG
//
//  Created by wangkan on 2017/1/4.
//  Copyright © 2017年 rockgarden. All rights reserved.
//

import UIKit
import AVFoundation

enum ModeCapture {
    case Photo
    case Video
}

public class CameraView: UIView {

    let cameraEngine = CameraEngine.sharedInstance
    fileprivate var cameraLayer: AVCaptureVideoPreviewLayer!
    var mode: ModeCapture = .Photo
    fileprivate let focusView = FocusView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        insertCameraLayer()
    }

    func insertCameraLayer() {
        guard let pl = cameraEngine.previewLayer else { return }
        cameraLayer = pl
        cameraLayer.frame = bounds
        self.layer.insertSublayer(cameraLayer, at: 0)
    }
    
    public func configureGesture() {
        if let gestureRecognizers = gestureRecognizers {
            gestureRecognizers.forEach({ removeGestureRecognizer($0) })
        }
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(zoom(_:)))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(focus(_:)))
        self.addGestureRecognizer(tapGesture)
        self.addGestureRecognizer(pinchGesture)
        isUserInteractionEnabled = true
        let lines = focusView.horizontalLines + focusView.verticalLines + focusView.outerLines
        lines.forEach { line in
            line.alpha = 0
        }
    }
    
    var originScaleFactor: CGFloat!
    internal func zoom(_ sender: UIPinchGestureRecognizer) {
        let gain: CGFloat = 1
        let minScaleFactor: CGFloat = 1, maxScaleFactor: CGFloat = 10
        switch sender.state {
        case .possible, .failed:
            return
        case .began:
            debugPrint("began",sender.scale)
            originScaleFactor = cameraEngine.cameraZoomFactor!
            break
        case .changed:
            debugPrint("changed",sender.scale)
            if (sender.scale > 1) {
                // increase zoom
                if (originScaleFactor <= maxScaleFactor) { cameraEngine.cameraZoomFactor = originScaleFactor * sender.scale * gain }
            } else {
                // decrease zoom
                if (originScaleFactor > minScaleFactor) { cameraEngine.cameraZoomFactor = originScaleFactor * sender.scale * gain}
            }
            break
        case .ended:
            debugPrint("ended",sender.scale)
            if (cameraEngine.cameraZoomFactor > 10) {
                cameraEngine.cameraZoomFactor = 10
            }
            if (cameraEngine.cameraZoomFactor < 1) {
                cameraEngine.cameraZoomFactor = 1
            }
            break
        default: break
        }
    }

    internal func focus(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: self)
        let viewsize = self.bounds.size
        let newPoint = CGPoint(x: point.y/viewsize.height, y: 1.0-point.x/viewsize.width)
        guard cameraEngine.focus(newPoint) else { return }
        focusView.alpha = 0.0
        focusView.center = point
        addSubview(focusView) //bringSubview(toFront: focusView)
        focusView.focusAnimate()
    }

    func setModeCapture() {    }

    public func cycleFlash() -> AVCaptureFlashMode {
        let fM = cameraEngine.flashMode
        if fM == .on {
            cameraEngine.flashMode = .off
        } else if fM == .off {
            cameraEngine.flashMode = .auto
        } else {
            cameraEngine.flashMode = .on
        }
        return cameraEngine.flashMode
    }

    /// 若是 View 支持 Orientation cameraLayer 会自动 Orientation
    public func rotatePreview() {
        guard cameraLayer != nil else {
            return
        }
        switch UIApplication.shared.statusBarOrientation {
        case .portrait:
            cameraLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
            break
        case .portraitUpsideDown:
            cameraLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            break
        case .landscapeRight:
            cameraLayer?.connection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
            break
        case .landscapeLeft:
            cameraLayer?.connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            break
        default: break
        }
    }

}

