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
    
    //MARK:- AV Properties
    //need a capture device, preview layer, session
    var captureSession: AVCaptureSession?
    
    var isCapturing: Bool = false {
        didSet {
            if isCapturing {
                animateView(animatableView: recordingView, startRunning: true)
            } else if !isCapturing {
                animateView(animatableView: recordingView, startRunning: false)
            }
        }
    }
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(videoPreviewView)
        
        navigationController?.navigationBar.isHidden = true
        
        setupUI()
        beginSession()
        captureSession?.startRunning()
        
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
        
        NSLayoutConstraint.activate(recordingViewConstraints)
        NSLayoutConstraint.activate(cameraButtonConstraints)

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
        let actionSheet = UIAlertController(title: "Take a photo or a video?", message: nil, preferredStyle: .actionSheet)

        let choicePhoto = UIAlertAction(title: "Photo", style: .default) { (_) in
            self.getImageFromSampleBuffer(buffer: nil)
            self.dismiss(animated: true, completion: nil)
        }
        let choiceVideo = UIAlertAction(title: "Video", style: .default) { (_) in
            self.streamImagesFromSampleBuffer(buffer: nil)
            self.dismiss(animated: true, completion: nil)
        }

        actionSheet.addAction(choicePhoto)
        actionSheet.addAction(choiceVideo)
        present(actionSheet, animated: true, completion: nil)
        self.navigationController?.pushViewController(PhotoViewController(), animated: true)
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
    
    func streamImagesFromSampleBuffer(buffer: CMSampleBuffer?) {
        isCapturing = true
        print("video chosen")
    }
    
    func endRecording() {
        isCapturing = false
        captureSession?.stopRunning()
    }
    
    func getImageFromSampleBuffer(buffer: CMSampleBuffer?) {
        print("photo chosen")
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if isCapturing {
            //get an aimage
        }
    }
}

