//
//  Models.swift
//  Cinepulse
//
//  Created by Abhishek C Sreejith on 25/10/25.
//

struct Movie: Codable {
    let id: String;
    let title: String;
    let rating: Double;
    let duration: String; 
    let posterURL: String?;
}

struct OMDbSearchResponse: Decodable {
    let Search: [OMDbMovieSummary]?
    let totalResults: String?
    let Response: String
    let Error: String?
}

struct OMDbMovieSummary: Decodable {
    let Title: String
    let Year: String
    let imdbID: String
    let Poster: String
}

struct OMDbMovieDetail: Decodable {
    let Title: String
    let Year: String
    let imdbID: String
    let Poster: String
    let Runtime: String?
    let imdbRating: String?
    let Plot: String?
    let Genre: String?
    let Actors: String?
}

struct MovieDetail: Codable {
    let id: String
    let title: String
    let rating: Double
    let duration: String
    let posterURL: String?
    let plot: String?
    let genres: [String]
    let cast: [String]
}
