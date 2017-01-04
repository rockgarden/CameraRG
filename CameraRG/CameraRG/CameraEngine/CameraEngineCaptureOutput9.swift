//
//  CameraEngineCaptureOutput9.swift
//  CameraEngine
//
//  Created by wangkan on 2016/12/30.
//  Copyright © 2016年 Rockgarden. All rights reserved.
//

import AVFoundation

class CameraEngineCaptureOutput9: CameraEngineCaptureOutput {
    
    private let stillCameraOutput = AVCaptureStillImageOutput()
    
    func capturePhotoBuffer(_ blockCompletion: @escaping blockCompletionCapturePhotoBuffer) {
        guard let connectionVideo  = stillCameraOutput.connection(withMediaType: AVMediaTypeVideo) else {
            blockCompletion(nil, nil)
            return
        }
        connectionVideo.videoOrientation = AVCaptureVideoOrientation.orientationFromUIDeviceOrientation(UIDevice.current.orientation)
        stillCameraOutput.captureStillImageAsynchronously(from: connectionVideo, completionHandler: blockCompletion)
    }
    
    func capturePhoto(_ blockCompletion: @escaping blockCompletionCapturePhoto) {
        guard let connectionVideo  = stillCameraOutput.connection(withMediaType: AVMediaTypeVideo) else {
            blockCompletion(nil, nil)
            return
        }
        blockCompletionPhoto = blockCompletion
        connectionVideo.videoOrientation = AVCaptureVideoOrientation.orientationFromUIDeviceOrientation(UIDevice.current.orientation)
        stillCameraOutput.captureStillImageAsynchronously(from: connectionVideo) { (sampleBuffer, err) -> Void in
            if let err = err {
                blockCompletion(nil, err)
            }
            else {
                if let sampleBuffer = sampleBuffer, let dataImage = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer) {
                    let image = UIImage(data: dataImage)
                    blockCompletion(image, nil)
                }
                else {
                    blockCompletion(nil, nil)
                }
            }
        }
    }
    
    func configureCaptureOutput(_ session: AVCaptureSession, sessionQueue: DispatchQueue) {
        if session.canAddOutput(captureVideoOutput) {
            session.addOutput(captureVideoOutput)
            captureVideoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        }
        if session.canAddOutput(captureAudioOutput) {
            session.addOutput(captureAudioOutput)
            captureAudioOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        }
        if session.canAddOutput(stillCameraOutput) {
            session.addOutput(stillCameraOutput)
        }
    }
}



