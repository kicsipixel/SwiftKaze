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
///     in: projectDirectory
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

  /// Runs Tailwind CSS to compile stylesheets.
  /// - Parameters:
  ///   - input: The input CSS file path.
  ///   - output: The output CSS file path.
  ///   - directory: The working directory for Tailwind.
  public func run(
    input: URL,
    output: URL,
    in directory: URL
  ) async throws {
    let executableURL = try await downloader.download(version: version, directory: self.directory)

    let arguments: [String] = [
      "--input", input.path,
      "--output", output.path,
    ]

    try await executor.run(executableURL: executableURL, workingDirectory: directory, arguments: arguments)
  }

  /// Watches for file changes and recompiles Tailwind CSS automatically.
  ///
  /// This method runs indefinitely until the enclosing `Task` is cancelled.
  ///
  /// Example usage:
  /// ```swift
  /// let watchTask = Task {
  ///     try await kaze.watch(
  ///         input: inputCSSURL,
  ///         output: outputCSSURL,
  ///         in: projectDirectory
  ///     )
  /// }
  /// // Later, to stop watching:
  /// watchTask.cancel()
  /// ```
  ///
  /// - Parameters:
  ///   - input: The input CSS file path.
  ///   - output: The output CSS file path.
  ///   - directory: The working directory for Tailwind.
  public func watch(
    input: URL,
    output: URL,
    in directory: URL
  ) async throws {
    let executableURL = try await downloader.download(version: version, directory: self.directory)

    let arguments: [String] = [
      "--input", input.path,
      "--output", output.path,
      "--watch",
    ]

    try await executor.runUntilCancelled(executableURL: executableURL, workingDirectory: directory, arguments: arguments)
  }
}
