//
//  MoviesCollectionViewCell.swift
//  Cinepulse
//
//  Created by Abhishek C Sreejith on 25/10/25.
//

import UIKit

class MoviesCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var movieTitle: UILabel!
    @IBOutlet weak var posterImage: UIImageView!
    @IBOutlet weak var favoriteButton: UIButton!

    private var currentMovie: Movie?
    var onToggleFavorite: ((Movie) -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(with movie: Movie, isFavorite: Bool, onToggle: @escaping (Movie) -> Void) {
        print("Configuring cell for movie: \(movie.title)")
        currentMovie = movie
        onToggleFavorite = onToggle
        movieTitle.text = movie.title
        ratingLabel.text = String(format: "%.1f", movie.rating)
        durationLabel.text = "\(movie.duration) mins"  // e.g., "2h 22m"

        // Reset image
        posterImage.layer.cornerRadius = 15
        posterImage.image = UIImage(systemName: "photo")
        posterImage.tintColor = .systemGray3

        if let imageURL = movie.posterURL {
            loadImage(from: imageURL)
        }

        let imageName = isFavorite ? "heart.fill" : "heart"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    @IBAction func favoriteTapped(_ sender: UIButton) {
        guard let movie = currentMovie else { return }
        onToggleFavorite?(movie)
    }

    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) {
            [weak self] data, response, error in
            guard let data = data,
                error == nil,
                let image = UIImage(data: data)
            else {
                return
            }

            DispatchQueue.main.async {
                self?.posterImage.image = image
                self?.posterImage.contentMode = .scaleAspectFill
            }
        }.resume()
    }
}
