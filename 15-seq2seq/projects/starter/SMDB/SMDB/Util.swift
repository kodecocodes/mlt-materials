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

import CoreML

/// Loads a JSON file if it contains a single dictionary, with String keys and
/// integer values. The keys are assumed to be single characters.
/// Do not include the ".json" extension in the 'from' parameter.
func loadCharToIntJsonMap(from: String) -> [Character:Int] {
  let jsonFile = Bundle.main.url(forResource: from, withExtension: "json")!
  let data = try! Data(contentsOf: jsonFile)
  let json = try! JSONSerialization.jsonObject(with: data, options: [])
  
  guard let object = json as? [String: Int] else {
    return [:]
  }
  
  var char2Int: [Character: Int] = [:]
  for (token, id) in object {
    char2Int[token[token.startIndex]] = id
  }
  return char2Int
}

/// Loads a JSON file if it contains a single dictionary, with String keys
/// and String values, but the keys must be parsable as integers and the
/// values are assumed to be single characters.
/// Do not include the ".json" extension in the 'from' parameter.
func loadIntToCharJsonMap(from: String) -> [Int:Character] {
  let jsonFile = Bundle.main.url(forResource: from, withExtension: "json")!
  let data = try! Data(contentsOf: jsonFile)
  let json = try! JSONSerialization.jsonObject(with: data, options: [])
  
  guard let object = json as? [String:String] else {
    return [:]
  }
  
  var int2Char = [Int:Character]()
  for (id, token) in object {
    int2Char[Int(id)!] = token[token.startIndex]
  }
  return int2Char
}

/// This is a basic implementation of argmax, but it's not the only or
/// best way to do it. If you know your want to use your model's argmax,
/// add a ReduceLayerParams Core ML argmax layer to your model spec. Or
/// try using the Accelerate framework.
func argmax(array: MLMultiArray) -> Int {
  var maxIndex = 0
  var maxValue = array[0].doubleValue
  for i in 1..<array.count where array[i].doubleValue > maxValue {
    maxValue = array[i].doubleValue
    maxIndex = i
  }
  return maxIndex
}

/// Helper function to create MLMultiArray initialized to all zeroes
func initMultiArray(shape: [NSNumber]) -> MLMultiArray {
  let multiArray = try! MLMultiArray(shape: shape, dataType: .double)
  let size = shape.reduce(1) { x, y in x * y.intValue }
  memset(multiArray.dataPointer, 0, MemoryLayout<Double>.stride * size)
  return multiArray
}
