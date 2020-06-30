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

import NaturalLanguage

print("---Getting parts of speech for a sentence---")

let text = "This book about machine learning is the best!"

let posTagger = NLTagger(tagSchemes: [.lexicalClass])
posTagger.string = text

posTagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitWhitespace]) { tag, tokenRange in
  if let tag = tag {
    print("\"\(text[tokenRange])\" is a \(tag.rawValue)")
  }
  return true
}

let doc = """
This is a longer example of text. Hopefully the tokenizer will handle different units of text. This one is a sentence that's part of a paragraph.
This should be a second paragraph, but let's see what the tokenizer thinks. This may not seem that useful, but it really is. There are many times when you'll want to process text a sentence, paragraph, or even a full document at a time.
Here we are at paragraph number three. At least, that's what I would assume. Let's see what we get!
"""

print("---Tokenizing all paragraphs---")

var tokenizer = NLTokenizer(unit: .paragraph)
tokenizer.string = doc
tokenizer.enumerateTokens(in: doc.startIndex..<doc.endIndex) { tokenRange, _ in
  print(">>\(doc[tokenRange])")
  return true
}

print("---Tokenizing all sentences---")

tokenizer = NLTokenizer(unit: .sentence)
tokenizer.string = doc
tokenizer.enumerateTokens(in: doc.startIndex..<doc.endIndex) { tokenRange, _ in
  print(">>\(doc[tokenRange])")
  return true
}
