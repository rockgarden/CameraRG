//
//  CameraEngineDevice.swift
//  CameraEngine2
//
//  Created by Remi Robert on 24/12/15.
//  Copyright © 2015 Remi Robert. All rights reserved.
//

import UIKit
import AVFoundation

public enum CameraEngineCameraFocus {

    case locked
    case autoFocus
    case continuousAutoFocus
    
    func foundationFocus() -> AVCaptureFocusMode {
        switch self {
        case .locked: return AVCaptureFocusMode.locked
        case .autoFocus: return AVCaptureFocusMode.autoFocus
        case .continuousAutoFocus: return AVCaptureFocusMode.continuousAutoFocus
        }
    }
    
    public func description() -> String {
        switch self {
        case .locked: return "Locked"
        case .autoFocus: return "AutoFocus"
        case .continuousAutoFocus: return "ContinuousAutoFocus"
        }
    }
    
    public static func availableFocus() -> [CameraEngineCameraFocus] {
        return [
            .locked,
            .autoFocus,
            .continuousAutoFocus
        ]
    }
}

class CameraEngineDevice {
    
    private var backCameraDevice: AVCaptureDevice!
    private var frontCameraDevice: AVCaptureDevice!
    var micCameraDevice: AVCaptureDevice!
    var currentDevice: AVCaptureDevice?
    var currentPosition: AVCaptureDevicePosition = .unspecified
    
    func changeCameraFocusMode(_ focusMode: CameraEngineCameraFocus) {
        if let currentDevice = currentDevice {
            do {
                try currentDevice.lockForConfiguration()
                if currentDevice.isFocusModeSupported(focusMode.foundationFocus()) {
                    currentDevice.focusMode = focusMode.foundationFocus()
                }
                currentDevice.unlockForConfiguration()
            }
            catch {
                fatalError("[CameraEngine] error, impossible to lock configuration device")
            }
        }
    }
    
    func changeCurrentZoomFactor(_ newFactor: CGFloat) -> CGFloat {
        var zoom: CGFloat = 1.0
        if let currentDevice = currentDevice {
            do {
                try currentDevice.lockForConfiguration()
                zoom = max(1.0, min(newFactor, currentDevice.activeFormat.videoMaxZoomFactor))
                currentDevice.videoZoomFactor = zoom
                currentDevice.unlockForConfiguration()
            }
            catch {
                zoom = -1.0
                fatalError("[CameraEngine] error, impossible to lock configuration device")
            }
        }
        return zoom
    }
    
    func changeCurrentDevice(_ position: AVCaptureDevicePosition) {
        currentPosition = position
        switch position {
        case .back: currentDevice = backCameraDevice
        case .front: currentDevice = frontCameraDevice
        case .unspecified: currentDevice = nil
        }
    }
    
    private func configureDeviceCamera() {
        if #available(iOS 10.0, *) {
            backCameraDevice = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInDuoCamera, AVCaptureDeviceType.builtInTelephotoCamera, AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.back).devices.first
            frontCameraDevice = AVCaptureDeviceDiscoverySession(deviceTypes: [AVCaptureDeviceType.builtInDuoCamera, AVCaptureDeviceType.builtInTelephotoCamera, AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.front).devices.first
        } else {
            let availableCameraDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
            for device in availableCameraDevices as! [AVCaptureDevice] {
                if device.position == .back {
                    backCameraDevice = device
                }
                else if device.position == .front {
                    frontCameraDevice = device
                }
            }
        }
    }
    
    private func configureDeviceMic() {
        micCameraDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
    }
    
    init() {
        configureDeviceCamera()
        configureDeviceMic()
        changeCurrentDevice(.back)
    }

}
