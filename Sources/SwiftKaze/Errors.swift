import Foundation

/// Errors that can occur when using SwiftKaze.
public enum SwiftKazeError: Error, Sendable, LocalizedError {
  /// The current platform (OS/architecture combination) is not supported.
  case unsupportedPlatform

  /// Failed to download the Tailwind binary.
  case downloadFailed(String)

  /// The downloaded file's checksum doesn't match the expected value.
  case checksumMismatch

  /// Failed to execute the Tailwind binary.
  case executionFailed(String)

  /// Failed to fetch the latest version from GitHub.
  case versionFetchFailed

  /// Failed to make the downloaded binary executable.
  case permissionError(String)

  public var errorDescription: String? {
    switch self {
    case .unsupportedPlatform:
      return "The current platform is not supported by Tailwind CSS."
    case .downloadFailed(let message):
      return "Failed to download Tailwind CSS: \(message)"
    case .checksumMismatch:
      return "The downloaded file's checksum doesn't match. The file may be corrupted."
    case .executionFailed(let message):
      return "Failed to execute Tailwind CSS: \(message)"
    case .versionFetchFailed:
      return "Failed to fetch the latest Tailwind CSS version from GitHub."
    case .permissionError(let message):
      return "Permission error: \(message)"
    }
  }
}
