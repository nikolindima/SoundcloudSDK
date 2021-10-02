//
//  UserRequest.swift
//  SoundcloudSDK
//
//  Created by Kevin DELANNOY on 25/04/15.
//  Copyright (c) 2015 Kevin Delannoy. All rights reserved.
//

import Foundation

public extension User {
    static let BaseURL = URL(string: "https://api.soundcloud.com/users")!

    /**
     Loads an user profile

     - parameter identifier: The identifier of the user to load
     - parameter completion: The closure that will be called when user profile is loaded or upon error
     */
    @discardableResult
    static func user(identifier: Int, completion: @escaping (SimpleAPIResponse<User>) -> Void) -> CancelableOperation? {
        
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(SimpleAPIResponse(error: .needsLogin))
            return nil
        }
        

        let url = BaseURL.appendingPathComponent("\(identifier)")
        let headers = ["Authorization" : "OAuth \(oauthToken)"]
        
        let request = Request(url: url, method: .get, parameters: nil, headers: headers, parse: {
            if let user = User(JSON: $0) {
                return .success(user)
            }
            return .failure(.parsing)
        }) { result in
            completion(SimpleAPIResponse(result: result))
        }
        request.start()
        return request
    }

    /**
     Search users that fit requested name.

     - parameter query:      The query to run.
     - parameter completion: The closure that will be called when users are loaded or upon error.
     */
    @discardableResult
    static func search(query: String, completion: @escaping (PaginatedAPIResponse<User>) -> Void) -> CancelableOperation? {
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(PaginatedAPIResponse(error: .needsLogin))
            return nil
        }
        let parse = { (JSON: JSONObject) -> Result<[User], SoundcloudError> in
            guard let users = JSON.flatMap(transform: { User(JSON: $0) }) else {
                return .failure(.parsing)
            }
            return .success(users)
        }

        let parameters = ["linked_partitioning": "true", "q": query]
        let headers = ["Authorization" : "OAuth \(oauthToken)"]
        
        let request = Request(url: BaseURL, method: .get, parameters: parameters, headers: headers, parse: { JSON -> Result<PaginatedAPIResponse<User>, SoundcloudError> in
            return .success(PaginatedAPIResponse(JSON: JSON, parse: parse))
        }) { result in
            completion(result.recover { PaginatedAPIResponse(error: $0) })
        }
        request.start()
        return request
    }

    /**
     Loads tracks the user uploaded to Soundcloud

     - parameter completion: The closure that will be called when tracks are loaded or upon error
     */
    @discardableResult
    func tracks(completion: @escaping (PaginatedAPIResponse<Track>) -> Void) -> CancelableOperation? {
        return User.tracks(from: identifier, completion: completion)
    }

    /**
     Loads tracks the user uploaded to Soundcloud

     - parameter userIdentifier: The identifier of the user to load
     - parameter completion:     The closure that will be called when tracks are loaded or upon error
     */
    @discardableResult
    static func tracks(from userIdentifier: Int, completion: @escaping (PaginatedAPIResponse<Track>) -> Void) -> CancelableOperation? {
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(PaginatedAPIResponse(error: .needsLogin))
            return nil
        }
        let url = BaseURL.appendingPathComponent("\(userIdentifier)/tracks")
        let parameters = ["linked_partitioning": "true"]
        let headers = ["Authorization" : "OAuth \(oauthToken)"]

        let parse = { (JSON: JSONObject) -> Result<[Track], SoundcloudError> in
            guard let tracks = JSON.flatMap(transform: { Track(JSON: $0) }) else {
                return .failure(.parsing)
            }
            return .success(tracks)
        }

        let request = Request(url: url, method: .get, parameters: parameters, headers: headers, parse: { JSON -> Result<PaginatedAPIResponse<Track>, SoundcloudError> in
            return .success(PaginatedAPIResponse(JSON: JSON, parse: parse))
        }) { result in
            completion(result.recover { PaginatedAPIResponse(error: $0) })
        }
        request.start()
        return request
    }

    /**
     Load all comments from the user

     - parameter completion: The closure that will be called when the comments are loaded or upon error
     */
    @discardableResult
    func comments(completion: @escaping (PaginatedAPIResponse<Comment>) -> Void) -> CancelableOperation? {
        return User.comments(from: identifier, completion: completion)
    }

    /**
     Load all comments from the user

     - parameter userIdentifier: The user identifier
     - parameter completion:     The closure that will be called when the comments are loaded or upon error
     */
    @discardableResult
    static func comments(from userIdentifier: Int, completion: @escaping (PaginatedAPIResponse<Comment>) -> Void) -> CancelableOperation? {
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(PaginatedAPIResponse(error: .needsLogin))
            return nil
        }
        let url = BaseURL.appendingPathComponent("\(userIdentifier)/comments")
        let parameters = ["linked_partitioning": "true"]
        let headers = ["Authorization" : "OAuth \(oauthToken)"]
        let parse = { (JSON: JSONObject) -> Result<[Comment], SoundcloudError> in
            guard let comments = JSON.flatMap(transform: { Comment(JSON: $0) }) else {
                return .failure(.parsing)
            }
            return .success(comments)
        }

        let request = Request(url: url, method: .get, parameters: parameters, headers:  headers, parse: { JSON -> Result<PaginatedAPIResponse<Comment>, SoundcloudError> in
            return .success(PaginatedAPIResponse(JSON: JSON, parse: parse))
        }) { result in
            completion(result.recover { PaginatedAPIResponse(error: $0) })
        }
        request.start()
        return request
    }

    /**
     Loads favorited tracks of the user

     - parameter completion: The closure that will be called when tracks are loaded or upon error
     */
    @discardableResult
    func favorites(completion: @escaping (PaginatedAPIResponse<Track>) -> Void) -> CancelableOperation? {
        return User.favorites(from: identifier, completion: completion)
    }

    /**
     Loads favorited tracks of the user

     - parameter userIdentifier: The user identifier
     - parameter completion:     The closure that will be called when tracks are loaded or upon error
     */
    @discardableResult
    static func favorites(from userIdentifier: Int, completion: @escaping (PaginatedAPIResponse<Track>) -> Void) -> CancelableOperation? {
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(PaginatedAPIResponse(error: .needsLogin))
            return nil
        }
        let url = BaseURL.appendingPathComponent("\(userIdentifier)/likes/tracks")
        let parameters = ["linked_partitioning": "true"]

        let parse = { (JSON: JSONObject) -> Result<[Track], SoundcloudError> in
            guard let tracks = JSON.flatMap(transform: { Track(JSON: $0) }) else {
                return .failure(.parsing)
            }
            return .success(tracks)
        }
        let headers = ["Authorization" : "OAuth \(oauthToken)"]

        let request = Request(url: url, method: .get, parameters: parameters, headers: headers, parse: { JSON -> Result<PaginatedAPIResponse<Track>, SoundcloudError> in
            return .success(PaginatedAPIResponse(JSON: JSON, parse: parse))
        }) { result in
            completion(result.recover { PaginatedAPIResponse(error: $0) })
        }
        request.start()
        return request
    }

    /**
     Loads followers of the user

     - parameter completion: The closure that will be called when followers are loaded or upon error
     */
    @discardableResult
    func followers(completion: @escaping (PaginatedAPIResponse<User>) -> Void) -> CancelableOperation? {
        return User.followers(from: identifier, completion: completion)
    }

    /**
     Loads followers of the user

     - parameter userIdentifier: The user identifier
     - parameter completion: The closure that will be called when followers are loaded or upon error
     */
    @discardableResult
    static func followers(from userIdentifier: Int, completion: @escaping (PaginatedAPIResponse<User>) -> Void) -> CancelableOperation? {

        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(PaginatedAPIResponse(error: .needsLogin))
            return nil
        }
        
        let url = BaseURL.appendingPathComponent("\(userIdentifier)/followers")
        
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
     Loads followed users of the user

     - parameter completion: The closure that will be called when followed users are loaded or upon error
     */
    @discardableResult
    func followings(completion: @escaping (PaginatedAPIResponse<User>) -> Void) -> CancelableOperation? {
        return User.followings(from: identifier, completion: completion)
    }

    /**
     Loads followed users of the user

     - parameter userIdentifier: The user identifier
     - parameter completion: The closure that will be called when followed users are loaded or upon error
     */
    @discardableResult
    static func followings(from userIdentifier: Int, completion: @escaping (PaginatedAPIResponse<User>) -> Void) -> CancelableOperation? {
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(PaginatedAPIResponse(error: .needsLogin))
            return nil
        }
        let url = BaseURL.appendingPathComponent("\(userIdentifier)/followings")
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
     Follow the given user.

     **This method requires a Session.**

     - parameter userIdentifier: The identifier of the user to follow
     - parameter completion:     The closure that will be called when the user has been followed or upon error
     */
    @discardableResult
    @available(tvOS, unavailable)
    func follow(userIdentifier: Int, completion: @escaping (SimpleAPIResponse<Bool>) -> Void) -> CancelableOperation? {
        #if !os(tvOS)
            return User.changeFollowStatus(follow: true, userIdentifier: userIdentifier, completion: completion)
        #else
            return nil
        #endif
    }

    /**
     Follow the given user.

     **This method requires a Session.**

     - parameter userIdentifier: The identifier of the user to follow
     - parameter completion:     The closure that will be called when the user has been followed or upon error
     */
    @discardableResult
    @available(tvOS, unavailable)
    static func follow(userIdentifier: Int, completion: @escaping (SimpleAPIResponse<Bool>) -> Void) -> CancelableOperation? {
        #if !os(tvOS)
            return User.changeFollowStatus(follow: true, userIdentifier: userIdentifier, completion: completion)
        #else
            return nil
        #endif
    }

    /**
     Unfollow the given user.

     **This method requires a Session.**

     - parameter userIdentifier: The identifier of the user to unfollow
     - parameter completion:     The closure that will be called when the user has been unfollowed or upon error
     */
    @discardableResult
    @available(tvOS, unavailable)
    func unfollow(userIdentifier: Int, completion: @escaping (SimpleAPIResponse<Bool>) -> Void) -> CancelableOperation? {
        #if !os(tvOS)
            return User.changeFollowStatus(follow: false, userIdentifier: userIdentifier, completion: completion)
        #else
            return nil
        #endif
    }

    /**
     Unfollow the given user.

     **This method requires a Session.**

     - parameter userIdentifier: The identifier of the user to unfollow
     - parameter completion:     The closure that will be called when the user has been unfollowed or upon error
     */
    @discardableResult
    @available(tvOS, unavailable)
    static func unfollow(userIdentifier: Int, completion: @escaping (SimpleAPIResponse<Bool>) -> Void) -> CancelableOperation? {
        #if !os(tvOS)
            return User.changeFollowStatus(follow: false, userIdentifier: userIdentifier, completion: completion)
        #else
            return nil
        #endif
    }

    @available(tvOS, unavailable)
    private static func changeFollowStatus(follow: Bool, userIdentifier: Int, completion: @escaping (SimpleAPIResponse<Bool>) -> Void) -> CancelableOperation? {
#if !os(tvOS)
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(SimpleAPIResponse(error: .needsLogin))
            return nil
        }
        let url = BaseURL
            .deletingLastPathComponent()
            .appendingPathComponent("me/followings/\(userIdentifier)")
        
        let headers = ["Authorization" : "OAuth \(oauthToken)"]
        
        let request = Request(url: url, method: follow ? .put : .delete, parameters: nil, headers: headers, parse: { _ in
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
     Loads user's playlists

     - parameter completion: The closure that will be called when playlists has been loaded or upon error
     */
    @discardableResult
    func playlists(completion: @escaping (PaginatedAPIResponse<Playlist>) -> Void) -> CancelableOperation? {
        return User.playlists(from: identifier, completion: completion)
    }

    /**
     Loads user's playlists

     - parameter userIdentifier: The identifier of the user to unfollow
     - parameter completion: The closure that will be called when playlists has been loaded or upon error
     */
    @discardableResult
    static func playlists(from userIdentifier: Int, completion: @escaping (PaginatedAPIResponse<Playlist>) -> Void) -> CancelableOperation? {
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(PaginatedAPIResponse(error: .needsLogin))
            return nil
        }
        let url = BaseURL.appendingPathComponent("\(userIdentifier)/playlists")
        let parameters = ["linked_partitioning": "true"]
        let headers = ["Authorization" : "OAuth \(oauthToken)"]

        let parse = { (JSON: JSONObject) -> Result<[Playlist], SoundcloudError> in
            guard let playlists = JSON.flatMap(transform: { Playlist(JSON: $0) }) else {
                return .failure(.parsing)
            }
            return .success(playlists)
        }

        let request = Request(url: url, method: .get, parameters: parameters, headers: headers, parse: { JSON -> Result<PaginatedAPIResponse<Playlist>, SoundcloudError> in
            return .success(PaginatedAPIResponse(JSON: JSON, parse: parse))
        }) { result in
            completion(result.recover { PaginatedAPIResponse(error: $0) })
        }
        request.start()
        return request
    }
}
