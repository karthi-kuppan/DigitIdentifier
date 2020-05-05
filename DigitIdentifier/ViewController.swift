//
//  ViewController.swift
//  DigitIdentifier
//
//  Created by Karthikeyan Kuppan on 4/26/20.
//  Copyright © 2020 Karthi Kuppan. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resizedImageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    
    private var classifier: DigitClassifier?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        // Initialize a DigitClassifier instance
        DigitClassifier.newInstance { result in
          switch result {
          case let .success(classifier):
            self.classifier = classifier
          case .error(_):
            self.resultLabel.text = "Failed to initialize."
          }
        }
    }

    @IBAction func captureImage(_ sender: Any) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        self.resultLabel.text = "Capture a picture to identify"
        
        let actionSheet = UIAlertController(title: "Picture Source", message: "Choose a Picture or Capture one!", preferredStyle:.actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {(action: UIAlertAction) in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePickerController.sourceType = .camera
                self.present(imagePickerController, animated: true, completion: nil)
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: {(action: UIAlertAction) in
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }))

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: {(action: UIAlertAction) in }))
        
        self.present(actionSheet, animated: true, completion: nil)

    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let imageForDisplay = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        let imageToIdentify = imageForDisplay.fixedOrientation()
        
        let resizedImage = imageToIdentify?.resizeImage(with: CGSize(width: 28, height: 28))
        
        imageView.image = imageForDisplay
        resizedImageView.image = resizedImage
        classifyImage(image: resizedImage!)
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    /// Classify the image currently on the canvas and display result.
    private func classifyImage(image: UIImage) {
      guard let classifier = self.classifier else { return }

      // Run digit classifier.
      classifier.classify(image: image) { result in
        // Show the classification result on screen.
        switch result {
        case let .success(classificationResult):
          self.resultLabel.text = classificationResult
        case .error(_):
          self.resultLabel.text = "Failed to classify the image captured."
        }
      }
    }

}

