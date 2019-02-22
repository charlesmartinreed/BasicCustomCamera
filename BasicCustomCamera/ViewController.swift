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
    var captureSession: AVCaptureSession?
    var backCamera: AVCaptureDevice? = {
       return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }()
    
    var frontCamera: AVCaptureDevice? = {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    }()
    
    //let captureLayer = CALayer()
    
    //let captureDevice: AVCaptureDevice!
    
    let cameraButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(#imageLiteral(resourceName: "cameraIcon"), for: .normal)
        button.addTarget(self, action: #selector(handleCameraButtonTapped), for: .touchUpInside)
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        view.backgroundColor = .white
        
        setupUI()
        beginSession()
        captureSession?.startRunning()
        
//        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(handleCameraButtonTapped))
        
    }
    
    private func setupUI() {
       view.addSubview(cameraButton)
        
        let cameraButtonConstraints: [NSLayoutConstraint] = [
            cameraButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            cameraButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            cameraButton.heightAnchor.constraint(equalToConstant: 50),
            cameraButton.widthAnchor.constraint(equalToConstant: 50)
        ]
        NSLayoutConstraint.activate(cameraButtonConstraints)
    }
    
    private func beginSession() {
        captureSession = AVCaptureSession()
        guard let session = captureSession, let captureDevice = frontCamera else  {
            print("Problem initializing session")
            return
        }
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            session.beginConfiguration()
            
            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            output.alwaysDiscardsLateVideoFrames = true
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            session.commitConfiguration()
            let queue = DispatchQueue(label: "basic-camera-app")
            output.setSampleBufferDelegate(self, queue: queue)
        } catch let error {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    @objc private func handleCameraButtonTapped() {
        print("camera tapped")
        self.navigationController?.pushViewController(PhotoViewController(), animated: true)
    }


}

