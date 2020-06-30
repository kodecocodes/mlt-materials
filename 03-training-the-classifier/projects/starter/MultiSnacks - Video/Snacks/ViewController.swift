import CoreMedia
import CoreML
import UIKit
import Vision

class ViewController: UIViewController {

  @IBOutlet var videoPreview: UIView!
  @IBOutlet var resultsView: UIView!
  @IBOutlet var resultsLabel: UILabel!
  @IBOutlet var fpsLabel: UILabel!

  var videoCapture: VideoCapture!
  let semaphore = DispatchSemaphore(value: ViewController.maxInflightBuffers)
  let fpsCounter = FPSCounter()

  lazy var visionModel: VNCoreMLModel = {
    do {
      let multiSnacks = MultiSnacks()
      return try VNCoreMLModel(for: multiSnacks.model)
    } catch {
      fatalError("Failed to create VNCoreMLModel: \(error)")
    }
  }()

  var classificationRequests = [VNCoreMLRequest]()
  var inflightBuffer = 0
  static let maxInflightBuffers = 2

  func setUpVision() {
    for _ in 0..<ViewController.maxInflightBuffers {
      let request = VNCoreMLRequest(model: visionModel, completionHandler: {
        [weak self] request, error in
        self?.processObservations(for: request, error: error)
      })

      request.imageCropAndScaleOption = .centerCrop
      classificationRequests.append(request)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    resultsLabel.text = ""
    fpsLabel.text = ""
    setUpVision()
    setUpCamera()
  }

  func setUpCamera() {
    videoCapture = VideoCapture()
    videoCapture.delegate = self

    // Change this line to limit how often the video capture delegate gets
    // called. 1 means it is called 30 times per second, which gives realtime
    // results but also uses more battery power.
    videoCapture.frameInterval = 1

    videoCapture.setUp(sessionPreset: .high) { success in
      if success {
        // Add the video preview into the UI.
        if let previewLayer = self.videoCapture.previewLayer {
          self.videoPreview.layer.addSublayer(previewLayer)
          self.resizePreviewLayer()
        }
        self.fpsCounter.start()
        self.videoCapture.start()
      }
    }
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    resizePreviewLayer()
  }

  func resizePreviewLayer() {
    videoCapture.previewLayer?.frame = videoPreview.bounds
  }

  func classify(sampleBuffer: CMSampleBuffer) {
    if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
      // Tell Vision about the orientation of the image.
      let orientation = CGImagePropertyOrientation(UIDevice.current.orientation)

      // Get additional info from the camera.
      var options: [VNImageOption : Any] = [:]
      if let cameraIntrinsicMatrix = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
        options[.cameraIntrinsics] = cameraIntrinsicMatrix
      }

      // The semaphore is used to block the VideoCapture queue and drop frames
      // when Core ML can't keep up.
      semaphore.wait()

      // For better throughput, we want to schedule multiple Vision requests
      // in parallel. These need to be separate instances, and inflightBuffer
      // is the index of the current request object to use.
      let request = self.classificationRequests[inflightBuffer]
      inflightBuffer += 1
      if inflightBuffer >= ViewController.maxInflightBuffers {
        inflightBuffer = 0
      }

      // For better throughput, perform the prediction on a background queue
      // instead of on the VideoCapture queue.
      DispatchQueue.global(qos: .userInitiated).async {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: options)
        do {
          try handler.perform([request])
        } catch {
          print("Failed to perform classification: \(error)")
        }
        self.semaphore.signal()
      }
    }
  }

  func processObservations(for request: VNRequest, error: Error?) {
    DispatchQueue.main.async {
      if let results = request.results as? [VNClassificationObservation] {
        if results.isEmpty {
          self.resultsLabel.text = "nothing found"
        } else {
          let top3 = results.prefix(3).map { observation in
            String(format: "%@ %.1f%%", observation.identifier, observation.confidence * 100)
          }
          self.resultsLabel.text = top3.joined(separator: "\n")
        }
      } else if let error = error {
        self.resultsLabel.text = "error: \(error.localizedDescription)"
      } else {
        self.resultsLabel.text = "???"
      }

      self.fpsCounter.frameCompleted()
      self.fpsLabel.text = String(format: "%.1f FPS", self.fpsCounter.fps)
    }
  }
}

extension ViewController: VideoCaptureDelegate {
  func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame sampleBuffer: CMSampleBuffer) {
    classify(sampleBuffer: sampleBuffer)
  }
}
