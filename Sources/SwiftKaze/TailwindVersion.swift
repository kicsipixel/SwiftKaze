import Foundation

/// Represents the version of Tailwind CSS to download and use.
public enum TailwindVersion: Sendable, Hashable {
  /// Uses the latest available version from GitHub releases.
  case latest

  /// Uses a specific fixed version (e.g., "3.4.1" or "v3.4.1").
  case fixed(String)

  /// Returns the version string formatted for GitHub releases (prefixed with "v").
  var releaseTag: String? {
    switch self {
    case .latest:
      return nil
    case .fixed(let version):
      return version.hasPrefix("v") ? version : "v\(version)"
    }
  }
}
