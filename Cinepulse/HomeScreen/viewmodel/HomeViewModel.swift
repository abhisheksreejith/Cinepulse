//
//  HomeViewModel.swift
//  Cinepulse
//
//  Created by Assistant on 25/10/25.
//

import Foundation

final class HomeViewModel {
    private let service: MovieServicing
    private let favorites: FavoritesStoring = FavoritesStore.shared

    private(set) var movies: [Movie] = [] {
        didSet { onMoviesChange?(movies) }
    }

    var onMoviesChange: (([Movie]) -> Void)?
    var onLoadingChange: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    var onTitleChange: ((String) -> Void)?
    var onFavoritesChange: (() -> Void)?

    init(service: MovieServicing = MovieService()) {
        self.service = service
    }

    func search(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            movies = []
            onTitleChange?("Popular Movies")
            return
        }
        onLoadingChange?(true)
        service.searchMovies(query: trimmed) { [weak self] result in
            guard let self = self else { return }
            self.onLoadingChange?(false)
            switch result {
            case .success(let movies):
                self.movies = movies
                self.onTitleChange?("Results for \(trimmed)")
            case .failure(let error):
                self.onError?(error.localizedDescription)
                self.movies = []
                self.onTitleChange?("Popular Movies")
            }
        }
    }

    func isFavorite(_ id: String) -> Bool {
        return favorites.isFavorite(id: id)
    }

    func toggleFavorite(_ movie: Movie) {
        favorites.toggleFavorite(movie: movie)
        onFavoritesChange?()
    }
}


