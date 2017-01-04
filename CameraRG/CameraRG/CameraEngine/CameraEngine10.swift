//
//  CameraEngine10.swift
//  CameraEngine
//
//  Created by wangkan on 2016/12/30.
//  Copyright © 2016年 Rockgarden. All rights reserved.
//

import AVFoundation

@available(iOS 10.0, *)
public class CameraEngine10: CameraEngine {

    private let capturePhotoSettings = AVCapturePhotoSettings()
    
    //MARK: - Device management
    
    public override func configureFlash(_ mode: AVCaptureFlashMode) {
        if let currentDevice = cameraDevice.currentDevice, currentDevice.isFlashAvailable && capturePhotoSettings.flashMode != mode {
            capturePhotoSettings.flashMode = mode
        }
    }
    
    //MARK: - Device I/O configuration
    
    public override func configureOutputDevice() {
        let cameraOutput10 = cameraOutput as! CameraEngineCaptureOutput10
        cameraOutput10.configureCaptureOutput(session, sessionQueue: sessionQueue)
        cameraMetadata.previewLayer = previewLayer
        cameraMetadata.configureMetadataOutput(session, sessionQueue: sessionQueue, metadataType: metadataDetection)
    }
    
    
    //MARK: - Extension capture
    
    /* Important: AVCapturePhotoSettings 必须 init, 不可引用!
     It is illegal to reuse a AVCapturePhotoSettings instance for multiple captures. Calling the capturePhoto(with:delegate:) method throws an exception (invalidArgumentException) if the settings object’s uniqueID value matches that of any previously used settings object.
     To reuse a specific combination of settings, use the init(from:) initializer to create a new, unique AVCapturePhotoSettings instance from an existing photo settings object.
     To take a picture, a client instantiates and configures an AVCapturePhotoSettings object, then calls AVCapturePhotoOutput's -capturePhotoWithSettings:delegate:, passing the settings and a delegate to be informed when events relating to the photo capture occur.
     Since AVCapturePhotoSettings has no reference to the AVCapturePhotoOutput instance with which it will be used, minimal validation occurs while you configure an AVCapturePhotoSettings instance. The bulk of the validation is executed when you call AVCapturePhotoOutput's -capturePhotoWithSettings:delegate:.
     */
    public override func capturePhoto(_ blockCompletion: @escaping blockCompletionCapturePhoto) {
        let uniqueSettings = AVCapturePhotoSettings.init(from: capturePhotoSettings)
        let cameraOutput10 = cameraOutput as! CameraEngineCaptureOutput10
        cameraOutput10.capturePhoto(settings: uniqueSettings, blockCompletion)
    }
    
    public override func capturePhotoBuffer(_ blockCompletion: @escaping blockCompletionCapturePhotoBuffer) {
        let uniqueSettings = AVCapturePhotoSettings.init(from: capturePhotoSettings)
        let cameraOutput10 = cameraOutput as! CameraEngineCaptureOutput10
        cameraOutput10.capturePhotoBuffer(settings: uniqueSettings, blockCompletion)
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
