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

import UIKit

class ReviewsTableViewController: UITableViewController {

  var baseReviews: [Review] = ReviewsManager.instance.reviews
  var reviews: [Review] = []
  var searchTerm: String?

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 188.0

    let searchController = UISearchController(searchResultsController: nil)
    searchController.searchBar.autocapitalizationType = .none
    searchController.delegate = self
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    definesPresentationContext = true
    navigationItem.searchController = searchController
    reviews = baseReviews
  }

  // MARK: - Table view data source

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    reviews.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ReviewTableViewCell
    let review = reviews[indexPath.row]
    cell.bodyTextLabel.text = review.text
    cell.titleLabel.text = review.movie
    cell.setSentiment(sentiment: review.sentiment)

    if let translatedText = review.translatedText {
      cell.bodyTextLabel.text = "\(review.text)\n\nTranslation:\n\n\(translatedText)"
    }

    return cell
  }
}

extension ReviewsTableViewController: UISearchResultsUpdating {

  func filterContent(searchText: String) {
    if searchText != "" {
      findMatches(searchText)
    } else {
      reviews = baseReviews
    }
    tableView.reloadData()
  }

  func findMatches(_ searchText: String) {
    var matches: Set<Review> = []
    if let founds = ReviewsManager.instance.searchTerms[searchText.lowercased()] {
      matches.formUnion(founds)
    }
    reviews = matches.filter { baseReviews.contains($0) }
  }

  func updateSearchResults(for searchController: UISearchController) {
    filterContent(searchText: searchController.searchBar.text!)
  }
}

extension ReviewsTableViewController: UISearchControllerDelegate {
  func willDismissSearchController(_ searchController: UISearchController) {
    filterContent(searchText: "")
  }
}
