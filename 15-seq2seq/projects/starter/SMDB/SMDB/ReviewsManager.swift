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
import NaturalLanguage

class ReviewsManager {
  static let instance: ReviewsManager = ReviewsManager()
  
  let reviews: [Review]
  var searchTerms: [String: Set<Review>] = [:]
  private (set) var reviewsByMovie: [String: [Review]] = [:]
  private (set) var reviewsByActor: [String: [Review]] = [:]
  private (set) var reviewsByLanguage: [NLLanguage: [Review]] = [:]

  private init() {
    reviews = ReviewsManager.loadReviews()
    discoverStuffAboutReviews()
  }

  static private func loadReviews() -> [Review] {
    let reviewFile = Bundle.main.url(forResource: "reviews", withExtension: "json")!
    let data = try! Data(contentsOf: reviewFile)
    let envelope = try! JSONDecoder().decode(ReviewEnvelope.self, from: data)
    return envelope.reviews
  }

  private func discoverStuffAboutReviews() {
    let sentimentClassifier = getSentimentClassifier()
    reviews.forEach {
      getInfo($0, sentimentClassifier: sentimentClassifier)
      addMovie($0)
      addActors($0)
      addLanguage($0)
    }
  }

  private func getInfo(_ review: Review, sentimentClassifier: NLModel?) {
    setLanguage(review)
    getNames(review)
    populateSearch(review)
    findSentiment(review, sentimentClassifier: sentimentClassifier)
    translateReview(review)
  }

  private func addMovie(_ review: Review) {
    let movie = review.movie
    var reviewsForMovie = reviewsByMovie[movie] ?? []
    reviewsForMovie.append(review)
    reviewsByMovie[movie] = reviewsForMovie
  }

  private func addActors(_ review: Review) {
    review.actors?.forEach { actor in
      var reviewsForActor = reviewsByActor[actor] ?? []
      reviewsForActor.append(review)
      reviewsByActor[actor] = reviewsForActor
    }
  }

  private func addLanguage(_ review: Review) {
    guard let language = review.language else {
      return
    }
    
    var reviewsForLanguage = reviewsByLanguage[language] ?? []
    reviewsForLanguage.append(review)
    reviewsByLanguage[language] = reviewsForLanguage
  }

  private func getNames(_ review: Review) {
    getPeopleNames(text: review.text) { name in
      var actors = review.actors ?? []
      actors.append(name)
      review.actors = actors
    }
  }

  private func populateSearch(_ review: Review) {
    getSearchTerms(text: review.text) { word in
      guard var values = searchTerms[word] else {
        searchTerms[word] = Set([review])
        return
      }
      values.insert(review)
      searchTerms[word] = values
    }
  }

  private func setLanguage(_ review: Review) {
    review.language = getLanguage(text: review.text)
  }

  private func findSentiment(_ review: Review, sentimentClassifier: NLModel?) {
    guard let sentimentClassifier = sentimentClassifier,
      review.language == sentimentClassifier.configuration.language else {
      return
    }
    let prediction = predictSentiment(text: review.text, sentimentClassifier: sentimentClassifier)
    review.sentiment = prediction == nil ? nil : prediction == "neg" ? 0 : 1
  }

  private func translateReview(_ review: Review) {
    if review.language == .spanish {
      var translatedText = ""
      let spanishSentences = getSentences(text: review.text)
      for sentence in spanishSentences {
        if let translation = spanishToEnglish(text: sentence.trimmingCharacters(in: .whitespaces)) {
          translatedText += "\(translation) "
        }
      }
      if translatedText.count > 0 {
        review.translatedText = translatedText
      }
    }
  }
}

fileprivate struct ReviewEnvelope: Decodable {
  let reviews: [Review]
}
