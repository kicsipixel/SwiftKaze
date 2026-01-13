import Foundation

/// CPU architecture types supported by Tailwind CSS releases.
public enum CPUArchitecture: String, Sendable, Hashable {
  case aarch64 = "aarch64"
  case arm64 = "arm64"
  case armv7 = "armv7"
  case x86_64 = "x86_64"

  /// The architecture name used in Tailwind CSS binary filenames.
  var tailwindArchName: String {
    switch self {
    case .arm64, .aarch64:
      return "arm64"
    case .armv7:
      return "armv7"
    case .x86_64:
      return "x64"
    }
  }
}

/// Operating system types supported by Tailwind CSS releases.
public enum OperatingSystem: String, Sendable, Hashable {
  case macOS
  case linux
  case windows

  /// The OS name used in Tailwind CSS binary filenames.
  var tailwindOSName: String {
    switch self {
    case .macOS:
      return "macos"
    case .linux:
      return "linux"
    case .windows:
      return "windows"
    }
  }

  /// File extension for executables on this OS.
  var executableExtension: String {
    switch self {
    case .windows:
      return ".exe"
    case .macOS, .linux:
      return ""
    }
  }

  /// Detects the current operating system at compile time.
  static var current: OperatingSystem {
    #if os(Windows)
      return .windows
    #elseif os(macOS)
      return .macOS
    #else
      return .linux
    #endif
  }
}

/// Detects the CPU architecture and operating system of the current machine.
public struct ArchitectureDetector: Sendable {
  public init() {}

  /// Detects the CPU architecture using `uname -m`.
  public func detectArchitecture() -> CPUArchitecture? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/uname")
    process.arguments = ["-m"]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice

    do {
      try process.run()
      process.waitUntilExit()

      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      guard let output = String(data: data, encoding: .utf8) else {
        return nil
      }
      return CPUArchitecture(rawValue: output.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    catch {
      return nil
    }
  }

  /// Returns the current operating system.
  public func detectOS() -> OperatingSystem {
    OperatingSystem.current
  }

  /// Returns the Tailwind CSS binary name for the current platform.
  /// Format: `tailwindcss-{os}-{arch}{ext}`
  public func tailwindBinaryName() -> String? {
    guard let arch = detectArchitecture() else {
      return nil
    }
    let os = detectOS()
    return "tailwindcss-\(os.tailwindOSName)-\(arch.tailwindArchName)\(os.executableExtension)"
  }
}
