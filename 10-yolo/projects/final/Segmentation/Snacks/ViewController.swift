/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {
  
  @IBOutlet var imageView: UIImageView!
  @IBOutlet var backCameraButton: UIButton!
  @IBOutlet var backPhotoLibraryButton: UIButton!
  @IBOutlet var frontCameraButton: UIButton!
  @IBOutlet var frontPhotoLibraryButton: UIButton!

  var backImage: UIImage?
  var frontImage: UIImage?
  var destinationIsBack = false
  var showingColors = false
  var colors: [[UInt8]] = []

  let deepLab = DeepLab()
  let deepLabWidth: Int
  let deepLabHeight: Int

  var startTime: CFTimeInterval = 0
  var lastResults: MLMultiArray?

  lazy var visionRequest: VNCoreMLRequest = {
    do {
      let visionModel = try VNCoreMLModel(for: deepLab.model)

      let request = VNCoreMLRequest(model: visionModel, completionHandler: {
        [weak self] request, error in
        self?.processObservations(for: request, error: error)
      })

      request.imageCropAndScaleOption = .scaleFill
      return request
    } catch {
      fatalError("Failed to create VNCoreMLModel: \(error)")
    }
  }()

  required init?(coder aDecoder: NSCoder) {
    // Get the expected output width and height from the MLModel.
    // These should be 513x513 but it's better if we don't hardcode them.
    let outputs = deepLab.model.modelDescription.outputDescriptionsByName
    guard let output = outputs["ResizeBilinear_3__0"],
          let constraint = output.multiArrayConstraint else {
      fatalError("Expected 'ResizeBilinear_3__0' output")
    }
    deepLabHeight = constraint.shape[1].intValue
    deepLabWidth = constraint.shape[2].intValue

    super.init(coder: aDecoder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Make colors for the classes. (To keep the loop simple, we make
    // 27 colors even though there are only 21 classes.)
    for r: UInt8 in [0, 255, 127] {
      for g: UInt8 in [0, 127, 255] {
        for b: UInt8 in [63, 127, 255] {
          colors.append([r, g, b])
        }
      }
    }

    backCameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
    frontCameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)

    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  @IBAction func takePicture(sender: UIButton) {
    destinationIsBack = (sender == backCameraButton)
    presentPhotoPicker(sourceType: .camera)
  }

  @IBAction func choosePhoto(sender: UIButton) {
    destinationIsBack = (sender == backPhotoLibraryButton)
    presentPhotoPicker(sourceType: .photoLibrary)
  }

  @objc func handleTap(sender: UITapGestureRecognizer) {
    // Tapping the screen will flip between matting and colored modes.
    if sender.state == .ended {
      showingColors = !showingColors
      if let results = lastResults {
        show(results: results)
      }
    }
  }

  func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.sourceType = sourceType
    present(picker, animated: true)
  }

  func predict(image: UIImage) {
    startTime = CACurrentMediaTime()

    guard let ciImage = CIImage(image: image) else {
      print("Unable to create CIImage")
      return
    }

    let orientation = CGImagePropertyOrientation(image.imageOrientation)

    DispatchQueue.global(qos: .userInitiated).async {
      let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
      do {
        try handler.perform([self.visionRequest])
      } catch {
        print("Failed to perform prediction: \(error)")
      }
    }
  }

  func processObservations(for request: VNRequest, error: Error?) {
    if let results = request.results as? [VNCoreMLFeatureValueObservation],
       !results.isEmpty,
       let multiArray = results[0].featureValue.multiArrayValue {
      lastResults = multiArray
      showingColors = false

      let elapsed = CACurrentMediaTime() - startTime
      print("Model took \(elapsed) seconds")

      DispatchQueue.main.async {
        self.show(results: multiArray)
      }
    }
  }

  func show(results: MLMultiArray) {
    // If two images are selected, then compose the front image on top
    // of the background image. If only a front image is selected, then
    // show a colored segmentation mask.
    if !showingColors, let backImage = self.backImage, let frontImage = self.frontImage {
      self.imageView.image = self.matteImages(front: frontImage, back:backImage, features: results)
    } else {
      self.imageView.image = self.createMaskImage(from: results)
    }
  }

  func matteImages(front: UIImage, back: UIImage, features: MLMultiArray) -> UIImage {
    // NOTE: This is a very simple (and slow) way to blend the two images
    // together using the segmentation mask.

    // Resize both images to 513x513 pixels. This is the output size of the
    // DeepLab segmentation model. Also convert to RGBA bytes, so we can more
    // easily read their colors.
    let newSize = CGSize(width: deepLabWidth, height: deepLabHeight)
    let frontImage = front.resized(to: newSize)
    let frontPixels = frontImage.toByteArray()
    let backImage = back.resized(to: newSize)
    let backPixels = backImage.toByteArray()

    // Allocate an array that will hold the output pixels.
    let classes = features.shape[0].intValue
    let height = features.shape[1].intValue
    let width = features.shape[2].intValue
    var pixels = [UInt8](repeating: 255, count: width * height * 4)

    // We will access the MLMultiArray's memory through a pointer, which is
    // much faster than using the subscript `features[[c, y, x] as [NSNumber]]`.
    let featurePointer = UnsafeMutablePointer<Double>(OpaquePointer(features.dataPointer))
    let cStride = features.strides[0].intValue
    let yStride = features.strides[1].intValue
    let xStride = features.strides[2].intValue

    for y in 0..<height {
      for x in 0..<width {
        // Take the argmax for this pixel, i.e. the index of the largest class.
        var largestValue: Double = 0
        var largestClass = 0
        for c in 0..<classes {
          let value = featurePointer[c*cStride + y*yStride + x*xStride]
          if value > largestValue {
            largestValue = value
            largestClass = c
          }
        }

        // Decide which pixel to use: from the background image or the front?
        let pixelOffset = (y*width + x)*4
        let r: UInt8
        let g: UInt8
        let b: UInt8
        if largestClass == 0 {
          r = backPixels[pixelOffset + 0]
          g = backPixels[pixelOffset + 1]
          b = backPixels[pixelOffset + 2]
        } else {
          r = frontPixels[pixelOffset + 0]
          g = frontPixels[pixelOffset + 1]
          b = frontPixels[pixelOffset + 2]
        }

        // Write the corresponding color for this pixel to the new image.
        pixels[pixelOffset + 0] = r
        pixels[pixelOffset + 1] = g
        pixels[pixelOffset + 2] = b
        pixels[pixelOffset + 3] = 255
      }
    }

    return UIImage.fromByteArray(&pixels, width: width, height: height)
  }

  func createMaskImage(from features: MLMultiArray) -> UIImage {
    // NOTE: This is a very simple (and slow) way to display the segmentation
    // mask. In your own app you'll probably want to replace this with a Metal
    // shader for rendering to the display.

    let classes = features.shape[0].intValue
    let height = features.shape[1].intValue
    let width = features.shape[2].intValue
    var pixels = [UInt8](repeating: 255, count: width * height * 4)

    let featurePointer = UnsafeMutablePointer<Double>(OpaquePointer(features.dataPointer))
    let cStride = features.strides[0].intValue
    let yStride = features.strides[1].intValue
    let xStride = features.strides[2].intValue

    for y in 0..<height {
      for x in 0..<width {
        // Take the argmax for this pixel, i.e. the index of the largest class.
        var largestValue: Double = 0
        var largestClass = 0
        for c in 0..<classes {
          let value = featurePointer[c*cStride + y*yStride + x*xStride]
          if value > largestValue {
            largestValue = value
            largestClass = c
          }
        }

        // Write the corresponding color for this pixel to the new image.
        let color = colors[largestClass]
        let pixelOffset = (y*width + x)*4
        pixels[pixelOffset + 0] = color[0]
        pixels[pixelOffset + 1] = color[1]
        pixels[pixelOffset + 2] = color[2]
        pixels[pixelOffset + 3] = 255
      }
    }

    return UIImage.fromByteArray(&pixels, width: width, height: height)
  }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true)

    let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
    if destinationIsBack {
      backImage = image
    } else {
      frontImage = image
    }

    if let image = frontImage{
      predict(image: image)
    }
  }
}
