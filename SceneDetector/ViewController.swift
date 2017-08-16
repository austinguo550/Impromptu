/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import CoreML
import Vision
import Foundation

class ViewController: UIViewController {

  // MARK: - IBOutlets
  @IBOutlet weak var scene: UIImageView!
  @IBOutlet weak var answerLabel: UILabel!
  @IBOutlet weak var lyricsDisplay: UITextView!
  var errorMessage = ""

  // MARK: - Properties
  let vowels: [Character] = ["a", "e", "i", "o", "u"]
  var song = ""
  var lyrics = ""

  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()

    guard let image = UIImage(named: "train_night") else {
      fatalError("no starting image")
    }

    scene.image = image
    
    // MARK: - added last step
    guard let ciImage = CIImage(image: image) else {
      fatalError("couldn't convert UIImage to CIImage")
    }
    
    detectScene(image: ciImage)
  }
}

// MARK: - IBActions
extension ViewController {

  @IBAction func pickImage(_ sender: Any) {
    let pickerController = UIImagePickerController()
    pickerController.delegate = self
    pickerController.sourceType = .savedPhotosAlbum
    present(pickerController, animated: true)
  }
}

// MARK: - UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate {

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    dismiss(animated: true)

    guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
      fatalError("couldn't load image from Photos")
    }

    scene.image = image
    
    // MARK: - added last step
    guard let ciImage = CIImage(image: image) else {
      fatalError("couldn't convert UIImage to CIImage")
    }
    
    detectScene(image: ciImage)
  }
}

// MARK: - UINavigationControllerDelegate
extension ViewController: UINavigationControllerDelegate {
}

// MARK: - CoreML
extension ViewController {
  
  func detectScene(image: CIImage) {
    answerLabel.text = "Detecting scene..."
    
    // Load the ML Model through its generated class. If it didn't load, model = nil so we need to get rid of it
    guard let model = try? VNCoreMLModel(for: GoogLeNetPlaces().model) else {
     fatalError("Can't load Places ML Model")
    }
    
    let request = VNCoreMLRequest(model: model) { [weak self] request, error
      in
      guard let results = request.results as? [VNClassificationObservation],
        let topResult = results.first else {
          fatalError("Unexpected result type from VNCoreMLRequest")
      }
      
      // Update UI on main queue
      let article = (self?.vowels.contains(topResult.identifier.first!))! ? "an" : "a"  // can force unwrap first because know top result exists
      let searchTerm = topResult.identifier
      DispatchQueue.main.async { [weak self]
        in
        self?.answerLabel.text = "\(Int(topResult.confidence * 100))% it's \(article) \(searchTerm)"
        self?.httpGet(callType: Genius.SONG, query: searchTerm)
        self?.lyricsDisplay.text = self?.lyrics
        
      }
    }
    
    // Run the CoreML GoogleNet Places classifier on the global dispatch queue
    let handler = VNImageRequestHandler(ciImage: image)
    DispatchQueue.global(qos: .userInteractive).async {
      do {
        try handler.perform([request])
      } catch {
        print(error)
      }
    }
  }
  
}



