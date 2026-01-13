import Foundation
import Logging

/// SwiftKaze provides a Swift interface to download and run the Tailwind CSS CLI.
///
/// Example usage:
/// ```swift
/// let kaze = SwiftKaze(version: .latest)
/// try await kaze.run(
///     input: inputCSSURL,
///     output: outputCSSURL,
///     in: projectDirectory,
///     options: .content("views/**/*.html"), .minify
/// )
/// ```
public final class SwiftKaze: Sendable {
  private let version: TailwindVersion
  private let directory: URL
  private let downloader: Downloader
  private let executor: Executor

  /// Creates a new SwiftKaze instance.
  /// - Parameters:
  ///   - version: The Tailwind CSS version to use. Defaults to `.latest`.
  ///   - directory: Directory to store downloaded binaries. Defaults to system temp directory.
  public init(
    version: TailwindVersion = .latest,
    directory: URL? = nil
  ) {
    self.version = version
    self.directory = directory ?? Downloader.defaultDirectory
    self.downloader = Downloader()
    self.executor = Executor()
  }

  /// Creates a `tailwind.config.js` configuration file.
  ///
  /// - Note: This method is only supported for Tailwind CSS v3.x. Tailwind v4 no longer
  ///   requires a configuration file and uses CSS-based configuration instead.
  ///
  /// - Parameters:
  ///   - directory: The directory to create the config file in.
  ///   - options: Configuration options for initialization.
  @available(*, deprecated, message: "Tailwind CSS v4 no longer uses init command. Use CSS-based configuration instead.")
  public func initialize(
    in directory: URL,
    options: InitializeOption...
  ) async throws {
    let executableURL = try await downloader.download(version: version, directory: self.directory)
    var arguments = ["init"]
    arguments.append(contentsOf: Set(options).toArguments())
    try await executor.run(executableURL: executableURL, workingDirectory: directory, arguments: arguments)
  }

  /// Runs Tailwind CSS to compile stylesheets.
  /// - Parameters:
  ///   - input: The input CSS file path.
  ///   - output: The output CSS file path.
  ///   - directory: The working directory for Tailwind.
  ///   - options: Run options to customize behavior.
  public func run(
    input: URL,
    output: URL,
    in directory: URL,
    options: RunOption...
  ) async throws {
    let executableURL = try await downloader.download(version: version, directory: self.directory)

    var arguments: [String] = [
      "--input", input.path,
      "--output", output.path,
    ]

    let optionSet = Set(options)
    arguments.append(contentsOf: optionSet.toArguments())

    try await executor.run(executableURL: executableURL, workingDirectory: directory, arguments: arguments)
  }
}

// MARK: - Initialize Options

extension SwiftKaze {
  /// Options for the `init` command.
  public enum InitializeOption: Hashable, Sendable {
    /// Initialize configuration file as ESM.
    case esm

    /// Initialize configuration file as TypeScript.
    case ts

    /// Initialize a postcss.config.js file.
    case postcss

    /// Include default values for all options in the generated config.
    case full

    var arguments: [String] {
      switch self {
      case .esm: return ["--esm"]
      case .ts: return ["--ts"]
      case .postcss: return ["--postcss"]
      case .full: return ["--full"]
      }
    }
  }
}

// MARK: - Run Options

extension SwiftKaze {
  /// Options for running Tailwind CSS compilation.
  ///
  /// Note: Tailwind CSS v4 has a simplified CLI. Some options from v3 are no longer available.
  public enum RunOption: Hashable, Sendable {
    /// Watch for file changes and rebuild automatically.
    case watch

    /// Watch mode that keeps running even when stdin closes (use `--watch=always`).
    case watchAlways

    /// Minify the output CSS.
    case minify

    /// Optimize the output without minifying.
    case optimize

    /// Generate a source map.
    case sourceMap

    /// Set the current working directory.
    case cwd(URL)

    var arguments: [String] {
      switch self {
      case .watch:
        return ["--watch"]
      case .watchAlways:
        return ["--watch=always"]
      case .minify:
        return ["--minify"]
      case .optimize:
        return ["--optimize"]
      case .sourceMap:
        return ["--map"]
      case .cwd(let url):
        return ["--cwd", url.path]
      }
    }
  }
}

// MARK: - Option Set Extensions

extension Set where Element == SwiftKaze.InitializeOption {
  func toArguments() -> [String] {
    flatMap(\.arguments)
  }
}

extension Set where Element == SwiftKaze.RunOption {
  func toArguments() -> [String] {
    flatMap(\.arguments)
  }
}
