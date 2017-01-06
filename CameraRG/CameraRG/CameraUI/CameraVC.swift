//
//  CameraVC.swift
//  CameraRG
//
//  Created by wangkan on 2017/1/4.
//  Copyright © 2017年 rockgarden. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

public extension CameraVC {
    public class func imagePickerViewController(croppingEnabled: Bool, completion: @escaping CameraCompletion) -> UINavigationController {
        let imagePicker = PhotoLibraryViewController()
        let navigationController = UINavigationController(rootViewController: imagePicker)
        
        navigationController.navigationBar.barTintColor = UIColor.black
        navigationController.navigationBar.barStyle = UIBarStyle.black
        navigationController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        
        imagePicker.onSelectionComplete = { [weak imagePicker] asset in
            if let asset = asset {
                let confirmController = ConfirmViewController(asset: asset, allowsCropping: croppingEnabled)
                confirmController.onComplete = { [weak imagePicker] image, asset in
                    if let image = image, let asset = asset {
                        completion(image, asset)
                    } else {
                        imagePicker?.dismiss(animated: true, completion: nil)
                    }
                }
                confirmController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
                imagePicker?.present(confirmController, animated: true, completion: nil)
            } else {
                completion(nil, nil)
            }
        }
        return navigationController
    }
}


public typealias CameraCompletion = (UIImage?, PHAsset?) -> Void

public class CameraVC: UIViewController {
    
    var didUpdateViews = false
    var allowCropping = false
    var animationRunning = false
    
    var lastInterfaceOrientation : UIInterfaceOrientation?
    var onCompletion: CameraCompletion?
    var volumeControl: VolumeControl?
    
    var animationDuration: TimeInterval = 0.5
    var animationSpring: CGFloat = 0.5
    var rotateAnimation: UIViewAnimationOptions = .curveLinear
    
    var cameraButtonEdgeConstraint: NSLayoutConstraint?
    var cameraButtonGravityConstraint: NSLayoutConstraint?
    
    var closeButtonEdgeConstraint: NSLayoutConstraint?
    var closeButtonGravityConstraint: NSLayoutConstraint?
    
    var containerButtonsEdgeOneConstraint: NSLayoutConstraint?
    var containerButtonsEdgeTwoConstraint: NSLayoutConstraint?
    var containerButtonsGravityConstraint: NSLayoutConstraint?
    
    var swapButtonEdgeOneConstraint: NSLayoutConstraint?
    var swapButtonEdgeTwoConstraint: NSLayoutConstraint?
    var swapButtonGravityConstraint: NSLayoutConstraint?
    
    var libraryButtonEdgeOneConstraint: NSLayoutConstraint?
    var libraryButtonEdgeTwoConstraint: NSLayoutConstraint?
    var libraryButtonGravityConstraint: NSLayoutConstraint?
    
    var flashButtonEdgeConstraint: NSLayoutConstraint?
    var flashButtonGravityConstraint: NSLayoutConstraint?
    
    var zoomButtonEdgeConstraint: NSLayoutConstraint?
    var zoomButtonGravityConstraint: NSLayoutConstraint?
    
    var cameraOverlayEdgeOneConstraint: NSLayoutConstraint?
    var cameraOverlayEdgeTwoConstraint: NSLayoutConstraint?
    var cameraOverlayWidthConstraint: NSLayoutConstraint?
    var cameraOverlayCenterConstraint: NSLayoutConstraint?
    
    let cameraView : CameraView = {
        let cameraView = CameraView()
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        return cameraView
    }()
    
    let cameraOverlay : FocusView = {
        let cameraOverlay = FocusView()
        cameraOverlay.translatesAutoresizingMaskIntoConstraints = false
        return cameraOverlay
    }()
    
    let cameraButton : UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        button.setImage(UIImage(named: "cameraButton",
                                in: Bundle(for: CameraVC.self),
                                compatibleWith: nil),
                        for: .normal)
        button.setImage(UIImage(named: "cameraButtonHighlighted",
                                in: Bundle(for: CameraVC.self),
                                compatibleWith: nil),
                        for: .highlighted)
        return button
    }()
    
    let closeButton : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "closeButton",
                                in: Bundle(for: CameraVC.self),
                                compatibleWith: nil),
                        for: .normal)
        return button
    }()
    
    let swapButton : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "swapButton",
                                in: Bundle(for: CameraVC.self),
                                compatibleWith: nil),
                        for: .normal)
        return button
    }()
    
    let libraryButton : UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "libraryButton",
                                in: Bundle(for: CameraVC.self),
                                compatibleWith: nil),
                        for: .normal)
        return button
    }()
    
    let flashButton : UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "flashAutoIcon",
                                in: Bundle(for: CameraVC.self),
                                compatibleWith: nil),
                        for: .normal)
        return button
    }()
    
    let zoomButton : UIButton = {
        let button = SqueezeButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundImage(UIImage(named: "flashOffIcon",
                                in: Bundle(for: CameraVC.self),
                                compatibleWith: nil),
                        for: .normal)
        button.setTitle("x1", for: .normal)
        button.setTitleColor(.yellow, for: .normal)
        return button
    }()
    
    let containerSwapLibraryButton : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    public init(croppingEnabled: Bool, allowsLibraryAccess: Bool = true, completion: @escaping CameraCompletion) {
        super.init(nibName: nil, bundle: nil)
        onCompletion = completion
        allowCropping = croppingEnabled
        cameraOverlay.isHidden = !allowCropping
        libraryButton.isEnabled = allowsLibraryAccess
        libraryButton.isHidden = !allowsLibraryAccess
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    /**
     * Configure the background of the superview to black
     * and add the views on this superview. Then, request
     * the update of constraints for this superview.
     */
    public override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.black
        [cameraView,
         cameraOverlay,
         cameraButton,
         closeButton,
         flashButton,
         zoomButton,
         containerSwapLibraryButton].forEach({ view.addSubview($0) })
        [swapButton, libraryButton].forEach({ containerSwapLibraryButton.addSubview($0) })
        view.setNeedsUpdateConstraints()
    }
    
    /**
     * Setup the constraints when the app is starting or rotating the screen.
     * To avoid the override/conflict of stable constraint, these
     * stable constraint are one time configurable.
     * Any other dynamic constraint are configurable when the
     * device is rotating, based on the device orientation.
     */
    override public func updateViewConstraints() {

        if !didUpdateViews {
            configCameraViewConstraints()
            didUpdateViews = true
        }
        
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        let portrait = statusBarOrientation.isPortrait
        
        configCameraButtonEdgeConstraint(statusBarOrientation)
        configCameraButtonGravityConstraint(portrait)
        
        removeCloseButtonConstraints()
        configCloseButtonEdgeConstraint(statusBarOrientation)
        configCloseButtonGravityConstraint(statusBarOrientation)
        
        removeContainerConstraints()
        configContainerEdgeConstraint(statusBarOrientation)
        configContainerGravityConstraint(statusBarOrientation)
        
        removeSwapButtonConstraints()
        configSwapButtonEdgeConstraint(statusBarOrientation)
        configSwapButtonGravityConstraint(portrait)
        
        removeLibraryButtonConstraints()
        configLibraryEdgeButtonConstraint(statusBarOrientation)
        configLibraryGravityButtonConstraint(portrait)
        
        configFlashEdgeButtonConstraint(statusBarOrientation)
        configFlashGravityButtonConstraint(statusBarOrientation)
        
        configZoomEdgeButtonConstraint(statusBarOrientation)
        configZoomGravityButtonConstraint(statusBarOrientation)
        
        let padding : CGFloat = portrait ? 16.0 : -16.0
        removeCameraOverlayEdgesConstraints()
        configCameraOverlayEdgeOneContraint(portrait, padding: padding)
        configCameraOverlayEdgeTwoConstraint(portrait, padding: padding)
        configCameraOverlayWidthConstraint(portrait)
        configCameraOverlayCenterConstraint(portrait)
        
        rotate(actualInterfaceOrientation: statusBarOrientation)
        
        super.updateViewConstraints()
    }
    
    /**
     * Add observer to check when the camera has started,
     * enable the volume buttons to take the picture,
     * configure the actions of the buttons on the screen,
     * check the permissions of access of the camera and
     * the photo library.
     * Configure the camera focus when the application
     * start, to avoid any bluried image.
     */
    public override func viewDidLoad() {
        super.viewDidLoad()
        addCameraObserver()
        addRotateObserver()
        addCameraZoomObserver()
        setupVolumeControl()
        setupActions()
        //checkPermissions()
        cameraView.configureGesture()
    }
    
    /**
     * Start the session of the camera.
     */
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraView.cameraEngine.startSession()
    }
    
    /**
     * Enable the button to take the picture when the camera is ready.
     */
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if cameraView.cameraEngine.session.isRunning == true {
            notifyCameraReady()
        }
    }
    
    /**
     * This method will disable the rotation of the
     */
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        lastInterfaceOrientation = UIApplication.shared.statusBarOrientation
        if animationRunning {
            return
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        coordinator.animate(alongsideTransition: { animation in
            self.view.setNeedsUpdateConstraints()
        }, completion: { _ in
            CATransaction.commit()
        })
    }
    
    /**
     * Observer the camera status, when it is ready,
     * it calls the method cameraReady to enable the
     * button to take the picture.
     */
    private func addCameraObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notifyCameraReady),
            name: NSNotification.Name.AVCaptureSessionDidStartRunning,
            object: nil)
    }
    
    /**
     * Observer the device orientation to update the orientation of CameraView.
     */
    private func addRotateObserver() {
        cameraView.cameraEngine.rotationCamera = true
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(rotateCameraView),
//            name: NSNotification.Name.UIDeviceOrientationDidChange,
//            object: nil)
    }
    
    /**
     * Observer the camera zoom factor, when it is changed,
     * it set the zoomButton title to equal new cameraZoomFactor.
     */
    private func addCameraZoomObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notifyCameraZoom),
            name: NSNotification.Name(rawValue: "videoZoomFactor"),
            object: nil)
    }
    
    internal func notifyCameraZoom(_ n: Notification) {
        guard let z = n.object else {return}
        self.zoomButton.setTitle("×\(String(describing: z))", for: .normal)
    }
    
    internal func notifyCameraReady() {
        cameraButton.isEnabled = true
    }
    
    /**
     * Attach the take of picture for any volume button.
     */
    private func setupVolumeControl() {
        volumeControl = VolumeControl(view: view) { [weak self] _ in
            if self?.cameraButton.isEnabled == true {
                self?.capturePhoto()
            }
        }
    }
    
    /**
     * Configure the action for every button on this
     * layout.
     */
    private func setupActions() {
        cameraButton.action = { [weak self] in self?.capturePhoto() }
        swapButton.action = { [weak self] in self?.swapCamera() }
        libraryButton.action = { [weak self] in self?.showLibrary() }
        closeButton.action = { [weak self] in self?.close() }
        flashButton.action = { [weak self] in self?.toggleFlash() }
        zoomButton.action = { [weak self] in self?.zoomOne() }
    }
    
    /**
     * Toggle the buttons status, based on the actual
     * state of the camera.
     */
    private func toggleButtons(enabled: Bool) {
        [cameraButton,
         closeButton,
         swapButton,
         libraryButton].forEach({ $0.isEnabled = enabled })
    }
    
    func rotateCameraView() {
        cameraView.rotatePreview()
    }
    
    /**
     * This method will rotate the buttons based on
     * the last and actual orientation of the device.
     */
    internal func rotate(actualInterfaceOrientation: UIInterfaceOrientation) {
        
        if lastInterfaceOrientation != nil {
            let lastTransform = CGAffineTransform(rotationAngle: CGFloat(radians(currentRotation(
                lastInterfaceOrientation!, newOrientation: actualInterfaceOrientation))))
            self.setTransform(transform: lastTransform)
        }
        
        let transform = CGAffineTransform(rotationAngle: 0)
        animationRunning = true
        
        /**
         * Dispach delay to avoid any conflict between the CATransaction of rotation of the screen
         * and CATransaction of animation of buttons.
         */
        
        let time = DispatchTime.now() + Double(1 * UInt64(NSEC_PER_SEC)/10)
        DispatchQueue.main.asyncAfter(deadline: time) {
            
            CATransaction.begin()
            CATransaction.setDisableActions(false)
            CATransaction.commit()
            
            UIView.animate(
                withDuration: self.animationDuration,
                delay: 0.1,
                usingSpringWithDamping: self.animationSpring,
                initialSpringVelocity: 0,
                options: self.rotateAnimation,
                animations: {
                    self.setTransform(transform: transform)
            }, completion: { _ in
                self.animationRunning = false
            })
        }
    }
    
    func setTransform(transform: CGAffineTransform) {
        closeButton.transform = transform
        swapButton.transform = transform
        libraryButton.transform = transform
        flashButton.transform = transform
        zoomButton.transform = transform
    }
    
    /**
     * Validate the permissions of the camera and
     * library, if the user do not accept these
     * permissions, it shows an view that notifies
     * the user that it not allow the permissions.
     */
    private func checkPermissions() {
        if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) != .authorized {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { granted in
                DispatchQueue.main.async() {
                    if !granted {
                        self.showNoPermissionsView()
                    }
                }
            }
        }
    }
    
    /**
     * Generate the view of no permission.
     */
    private func showNoPermissionsView(library: Bool = false) {
        let permissionsView = PermissionsView(frame: view.bounds)
        let title: String
        let desc: String
        
        if library {
            title = localizedString("permissions.library.title")
            desc = localizedString("permissions.library.description")
        } else {
            title = localizedString("permissions.title")
            desc = localizedString("permissions.description")
        }
        
        permissionsView.configureInView(view, title: title, descriptiom: desc, completion: close)
    }
    
    /**
     * This method will be called when the user try to take the picture.
     * It will lock any button while the shot is taken, then, realease the buttons and save the picture on the device.
     */
    internal func capturePhoto() {

        toggleButtons(enabled: false)

        func alartLocal(t: String) {
            let alertController =  UIAlertController(title: t, message: nil, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }

        switch cameraView.mode {
        case .Photo:
            cameraView.cameraEngine.capturePhoto { (image , error) -> (Void) in
                if let image = image {
                    CameraEngineFileManager.savePhoto(image) {(success, error) -> (Void) in
                        if success {
                            alartLocal(t: "Success, image saved !")
                        }
                    }
                }
            }
        case .Video:
            if !cameraView.cameraEngine.isRecording {
                if let url = CameraEngineFileManager.temporaryPath("video.mp4") {
                    cameraButton.setTitle("stop", for: .normal)
                    cameraView.cameraEngine.startRecordingVideo(url) {(url, error) -> (Void) in
                        if let url = url {
                            DispatchQueue.main.async {
                                self.cameraButton.setTitle("start", for: .normal)
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
                cameraView.cameraEngine.stopRecordingVideo()
            }
        }

        toggleButtons(enabled: true)
    }
    
    internal func saveImage(image: UIImage) {
        _ = SingleImageSaver()
            .setImage(image)
            .onSuccess { asset in
                self.layoutCameraResult(asset: asset)
            }
            .onFailure { error in
                self.toggleButtons(enabled: true)
                self.showNoPermissionsView(library: true)
            }
            .save()
    }
    
    internal func close() {
        onCompletion?(nil, nil)
    }
    
    internal func showLibrary() {
        let imagePicker = CameraVC.imagePickerViewController(croppingEnabled: allowCropping) { image, asset in
            defer {
                self.dismiss(animated: true, completion: nil)
            }
            guard let image = image, let asset = asset else {
                return
            }
            self.onCompletion?(image, asset)
        }
        present(imagePicker, animated: true) {
            self.cameraView.cameraEngine.stopSession()
        }
    }
    
    internal func toggleFlash() {
        let fM = cameraView.cycleFlash()
        let image = UIImage(named: flashImage(fM),
                            in: Bundle(for: CameraVC.self),
                            compatibleWith: nil)
        flashButton.setImage(image, for: .normal)
    }
    
    internal func zoomOne() {
        cameraView.cameraEngine.cameraZoomFactor = 1.0
        zoomButton.setTitle("x1", for: .normal)
    }
    
    internal func swapCamera() {
        let isBack = cameraView.cameraEngine.switchCurrentDevice()
        if isBack { flashButton.isHidden = false } else {flashButton.isHidden = true}
    }
    
    internal func layoutCameraResult(asset: PHAsset) {
        cameraView.cameraEngine.stopSession()
        startConfirmController(asset: asset)
        toggleButtons(enabled: true)
    }
    
    private func startConfirmController(asset: PHAsset) {
        let confirmViewController = ConfirmViewController(asset: asset, allowsCropping: allowCropping)
        confirmViewController.onComplete = { image, asset in
            if let image = image, let asset = asset {
                self.onCompletion?(image, asset)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
        confirmViewController.modalTransitionStyle = .crossDissolve
        present(confirmViewController, animated: true, completion: nil)
    }
    
}


//
//  CameraViewControllerConstraint.swift
//  CameraViewControllerConstraint
//
//  Created by Pedro Paulo de Amorim.
//  Copyright (c) 2016 zero. All rights reserved.
//

/**
 * This extension provides the configuration of
 * constraints for CameraViewController.
 */
internal extension CameraVC {
    
    /**
     * To attach the view to the edges of the superview, it needs
     to be pinned on the sides of the self.view, based on the
     edges of this superview.
     * This configure the cameraView to show, in real time, the
     * camera.
     */
    func configCameraViewConstraints() {
        [.left, .right, .top, .bottom].forEach({
            view.addConstraint(NSLayoutConstraint(
                item: cameraView,
                attribute: $0,
                relatedBy: .equal,
                toItem: view,
                attribute: $0,
                multiplier: 1.0,
                constant: 0))
        })
    }
    
    /**
     * Add the constraints based on the device orientation,
     * this pin the button on the bottom part of the screen
     * when the device is portrait, when landscape, pin
     * the button on the right part of the screen.
     */
    func configCameraButtonEdgeConstraint(_ statusBarOrientation: UIInterfaceOrientation) {
        view.autoRemoveConstraint(cameraButtonEdgeConstraint)
        
        let attribute : NSLayoutAttribute = {
            switch statusBarOrientation {
            case .portrait: return .bottom
            case .landscapeRight: return .right
            case .landscapeLeft: return .left
            default: return .top
            }
        }()
        
        cameraButtonEdgeConstraint = NSLayoutConstraint(
            item: cameraButton,
            attribute: attribute,
            relatedBy: .equal,
            toItem: view,
            attribute: attribute,
            multiplier: 1.0,
            constant: attribute == .right || attribute == .bottom ? -8 : 8)
        view.addConstraint(cameraButtonEdgeConstraint!)
    }
    
    /**
     * Add the constraints based on the device orientation,
     * centerX the button based on the width of screen.
     * When the device is landscape orientation, centerY
     * the button based on the height of screen.
     */
    func configCameraButtonGravityConstraint(_ portrait: Bool) {
        view.autoRemoveConstraint(cameraButtonGravityConstraint)
        let attribute : NSLayoutAttribute = portrait ? .centerX : .centerY
        cameraButtonGravityConstraint = NSLayoutConstraint(
            item: cameraButton,
            attribute: attribute,
            relatedBy: .equal,
            toItem: view,
            attribute: attribute,
            multiplier: 1.0,
            constant: 0)
        view.addConstraint(cameraButtonGravityConstraint!)
    }
    
    /**
     * Remove the constraints of container.
     */
    func removeContainerConstraints() {
        view.autoRemoveConstraint(containerButtonsEdgeOneConstraint)
        view.autoRemoveConstraint(containerButtonsEdgeTwoConstraint)
        view.autoRemoveConstraint(containerButtonsGravityConstraint)
    }
    
    /**
     * Configure the edges constraints of container that
     * handle the center position of SwapButton and LibraryButton.
     */
    func configContainerEdgeConstraint(_ statusBarOrientation : UIInterfaceOrientation) {
        
        let attributeOne : NSLayoutAttribute
        let attributeTwo : NSLayoutAttribute
        
        switch statusBarOrientation {
        case .portrait:
            attributeOne = .left
            attributeTwo = .right
            break
        case .landscapeRight:
            attributeOne = .bottom
            attributeTwo = .top
            break
        case .landscapeLeft:
            attributeOne = .top
            attributeTwo = .bottom
            break
        default:
            attributeOne = .right
            attributeTwo = .left
            break
        }
        
        containerButtonsEdgeOneConstraint = NSLayoutConstraint(
            item: containerSwapLibraryButton,
            attribute: attributeOne,
            relatedBy: .equal,
            toItem: cameraButton,
            attribute: attributeTwo,
            multiplier: 1.0,
            constant: 0)
        view.addConstraint(containerButtonsEdgeOneConstraint!)
        
        containerButtonsEdgeTwoConstraint = NSLayoutConstraint(
            item: containerSwapLibraryButton,
            attribute: attributeTwo,
            relatedBy: .equal,
            toItem: view,
            attribute: attributeTwo,
            multiplier: 1.0,
            constant: 0)
        view.addConstraint(containerButtonsEdgeTwoConstraint!)
        
    }
    
    /**
     * Configure the gravity of container, based on the
     * orientation of the device.
     */
    func configContainerGravityConstraint(_ statusBarOrientation : UIInterfaceOrientation) {
        let attributeCenter : NSLayoutAttribute = statusBarOrientation.isPortrait ? .centerY : .centerX
        containerButtonsGravityConstraint = NSLayoutConstraint(
            item: containerSwapLibraryButton,
            attribute: attributeCenter,
            relatedBy: .equal,
            toItem: cameraButton,
            attribute: attributeCenter,
            multiplier: 1.0,
            constant: 0)
        view.addConstraint(containerButtonsGravityConstraint!)
    }
    
    /**
     * Remove the SwapButton constraints to be updated when
     * the device was rotated.
     */
    func removeSwapButtonConstraints() {
        view.autoRemoveConstraint(swapButtonEdgeOneConstraint)
        view.autoRemoveConstraint(swapButtonEdgeTwoConstraint)
        view.autoRemoveConstraint(swapButtonGravityConstraint)
    }
    
    /**
     * If the device is portrait, pin the SwapButton on the
     * right side of the CameraButton.
     * If landscape, pin the SwapButton on the top of the
     * CameraButton.
     */
    func configSwapButtonEdgeConstraint(_ statusBarOrientation : UIInterfaceOrientation) {
        
        let attributeOne : NSLayoutAttribute
        let attributeTwo : NSLayoutAttribute
        
        switch statusBarOrientation {
        case .portrait:
            attributeOne = .top
            attributeTwo = .bottom
            break
        case .landscapeRight:
            attributeOne = .left
            attributeTwo = .right
            break
        case .landscapeLeft:
            attributeOne = .right
            attributeTwo = .left
            break
        default:
            attributeOne = .bottom
            attributeTwo = .top
            break
        }
        
        swapButtonEdgeOneConstraint = NSLayoutConstraint(
            item: swapButton,
            attribute: attributeOne,
            relatedBy: .equal,
            toItem: containerSwapLibraryButton,
            attribute: attributeOne,
            multiplier: 1.0,
            constant: 0)
        view.addConstraint(swapButtonEdgeOneConstraint!)
        
        swapButtonEdgeTwoConstraint = NSLayoutConstraint(
            item: swapButton,
            attribute: attributeTwo,
            relatedBy: .equal,
            toItem: containerSwapLibraryButton,
            attribute: attributeTwo,
            multiplier: 1.0,
            constant: 0)
        view.addConstraint(swapButtonEdgeTwoConstraint!)
        
    }
    
    /**
     * Configure the center of SwapButton, based on the
     * axis center of CameraButton.
     */
    func configSwapButtonGravityConstraint(_ portrait: Bool) {
        swapButtonGravityConstraint = NSLayoutConstraint(
            item: swapButton,
            attribute: portrait ? .right : .bottom,
            relatedBy: .lessThanOrEqual,
            toItem: containerSwapLibraryButton,
            attribute: portrait ? .centerX : .centerY,
            multiplier: 1.0,
            constant: -4.0 * DeviceConfig.SCREEN_MULTIPLIER)
        view.addConstraint(swapButtonGravityConstraint!)
    }
    
    func removeCloseButtonConstraints() {
        view.autoRemoveConstraint(closeButtonEdgeConstraint)
        view.autoRemoveConstraint(closeButtonGravityConstraint)
    }
    
    /**
     * Pin the close button to the left of the superview.
     */
    func configCloseButtonEdgeConstraint(_ statusBarOrientation : UIInterfaceOrientation) {

        let attribute : NSLayoutAttribute = {
            switch statusBarOrientation {
            case .portrait: return .left
            case .landscapeRight, .landscapeLeft: return .centerX
            default: return .right
            }
        }()
        
        closeButtonEdgeConstraint = NSLayoutConstraint(
            item: closeButton,
            attribute: attribute,
            relatedBy: .equal,
            toItem: attribute != .centerX ? view : cameraButton,
            attribute: attribute,
            multiplier: 1.0,
            constant: attribute != .centerX ? 16 : 0)
        view.addConstraint(closeButtonEdgeConstraint!)
    }
    
    /**
     * Add the constraint for the CloseButton, based on
     * the device orientation.
     * If portrait, it pin the CloseButton on the CenterY
     * of the CameraButton.
     * Else if landscape, pin this button on the Bottom
     * of superview.
     */
    func configCloseButtonGravityConstraint(_ statusBarOrientation : UIInterfaceOrientation) {
        
        let attribute : NSLayoutAttribute
        let constant : CGFloat
        
        switch statusBarOrientation {
        case .portrait:
            attribute = .centerY
            constant = 0.0
            break
        case .landscapeRight:
            attribute = .bottom
            constant = -16.0
            break
        case .landscapeLeft:
            attribute = .top
            constant = 16.0
            break
        default:
            attribute = .centerX
            constant = 0.0
            break
        }
        
        closeButtonGravityConstraint = NSLayoutConstraint(
            item: closeButton,
            attribute: attribute,
            relatedBy: .equal,
            toItem: attribute == .bottom || attribute == .top ? view : cameraButton,
            attribute: attribute,
            multiplier: 1.0,
            constant: constant)
        
        view.addConstraint(closeButtonGravityConstraint!)
    }
    
    /**
     * Remove the LibraryButton constraints to be updated when
     * the device was rotated.
     */
    func removeLibraryButtonConstraints() {
        view.autoRemoveConstraint(libraryButtonEdgeOneConstraint)
        view.autoRemoveConstraint(libraryButtonEdgeTwoConstraint)
        view.autoRemoveConstraint(libraryButtonGravityConstraint)
    }
    
    /**
     * Add the constraint of the LibraryButton, if the device
     * orientation is portrait, pin the right side of SwapButton
     * to the left side of LibraryButton.
     * If landscape, pin the bottom side of CameraButton on the
     * top side of LibraryButton.
     */
    func configLibraryEdgeButtonConstraint(_ statusBarOrientation : UIInterfaceOrientation) {
        
        let attributeOne : NSLayoutAttribute
        let attributeTwo : NSLayoutAttribute
        
        switch statusBarOrientation {
        case .portrait:
            attributeOne = .top
            attributeTwo = .bottom
            break
        case .landscapeRight:
            attributeOne = .left
            attributeTwo = .right
            break
        case .landscapeLeft:
            attributeOne = .right
            attributeTwo = .left
            break
        default:
            attributeOne = .bottom
            attributeTwo = .top
            break
        }
        
        libraryButtonEdgeOneConstraint = NSLayoutConstraint(
            item: libraryButton,
            attribute: attributeOne,
            relatedBy: .equal,
            toItem: containerSwapLibraryButton,
            attribute: attributeOne,
            multiplier: 1.0,
            constant: 0)
        view.addConstraint(libraryButtonEdgeOneConstraint!)
        
        libraryButtonEdgeTwoConstraint = NSLayoutConstraint(
            item: libraryButton,
            attribute: attributeTwo,
            relatedBy: .equal,
            toItem: containerSwapLibraryButton,
            attribute: attributeTwo,
            multiplier: 1.0,
            constant: 0)
        view.addConstraint(libraryButtonEdgeTwoConstraint!)
        
    }
    
    /**
     * Set the center gravity of the LibraryButton based
     * on the position of CameraButton.
     */
    func configLibraryGravityButtonConstraint(_ portrait: Bool) {
        libraryButtonGravityConstraint = NSLayoutConstraint(
            item: libraryButton,
            attribute: portrait ? .left : .top,
            relatedBy: .lessThanOrEqual,
            toItem: containerSwapLibraryButton,
            attribute: portrait ? .centerX : .centerY,
            multiplier: 1.0,
            constant: 4.0 * DeviceConfig.SCREEN_MULTIPLIER)
        view.addConstraint(libraryButtonGravityConstraint!)
    }
    
    /**
     * If the device orientation is portrait, pin the top of
     * FlashButton to the top side of superview.
     * Else if, pin the FlashButton bottom side on the top side
     * of SwapButton.
     */
    func configFlashEdgeButtonConstraint(_ statusBarOrientation: UIInterfaceOrientation) {
        view.autoRemoveConstraint(flashButtonEdgeConstraint)
        
        let constraintRight = statusBarOrientation == .portrait || statusBarOrientation == .landscapeRight
        let attribute : NSLayoutAttribute = constraintRight ? .top : .bottom
        
        flashButtonEdgeConstraint = NSLayoutConstraint(
            item: flashButton,
            attribute: attribute,
            relatedBy: .equal,
            toItem: view,
            attribute: attribute,
            multiplier: 1.0,
            constant: constraintRight ? 8 : -8)
        view.addConstraint(flashButtonEdgeConstraint!)
    }
    
    /**
     * If the device orientation is portrait, pin the
     right side of FlashButton to the right side of
     * superview.
     * Else if, centerX the FlashButton on the CenterX
     * of CameraButton.
     */
    func configFlashGravityButtonConstraint(_ statusBarOrientation: UIInterfaceOrientation) {
        view.autoRemoveConstraint(flashButtonGravityConstraint)
        
        let constraintRight = statusBarOrientation == .portrait || statusBarOrientation == .landscapeLeft
        let attribute : NSLayoutAttribute = constraintRight ? .right : .left
        
        flashButtonGravityConstraint = NSLayoutConstraint(
            item: flashButton,
            attribute: attribute,
            relatedBy: .equal,
            toItem: view,
            attribute: attribute,
            multiplier: 1.0,
            constant: constraintRight ? -8 : 8)
        view.addConstraint(flashButtonGravityConstraint!)
    }
    
    /**
     * If the device orientation is portrait, pin the top of
     * zoomButton to the top side of superview.
     * Else if, pin the zoomButton bottom side on the top side
     * of SwapButton.
     */
    func configZoomEdgeButtonConstraint(_ statusBarOrientation: UIInterfaceOrientation) {
        view.autoRemoveConstraint(zoomButtonEdgeConstraint)
        
        let constraintLeft = statusBarOrientation == .portrait || statusBarOrientation == .landscapeRight
        let attribute : NSLayoutAttribute = constraintLeft ? .top : .bottom
        
        zoomButtonEdgeConstraint = NSLayoutConstraint(
            item: zoomButton,
            attribute: attribute,
            relatedBy: .equal,
            toItem: view,
            attribute: attribute,
            multiplier: 1.0,
            constant: constraintLeft ? 8 : -8)
        view.addConstraint(zoomButtonEdgeConstraint!)
    }
    
    /**
     * If the device orientation is portrait, pin the
     left side of zoomButton to the left side of superview.
     * Else if, centerX the zoomButton on the CenterX
     * of CameraButton.
     */
    func configZoomGravityButtonConstraint(_ statusBarOrientation: UIInterfaceOrientation) {
        view.autoRemoveConstraint(zoomButtonGravityConstraint)
        
        let constraintLeft = statusBarOrientation == .portrait || statusBarOrientation == .landscapeLeft
        let attribute : NSLayoutAttribute = constraintLeft ? .left : .right
        
        zoomButtonGravityConstraint = NSLayoutConstraint(
            item: zoomButton,
            attribute: attribute,
            relatedBy: .equal,
            toItem: view,
            attribute: attribute,
            multiplier: 1.0,
            constant: constraintLeft ? 8 : -8)
        view.addConstraint(zoomButtonGravityConstraint!)
    }
    
    /**
     * Used to create a perfect square for CameraOverlay.
     * This method will determinate the size of CameraOverlay,
     * if portrait, it will use the width of superview to
     * determinate the height of the view. Else if landscape,
     * it uses the height of the superview to create the width
     * of the CameraOverlay.
     */
    func configCameraOverlayWidthConstraint(_ portrait: Bool) {
        view.autoRemoveConstraint(cameraOverlayWidthConstraint)
        cameraOverlayWidthConstraint = NSLayoutConstraint(
            item: cameraOverlay,
            attribute: portrait ? .height : .width,
            relatedBy: .equal,
            toItem: cameraOverlay,
            attribute: portrait ? .width : .height,
            multiplier: 1.0,
            constant: 0)
        view.addConstraint(cameraOverlayWidthConstraint!)
    }
    
    /**
     * This method will center the relative position of
     * CameraOverlay, based on the biggest size of the
     * superview.
     */
    func configCameraOverlayCenterConstraint(_ portrait: Bool) {
        view.autoRemoveConstraint(cameraOverlayCenterConstraint)
        let attribute : NSLayoutAttribute = portrait ? .centerY : .centerX
        cameraOverlayCenterConstraint = NSLayoutConstraint(
            item: cameraOverlay,
            attribute: attribute,
            relatedBy: .equal,
            toItem: view,
            attribute: attribute,
            multiplier: 1.0,
            constant: 0)
        view.addConstraint(cameraOverlayCenterConstraint!)
    }
    
    /**
     * Remove the CameraOverlay constraints to be updated when
     * the device was rotated.
     */
    func removeCameraOverlayEdgesConstraints() {
        view.autoRemoveConstraint(cameraOverlayEdgeOneConstraint)
        view.autoRemoveConstraint(cameraOverlayEdgeTwoConstraint)
    }
    
    /**
     * It needs to get a determined smallest size of the screen
     to create the smallest size to be used on CameraOverlay.
     It uses the orientation of the screen to determinate where
     the view will be pinned.
     */
    func configCameraOverlayEdgeOneContraint(_ portrait: Bool, padding: CGFloat) {
        let attribute : NSLayoutAttribute = portrait ? .left : .bottom
        cameraOverlayEdgeOneConstraint = NSLayoutConstraint(
            item: cameraOverlay,
            attribute: attribute,
            relatedBy: .equal,
            toItem: view,
            attribute: attribute,
            multiplier: 1.0,
            constant: padding)
        view.addConstraint(cameraOverlayEdgeOneConstraint!)
    }
    
    /**
     * It needs to get a determined smallest size of the screen
     to create the smallest size to be used on CameraOverlay.
     It uses the orientation of the screen to determinate where
     the view will be pinned.
     */
    func configCameraOverlayEdgeTwoConstraint(_ portrait: Bool, padding: CGFloat) {
        let attributeTwo : NSLayoutAttribute = portrait ? .right : .top
        cameraOverlayEdgeTwoConstraint = NSLayoutConstraint(
            item: cameraOverlay,
            attribute: attributeTwo,
            relatedBy: .equal,
            toItem: view,
            attribute: attributeTwo,
            multiplier: 1.0,
            constant: -padding)
        view.addConstraint(cameraOverlayEdgeTwoConstraint!)
    }
    
}

