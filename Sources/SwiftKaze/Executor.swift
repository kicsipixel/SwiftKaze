import Foundation
import Logging

/// Executes the Tailwind CSS binary.
public struct Executor: Sendable {
  private let logger: Logger

  public init(logger: Logger = Logger(label: "io.swiftkaze.Executor")) {
    self.logger = logger
  }

  /// Runs the Tailwind CSS binary with the specified arguments.
  /// - Parameters:
  ///   - executableURL: Path to the Tailwind CSS binary.
  ///   - workingDirectory: Directory to run the command in.
  ///   - arguments: Command-line arguments to pass.
  public func run(
    executableURL: URL,
    workingDirectory: URL,
    arguments: [String]
  ) async throws {
    let allArguments = [executableURL.path] + arguments
    logger.info("Running: \(allArguments.joined(separator: " "))")

    let process = Process()
    process.executableURL = executableURL
    process.arguments = arguments
    process.currentDirectoryURL = workingDirectory

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    do {
      try process.run()
    }
    catch {
      throw SwiftKazeError.executionFailed(error.localizedDescription)
    }

    // Read output in background tasks (works on both macOS and Linux)
    let logger = self.logger

    async let stdoutTask: Void = Task.detached {
      let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
      if let output = String(data: data, encoding: .utf8), !output.isEmpty {
        logger.info("\(output.trimmingCharacters(in: .whitespacesAndNewlines))")
      }
    }.value

    async let stderrTask: Void = Task.detached {
      let data = stderrPipe.fileHandleForReading.readDataToEndOfFile()
      if let output = String(data: data, encoding: .utf8), !output.isEmpty {
        // Use info level since Tailwind sends useful warnings to stderr
        logger.info("\(output.trimmingCharacters(in: .whitespacesAndNewlines))")
      }
    }.value

    // Wait for process to complete
    process.waitUntilExit()

    // Wait for output readers to finish
    await stdoutTask
    await stderrTask

    guard process.terminationStatus == 0 else {
      throw SwiftKazeError.executionFailed("Process exited with status \(process.terminationStatus)")
    }
  }

  /// Runs the Tailwind CSS binary as a long-lived process that can be cancelled via structured concurrency.
  ///
  /// When the enclosing `Task` is cancelled, the process is terminated gracefully.
  /// Unlike `run()`, this method does not throw when the process exits due to cancellation.
  ///
  /// - Parameters:
  ///   - executableURL: Path to the Tailwind CSS binary.
  ///   - workingDirectory: Directory to run the command in.
  ///   - arguments: Command-line arguments to pass.
  public func runUntilCancelled(
    executableURL: URL,
    workingDirectory: URL,
    arguments: [String]
  ) async throws {
    let allArguments = [executableURL.path] + arguments
    logger.info("Running: \(allArguments.joined(separator: " "))")

    let process = Process()
    process.executableURL = executableURL
    process.arguments = arguments
    process.currentDirectoryURL = workingDirectory

    // Tailwind's --watch mode reads from stdin and exits on EOF,
    // so provide a pipe that stays open for the process's lifetime.
    let stdinPipe = Pipe()
    process.standardInput = stdinPipe

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    do {
      try process.run()
    }
    catch {
      throw SwiftKazeError.executionFailed(error.localizedDescription)
    }

    let logger = self.logger

    try await withTaskCancellationHandler {
      async let stdoutTask: Void = Task.detached {
        let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8), !output.isEmpty {
          logger.info("\(output.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
      }.value

      async let stderrTask: Void = Task.detached {
        let data = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8), !output.isEmpty {
          logger.info("\(output.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
      }.value

      process.waitUntilExit()

      await stdoutTask
      await stderrTask

      // Only throw if the process exited with an error and was not cancelled
      if !Task.isCancelled && process.terminationStatus != 0 {
        throw SwiftKazeError.executionFailed("Process exited with status \(process.terminationStatus)")
      }
    } onCancel: {
      if process.isRunning {
        process.terminate()
      }
      // Close stdin pipe to unblock the process if it's reading from stdin
      try? stdinPipe.fileHandleForWriting.close()
    }
  }
}
