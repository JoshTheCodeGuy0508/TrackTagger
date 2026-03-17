TrackTagger
A powerful macOS application that automatically enriches your music metadata using intelligent identification and comprehensive music databases.
Overview
TrackTagger streamlines the process of organizing your music library by automatically identifying audio tracks and populating their metadata with accurate information including title, artist, album, release date, and high-quality album artwork.
Key Features

🎵 Smart Track Identification - Uses Apple's ShazamKit to identify audio files with precision
📚 Comprehensive Metadata - Fetches detailed metadata from MusicBrainz, the open music encyclopedia
🎨 High-Quality Artwork - Retrieves album artwork from the Cover Art Archive
⚡ Batch Processing - Process multiple files at once, perfect for large music libraries
🔒 Non-Destructive - Original audio quality is preserved; only metadata is modified
🎯 Multiple Format Support - Works with MP3, M4A, and other common audio formats
📦 Self-Contained - No external dependencies required; FFmpeg is bundled within the app

How It Works
TrackTagger uses a streamlined three-step process:

Identification - ShazamKit analyzes your audio file and identifies the track, returning an ISRC (International Standard Recording Code)
Enrichment - MusicBrainz API is queried using the ISRC to fetch comprehensive metadata (title, artist, album, release date)
Enhancement - Cover Art Archive provides high-quality album artwork, which is embedded directly into the audio file

The entire process is automated and happens in seconds per file.

Installation

Download the latest release from the Releases page
Mount the .dmg file and drag TrackTagger to your Applications folder
Launch TrackTagger from Applications
Grant any required permissions when prompted

Usage
Basic Workflow

Select Files - Click "Choose Audio Files" to select the tracks you want to enrich
Add More Files - Optionally add additional files to process in batch
Process - Click "Process Files" and watch as TrackTagger works through your library
Results - View the results for each file showing success status and metadata details

Tips for Best Results

High-Quality Source Audio - ShazamKit works best with audio that has minimal background noise
Known Releases - Tracks that are officially released perform better (ISRC lookups are more reliable)
Batch Processing - Process multiple files at once to save time
Verify Results - While rare, you can verify results in your music player and manually adjust if needed


System Architecture
Core Components

ShazamKit - Apple's native framework for audio identification
MusicBrainz Service - Fetches detailed metadata using ISRC codes
Cover Art Archive Service - Retrieves high-quality album artwork
FFmpeg - Handles metadata writing to audio files while preserving quality
SwiftUI - Modern, responsive user interface

Data Flow
Audio File → ShazamKit → ISRC Code
         ↓
    MusicBrainz API → Metadata + Release ID
         ↓
  Cover Art Archive → Artwork
         ↓
    FFmpeg Writer → Enhanced Audio File
Technical Details
Metadata Written

Title - Track name
Artist - Primary artist
Album - Album name
Album Artist - Album's primary artist
Release Date - Original release date
Artwork - Embedded album cover (highest quality available)

Supported Formats
FormatID3 TagsMP4 TagsArtworkStatusMP3✅N/A✅SupportedM4AN/A✅✅SupportedFLAC✅N/A✅PlannedWAVLimitedN/ALimitedPlanned
Performance

Identification: ~2-5 seconds per file (depends on network)
Metadata Fetch: ~1-2 seconds per file
Artwork Download: ~0.5-2 seconds per file (depends on image size)
File Writing: ~1-3 seconds per file (depends on file size and network)

Total Time per File: ~5-15 seconds
Privacy & Data
TrackTagger respects your privacy:

All audio is processed locally using ShazamKit
Audio files are never uploaded to external servers (ShazamKit uses fingerprinting, not full audio transfer)
Only the generated fingerprint is sent to Shazam's servers
Metadata is fetched from open, public databases (MusicBrainz, Cover Art Archive)
No user data is collected or stored

Troubleshooting
"Track not found in Shazam database"

The audio might be too obscure or not officially released
Try with a cleaner, higher-quality version of the file
Ensure audio is not heavily distorted

"No ISRC found for track"

ShazamKit couldn't identify the track
This is most common with unreleased, amateur, or heavily modified versions
Try a different audio file or official release

"No release found in MusicBrainz"

The ISRC exists in Shazam but not in MusicBrainz
This is rare for officially released music
Consider manually adding the track to MusicBrainz (community-driven)

"FFmpeg binary not found"

The app bundle may be corrupted
Try reinstalling from the official release
Report this issue on GitHub

