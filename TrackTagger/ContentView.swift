import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selectedFiles: [URL] = []
    @State private var isProcessing = false
    @State private var processingStatus = ""
    @State private var results: [ProcessResult] = []
    @State private var showingFilePicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("TrackTagger")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Automatically enrich your music metadata using Shazam, MusicBrainz, and Cover Art Archive")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // File Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Selected Files")
                    .font(.headline)
                
                if selectedFiles.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No files selected")
                            .foregroundColor(.secondary)
                        Button(action: { showingFilePicker = true }) {
                            Text("Choose Audio Files")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(selectedFiles, id: \.self) { file in
                            HStack {
                                Image(systemName: "music.note")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(file.lastPathComponent)
                                        .lineLimit(1)
                                    Text(file.path)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Button(action: {
                                    selectedFiles.removeAll { $0 == file }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(8)
                            .background(Color.gray.opacity(0.08))
                            .cornerRadius(6)
                        }
                        
                        Button(action: { showingFilePicker = true }) {
                            Text("Add More Files")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            // Processing Section
            if !results.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Results")
                        .font(.headline)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(results, id: \.id) { result in
                                ResultRow(result: result)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
            
            // Status
            if !processingStatus.isEmpty {
                HStack(spacing: 12) {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(processingStatus)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
            
            // Process Button
            if !selectedFiles.isEmpty {
                Button(action: processFiles) {
                    if isProcessing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Processing...")
                        }
                    } else {
                        Text("Process Files")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isProcessing ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(isProcessing)
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [
                UTType(filenameExtension: "mp3") ?? .audio,
                UTType(filenameExtension: "m4a") ?? .audio,
            ],
            allowsMultipleSelection: true,
            onCompletion: { result in
                if case .success(let urls) = result {
                    selectedFiles.append(contentsOf: urls)
                }
            }
        )
    }
    
    private func processFiles() {
        isProcessing = true
        results = []
        
        Task {
            for (index, fileURL) in selectedFiles.enumerated() {
                processingStatus = "Processing \(index + 1) of \(selectedFiles.count)..."
                
                do {
                    // Step 1: Identify with Shazam
                    processingStatus = "Identifying: \(fileURL.lastPathComponent)..."
                    let shazamTrack = try await ShazamService.shared.identifyTrack(from: fileURL)
                    
                    guard let isrc = shazamTrack.isrc else {
                        throw NSError(domain: "ContentView", code: -1, userInfo: [NSLocalizedDescriptionKey: "No ISRC found for track"])
                    }
                    
                    // Step 2: Fetch metadata from MusicBrainz
                    processingStatus = "Fetching metadata from MusicBrainz..."
                    let recording = try await MusicBrainzService.shared.fetchRecording(byISRC: isrc)
                    
                    // Step 3: Get release ID for artwork
                    guard let releaseID = recording.releases?.first?.id else {
                        throw NSError(domain: "ContentView", code: -2, userInfo: [NSLocalizedDescriptionKey: "No release found"])
                    }
                    
                    // Step 4: Fetch artwork
                    processingStatus = "Fetching album artwork..."
                    var artworkData: Data?
                    if let coverArtURL = try await CoverArtService.shared.fetchCoverArt(forReleaseID: releaseID) {
                        artworkData = try await CoverArtService.shared.downloadArtwork(from: coverArtURL)
                    }
                    
                    // Step 5: Build metadata
                    let releaseDate = recording.releases?.first?.date
                    let artist = recording.artistCredit?.first?.artist?.name ?? shazamTrack.artist
                    
                    let metadata = AudioFileMetadata(
                        title: recording.title,
                        artist: artist,
                        album: recording.releases?.first?.title ?? shazamTrack.album ?? "Unknown",
                        albumArtist: artist,
                        releaseDate: releaseDate,
                        trackNumber: nil,
                        artworkURL: nil,
                        artworkData: artworkData
                    )
                    
                    // Step 6: Write metadata to file
                    processingStatus = "Writing metadata to file..."
                    try await FFmpegMetadataWriter.shared.writeMetadata(metadata, to: fileURL)
                    
                    // Success
                    results.append(ProcessResult(
                        id: UUID(),
                        fileName: fileURL.lastPathComponent,
                        status: .success,
                        message: "\(recording.title) by \(artist)"
                    ))
                    
                } catch {
                    results.append(ProcessResult(
                        id: UUID(),
                        fileName: fileURL.lastPathComponent,
                        status: .error,
                        message: error.localizedDescription
                    ))
                }
            }
            
            isProcessing = false
            processingStatus = "Done!"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                processingStatus = ""
            }
        }
    }
}

struct ResultRow: View {
    let result: ProcessResult
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.status == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.status == .success ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result.fileName)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(result.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(6)
    }
}

struct ProcessResult {
    let id: UUID
    let fileName: String
    let status: ProcessStatus
    let message: String
}

enum ProcessStatus {
    case success
    case error
}

#Preview {
    ContentView()
}
