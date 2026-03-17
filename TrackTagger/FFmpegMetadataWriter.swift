import Foundation

class FFmpegMetadataWriter {
    static let shared = FFmpegMetadataWriter()
    
    private func getFFmpegPath() throws -> URL {
        guard let bundlePath = Bundle.main.resourcePath else {
            throw NSError(domain: "FFmpegMetadataWriter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find app bundle"])
        }
        
        let ffmpegURL = URL(fileURLWithPath: bundlePath).appendingPathComponent("ffmpeg")
        
        guard FileManager.default.fileExists(atPath: ffmpegURL.path) else {
            throw NSError(domain: "FFmpegMetadataWriter", code: -2, userInfo: [NSLocalizedDescriptionKey: "FFmpeg binary not found in app bundle"])
        }
        
        return ffmpegURL
    }
    
    func writeMetadata(_ metadata: AudioFileMetadata, to fileURL: URL) async throws {
        let ffmpegURL = try getFFmpegPath()
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileName = UUID().uuidString + "." + fileURL.pathExtension
        let tempFileURL = tempDirectory.appendingPathComponent(tempFileName)
        
        var arguments: [String] = [
            "-i", fileURL.path,
            "-c", "copy",
            "-metadata", "title=\(metadata.title)",
            "-metadata", "artist=\(metadata.artist)",
            "-metadata", "album=\(metadata.album)",
        ]
        
        if let albumArtist = metadata.albumArtist {
            arguments.append(contentsOf: ["-metadata", "album_artist=\(albumArtist)"])
        }
        
        if let releaseDate = metadata.releaseDate {
            arguments.append(contentsOf: ["-metadata", "date=\(releaseDate)"])
        }
        
        if let trackNumber = metadata.trackNumber {
            arguments.append(contentsOf: ["-metadata", "track=\(trackNumber)"])
        }
        
        if let artworkData = metadata.artworkData {
            let artworkPath = tempDirectory.appendingPathComponent("artwork_\(UUID().uuidString).jpg")
            try artworkData.write(to: artworkPath)
            arguments.append(contentsOf: ["-i", artworkPath.path])
            arguments.append(contentsOf: ["-map", "0", "-map", "1", "-c", "copy", "-disposition:v:1", "attached_pic"])
        }
        
        arguments.append("-y")
        arguments.append(tempFileURL.path)
        
        try await executeFFmpeg(ffmpegURL: ffmpegURL, arguments: arguments)
        
        try FileManager.default.removeItem(at: fileURL)
        try FileManager.default.moveItem(at: tempFileURL, to: fileURL)
        
        let tempFiles = (try? FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)) ?? []
        for file in tempFiles {
            let filename = file.lastPathComponent
            if filename.hasPrefix("artwork_") && filename.hasSuffix(".jpg") {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
    
    private func executeFFmpeg(ffmpegURL: URL, arguments: [String]) async throws {
        let process = Process()
        process.executableURL = ffmpegURL
        process.arguments = arguments
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                process.waitUntilExit()
                continuation.resume()
            }
        }
    }
}
