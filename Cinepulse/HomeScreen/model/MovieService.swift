//
//  MovieService.swift
//  Cinepulse
//
//  Created by Assistant on 25/10/25.
//

import Foundation

protocol MovieServicing {
    func searchMovies(query: String, completion: @escaping (Result<[Movie], Error>) -> Void)
    func fetchDetails(imdbID: String, completion: @escaping (Result<MovieDetail, Error>) -> Void)
}

final class MovieService: MovieServicing {
    private let apiKey: String
    private let baseURL: String
    private let urlSession: URLSession

    init(apiKey: String? = nil, urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        // Load from Secrets.plist first; fall back to argument if provided; else empty
        let secrets = MovieService.loadSecrets()
        self.baseURL = secrets["OMDB_BASE_URL"] as? String ?? "https://www.omdbapi.com/"
        self.apiKey = (secrets["OMDB_API_KEY"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? (secrets["OMDB_API_KEY"] as! String)
            : (apiKey ?? "")
    }

    func searchMovies(query: String, completion: @escaping (Result<[Movie], Error>) -> Void) {
        guard let searchURL = url(with: ["s": query]) else {
            completion(.success([]))
            return
        }

        fetch(type: OMDbSearchResponse.self, from: searchURL) { [weak self] result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let searchResponse):
                guard searchResponse.Response == "True", let summaries = searchResponse.Search, !summaries.isEmpty else {
                    completion(.success([]))
                    return
                }

                self?.hydrateDetails(for: summaries, completion: completion)
            }
        }
    }

    func fetchDetails(imdbID: String, completion: @escaping (Result<MovieDetail, Error>) -> Void) {
        guard let detailURL = url(with: ["i": imdbID]) else {
            completion(.failure(NSError(domain: "OMDb", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid ID"])) )
            return
        }
        fetch(type: OMDbMovieDetail.self, from: detailURL) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let detail):
                let rating = Double(detail.imdbRating ?? "") ?? 0.0
                let durationMinutes = MovieService.parseMinutes(from: detail.Runtime)
                let genres = (detail.Genre ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                let cast = (detail.Actors ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                let mapped = MovieDetail(
                    id: detail.imdbID,
                    title: detail.Title,
                    rating: rating,
                    duration: durationMinutes,
                    posterURL: detail.Poster,
                    plot: detail.Plot,
                    genres: genres,
                    cast: cast
                )
                completion(.success(mapped))
            }
        }
    }

    private func hydrateDetails(for summaries: [OMDbMovieSummary], completion: @escaping (Result<[Movie], Error>) -> Void) {
        let group = DispatchGroup()
        var movies: [Movie] = []
        var firstError: Error?
        let lock = NSLock()

        // Limit to a reasonable number to avoid too many requests
        let limitedSummaries = Array(summaries.prefix(20))

        for summary in limitedSummaries {
            group.enter()
            guard let detailURL = url(with: ["i": summary.imdbID]) else {
                group.leave()
                continue
            }

            fetch(type: OMDbMovieDetail.self, from: detailURL) { result in
                defer { group.leave() }
                switch result {
                case .failure(let error):
                    lock.lock()
                    if firstError == nil { firstError = error }
                    lock.unlock()
                case .success(let detail):
                    let rating = Double(detail.imdbRating ?? "") ?? 0.0
                    let durationMinutes = MovieService.parseMinutes(from: detail.Runtime)
                    let movie = Movie(
                        id: detail.imdbID,
                        title: detail.Title,
                        rating: rating,
                        duration: durationMinutes,
                        posterURL: detail.Poster
                    )
                    lock.lock()
                    movies.append(movie)
                    lock.unlock()
                }
            }
        }

        group.notify(queue: .main) {
            if let error = firstError, movies.isEmpty {
                completion(.failure(error))
            } else {
                completion(.success(movies))
            }
        }
    }

    private func fetch<T: Decodable>(type: T.Type, from url: URL, completion: @escaping (Result<T, Error>) -> Void) {
        urlSession.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "OMDb", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])) ) }
                return
            }
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async { completion(.success(decoded)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    private func url(with queryItems: [String: String]) -> URL? {
        var components = URLComponents(string: baseURL)
        var items: [URLQueryItem] = [URLQueryItem(name: "apikey", value: apiKey)]
        for (key, value) in queryItems {
            items.append(URLQueryItem(name: key, value: value))
        }
        components?.queryItems = items
        return components?.url
    }

    private static func loadSecrets() -> [String: Any] {
        // Secrets.plist must be added to the target's Copy Bundle Resources
        // We search at bundle root (no subdirectory) because Xcode groups don't imply bundle subfolders
        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
           let dict = plist as? [String: Any] {
            return dict
        }
        // Fallback using path API
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let data = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dict = plist as? [String: Any] else {
            return [:]
        }
        return dict
    }

    private static func parseMinutes(from runtime: String?) -> String {
        guard let runtime = runtime else { return "N/A" }
        // Typical format: "136 min"
        let digits = runtime.split(separator: " ").first ?? Substring("")
        return digits.isEmpty ? "N/A" : String(digits)
    }
}


