//
//  DigitClassifier.swift
//  DigitIdentifier
//
//  Created by Karthikeyan Kuppan on 4/26/20.
//  Copyright © 2020 Karthi Kuppan. All rights reserved.
//

import CoreImage
import UIKit
import TensorFlowLite

class DigitClassifier {

  /// TensorFlow Lite `Interpreter` object for performing inference on a given model.
  private var interpreter: Interpreter
  private var inputImageWidth: Int
  private var inputImageHeight: Int

  static func newInstance(completion: @escaping ((Result<DigitClassifier>) -> ())) {
    // Run initialization in background thread to avoid UI freeze
    DispatchQueue.global(qos: .background).async {

      // Construct the path to the model file.
      guard let modelPath = Bundle.main.path(
        forResource: Constant.modelFilename,
        ofType: Constant.modelFileExtension
        ) else {
          print("Failed to load the model file with name: \(Constant.modelFilename).\(Constant.modelFileExtension)")
          DispatchQueue.main.async {
            completion(.error(InitializationError.invalidModel("\(Constant.modelFilename).\(Constant.modelFileExtension)")))
          }
          return
      }

      // Specify the options for the `Interpreter`.
        var options = Interpreter.Options()
      options.threadCount = 2

      do {
        // Create the `Interpreter`.
        let interpreter = try Interpreter(modelPath: modelPath, options: options)

        // Allocate memory for the model's input `Tensor`s.
        try interpreter.allocateTensors()

        // Read TF Lite model input dimension
        let inputShape = try interpreter.input(at: 0).shape
        let inputImageWidth = inputShape.dimensions[1]
        let inputImageHeight = inputShape.dimensions[2]

        // Create DigitClassifier instance and return
        let classifier = DigitClassifier(
          interpreter: interpreter,
          inputImageWidth: inputImageWidth,
          inputImageHeight: inputImageHeight
        )
        DispatchQueue.main.async {
          completion(.success(classifier))
        }
      } catch let error {
        print("Failed to create the interpreter with error: \(error.localizedDescription)")
        DispatchQueue.main.async {
          completion(.error(InitializationError.internalError(error)))
        }
        return
      }
    }
  }

  /// Initialize Digit Classifer instance
  fileprivate init(interpreter: Interpreter, inputImageWidth: Int, inputImageHeight: Int) {
    self.interpreter = interpreter
    self.inputImageWidth = inputImageWidth
    self.inputImageHeight = inputImageHeight
  }

  /// Run image classification on the input image.
  ///
  /// - Parameters
  ///   - image: an UIImage instance to classify.
  ///   - completion: callback to receive the classification result.
  func classify(image: UIImage, completion: @escaping ((Result<String>) -> ())) {
    DispatchQueue.global(qos: .background).async {
      let outputTensor: Tensor
      do {
        // Preprocessing: Convert the input UIImage to (28 x 28) grayscale image to feed to TF Lite model.
        guard let rgbData = image.scaledData(with: CGSize(width: self.inputImageWidth, height: self.inputImageHeight))
          else {
            DispatchQueue.main.async {
              completion(.error(ClassificationError.invalidImage))
            }
            print("Failed to convert the image buffer to RGB data.")
            return
        }

        // Allocate memory for the model's input `Tensor`s.
        try self.interpreter.allocateTensors()

        // Copy the RGB data to the input `Tensor`.
        try self.interpreter.copy(rgbData, toInputAt: 0)

        // Run inference by invoking the `Interpreter`.
        try self.interpreter.invoke()

        // Get the output `Tensor` to process the inference results.
        outputTensor = try self.interpreter.output(at: 0)
      } catch let error {
        print("Failed to invoke the interpreter with error: \(error.localizedDescription)")
        DispatchQueue.main.async {
          completion(.error(ClassificationError.internalError(error)))
        }
        return
      }

      // Postprocessing: Find the label with highest confidence and return as human readable text.
      let results = outputTensor.data.toArray(type: Float32.self)
      let maxConfidence = results.max() ?? -1
      let maxIndex = results.firstIndex(of: maxConfidence) ?? -1
      let humanReadableResult = "Predicted: \(maxIndex)\nConfidence: \(maxConfidence)"

      // Return the classification result
      DispatchQueue.main.async {
        completion(.success(humanReadableResult))
      }
    }
  }
}

/// Convenient enum to return result with a callback
enum Result<T> {
  case success(T)
  case error(Error)
}

/// Define errors that could happen in the initialization of this class
enum InitializationError: Error {
  // Invalid TF Lite model
  case invalidModel(String)
  // TF Lite Internal Error when initializing
  case internalError(Error)
}

/// Define errors that could happen in when doing image clasification
enum ClassificationError: Error {
  // Invalid input image
  case invalidImage
  // TF Lite Internal Error when initializing
  case internalError(Error)
}

// MARK: - Constants
private enum Constant {
  /// Specify the TF Lite model file
  static let modelFilename = "mnist"
  static let modelFileExtension = "tflite"
}

