//
//  FavouritesViewController.swift
//  Cinepulse
//
//  Created by Abhishek C Sreejith on 26/10/25.
//

import UIKit

class FavouritesViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView?
    @IBOutlet weak var emptyView: UIView!

    private var favorites: [Movie] = []
    private let spacing: CGFloat = 16
    private let numberOfColumns: CGFloat = 2
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = ""
        setupCollectionView()
        reloadFavorites()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadFavorites()
    }

    @IBAction func backButtonAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    private func setupCollectionView() {
        collectionView?.delegate = self
        collectionView?.dataSource = self
        let nib = UINib(nibName: "MoviesCollectionViewCell", bundle: nil)
        collectionView?.register(nib, forCellWithReuseIdentifier: "MovieCell")

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView?.collectionViewLayout = layout
        collectionView?.backgroundColor = .clear
    }

    private func reloadFavorites() {
        favorites = FavoritesStore.shared.allFavorites()
        emptyView.isHidden = !favorites.isEmpty
        collectionView?.isHidden = favorites.isEmpty
        collectionView?.reloadData()
    }
}

extension FavouritesViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return favorites.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath) as? MoviesCollectionViewCell else {
            return UICollectionViewCell()
        }
        let movie = favorites[indexPath.item]
        let isFav = true
        cell.configure(with: movie, isFavorite: isFav) { [weak self] tapped in
            FavoritesStore.shared.toggleFavorite(movie: tapped)
            self?.reloadFavorites()
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedMovie = favorites[indexPath.item]
        let storyboard = UIStoryboard(name: "MovieDetails", bundle: nil)
        if let detailsVC = storyboard.instantiateViewController(withIdentifier: "MovieDetailsViewController") as? MovieDetailsViewController {
            detailsVC.movieID = selectedMovie.id
            self.navigationController?.pushViewController(detailsVC, animated: true)
        }
    }
}

extension FavouritesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing = spacing * (numberOfColumns - 1)
        let width = (collectionView.bounds.width - totalSpacing) / numberOfColumns
        let height = width * 1.5 + 70
        return CGSize(width: width, height: height)
    }
}


