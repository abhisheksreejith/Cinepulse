//
//  MovieService.swift
//  Cinepulse
//
//  Created by Assistant on 25/10/25.
//

import Foundation

protocol MovieServicing {
    func searchMovies(query: String, completion: @escaping (Result<[Movie], Error>) -> Void)
    func fetchDetails(movieID: String, completion: @escaping (Result<MovieDetail, Error>) -> Void)
    func fetchPopular(completion: @escaping (Result<[Movie], Error>) -> Void)
}

final class MovieService: MovieServicing {
    private let apiKey: String
    private let baseURL: String
    private let urlSession: URLSession
    private let imageBaseURL = "https://image.tmdb.org/t/p/w500"

    init(apiKey: String? = nil, urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        let secrets = MovieService.loadSecrets()
        let tmdbBase = (secrets["TMDB_BASE_URL"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let tmdbKey = (secrets["TMDB_API_KEY"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.baseURL = (tmdbBase?.isEmpty == false ? tmdbBase! : "https://api.themoviedb.org/3")
        self.apiKey = (tmdbKey?.isEmpty == false ? tmdbKey! : (apiKey ?? ""))
    }

    // MARK: - Popular (TMDb)
    func fetchPopular(completion: @escaping (Result<[Movie], Error>) -> Void) {
        var comps = URLComponents(string: baseURL)
        let basePath = comps?.path ?? ""
        comps?.path = (basePath.hasSuffix("/") ? basePath + "movie/popular" : basePath + "/movie/popular")
        comps?.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        guard let url = comps?.url else { completion(.success([])); return }
        fetch(type: TMDbSearchResponse.self, from: url) { [weak self] result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let items: [Movie] = response.results.map { s in
                    Movie(
                        id: String(s.id),
                        title: s.title,
                        rating: s.vote_average,
                        duration: "N/A",
                        posterURL: s.poster_path != nil ? (self?.imageBaseURL ?? "") + s.poster_path! : nil
                    )
                }
                completion(.success(items))
            }
        }
    }

    // MARK: - Search (TMDb)
    func searchMovies(query: String, completion: @escaping (Result<[Movie], Error>) -> Void) {
        var comps = URLComponents(string: baseURL)
        let basePath = comps?.path ?? ""
        comps?.path = (basePath.hasSuffix("/") ? basePath + "search/movie" : basePath + "/search/movie")
        comps?.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: query)
        ]
        guard let url = comps?.url else { completion(.success([])); return }
        fetch(type: TMDbSearchResponse.self, from: url) { [weak self] result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let items: [Movie] = response.results.map { s in
                    Movie(
                        id: String(s.id),
                        title: s.title,
                        rating: s.vote_average,
                        duration: "N/A",
                        posterURL: s.poster_path != nil ? (self?.imageBaseURL ?? "") + s.poster_path! : nil
                    )
                }
                completion(.success(items))
            }
        }
    }

    // MARK: - Details (TMDb)
    func fetchDetails(movieID: String, completion: @escaping (Result<MovieDetail, Error>) -> Void) {
        guard let id = Int(movieID) else {
            completion(.failure(NSError(domain: "TMDb", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid ID"])));
            return
        }
        // Details
        var detailComps = URLComponents(string: baseURL)
        let basePath = detailComps?.path ?? ""
        detailComps?.path = (basePath.hasSuffix("/") ? basePath + "movie/\(id)" : basePath + "/movie/\(id)")
        detailComps?.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        guard let detailURL = detailComps?.url else {
            completion(.failure(NSError(domain: "TMDb", code: -3, userInfo: nil)))
            return
        }

        fetch(type: TMDbMovieDetail.self, from: detailURL) { [weak self] result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let d):
                // Credits (cast)
                var creditsComps = URLComponents(string: self?.baseURL ?? "")
                let creditsBasePath = creditsComps?.path ?? ""
                creditsComps?.path = (creditsBasePath.hasSuffix("/") ? creditsBasePath + "movie/\(id)/credits" : creditsBasePath + "/movie/\(id)/credits")
                creditsComps?.queryItems = [URLQueryItem(name: "api_key", value: self?.apiKey)]
                // Videos (trailers)
                var videosComps = URLComponents(string: self?.baseURL ?? "")
                let videosBasePath = videosComps?.path ?? ""
                videosComps?.path = (videosBasePath.hasSuffix("/") ? videosBasePath + "movie/\(id)/videos" : videosBasePath + "/movie/\(id)/videos")
                videosComps?.queryItems = [URLQueryItem(name: "api_key", value: self?.apiKey)]

                let creditsURL = creditsComps?.url
                let videosURL = videosComps?.url

                let group = DispatchGroup()
                var castNames: [String] = []
                var trailerURLString: String? = nil

                if let creditsURL {
                    group.enter()
                    self?.fetch(type: TMDbCredits.self, from: creditsURL) { creditsRes in
                        if case let .success(c) = creditsRes {
                            castNames = c.cast.prefix(12).map { $0.name }
                        }
                        group.leave()
                    }
                }

                if let videosURL {
                    group.enter()
                    self?.fetch(type: TMDbVideos.self, from: videosURL) { videosRes in
                        if case let .success(videos) = videosRes {
                            // Pick first YouTube trailer
                            if let trailer = videos.results.first(where: { $0.site.lowercased() == "youtube" && $0.type.lowercased().contains("trailer") }) {
                                trailerURLString = "https://www.youtube.com/watch?v=\(trailer.key)"
                            }
                        }
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    let genres = d.genres.map { $0.name }
                    let poster = d.poster_path != nil ? (self?.imageBaseURL ?? "") + d.poster_path! : nil
                    let mapped = MovieDetail(
                        id: String(d.id),
                        title: d.title,
                        rating: d.vote_average,
                        duration: d.runtime != nil ? String(d.runtime!) : "N/A",
                        posterURL: poster,
                        plot: d.overview,
                        genres: genres,
                        cast: castNames,
                        trailerURL: trailerURLString
                    )
                    completion(.success(mapped))
                }
            }
        }
    }

    // MARK: - Networking
    private func fetch<T: Decodable>(type: T.Type, from url: URL, completion: @escaping (Result<T, Error>) -> Void) {
        urlSession.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "TMDb", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])) ) }
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

    private static func loadSecrets() -> [String: Any] {
        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
           let dict = plist as? [String: Any] {
            return dict
        }
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let data = FileManager.default.contents(atPath: path),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
           let dict = plist as? [String: Any] {
            return dict
        }
        return [:]
    }
}

// MARK: - TMDb DTOs
private struct TMDbSearchResponse: Decodable { let results: [TMDbMovieSummary] }
private struct TMDbMovieSummary: Decodable { let id: Int; let title: String; let vote_average: Double; let poster_path: String? }
private struct TMDbMovieDetail: Decodable { let id: Int; let title: String; let overview: String?; let runtime: Int?; let vote_average: Double; let poster_path: String?; let genres: [TMDbGenre] }
private struct TMDbGenre: Decodable { let id: Int; let name: String }
private struct TMDbCredits: Decodable { let cast: [TMDbCast] }
private struct TMDbCast: Decodable { let name: String }
private struct TMDbVideos: Decodable { let results: [TMDbVideo] }
private struct TMDbVideo: Decodable { let key: String; let site: String; let type: String }


