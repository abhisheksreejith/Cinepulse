//
//  FavoritesStore.swift
//  Cinepulse
//
//  Created by Assistant on 25/10/25.
//

import Foundation

protocol FavoritesStoring {
    func isFavorite(id: String) -> Bool
    func toggleFavorite(movie: Movie)
    func allFavorites() -> [Movie]
}

final class FavoritesStore: FavoritesStoring {
    static let shared = FavoritesStore()

    private let userDefaults: UserDefaults
    private let key = "favorite_movies"

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func isFavorite(id: String) -> Bool {
        return favoritesDict()[id] != nil
    }

    func toggleFavorite(movie: Movie) {
        var dict = favoritesDict()
        if dict[movie.id] != nil {
            dict.removeValue(forKey: movie.id)
        } else {
            dict[movie.id] = movie
        }
        save(dict: dict)
    }

    func allFavorites() -> [Movie] {
        return Array(favoritesDict().values)
    }

    // MARK: - Private

    private func favoritesDict() -> [String: Movie] {
        guard let data = userDefaults.data(forKey: key) else { return [:] }
        if let decoded = try? JSONDecoder().decode([String: Movie].self, from: data) {
            return decoded
        }
        return [:]
    }

    private func save(dict: [String: Movie]) {
        if let data = try? JSONEncoder().encode(dict) {
            userDefaults.set(data, forKey: key)
        }
    }
}


