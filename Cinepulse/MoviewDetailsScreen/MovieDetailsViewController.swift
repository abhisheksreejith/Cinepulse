//
//  MovieDetailsViewController.swift
//  Cinepulse
//
//  Created by Abhishek C Sreejith on 26/10/25.
//

import UIKit
import AVKit
import AVFoundation

class MovieDetailsViewController: UIViewController {
    @IBOutlet weak var trailerView: UIView!
    @IBOutlet weak var movieTitle: UILabel!
    @IBOutlet weak var favouriteButton: UIButton!
    @IBOutlet weak var rating: UILabel!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var genresCollection: UICollectionView!
    @IBOutlet weak var genresHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var castTitleLabel: UILabel!
    @IBOutlet weak var castStack: UIStackView!
    @IBOutlet weak var castCollection: UICollectionView!
    @IBOutlet weak var castHeightConstraint: NSLayoutConstraint!

    var imdbID: String?
    private let service: MovieServicing = MovieService()
    private var genres: [String] = []
    private var cast: [String] = []
    private var currentMovie: Movie?
    private var trailerPlayerVC: AVPlayerViewController?
    private let loadingOverlay = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    override func viewDidLoad() {
        super.viewDidLoad()
        // Ensure description label sizes to its intrinsic height only
        descriptionLabel.numberOfLines = 0
        descriptionLabel.setContentHuggingPriority(.required, for: .vertical)
        descriptionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        trailerView.layer.cornerRadius = 16
        setupGenres()
        setupCast()
        setupLoading()
        loadDetails()
        let urlString  = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        setTrailerURL(urlString)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure multi-line label measures correctly and does not expand
        descriptionLabel.preferredMaxLayoutWidth = descriptionLabel.bounds.width
        movieTitle.numberOfLines = 0
        movieTitle.lineBreakMode = .byWordWrapping
        movieTitle.setContentHuggingPriority(.required, for: .vertical)
        movieTitle.setContentCompressionResistancePriority(.required, for: .vertical)
        updateGenresHeight()
        updateCastHeight()
    }

    private func loadDetails() {
        guard let id = imdbID else { return }
        setLoading(true)
        service.fetchDetails(imdbID: id) { [weak self] result in
            switch result {
            case .failure:
                self?.setLoading(false)
            case .success(let detail):
                self?.apply(detail)
                self?.setLoading(false)
            }
        }
    }

    private func apply(_ detail: MovieDetail) {
        movieTitle.text = detail.title
        rating.text = String(format: "%.1f", detail.rating)
        duration.text = "\(detail.duration) mins"
        descriptionLabel.text = detail.plot ?? ""
        descriptionLabel.lineBreakMode = .byWordWrapping
        genres = detail.genres
        genresCollection.reloadData()
        view.setNeedsLayout()
        view.layoutIfNeeded()
        updateGenresHeight()
        cast = detail.cast
        renderCast()
        castCollection.reloadData()
        updateCastHeight()

        // Build favorite model and update button state
        currentMovie = Movie(
            id: detail.id,
            title: detail.title,
            rating: detail.rating,
            duration: detail.duration,
            posterURL: detail.posterURL
        )
        updateFavoriteButton()
    }
}

// MARK: - Cast Rendering
extension MovieDetailsViewController {
    private func renderCast() {
        let hasCast = !cast.isEmpty
        castTitleLabel.isHidden = !hasCast
        castStack?.isHidden = !hasCast
    }
}

extension MovieDetailsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private func setupGenres() {
        genresCollection.delegate = self
        genresCollection.dataSource = self
        genresCollection.backgroundColor = .clear
        genresCollection.register(GenreChipCell.self, forCellWithReuseIdentifier: "GenreChipCell")
        if let layout = genresCollection.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .vertical
            layout.minimumInteritemSpacing = 8
            layout.minimumLineSpacing = 8
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
        genresCollection.alwaysBounceVertical = false
        genresCollection.isScrollEnabled = false
    }

    private func setupCast() {
        castCollection?.delegate = self
        castCollection?.dataSource = self
        castCollection?.backgroundColor = .clear
        castCollection?.register(CastPersonCell.self, forCellWithReuseIdentifier: "CastPersonCell")
        if let layout = castCollection?.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .vertical
            layout.minimumInteritemSpacing = 12
            layout.minimumLineSpacing = 12
        }
        castCollection?.alwaysBounceVertical = false
        castCollection?.isScrollEnabled = false
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == genresCollection { return genres.count }
        return cast.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == genresCollection {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GenreChipCell", for: indexPath) as? GenreChipCell else {
                return UICollectionViewCell()
            }
            cell.configure(text: genres[indexPath.item])
            return cell
        } else {
            collectionView.register(CastPersonCell.self, forCellWithReuseIdentifier: "CastPersonCell")
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CastPersonCell", for: indexPath) as? CastPersonCell else {
                return UICollectionViewCell()
            }
            cell.configure(name: cast[indexPath.item])
            return cell
        }
    }

    private func updateGenresHeight() {
        let contentHeight = genresCollection.collectionViewLayout.collectionViewContentSize.height
        // Add a tiny padding to avoid clipping rounded corners
        genresHeightConstraint?.constant = max(0, contentHeight)
    }

    private func updateCastHeight() {
        guard let castCollection = castCollection,
              let layout = castCollection.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        // Compute dynamic height with 3 columns grid
        castCollection.layoutIfNeeded()
        let width = castCollection.bounds.width
        let columns: CGFloat = 3
        let spacing = layout.minimumInteritemSpacing
        let totalSpacing = spacing * (columns - 1)
        let itemWidth = floor((width - totalSpacing) / columns)
        layout.itemSize = CGSize(width: itemWidth, height: 72)
        let contentHeight = castCollection.collectionViewLayout.collectionViewContentSize.height
        castHeightConstraint?.constant = contentHeight
    }

    // MARK: - Loading UI
    private func setupLoading() {
        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.backgroundColor = UIColor(named: "Background")?.withAlphaComponent(1)
        loadingOverlay.isHidden = true
        view.addSubview(loadingOverlay)
        NSLayoutConstraint.activate([
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setLoading(_ isLoading: Bool) {
        if isLoading {
            loadingOverlay.isHidden = false
            loadingIndicator.startAnimating()
            view.isUserInteractionEnabled = false
        } else {
            loadingOverlay.isHidden = true
            loadingIndicator.stopAnimating()
            view.isUserInteractionEnabled = true
        }
    }

    // MARK: - Trailer Playback
    func setTrailerURL(_ urlString: String) {
        guard let container = trailerView else { return }
        var finalURL: URL?
        if var comps = URLComponents(string: urlString) {
            if comps.scheme == "http" { comps.scheme = "https" }
            finalURL = comps.url
        }
        if finalURL == nil { finalURL = URL(string: urlString) }
        guard let url = finalURL else { return }
        // Remove existing player if any
        if let existing = trailerPlayerVC {
            existing.willMove(toParent: nil)
            existing.view.removeFromSuperview()
            existing.removeFromParent()
        }

        let player = AVPlayer(url: url)
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = true
        vc.videoGravity = .resizeAspectFill

        addChild(vc)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(vc.view)
        NSLayoutConstraint.activate([
            vc.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            vc.view.topAnchor.constraint(equalTo: container.topAnchor),
            vc.view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        vc.didMove(toParent: self)
        trailerPlayerVC = vc
        container.layer.cornerRadius = 16
        container.layer.masksToBounds = true
        DispatchQueue.main.async {
            player.play()
        }
    }

    // MARK: - Favorites
    private func updateFavoriteButton() {
        guard let currentMovie = currentMovie else { return }
        let isFav = FavoritesStore.shared.isFavorite(id: currentMovie.id)
        let imageName = isFav ? "heart.fill" : "heart"
        if let image = UIImage(systemName: imageName)?.withRenderingMode(.alwaysTemplate) {
            favouriteButton.setImage(image, for: .normal)
        } else {
            favouriteButton.setImage(UIImage(systemName: imageName), for: .normal)
        }
        favouriteButton.tintColor = UIColor(named: "Accent") ?? .systemRed
    }

    @IBAction func favoriteTapped(_ sender: UIButton) {
        print("Favorite tapped")
        guard let currentMovie = currentMovie else { return }
        FavoritesStore.shared.toggleFavorite(movie: currentMovie)
        updateFavoriteButton()
    }
}
