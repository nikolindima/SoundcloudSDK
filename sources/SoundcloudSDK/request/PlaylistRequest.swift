//
//  PlaylistRequest.swift
//
//
//  Created by Kevin DELANNOY on 06/08/15.
//
//

import Foundation

public extension Playlist {
    static let BaseURL = URL(string: "https://api.soundcloud.com/playlists")!

    /**
    Load playlist with a specific identifier

    - parameter identifier:  The identifier of the playlist to load
    - parameter secretToken: The secret token to access the playlist or nil
    - parameter completion:  The closure that will be called when playlist is loaded or upon error
    */
    @discardableResult
    static func playlist(identifier: Int, secretToken: String? = nil, completion: @escaping (SimpleAPIResponse<Playlist>) -> Void) -> CancelableOperation? {
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(SimpleAPIResponse(error: .needsLogin))
            return nil
        }
        let url = BaseURL.appendingPathComponent("\(identifier)")

        var parameters: [String: String] = [:]
        if let secretToken = secretToken {
            parameters["secret_token"] = secretToken
        }
        let headers = ["Authorization" : "OAuth \(oauthToken)"]

        let request = Request(url: url, method: .get, parameters: parameters, headers: headers, parse: {
            if let playlist = Playlist(JSON: $0) {
                return .success(playlist)
            }
            return .failure(.parsing)
        }) { result in
            completion(SimpleAPIResponse(result: result))
        }
        request.start()
        return request
    }

    #if os(iOS) || os(OSX)
    /**
     Creates a playlist with a name and a specific sharing access

     - parameter name:          The name of the playlist
     - parameter sharingAccess: The required sharing access
     - parameter completion:    The closure that will be called when playlist is created or upon error
     */
    @discardableResult
    static func create(name: String, sharingAccess: SharingAccess, completion: @escaping (SimpleAPIResponse<Playlist>) -> Void) -> CancelableOperation? {
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(SimpleAPIResponse(error: .needsLogin))
            return nil
        }

        let url = BaseURL

        let parameters = [
            "playlist[title]": name,
            "playlist[sharing]": sharingAccess.rawValue]
        let headers = ["Authorization" : "OAuth \(oauthToken)"]

        let request = Request(url: url, method: .post, parameters: parameters, headers: headers, parse: {
            if let playlist = Playlist(JSON: $0) {
                return .success(playlist)
            }
            return .failure(.parsing)
        }) { result in
            completion(SimpleAPIResponse(result: result))
        }
        request.start()
        return request
    }

    @discardableResult
    func addTrack(with identifier: Int, completion: @escaping (SimpleAPIResponse<Playlist>) -> Void) -> CancelableOperation? {
        return addTracks(with: [identifier], completion: completion)
    }

    @discardableResult
    func addTracks(with identifiers: [Int], completion: @escaping (SimpleAPIResponse<Playlist>) -> Void) -> CancelableOperation? {
        return updateTracks(withNewTracklist: tracks.map { $0.identifier } + identifiers, completion: completion)
    }

    @discardableResult
    func removeTrack(with identifier: Int, completion: @escaping (SimpleAPIResponse<Playlist>) -> Void) -> CancelableOperation? {
        return removeTracks(with: [identifier], completion: completion)
    }

    @discardableResult
    func removeTracks(with identifiers: [Int], completion: @escaping (SimpleAPIResponse<Playlist>) -> Void) -> CancelableOperation? {
        return updateTracks(withNewTracklist: tracks
            .map { $0.identifier }
            .filter { !identifiers.contains($0) }, completion: completion)
    }

    private func updateTracks(withNewTracklist identifiers: [Int], completion: @escaping (SimpleAPIResponse<Playlist>) -> Void) -> CancelableOperation? {
        guard let oauthToken = SoundcloudClient.session?.accessToken else {
            completion(SimpleAPIResponse(error: .needsLogin))
            return nil
        }

        let url = Playlist.BaseURL
            .appendingPathComponent("\(identifier)")

        let parameters = [
            "playlist": [
                "tracks": identifiers.map { ["id": "\($0)"] }
            ]
        ]
        let headers = ["Authorization" : "OAuth \(oauthToken)", "Content-Type": "application/json"]
        
        guard let JSONEncoded = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            completion(SimpleAPIResponse(error: .parsing))
            return nil
        }

        let request = Request(url: url, method: .put, parameters: JSONEncoded, headers: headers, parse: {
            if let playlist = Playlist(JSON: $0) {
                return .success(playlist)
            }
            return .failure(.parsing)
        }) { result in
            completion(SimpleAPIResponse(result: result))
        }
        request.start()
        return request
    }
    #endif
}
