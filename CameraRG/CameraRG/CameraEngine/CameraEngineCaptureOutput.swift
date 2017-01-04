//
//  CameraEngineCaptureOutput.swift
//  CameraEngine2
//
//  Created by Remi Robert on 24/12/15.
//  Copyright © 2015 Remi Robert. All rights reserved.
//  Modified by wangkan on 2016/12/30
//

import UIKit
import AVFoundation

public typealias blockCompletionCapturePhoto = (_ image: UIImage?, _ error: Error?) -> (Void)
public typealias blockCompletionCapturePhotoBuffer = ((_ sampleBuffer: CMSampleBuffer?, _ error: Error?) -> Void)
public typealias blockCompletionCaptureVideo = (_ url: URL?, _ error: NSError?) -> (Void)
public typealias blockCompletionOutputBuffer = (_ sampleBuffer: CMSampleBuffer) -> (Void)
public typealias blockCompletionProgressRecording = (_ duration: Float64) -> (Void)

extension AVCaptureVideoOrientation {
    static func orientationFromUIDeviceOrientation(_ orientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .portrait: return .portrait
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        case .portraitUpsideDown: return .portraitUpsideDown
        default: return .portrait
        }
    }
}

class CameraEngineCaptureOutput: NSObject {
    
    let movieFileOutput = AVCaptureMovieFileOutput()
    var captureVideoOutput = AVCaptureVideoDataOutput()
    var captureAudioOutput = AVCaptureAudioDataOutput()
    var blockCompletionVideo: blockCompletionCaptureVideo?
    var blockCompletionPhoto: blockCompletionCapturePhoto?
    
    let videoEncoder = CameraEngineVideoEncoder()
    
    var isRecording = false
    var blockCompletionBuffer: blockCompletionOutputBuffer?
    var blockCompletionProgress: blockCompletionProgressRecording?

    public static var sharedInstance: CameraEngineCaptureOutput {
        get {
            if #available(iOS 10.0, *) {
                return CameraEngineCaptureOutput10()
            } else {
                return CameraEngineCaptureOutput9()
            }
        }
    }
    
    func setPressetVideoEncoder(_ videoEncoderPresset: CameraEngineVideoEncoderEncoderSettings) {
        self.videoEncoder.presetSettingEncoder = videoEncoderPresset.configuration()
    }
    
    func startRecordVideo(_ blockCompletion: @escaping blockCompletionCaptureVideo, url: URL) {
        if self.isRecording == false {
            self.videoEncoder.startWriting(url)
            self.isRecording = true
        }
        else {
            self.isRecording = false
            self.stopRecordVideo()
        }
        self.blockCompletionVideo = blockCompletion
    }
    
    func stopRecordVideo() {
        self.isRecording = false
        self.videoEncoder.stopWriting(self.blockCompletionVideo)
    }
}


extension CameraEngineCaptureOutput: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    private func progressCurrentBuffer(_ sampleBuffer: CMSampleBuffer) {
        if let block = blockCompletionProgress, isRecording {
            block(videoEncoder.progressCurrentBuffer(sampleBuffer))
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        progressCurrentBuffer(sampleBuffer)
        if let block = self.blockCompletionBuffer {
            block(sampleBuffer)
        }
        if CMSampleBufferDataIsReady(sampleBuffer) == false || self.isRecording == false {
            return
        }
        if captureOutput == self.captureVideoOutput {
            self.videoEncoder.appendBuffer(sampleBuffer, isVideo: true)
        }
        else if captureOutput == self.captureAudioOutput {
            self.videoEncoder.appendBuffer(sampleBuffer, isVideo: false)
        }
    }
}


extension CameraEngineCaptureOutput: AVCaptureFileOutputRecordingDelegate {
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        print("start recording ...")
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        print("end recording video ... \(outputFileURL)")
        print("error : \(error)")
        if let blockCompletionVideo = self.blockCompletionVideo {
            blockCompletionVideo(outputFileURL, error as NSError?)
        }
    }
    
}
