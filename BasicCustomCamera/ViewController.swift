//
//  ViewController.swift
//  BasicCustomCamera
//
//  Created by Charles Martin Reed on 2/22/19.
//  Copyright © 2019 Charles Martin Reed. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
    
    //MARK:- Properties
    let photoVC = PhotoViewController()
    var takenPhoto: UIImage!
    
    //MARK:- AV Properties
    //need a capture device, preview layer, session
    var captureSession = AVCaptureSession()
    var photoFileOutput = AVCaptureVideoDataOutput()
    var videoFileOutput = AVCaptureMovieFileOutput()
    var capturedPixelBuffer: CVPixelBuffer?
    
    var filePathURL: URL?
    let filePathUUID = UUID().uuidString
    
    var isCapturingVideo: Bool = false {
        didSet {
            if isCapturingVideo {
                animateView(animatableView: recordingView, startRunning: true)
                stopButton.isHidden = false
            } else if !isCapturingVideo {
                animateView(animatableView: recordingView, startRunning: false)
                stopButton.isHidden = true
            }
        }
    }
    
    var captureDeviceIsFrontCam: Bool = true
    var isTakingPhoto: Bool = false
    
//    var backCamera: AVCaptureDevice? = {
//       return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
//    }()
    
    var frontCamera: AVCaptureDevice? = {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    }()
    
    var backCamera: AVCaptureDevice? = {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }()
    
    var microphone: AVCaptureDevice? = {
        return AVCaptureDevice.default(for: .audio)
    }()
    
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer? = {
        var previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        
        return previewLayer
    }()
    
    lazy var videoPreviewView: UIView = {
       let previewView = UIView(frame: view.frame)
        previewView.layer.backgroundColor = UIColor.orange.cgColor
        return previewView
    }()
    
    lazy var cameraButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(#imageLiteral(resourceName: "cameraIcon"), for: .normal)
        button.addTarget(self, action: #selector(handleCameraButtonTapped), for: .touchUpInside)
        
        return button
    }()
    
    lazy var flipCameraButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(#imageLiteral(resourceName: "flipCamera"), for: .normal)
        button.addTarget(self, action: #selector(handleFlipCamera), for: .touchUpInside)
        
        return button
    }()
    
    lazy var recordingView: UIView = {
        let recordingView = UIView()
        recordingView.translatesAutoresizingMaskIntoConstraints = false
        recordingView.backgroundColor = UIColor.red
        recordingView.layer.cornerRadius = 15
        return recordingView
    }()
    
    lazy var stopButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.setImage(#imageLiteral(resourceName: "stopButton"), for: .normal)
        button.addTarget(self, action: #selector(stopRecordingFromBuffer), for: .touchUpInside)
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(videoPreviewView)
        
        
        navigationController?.navigationBar.isHidden = true
        
        setupUI()
        beginSession()
        captureSession.startRunning()
        
//        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(handleCameraButtonTapped))
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = videoPreviewView.frame
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let previewLayer = previewLayer else { return }
        videoPreviewView.layer.addSublayer(previewLayer)
    }
    
    private func setupUI() {
        view.addSubview(recordingView)
        view.addSubview(cameraButton)
        view.addSubview(flipCameraButton)
        view.addSubview(stopButton)
        
        let cameraButtonConstraints: [NSLayoutConstraint] = [
            cameraButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            cameraButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            cameraButton.heightAnchor.constraint(equalToConstant: 75),
            cameraButton.widthAnchor.constraint(equalToConstant: 75)
        ]
        
        let flipCameraButtonConstraints: [NSLayoutConstraint] = [
            flipCameraButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            flipCameraButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            flipCameraButton.heightAnchor.constraint(equalToConstant: 75),
            flipCameraButton.widthAnchor.constraint(equalToConstant: 75)
        ]
        
        let recordingViewConstraints: [NSLayoutConstraint] = [
            recordingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
            recordingView.trailingAnchor.constraint(equalTo: cameraButton.leadingAnchor, constant: -8),
            recordingView.heightAnchor.constraint(equalToConstant: 30),
            recordingView.widthAnchor.constraint(equalToConstant: 30)
        ]
        
        let stopButtonConstraints: [NSLayoutConstraint] = [
            stopButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            stopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopButton.heightAnchor.constraint(equalToConstant: 75),
            stopButton.widthAnchor.constraint(equalToConstant: 75)
        ]
        
        let uiconstraints = [recordingViewConstraints, cameraButtonConstraints, stopButtonConstraints, flipCameraButtonConstraints]
        
        uiconstraints.forEach { (constraint) in
            NSLayoutConstraint.activate(constraint)
        }
//        for constraint in uiconstraints {
//            NSLayoutConstraint.activate(constraint)
//        }
        
//        NSLayoutConstraint.activate(recordingViewConstraints)
//        NSLayoutConstraint.activate(cameraButtonConstraints)
//        NSLayoutConstraint.activate(stopButtonConstraints)
//        NSLayoutConstraint.activate(flipCameraButtonConstraints)

    }
    
    private func beginSession() {
        
        photoFileOutput = AVCaptureVideoDataOutput()
        
        guard let micDevice = microphone
            else {
                print("Problem initializing microphon")
                return
            }
        
        guard let frontCamera = frontCamera else {
            print("Problem intializing front cam")
            return
        }
        
        guard let backCamera = backCamera else {
            print("Problem intializing back cam")
            return
        }
        
        //MARK:- AVCaptureSession input
        do {
            let videoInput = captureDeviceIsFrontCam ? try AVCaptureDeviceInput(device: frontCamera) : try AVCaptureDeviceInput(device: backCamera)
            //let videoInput = try AVCaptureDeviceInput(device: captureDevice)
            let audioInput = try AVCaptureDeviceInput(device: micDevice)
            
            captureSession.beginConfiguration()
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
            
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
            
        //MARK:- AVCaptureSession output
            
            let totalSeconds: Float64 = 600
            let preferredTimeScale: Int32 = 24
            
            let maxDuration = CMTimeMakeWithSeconds(totalSeconds, preferredTimescale: preferredTimeScale)
            videoFileOutput.maxRecordedDuration = maxDuration
            videoFileOutput.minFreeDiskSpaceLimit = 1024*1024*1000 //1 GB
            videoFileOutput.connection(with: .video)
            let connection = videoFileOutput.connection(with: .video)
            connection?.preferredVideoStabilizationMode = .auto
            connection?.videoOrientation = .portrait
            
            //dict needs a pixel format key and pixel format
            photoFileOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            photoFileOutput.alwaysDiscardsLateVideoFrames = true
            
            
            
            if captureSession.canAddOutput(photoFileOutput) {
                captureSession.addOutput(photoFileOutput)
                print("regular output added")
            }
            
        //MARK:- Setup Queue and Buffer Delegate
            captureSession.sessionPreset = AVCaptureSession.Preset.high
            captureSession.commitConfiguration()
            
            //setup for video recording path
            //let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let outputPath = URL(fileURLWithPath: documentsPath).appendingPathComponent("\(filePathUUID).mov")
            filePathURL = outputPath
    
            let queue = DispatchQueue(label: "basic-camera-app")
            photoFileOutput.setSampleBufferDelegate(self, queue: queue)
            
        } catch let error {
            print("Error: \(error.localizedDescription)")
        }
        
    }
    
    @objc private func handleFlipCamera() {
        captureDeviceIsFrontCam.toggle() //starts at true
        print("flipping")
        
//        captureSession.beginConfiguration()
//        if captureDeviceIsFrontCam {
//
//        }
        
    }
    
    @objc private func handleCameraButtonTapped() {
        let actionSheet = UIAlertController(title: "Take a photo or a video?", message: nil, preferredStyle: .actionSheet)

        let choicePhoto = UIAlertAction(title: "Photo", style: .default) { (_) in
            self.isTakingPhoto = true
            
            self.captureSession.beginConfiguration()
            self.captureSession.removeOutput(self.videoFileOutput)
            print("video output removed")
            if self.captureSession.canAddOutput(self.photoFileOutput) {
                self.captureSession.addOutput(self.photoFileOutput)
                print("photo output added")
            }
            self.captureSession.commitConfiguration()
        }

        let choiceVideo = UIAlertAction(title: "Video", style: .default) { (_) in
            self.isCapturingVideo = true
            
            self.captureSession.beginConfiguration()
            self.captureSession.removeOutput(self.photoFileOutput)
            print("photo output removed")
            if self.captureSession.canAddOutput(self.videoFileOutput) {
                self.captureSession.addOutput(self.videoFileOutput)
                print("video output added")
            }
            self.captureSession.commitConfiguration()
            
            DispatchQueue.main.async {
                self.startRecordingVideoFromSampleBuffer()
            }
        }
        
        let choiceCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        actionSheet.addAction(choicePhoto)
        actionSheet.addAction(choiceVideo)
        actionSheet.addAction(choiceCancel)
        present(actionSheet, animated: true, completion: nil)
        
    }
    
    //MARK:- Button animation
    func animateView(animatableView: UIView, startRunning: Bool) {
        let oldValue = animatableView.layer.backgroundColor
        let newValue = UIColor.green.cgColor
        
        let anim = CABasicAnimation(keyPath: "backgroundColor")
        if startRunning {
            anim.toValue = newValue
            anim.fromValue = oldValue
            anim.duration = 1.0
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            anim.autoreverses = true
            anim.repeatCount = .infinity
        } else {
            anim.toValue = oldValue
            anim.duration = 0.0
        }
        
        animatableView.layer.add(anim, forKey: "backgroundColor")
    }
    
    //MARK:- VIDEO functions
    //start the recording
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = .portrait
        default:
            orientation = .portrait
        }
        
        return orientation
    }
    
    func startRecordingVideoFromSampleBuffer() {
        if isCapturingVideo {
            print("attempting video")
            if let movieFileurl = filePathURL {
                videoFileOutput.startRecording(to: movieFileurl, recordingDelegate: self as AVCaptureFileOutputRecordingDelegate)
                print("recording")
            } else {
                print("path was taken")
            }
        }
    }
    
    @objc func stopRecordingFromBuffer() {
        isCapturingVideo = false
        videoFileOutput.stopRecording()
        
    }
    
    @objc func video(_ video: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let ac = UIAlertController(title: "Save Error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true, completion: nil)
        } else {
            let ac = UIAlertController(title: "Saved Successfully", message: "Your video has been stored in your Photo Library", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true, completion: nil)
        }
    }
    
    //MARK:- IMAGE FUNCTIONS
func getImageFromSampleBuffer(buffer: CVImageBuffer) -> UIImage? {
        print("conversion begins")
    
        let cIImage = CIImage(cvImageBuffer: buffer)
        let context = CIContext()
            
        let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(buffer), height: CVPixelBufferGetHeight(buffer))
            
        //CI ->  CG -> UI
        if let image = context.createCGImage(cIImage, from: imageRect) {
            print("converted image")
            return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .right)
            }

        print("could not get image")
        return nil
    }
    
    //MARK:- Delegate methods
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if isTakingPhoto {
            isTakingPhoto = false
            if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                capturedPixelBuffer = pixelBuffer //retain
                if let image = getImageFromSampleBuffer(buffer: capturedPixelBuffer!) {
                    DispatchQueue.main.async {
                        self.takenPhoto = image
                        self.photoVC.takenPhoto = self.takenPhoto
                    self.navigationController?.pushViewController(self.photoVC, animated: true)
                    }
                }
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("now recording")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        //receives callbacks when actual recording starts and stops in full
        if let error = error {
            print(error.localizedDescription)
        } else {
            //stop recording, let the user know if everything went OK
            guard let relativePath = filePathURL?.relativePath else { return }
            UISaveVideoAtPathToSavedPhotosAlbum(relativePath, self, #selector(video(_:didFinishSavingWithError:contextInfo:)), nil)
            
            captureSession.beginConfiguration()
            captureSession.removeOutput(videoFileOutput)
            captureSession.addOutput(photoFileOutput)
            captureSession.commitConfiguration()
            
            print("video output removed")
            print("photo output removed")
            print(String(describing: outputFileURL))
        }
    }
}

