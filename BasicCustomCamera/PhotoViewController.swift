//
//  PhotoViewController.swift
//  BasicCustomCamera
//
//  Created by Charles Martin Reed on 2/22/19.
//  Copyright © 2019 Charles Martin Reed. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {
    
    var takenPhoto: UIImage?
    
    lazy var imageView: UIImageView = {
        
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        
        //this will actually be used to navigate, rather than relying upon the nav controller's back button
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        
        imageView.addGestureRecognizer(swipeLeft)
        imageView.addGestureRecognizer(swipeRight)
        
        return imageView
        
    }()
    
    var instructionsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Swipe Left to Discard, Swipe Right to Save"
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        label.minimumScaleFactor = 0.5
        label.numberOfLines = 0
        label.textColor = .white
        
        return label
    }()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate()
        
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let photo = takenPhoto {
            imageView.image = photo
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        imageView.image = nil
    }
    
    private func setupUI() {
        view.addSubview(imageView)
        view.addSubview(instructionsLabel)
        
        let imageViewConstraints: [NSLayoutConstraint] = [
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            ]
        
        let instructionConstraints: [NSLayoutConstraint] = [
            instructionsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            instructionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            instructionsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            instructionsLabel.heightAnchor.constraint(equalToConstant: 60)
        ]
        
        NSLayoutConstraint.activate(imageViewConstraints)
        NSLayoutConstraint.activate(instructionConstraints)
        
        //animateOut(label: instructionsLabel)
        animateInstructionLabel()
    }
    
    private func animateOut(label: UIView) {
//        for view in view.subviews {
//            if view is UILabel {
//                UIV
//            }
//        }
//        let oldValue = label.layer.opacity
//        let newValue = 0
//
//        let anim = CABasicAnimation(keyPath: "opacity")
//        anim.fromValue = oldValue
//        anim.toValue = newValue
//        anim.duration = 2.0
//        anim.repeatCount = 0
//        anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
//
//        label.layer.add(anim, forKey: "opacity")
////        animationIsFinished = true
    }
    
    private func animateInstructionLabel() {
        UIView.animate(withDuration: 4.0, delay: 0, options: .curveEaseOut, animations: {
            self.instructionsLabel.alpha = 0
        }) { (_) in
            self.instructionsLabel.removeFromSuperview()
        }
    }
    
    private func saveImageLocally() {
        print("swiped right")
        UIImageWriteToSavedPhotosAlbum(takenPhoto!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let ac = UIAlertController(title: "Save Error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true, completion: nil)
        } else {
            let ac = UIAlertController(title: "Save Successful", message: "Your image has been saved to your Photo Library", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true, completion: nil)
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        
        switch gesture.direction {
        case .left:
            print("left")
            self.navigationController?.popViewController(animated: true)
        case .right:
            saveImageLocally()
        default:
            break
        }

    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
