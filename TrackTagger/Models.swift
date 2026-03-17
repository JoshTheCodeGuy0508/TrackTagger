import Foundation

// MARK: - Track Metadata from ShazamKit
struct ShazamTrack {
    let title: String
    let artist: String
    let album: String?
    let isrc: String?
    let artwork: URL?
}

// MARK: - MusicBrainz Recording Response
struct MusicBrainzRecording: Codable {
    let recordings: [Recording]?
    
    struct Recording: Codable {
        let id: String
        let title: String
        let artistCredit: [ArtistCredit]?
        let releases: [Release]?
        
        enum CodingKeys: String, CodingKey {
            case id, title
            case artistCredit = "artist-credit"
            case releases
        }
    }
    
    struct ArtistCredit: Codable {
        let artist: Artist?
        
        struct Artist: Codable {
            let name: String
        }
    }
    
    struct Release: Codable {
        let id: String
        let title: String
        let date: String?
        let media: [Media]?
        
        struct Media: Codable {
            let position: Int?
        }
    }
}

// MARK: - Cover Art Archive Response
struct CoverArtArchiveResponse: Codable {
    let images: [CoverArtImage]
    
    struct CoverArtImage: Codable {
        let id: String
        let types: [String]
        let front: Bool
        let back: Bool
        let edit: Int?
        let image: String
        let thumbnails: Thumbnails?
        
        struct Thumbnails: Codable {
            let small: String?
            let large: String?
        }
    }
}

// MARK: - Final Metadata to Write to File
struct AudioFileMetadata {
    let title: String
    let artist: String
    let album: String
    let albumArtist: String?
    let releaseDate: String?
    let trackNumber: Int?
    let artworkURL: URL?
    let artworkData: Data?
}
