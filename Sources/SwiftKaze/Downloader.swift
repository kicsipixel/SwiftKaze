import Foundation
import Logging

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Downloads Tailwind CSS binaries from GitHub releases.
public actor Downloader {
  private let architectureDetector: ArchitectureDetector
  private let logger: Logger
  private let session: URLSession

  /// GitHub releases base URL for Tailwind CSS.
  private static let releasesBaseURL = "https://github.com/tailwindlabs/tailwindcss/releases/download"

  /// GitHub API URL for fetching the latest release.
  private static let latestReleaseURL = "https://api.github.com/repos/tailwindlabs/tailwindcss/releases/latest"

  /// Default directory for storing downloaded binaries.
  public static var defaultDirectory: URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("SwiftKaze", isDirectory: true)
  }

  public init(
    architectureDetector: ArchitectureDetector = ArchitectureDetector(),
    logger: Logger = Logger(label: "io.swiftkaze.Downloader")
  ) {
    self.architectureDetector = architectureDetector
    self.logger = logger
    self.session = URLSession.shared
  }

  /// Downloads the Tailwind CSS binary for the specified version.
  /// - Parameters:
  ///   - version: The version to download.
  ///   - directory: The directory to store the binary. Defaults to temp directory.
  /// - Returns: The path to the downloaded binary.
  public func download(
    version: TailwindVersion,
    directory: URL = Downloader.defaultDirectory
  ) async throws -> URL {
    guard let binaryName = architectureDetector.tailwindBinaryName() else {
      throw SwiftKazeError.unsupportedPlatform
    }

    let resolvedVersion = try await resolveVersion(version)
    let binaryPath =
      directory
      .appendingPathComponent(resolvedVersion, isDirectory: true)
      .appendingPathComponent(binaryName)

    // Return cached binary if it exists
    if FileManager.default.fileExists(atPath: binaryPath.path) {
      logger.debug("Using cached binary at \(binaryPath.path)")
      return binaryPath
    }

    // Ensure directory exists
    try createDirectoryIfNeeded(binaryPath.deletingLastPathComponent())

    // Download binary
    let downloadURL = URL(string: "\(Self.releasesBaseURL)/\(resolvedVersion)/\(binaryName)")!
    logger.info("Downloading Tailwind CSS \(resolvedVersion) from \(downloadURL)")

    let (tempURL, response) = try await session.download(from: downloadURL)

    guard let httpResponse = response as? HTTPURLResponse,
      (200...299).contains(httpResponse.statusCode)
    else {
      throw SwiftKazeError.downloadFailed("HTTP request failed")
    }

    // Move to final location
    try FileManager.default.moveItem(at: tempURL, to: binaryPath)

    // Make executable
    try makeExecutable(binaryPath)

    logger.info("Downloaded Tailwind CSS to \(binaryPath.path)")
    return binaryPath
  }

  /// Resolves the version to download.
  private func resolveVersion(_ version: TailwindVersion) async throws -> String {
    switch version {
    case .latest:
      return try await fetchLatestVersion()
    case .fixed(let v):
      return v.hasPrefix("v") ? v : "v\(v)"
    }
  }

  /// Fetches the latest version tag from GitHub API.
  private func fetchLatestVersion() async throws -> String {
    logger.debug("Fetching latest version from GitHub API")

    guard let url = URL(string: Self.latestReleaseURL) else {
      throw SwiftKazeError.versionFetchFailed
    }

    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("SwiftKaze", forHTTPHeaderField: "User-Agent")

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
      (200...299).contains(httpResponse.statusCode)
    else {
      throw SwiftKazeError.versionFetchFailed
    }

    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
      let tagName = json["tag_name"] as? String
    else {
      throw SwiftKazeError.versionFetchFailed
    }

    logger.debug("Latest version: \(tagName)")
    return tagName
  }

  /// Creates a directory if it doesn't exist.
  private func createDirectoryIfNeeded(_ url: URL) throws {
    if !FileManager.default.fileExists(atPath: url.path) {
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
  }

  /// Makes a file executable (chmod +x).
  private func makeExecutable(_ url: URL) throws {
    #if !os(Windows)
      let attributes: [FileAttributeKey: Any] = [.posixPermissions: 0o755]
      try FileManager.default.setAttributes(attributes, ofItemAtPath: url.path)
    #endif
  }
}
