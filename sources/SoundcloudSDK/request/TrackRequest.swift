//
//  TrackRequest.swift
//  SoundcloudSDK
//
//  Created by Kevin DELANNOY on 25/04/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import Foundation

public extension Track {
    static let BaseURL = URL(string: "https://api.soundcloud.com/tracks")!

    /**
     Load track with a specific identifier

     - parameter identifier: The identifier of the track to load
     - parameter completion: The closure that will be called when track is loaded or upon error
     */
    @discardableResult
    static func track(identifier: Int, completion: @escaping (SimpleAPIResponse<Track>) -> Void) -> CancelableOperation? {
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(SimpleAPIResponse(error: .needsLogin))
            return nil
        }
        
        let url = BaseURL.appendingPathComponent("\(identifier)")
        let headers = ["Authorization" : "OAuth \(oauthToken)"]
        
        let request = Request(url: url, method: .get, parameters: nil, headers: headers, parse: {
            if let track = Track(JSON: $0) {
                return .success(track)
            }
            return .failure(.parsing)
        }) { result in
            completion(SimpleAPIResponse(result: result))
        }
        request.start()
        return request
    }

    /**
     Load tracks with specific identifiers

     - parameter identifiers: The identifiers of the tracks to load
     - parameter completion:  The closure that will be called when tracks are loaded or upon error
     */
    @discardableResult
    static func tracks(identifiers: [Int], completion: @escaping (SimpleAPIResponse<[Track]>) -> Void) -> CancelableOperation? {
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(SimpleAPIResponse(error: .needsLogin))
            return nil
        }
        let headers = ["Authorization" : "OAuth \(oauthToken)"]
        let parameters = ["ids": identifiers.map { "\($0)" }.joined(separator: ",")]
        let request = Request(url: BaseURL, method: .get, parameters: parameters, headers: headers, parse: {
            guard let tracks = $0.flatMap(transform: { Track(JSON: $0) }) else {
                return .failure(.parsing)
            }
            return .success(tracks)
        }) { result in
            completion(SimpleAPIResponse(result: result))
        }
        request.start()
        return request
    }

    /**
     Search tracks that fit asked queries.

     - parameter queries:    The queries to run
     - parameter completion: The closure that will be called when tracks are loaded or upon error
     */
    @discardableResult
    static func search(queries: [SearchQueryOptions], completion: @escaping (PaginatedAPIResponse<Track>) -> Void) -> CancelableOperation? {
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(PaginatedAPIResponse(error: .needsLogin))
            return nil
        }
        
        let parse = { (JSON: JSONObject) -> Result<[Track], SoundcloudError> in
            guard let tracks = JSON.flatMap(transform: { Track(JSON: $0) }) else {
                return .failure(.parsing)
            }
            return .success(tracks)
        }
        
        let headers = ["Authorization" : "OAuth \(oauthToken)"]
        var parameters = ["linked_partitioning": "true"]
        queries.map { $0.query }.forEach { parameters[$0.0] = $0.1 }

        let request = Request(url: BaseURL, method: .get, parameters: parameters, headers: headers, parse: { JSON -> Result<PaginatedAPIResponse<Track>, SoundcloudError> in
            return .success(PaginatedAPIResponse(JSON: JSON, parse: parse))
        }) { result in
            completion(result.recover { PaginatedAPIResponse(error: $0) })
        }
        request.start()
        return request
    }
    
    @discardableResult
    static func getPlayableUrl(identifier: Int,completion: @escaping (SimpleAPIResponse<URL>) -> Void) -> CancelableOperation? {
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(SimpleAPIResponse(error: .needsLogin))
            return nil
        }
        
        let url = BaseURL.appendingPathComponent("\(identifier)/streams")
        let headers = ["Authorization" : "OAuth \(oauthToken)"]
        
        let request = Request(url: url, method: .get, parameters: nil, headers: headers, parse: {
            guard let string = $0["http_mp3_128_url"].stringValue, let url = URL(string: string) else {
                return .failure(.parsing)
            }
            
            return .success(url)
        }) { result in
            completion(SimpleAPIResponse(result: result))
        }
        request.start()
        return request
    }

    /**
     Load comments relative to a track

     - parameter trackIdentifier: The track identifier.
     - parameter completion:      The closure that will be called when the comments are loaded or upon error
     */
    @discardableResult
    static func comments(on trackIdentifier: Int, completion: @escaping (PaginatedAPIResponse<Comment>) -> Void) -> CancelableOperation? {
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(PaginatedAPIResponse(error: .needsLogin))
            return nil
        }
        let parse = { (JSON: JSONObject) -> Result<[Comment], SoundcloudError> in
            guard let comments = JSON.flatMap(transform: { Comment(JSON: $0) }) else {
                return .failure(.parsing)
            }
            return .success(comments)
        }

        
        let url = BaseURL.appendingPathComponent("\(trackIdentifier)/comments")
        let parameters = ["linked_partitioning": "true"]
        let headers = ["Authorization" : "OAuth \(oauthToken)"]

        let request = Request(url: url, method: .get, parameters: parameters, headers: headers, parse: { JSON -> Result<PaginatedAPIResponse<Comment>, SoundcloudError> in
            return .success(PaginatedAPIResponse(JSON: JSON, parse: parse))
        }) { result in
            completion(result.recover { PaginatedAPIResponse(error: $0) })
        }
        request.start()
        return request
    }

    /**
     Load comments relative to a track

     - parameter completion: The closure that will be called when the comments are loaded or upon error
     */
    @discardableResult
    func comments(completion: @escaping (PaginatedAPIResponse<Comment>) -> Void) -> CancelableOperation? {
        return Track.comments(on: identifier, completion: completion)
    }

    /**
     Create a new comment on a track

     **This method requires a Session.**

     - parameter trackIdentifier: The track identifier.
     - parameter body:       The text body of the comment
     - parameter timestamp:  The progression of the track when the comment was validated
     - parameter completion: The closure that will be called when the comment is posted or upon error
     */
    @discardableResult
    @available(tvOS, unavailable)
    static func comment(on trackIdentifier: Int, body: String, timestamp: TimeInterval, completion: @escaping (SimpleAPIResponse<Comment>) -> Void) -> CancelableOperation? {
#if !os(tvOS)
        
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(SimpleAPIResponse(error: .needsLogin))
            return nil
        }
        
        let url = BaseURL.appendingPathComponent("\(trackIdentifier)/comments")
        let parameters = [
            "comment[body]": body,
            "comment[timestamp]": "\(timestamp)"
        ]
        let headers = ["Authorization" : "OAuth \(oauthToken)"]
        
        let request = Request(url: url, method: .post, parameters: parameters, headers: headers, parse: {
            if let comments = Comment(JSON: $0) {
                return .success(comments)
            }
            return .failure(.parsing)
        }) { result in
            completion(SimpleAPIResponse(result: result))
        }
        request.start()
        return request
#else
        return nil
#endif
    }

    /**
     Create a new comment on a track

     **This method requires a Session.**

     - parameter body:       The text body of the comment
     - parameter timestamp:  The progression of the track when the comment was validated
     - parameter completion: The closure that will be called when the comment is posted or upon error
     */
    @discardableResult
    @available(tvOS, unavailable)
    func comment(body: String, timestamp: TimeInterval, completion: @escaping (SimpleAPIResponse<Comment>) -> Void) -> CancelableOperation? {
        #if !os(tvOS)
            return Track.comment(on: identifier, body: body, timestamp: timestamp, completion: completion)
        #else
            return nil
        #endif
    }

    /**
     Fetch the list of users that favorited the track.

     - parameter trackIdentifier: The track identifier.
     - parameter completion:      The closure that will be called when users are loaded or upon error
     */
    @discardableResult
    static func favoriters(of trackIdentifier: Int, completion: @escaping (PaginatedAPIResponse<User>) -> Void) -> CancelableOperation? {
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(PaginatedAPIResponse(error: .needsLogin))
            return nil
        }
        
        let url = BaseURL.appendingPathComponent("\(trackIdentifier)/favoriters")
        let parameters = ["linked_partitioning": "true"]
        let headers = ["Authorization" : "OAuth \(oauthToken)"]
        

        let parse = { (JSON: JSONObject) -> Result<[User], SoundcloudError> in
            guard let users = JSON.flatMap(transform: { User(JSON: $0) }) else {
                return .failure(.parsing)
            }
            return .success(users)
        }

        let request = Request(url: url, method: .get, parameters: parameters, headers: headers, parse: { JSON -> Result<PaginatedAPIResponse<User>, SoundcloudError> in
            return .success(PaginatedAPIResponse(JSON: JSON, parse: parse))
        }) { result in
            completion(result.recover { PaginatedAPIResponse(error: $0) })
        }
        request.start()
        return request
    }

    /**
     Fetch the list of users that favorited the track.

     - parameter completion: The closure that will be called when users are loaded or upon error
     */
    @discardableResult
    func favoriters(completion: @escaping (PaginatedAPIResponse<User>) -> Void) -> CancelableOperation? {
        return Track.favoriters(of: identifier, completion: completion)
    }

    /**
     Favorites a track for the logged user

     **This method requires a Session.**

     - parameter trackIdentifier: The track identifier.
     - parameter completion:      The closure that will be called when the track has been favorited or upon error
     */
    @discardableResult
    @available(tvOS, unavailable)
    static func favorite(trackIdentifier: Int, completion: @escaping (SimpleAPIResponse<Bool>) -> Void) -> CancelableOperation? {
        #if !os(tvOS)
            return Track.changeFavoriteStatus(of: trackIdentifier, favorite: true, completion: completion)
        #else
            return nil
        #endif
    }

    /**
     Favorites a track for the logged user

     **This method requires a Session.**

     - parameter completion: The closure that will be called when the track has been favorited or upon error
     */
    @discardableResult
    @available(tvOS, unavailable)
    public func favorite(completion: @escaping (SimpleAPIResponse<Bool>) -> Void) -> CancelableOperation? {
        #if !os(tvOS)
            return Track.changeFavoriteStatus(of: identifier, favorite: true, completion: completion)
        #else
            return nil
        #endif
    }

    /**
     Unfavorites a track for the logged user

     **This method requires a Session.**

     - parameter trackIdentifier: The track identifier.
     - parameter completion:      The closure that will be called when the track has been unfavorited or upon error
     */
    @discardableResult
    @available(tvOS, unavailable)
    public static func unfavorite(trackIdentifier: Int, completion: @escaping (SimpleAPIResponse<Bool>) -> Void) -> CancelableOperation? {
        #if !os(tvOS)
            return Track.changeFavoriteStatus(of: trackIdentifier, favorite: false, completion: completion)
        #else
            return nil
        #endif
    }

    /**
     Unfavorites a track for the logged user

     **This method requires a Session.**

     - parameter completion: The closure that will be called when the track has been unfavorited or upon error
     */
    @discardableResult
    @available(tvOS, unavailable)
    public func unfavorite(completion: @escaping (SimpleAPIResponse<Bool>) -> Void) -> CancelableOperation? {
        #if !os(tvOS)
            return Track.changeFavoriteStatus(of: identifier, favorite: false, completion: completion)
        #else
            return nil
        #endif
    }

    @available(tvOS, unavailable)
    private static func changeFavoriteStatus(of trackIdentifier: Int, favorite: Bool, completion: @escaping (SimpleAPIResponse<Bool>) -> Void) -> CancelableOperation? {
        #if !os(tvOS)
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(SimpleAPIResponse(error: .needsLogin))
            return nil
        }
        
        let url = URL(string: "https://api.soundcloud.com/likes/tracks/\(trackIdentifier)")!
        
        let headers = ["Authorization" : "OAuth \(oauthToken)"]
        
        let request = Request(url: url, method: favorite ? .put : .delete, parameters: nil, headers: headers, parse: { _ in
            return .success(true)
        }) { result in
            completion(SimpleAPIResponse(result: result))
        }
        request.start()
        return request
#else
        return nil
#endif
    }

    /**
     Load related tracks of a track with a specific identifier

     - parameter identifier: The identifier of the track whose related tracks you wish to find
     - parameter completion: The closure that will be called when tracks are loaded or upon error
     */
    @discardableResult
    static func relatedTracks(identifier: Int, completion: @escaping (SimpleAPIResponse<[Track]>) -> Void) -> CancelableOperation? {
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(SimpleAPIResponse(error: .needsLogin))
            return nil
        }
        
        let url = BaseURL.appendingPathComponent("\(identifier)/related")
        let headers = ["Authorization" : "OAuth \(oauthToken)"]
        
        let request = Request(url: url, method: .get, parameters: nil, headers: headers, parse: {
            guard let tracks = $0.flatMap(transform: { Track(JSON: $0) }) else {
                return .failure(.parsing)
            }
            return .success(tracks)
        }) { result in
            completion(SimpleAPIResponse(result: result))
        }
        request.start()
        return request
    }
}
