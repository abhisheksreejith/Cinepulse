//
//  ViewController.swift
//  Cinepulse
//
//  Created by Abhishek C Sreejith on 25/10/25.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var searchFieldStack: UIStackView?
    @IBOutlet weak var searchTextField: UITextField?
    @IBOutlet weak var searchButton: UIButton?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var mainScrollView: UIScrollView?
    @IBOutlet weak var moviesCollectionView: UICollectionView?
    @IBOutlet weak var emptyView: UIView!
    private let viewModel = HomeViewModel()
    private var movies: [Movie] = []
    private let numberOfColumns: CGFloat = 2
    private let spacing: CGFloat = 16
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let loadingOverlay = UIView()
    private var searchDebounceTimer: Timer?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        appLayout()
        setupCollectionView()
        bindViewModel()
        setupSearchHandlers()
        setupLoadingIndicator()
//        loadSampleData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionViewHeight()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        moviesCollectionView?.reloadData()
    }

    @IBAction func navigateToWishlist(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Favourites", bundle: nil)
        if let favVC = storyboard.instantiateViewController(withIdentifier: "FavouritesViewController") as? FavouritesViewController {
            self.navigationController?.pushViewController(favVC, animated: true)
        }
    }
    func appLayout() {
        
        navigationController?.navigationBar.isHidden = true
        searchFieldStack?.layer.cornerRadius = 10

    }

    private func setupCollectionView() {
        // Set delegate and dataSource (if not done in Storyboard)
        moviesCollectionView?.delegate = self
        moviesCollectionView?.dataSource = self
        
         let nib = UINib(nibName: "MoviesCollectionViewCell", bundle: nil)
        moviesCollectionView!.register(nib, forCellWithReuseIdentifier: "MovieCell")

        // Configure layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        moviesCollectionView?.collectionViewLayout = layout
        moviesCollectionView?.isScrollEnabled = false  // Important!
        moviesCollectionView?.backgroundColor = .clear
    }

    private func bindViewModel() {
        viewModel.onMoviesChange = { [weak self] movies in
            guard let self = self else { return }
            self.movies = movies
            self.moviesCollectionView?.reloadData()
            self.updateCollectionViewHeight()
            let isEmpty = movies.isEmpty
            self.emptyView.isHidden = !isEmpty
            self.mainScrollView?.isHidden = isEmpty
        }
        viewModel.onFavoritesChange = { [weak self] in
            self?.moviesCollectionView?.reloadData()
        }
        viewModel.onLoadingChange = { [weak self] isLoading in
            DispatchQueue.main.async {
                self?.setLoading(isLoading)
            }
        }
        viewModel.onError = { [weak self] message in
            guard let self = self else { return }
            // Simple alert for now
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
        viewModel.onTitleChange = { [weak self] title in
            self?.titleLabel?.text = title
        }
    }

    private func setupSearchHandlers() {
        searchTextField?.delegate = self
        searchButton?.addTarget(self, action: #selector(didTapSearch), for: .touchUpInside)
        searchTextField?.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }

    @objc private func didTapSearch() {
        let text = searchTextField?.text ?? ""
        viewModel.search(query: text)
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        let text = textField.text ?? ""
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            // Restore mock data when cleared
            searchDebounceTimer?.invalidate()
            loadSampleData()
            titleLabel?.text = "Popular Movies"
            self.emptyView.isHidden = true
            self.mainScrollView?.isHidden = false
        } else {
            // Debounced search-as-you-type
            searchDebounceTimer?.invalidate()
            searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
                self?.viewModel.search(query: trimmed)
            }
        }
    }

    private func setupLoadingIndicator() {
        guard let scrollView = mainScrollView else { return }
        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.backgroundColor = UIColor(named: "Background")?.withAlphaComponent(0.8)
        loadingOverlay.isHidden = true
        scrollView.addSubview(loadingOverlay)
        NSLayoutConstraint.activate([
            loadingOverlay.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            loadingOverlay.topAnchor.constraint(equalTo: scrollView.frameLayoutGuide.topAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: scrollView.frameLayoutGuide.bottomAnchor)
        ])

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerYAnchor)
        ])
    }

    private func setLoading(_ isLoading: Bool) {
        if isLoading {
            loadingOverlay.isHidden = false
            loadingIndicator.startAnimating()
            mainScrollView?.isUserInteractionEnabled = false
        } else {
            loadingOverlay.isHidden = true
            loadingIndicator.stopAnimating()
            mainScrollView?.isUserInteractionEnabled = true
        }
    }
    
    private func loadSampleData() {
        movies = [
            Movie(
                id: "1",
                title: "The Shawshank Redemption",
                rating: 9.3,
                duration: "142",
                posterURL: nil
            ),
            Movie(
                id: "2",
                title: "The Godfather",
                rating: 9.2,
                duration: "175",
                posterURL: nil
            ),
            Movie(
                id: "3",
                title: "The Dark Knight",
                rating: 9.0,
                duration: "152",
                posterURL: nil
            ),
            Movie(
                id: "4",
                title: "Pulp Fiction",
                rating: 8.9,
                duration: "154",
                posterURL: nil
            ),
            Movie(
                id: "5",
                title: "The Dark Knight",
                rating: 9.0,
                duration: "152",
                posterURL: nil
            ),
            Movie(
                id: "6",
                title: "Pulp Fiction",
                rating: 8.9,
                duration: "154",
                posterURL: nil
            ),
            Movie(
                id: "7",
                title: "The Dark Knight",
                rating: 9.0,
                duration: "152",
                posterURL: nil
            ),
            Movie(
                id: "8",
                title: "Pulp Fiction",
                rating: 8.9,
                duration: "154",
                posterURL: nil
            ),
            Movie(
                id: "9",
                title: "The Dark Knight",
                rating: 9.0,
                duration: "152",
                posterURL: nil
            ),
            Movie(
                id: "10",
                title: "Pulp Fiction",
                rating: 8.9,
                duration: "154",
                posterURL: nil
            ),
        ]

        moviesCollectionView?.reloadData()
        updateCollectionViewHeight()
    }
    
    private func updateCollectionViewHeight() {
        guard !movies.isEmpty else { return }
        guard let moviesCollectionView = moviesCollectionView else { return }

        guard let layout = moviesCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let cellWidth =
            (moviesCollectionView.bounds.width - spacing) / numberOfColumns
        let cellHeight = cellWidth * 1.5 + 75

        let numberOfRows = ceil(Double(movies.count) / Double(numberOfColumns))
        let totalSpacing = layout.minimumLineSpacing * CGFloat(numberOfRows - 1)
        let height = (cellHeight * CGFloat(numberOfRows)) + totalSpacing

        // Update or add height constraint safely
        var heightConstraint: NSLayoutConstraint?
        for constraint in moviesCollectionView.constraints where constraint.firstAttribute == .height {
            heightConstraint = constraint
            break
        }

        if let heightConstraint {
            heightConstraint.constant = height
        } else {
            let newHeight = moviesCollectionView.heightAnchor.constraint(equalToConstant: height)
            newHeight.priority = .defaultHigh
            newHeight.isActive = true
        }
    }
    
}

// Mark: - UICollectionView Delegate & DataSource
extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return movies.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "MovieCell",
                for: indexPath
            ) as? MoviesCollectionViewCell
        else {
            return UICollectionViewCell()
        }
        let movie = movies[indexPath.item]
        let isFav = viewModel.isFavorite(movie.id)
        cell.configure(with: movie, isFavorite: isFav) { [weak self] tapped in
            self?.viewModel.toggleFavorite(tapped)
            // Update this single cell icon immediately
            if let currentIndex = self?.movies.firstIndex(where: { $0.id == tapped.id }) {
                self?.moviesCollectionView?.reloadItems(at: [IndexPath(item: currentIndex, section: 0)])
            }
        }
        return cell
    }
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let selectedMovie = movies[indexPath.item]
        let storyboard = UIStoryboard(name: "MovieDetails", bundle: nil)
        if let detailsVC = storyboard.instantiateViewController(withIdentifier: "MovieDetailsViewController") as? MovieDetailsViewController {
            detailsVC.movieID = selectedMovie.id
            self.navigationController?.pushViewController(detailsVC, animated: true)
        }
    }

}

//Mark: - UICollectionViewDelegateFlowLayout
extension ViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let totalSpacing = spacing * (numberOfColumns - 1)
        let width = (collectionView.bounds.width - totalSpacing) / numberOfColumns
        let height = width * 1.5 + 70
        
        return CGSize(width: width, height: height)
    }
}

//Mark: -UITextFieldDelegate
extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        viewModel.search(query: textField.text ?? "")
        return true
    }
}

