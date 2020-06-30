/// Copyright (c) 2020 Razeware LLC
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
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import PlaygroundSupport
import CreateML
import CoreML
import NaturalLanguage

let trainUrl =
  Bundle.main.url(
    forResource: "custom_tags", withExtension: "json")!
let trainData = try MLDataTable(contentsOf: trainUrl)

let model = try MLWordTagger(
  trainingData: trainData,
  tokenColumn: "tokens", labelColumn: "tags",
  parameters: MLWordTagger.ModelParameters(language: .english))

let projectDir = "TextClassification/"

let savedModelUrl =
  playgroundSharedDataDirectory.appendingPathComponent(
    projectDir + "AppleProductTagger.mlmodel")

try model.write(to: savedModelUrl)

let compiledModelUrl =
  try MLModel.compileModel(at: savedModelUrl)

let appleProductModel =
  try NLModel(contentsOf: compiledModelUrl)

let appleProductTagScheme = NLTagScheme("AppleProducts")
let appleProductTagger = NLTagger(tagSchemes: [appleProductTagScheme])
appleProductTagger.setModels(
  [appleProductModel], forTagScheme: appleProductTagScheme)

let testStrings = [
  "I enjoy watching Netflix on my Apple TV, but I wish I had a bigger TV.",
  "The Face ID on my new iPhone works really fast!",
  "What's up with the keyboard on my MacBook Pro?",
  "Do you prefer the iPhone or the Pixel?"
]

let appleProductTag = NLTag("AppleProduct")
let options: NLTagger.Options = [
  .omitWhitespace, .omitPunctuation, .omitOther]
  
for str in testStrings {
  print("Checking \(str)")
  appleProductTagger.string = str
  appleProductTagger.enumerateTags(
    in: str.startIndex..<str.endIndex,
    unit: .word,
    scheme: appleProductTagScheme,
    options: options) { tag, tokenRange in
    
    if tag == appleProductTag {
      print("Found Apple product: \(str[tokenRange])")
    }
    return true
  }
}
