//
//  TFLiteExtensions.swift
//  DigitIdentifier
//
//  Created by Karthikeyan Kuppan on 4/26/20.
//  Copyright © 2020 Karthi Kuppan. All rights reserved.
//

import CoreGraphics
import Foundation
import UIKit

// MARK: - UIImage
extension UIImage {

  // Returns the data representation of the image after scaling to the given `size` and converting
  // to grayscale.
  //
  // - Parameters
  //   - size: Size to scale the image to (i.e. image size used while training the model).
  // - Returns: The scaled image as data or `nil` if the image could not be scaled.
  public func scaledData(with size: CGSize) -> Data? {
    guard let cgImage = self.cgImage, cgImage.width > 0, cgImage.height > 0 else { return nil }

    let bitmapInfo = CGBitmapInfo(
      rawValue: CGImageAlphaInfo.none.rawValue
    )
    let width = Int(size.width)
    guard let context = CGContext(
      data: nil,
      width: width,
      height: Int(size.height),
      bitsPerComponent: cgImage.bitsPerComponent,
      bytesPerRow: width * 1,
      space: CGColorSpaceCreateDeviceGray(),
      bitmapInfo: bitmapInfo.rawValue)
      else {
        return nil
    }

    context.draw(cgImage, in: CGRect(origin: .zero, size: size))
    guard let scaledBytes = context.makeImage()?.dataProvider?.data as Data? else { return nil }
    let scaledFloats = scaledBytes.map { Float32($0) / Constant.maxRGBValue }

    return Data(copyingBufferOf: scaledFloats)
  }
    
    func invertedImage() -> UIImage? {
        
        let img = CoreImage.CIImage(cgImage: self.cgImage!)
        
        let filter = CIFilter(name: "CIColorInvert")
        filter!.setDefaults()
        
        filter!.setValue(img, forKey: "inputImage")
        
        let context = CIContext(options:nil)
        
        let cgimg = context.createCGImage((filter?.outputImage!)!, from: (filter?.outputImage!.extent)!)

        return UIImage(cgImage: cgimg!)
    }
        
    // Fix image orientaton to protrait up
    func fixedOrientation() -> UIImage? {
        guard imageOrientation != UIImage.Orientation.up else {
            // This is default orientation, don't need to do anything
            return self.copy() as? UIImage
        }

        guard let cgImage = self.cgImage else {
            // CGImage is not available
            return nil
        }

        guard let colorSpace = cgImage.colorSpace, let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil // Not able to create CGContext
        }

        var transform: CGAffineTransform = CGAffineTransform.identity

        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2.0)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat.pi / -2.0)
        case .up, .upMirrored:
            break
        @unknown default:
            fatalError("Missing...")
            break
        }

        // Flip image one more time if needed to, this is to prevent flipped image
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        @unknown default:
            fatalError("Missing...")
            break
        }

        ctx.concatenate(transform)

        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }

        guard let newCGImage = ctx.makeImage() else { return nil }
        return UIImage.init(cgImage: newCGImage, scale: 1, orientation: .up)
    }

    public func resizeImage(with size: CGSize) -> UIImage? {
      guard let cgImage = self.cgImage, cgImage.width > 0, cgImage.height > 0 else { return nil }

      let bitmapInfo = CGBitmapInfo(
        rawValue: CGImageAlphaInfo.none.rawValue
      )
      
        let width = Int(size.width)
      guard let context = CGContext(
        data: nil,
        width: width,
        height: Int(size.height),
        bitsPerComponent: cgImage.bitsPerComponent,
        bytesPerRow: width * 1,
        space: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: bitmapInfo.rawValue)
        else {
          return nil
      }
    
      context.draw(cgImage, in: CGRect(origin: .zero, size: size))
      guard let scaledImage = context.makeImage() else { return nil }

      return UIImage(cgImage: scaledImage)
    }

}

// MARK: - Data
extension Data {
  // Creates a new buffer by copying the buffer pointer of the given array.
  //
  // - Warning: The given array's element type `T` must be trivial in that it can be copied bit
  //     for bit with no indirection or reference-counting operations; otherwise, reinterpreting
  //     data from the resulting buffer has undefined behavior.
  // - Parameter array: An array with elements of type `T`.
  init<T>(copyingBufferOf array: [T]) {
    self = array.withUnsafeBufferPointer(Data.init)
  }

  func toArray<T>(type: T.Type) -> [T] where T: ExpressibleByIntegerLiteral {
    var array = Array<T>(repeating: 0, count: self.count/MemoryLayout<T>.stride)
    _ = array.withUnsafeMutableBytes { copyBytes(to: $0) }
    return array
  }
}

// MARK: - Constants
private enum Constant {
  static let maxRGBValue: Float32 = 255.0
}

