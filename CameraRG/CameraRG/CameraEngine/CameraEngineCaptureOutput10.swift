//
//  CameraEngineCaptureOutput10.swift
//  CameraEngine
//
//  Created by wangkan on 2016/12/30.
//  Copyright © 2016年 Rockgarden. All rights reserved.
//

import AVFoundation

@available(iOS 10.0, *)
class CameraEngineCaptureOutput10: CameraEngineCaptureOutput {
    
    private let stillCameraOutput = AVCapturePhotoOutput()
    
    func capturePhotoBuffer(settings: AVCapturePhotoSettings, _ blockCompletion: @escaping blockCompletionCapturePhotoBuffer) {
        guard let connectionVideo  = stillCameraOutput.connection(withMediaType: AVMediaTypeVideo) else {
            blockCompletion(nil, nil)
            return
        }
        connectionVideo.videoOrientation = AVCaptureVideoOrientation.orientationFromUIDeviceOrientation(UIDevice.current.orientation)
        stillCameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func capturePhoto(settings: AVCapturePhotoSettings, _ blockCompletion: @escaping blockCompletionCapturePhoto) {
        guard let connectionVideo  = stillCameraOutput.connection(withMediaType: AVMediaTypeVideo) else {
            blockCompletion(nil, nil)
            return
        }
        blockCompletionPhoto = blockCompletion
        connectionVideo.videoOrientation = AVCaptureVideoOrientation.orientationFromUIDeviceOrientation(UIDevice.current.orientation)
        stillCameraOutput.capturePhoto(with: settings, delegate: self)
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

@available(iOS 10.0, *)
extension CameraEngineCaptureOutput10: AVCapturePhotoCaptureDelegate {

    public func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let error = error {
            blockCompletionPhoto?(nil, error)
        }
        else {
            if let sampleBuffer = photoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: nil) {
                let image = UIImage(data: dataImage)
                blockCompletionPhoto?(image, nil)
            }
            else {
                blockCompletionPhoto?(nil, nil)
            }
        }
    }
}


