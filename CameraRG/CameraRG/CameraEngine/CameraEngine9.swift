//
//  CameraEngine9.swift
//  CameraEngine
//
//  Created by wangkan on 2016/12/30.
//  Copyright © 2016年 Rockgarden. All rights reserved.
//

import AVFoundation

//TODO: 在 init or load 强转 cameraOutput as! CameraEngineCaptureOutput9
public class CameraEngine9: CameraEngine {
    
    //MARK: - Device management
    
    public override func configureFlash(_ mode: AVCaptureFlashMode) {
        if let currentDevice = cameraDevice.currentDevice, currentDevice.isFlashAvailable && currentDevice.flashMode != mode {
            do {
                try currentDevice.lockForConfiguration()
                currentDevice.flashMode = mode
                currentDevice.unlockForConfiguration()
            }
            catch {
                fatalError("[CameraEngine] error lock configuration device")
            }
        }
    }
    
    public override func switchCurrentDevice() {
        if isRecording == false {
            changeCurrentDevice((cameraDevice.currentPosition == .back) ? .front : .back)
        }
    }

    
    //MARK: - Device I/O configuration
    
    public override func configureOutputDevice() {
        let cameraOutput9 = cameraOutput as! CameraEngineCaptureOutput9
        cameraOutput9.configureCaptureOutput(session, sessionQueue: self.sessionQueue)
        cameraMetadata.previewLayer = previewLayer
        cameraMetadata.configureMetadataOutput(session, sessionQueue: self.sessionQueue, metadataType: metadataDetection)
    }
    
    
    //MARK: - Extension capture

    public override func capturePhoto(_ blockCompletion: @escaping blockCompletionCapturePhoto) {
        let cameraOutput9 = cameraOutput as! CameraEngineCaptureOutput9
        cameraOutput9.capturePhoto(blockCompletion)
    }

    public override func capturePhotoBuffer(_ blockCompletion: @escaping blockCompletionCapturePhotoBuffer) {
        let cameraOutput9 = cameraOutput as! CameraEngineCaptureOutput9
        cameraOutput9.capturePhotoBuffer(blockCompletion)
    }
    
    public override func startRecordingVideo(_ url: URL, blockCompletion: @escaping blockCompletionCaptureVideo) {
        if isRecording == false {
            sessionQueue.async(execute: { () -> Void in
                self.cameraOutput.startRecordVideo(blockCompletion, url: url)
            })
        }
    }
    
    public override func stopRecordingVideo() {
        if isRecording {
            sessionQueue.async(execute: { () -> Void in
                self.cameraOutput.stopRecordVideo()
            })
        }
    }
    
}
