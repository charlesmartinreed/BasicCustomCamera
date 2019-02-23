//
//  ViewController.swift
//  BasicCustomCamera
//
//  Created by Charles Martin Reed on 2/22/19.
//  Copyright © 2019 Charles Martin Reed. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    //MARK:- Properties
    let photoVC = PhotoViewController()
    var takenPhoto: UIImage!
    
    //MARK:- AV Properties
    //need a capture device, preview layer, session
    var captureSession: AVCaptureSession?
    
    
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
    
    var isTakingPhoto: Bool = false
    
    var backCamera: AVCaptureDevice? = {
       return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }()
    
    var frontCamera: AVCaptureDevice? = {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    }()
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer? = {
        guard let captureSession = self.captureSession else { return nil }
        
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
        captureSession?.startRunning()
        print("capture session started")
        
//        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(handleCameraButtonTapped))
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = videoPreviewView.frame
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let previewLayer = previewLayer else { return }
        videoPreviewView.layer.addSublayer(previewLayer)
    }
    
    private func setupUI() {
        view.addSubview(recordingView)
        view.addSubview(cameraButton)
        view.addSubview(stopButton)
        
        let cameraButtonConstraints: [NSLayoutConstraint] = [
            cameraButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            cameraButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            cameraButton.heightAnchor.constraint(equalToConstant: 75),
            cameraButton.widthAnchor.constraint(equalToConstant: 75)
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
        
        NSLayoutConstraint.activate(recordingViewConstraints)
        NSLayoutConstraint.activate(cameraButtonConstraints)
        NSLayoutConstraint.activate(stopButtonConstraints)

    }
    
    private func beginSession() {
        captureSession = AVCaptureSession()
        guard let session = captureSession, let captureDevice = frontCamera else  {
            print("Problem initializing session")
            return
        }
        //MARK:- AVCaptureSession input
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            session.beginConfiguration()
            
            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }
            
        //MARK:- AVCaptureSession input
            let output = AVCaptureVideoDataOutput()
            
            //dict needs a pixel format key and pixel format
            output.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            output.alwaysDiscardsLateVideoFrames = true
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
        //MARK:- Setup Queue and Buffer Delegate
            session.commitConfiguration()
            let queue = DispatchQueue(label: "basic-camera-app")
            output.setSampleBufferDelegate(self, queue: queue)
        } catch let error {
            print("Error: \(error.localizedDescription)")
        }
        
    }
    
    @objc private func handleCameraButtonTapped() {
        self.isTakingPhoto = true
//        let actionSheet = UIAlertController(title: "Take a photo or a video?", message: nil, preferredStyle: .actionSheet)
//
//        let choicePhoto = UIAlertAction(title: "Photo", style: .default) { (_) in
//            self.isTakingPhoto = true
//            self.dismiss(animated: true, completion: nil)
//            print("isTakingPhoto is: \(self.isTakingPhoto)")
//        }
//
//        let choiceVideo = UIAlertAction(title: "Video", style: .default) { (_) in
//            self.isCapturingVideo = true
//            self.dismiss(animated: true, completion: nil)
//        }
//
//        actionSheet.addAction(choicePhoto)
//        actionSheet.addAction(choiceVideo)
//        present(actionSheet, animated: true, completion: nil)
        //self.navigationController?.pushViewController(PhotoViewController(), animated: true)
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
    func streamImagesFromSampleBuffer(buffer: CMSampleBuffer) {
        isCapturingVideo = true
        
    }
    
    @objc func stopRecordingFromBuffer() {
        isCapturingVideo = false
        //captureSession?.stopRunning()
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
                if let image = getImageFromSampleBuffer(buffer: pixelBuffer) {
                    photoVC.takenPhoto = image
                    DispatchQueue.main.async {
                        self.navigationController?.pushViewController(self.photoVC, animated: true)
                    }
                }
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        
        
//        if isTakingPhoto {
//            isTakingPhoto = false
//            getImageFromSampleBuffer(buffer: pixelBuffer)
//        }
//        if isTakingPhoto {
//            print("attempting to make photo")
//            isTakingPhoto = false //so we only get one image
//            if let image = self.getImageFromSampleBuffer(buffer: pixelBuffer) {
//                //display on the PhotoVC
//                photoVC.takenPhoto = image
//                print("attempting to push")
//                self.navigationController?.pushViewController(photoVC, animated: true)
//            }
//        }
    }
}

