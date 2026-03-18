import Foundation
import ShazamKit
@preconcurrency import AVFoundation

// MARK: - Shazam Service
class ShazamService: NSObject, SHSessionDelegate {
    static let shared = ShazamService()
    private var matchContinuation: CheckedContinuation<ShazamTrack, Error>?
    private var session: SHSession?
    
    func identifyTrack(from fileURL: URL) async throws -> ShazamTrack {
        _ = fileURL.startAccessingSecurityScopedResource()
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let asset = AVURLAsset(url: fileURL)
                    let signature = try await SHSignatureGenerator.signature(from: asset)
                    
                    DispatchQueue.main.async {
                        self.matchContinuation = continuation
                        self.session = SHSession()
                        self.session?.delegate = self
                        self.session?.match(signature)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func session(_ session: SHSession, didFind match: SHMatch) {
        let mediaItem = match.mediaItems.first
        let shazamTrack = ShazamTrack(
            title: mediaItem?.title ?? "Unknown",
            artist: mediaItem?.artist ?? "Unknown",
            album: mediaItem?.subtitle,
            isrc: mediaItem?.isrc,
            artwork: mediaItem?.artworkURL
        )
        matchContinuation?.resume(returning: shazamTrack)
        matchContinuation = nil
        self.session = nil
    }
    
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        let nsError = NSError(domain: "ShazamService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Track not found in Shazam database"])
        matchContinuation?.resume(throwing: nsError)
        matchContinuation = nil
        self.session = nil
    }
}

// MARK: - MusicBrainz Service
class MusicBrainzService {
    static let shared = MusicBrainzService()
    private let baseURL = "https://musicbrainz.org/ws/2"
    
    func fetchRecording(byISRC isrc: String) async throws -> MusicBrainzRecording.Recording {
        let urlString = "\(baseURL)/recording?query=isrc:\(isrc)&fmt=json"
        guard let encodedURL = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURL) else {
            throw NSError(domain: "MusicBrainzService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.setValue("TrackTagger/1.0 (macOS metadata enrichment tool)", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "MusicBrainzService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch from MusicBrainz"])
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(MusicBrainzRecording.self, from: data)
        
        guard let recording = result.recordings?.first else {
            throw NSError(domain: "MusicBrainzService", code: -3, userInfo: [NSLocalizedDescriptionKey: "No recording found for ISRC"])
        }
        
        return recording
    }
}

// MARK: - Cover Art Archive Service
class CoverArtService {
    static let shared = CoverArtService()
    private let baseURL = "https://coverartarchive.org"
    
    func fetchCoverArt(forReleaseID releaseID: String) async throws -> URL? {
        let urlString = "\(baseURL)/release/\(releaseID)"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "CoverArtService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(CoverArtArchiveResponse.self, from: data)
        
        if let frontCover = result.images.first(where: { $0.front }) {
            return URL(string: frontCover.image)
        }
        
        return result.images.first.flatMap { URL(string: $0.image) }
    }
    
    func downloadArtwork(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "CoverArtService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to download artwork"])
        }
        
        return data
    }
}
