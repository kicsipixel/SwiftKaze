import Foundation
import Testing

@testable import SwiftKaze

// MARK: - Architecture Detection Tests

@Test func architectureDetection() {
  let detector = ArchitectureDetector()
  let architecture = detector.detectArchitecture()

  #expect(architecture != nil, "Should detect CPU architecture")
}

@Test func operatingSystemDetection() {
  let detector = ArchitectureDetector()
  let os = detector.detectOS()

  #if os(macOS)
    #expect(os == .macOS)
  #elseif os(Linux)
    #expect(os == .linux)
  #elseif os(Windows)
    #expect(os == .windows)
  #endif
}

@Test func tailwindBinaryName() {
  let detector = ArchitectureDetector()
  let binaryName = detector.tailwindBinaryName()

  #expect(binaryName != nil, "Should generate binary name")

  if let name = binaryName {
    #expect(name.hasPrefix("tailwindcss-"), "Binary name should start with 'tailwindcss-'")

    #if os(macOS)
      #expect(name.contains("macos"), "Should contain 'macos' on macOS")
    #elseif os(Linux)
      #expect(name.contains("linux"), "Should contain 'linux' on Linux")
    #endif
  }
}

// MARK: - TailwindVersion Tests

@Test func versionReleaseTag() {
  let latestVersion = TailwindVersion.latest
  #expect(latestVersion.releaseTag == nil, "Latest version should have nil release tag")

  let fixedWithV = TailwindVersion.fixed("v3.4.1")
  #expect(fixedWithV.releaseTag == "v3.4.1")

  let fixedWithoutV = TailwindVersion.fixed("3.4.1")
  #expect(fixedWithoutV.releaseTag == "v3.4.1")
}

// MARK: - CPU Architecture Tests

@Test func cpuArchitectureTailwindNames() {
  #expect(CPUArchitecture.arm64.tailwindArchName == "arm64")
  #expect(CPUArchitecture.aarch64.tailwindArchName == "arm64")
  #expect(CPUArchitecture.x86_64.tailwindArchName == "x64")
  #expect(CPUArchitecture.armv7.tailwindArchName == "armv7")
}

// MARK: - Operating System Tests

@Test func operatingSystemTailwindNames() {
  #expect(OperatingSystem.macOS.tailwindOSName == "macos")
  #expect(OperatingSystem.linux.tailwindOSName == "linux")
  #expect(OperatingSystem.windows.tailwindOSName == "windows")
}

@Test func operatingSystemExtensions() {
  #expect(OperatingSystem.macOS.executableExtension == "")
  #expect(OperatingSystem.linux.executableExtension == "")
  #expect(OperatingSystem.windows.executableExtension == ".exe")
}

// MARK: - Run Option Tests (Tailwind v4)

@Test func runOptionArguments() {
  #expect(SwiftKaze.RunOption.watch.arguments == ["--watch"])
  #expect(SwiftKaze.RunOption.watchAlways.arguments == ["--watch=always"])
  #expect(SwiftKaze.RunOption.minify.arguments == ["--minify"])
  #expect(SwiftKaze.RunOption.optimize.arguments == ["--optimize"])
  #expect(SwiftKaze.RunOption.sourceMap.arguments == ["--map"])

  let cwdURL = URL(fileURLWithPath: "/path/to/project")
  #expect(SwiftKaze.RunOption.cwd(cwdURL).arguments == ["--cwd", "/path/to/project"])
}

// MARK: - Integration Tests (require network)

@Test func downloadAndRun() async throws {
  let tmpDir = FileManager.default.temporaryDirectory
    .appendingPathComponent("SwiftKazeTest-\(UUID().uuidString)", isDirectory: true)

  defer {
    try? FileManager.default.removeItem(at: tmpDir)
  }

  try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

  // Create input CSS file with Tailwind v4 syntax
  let inputCSS = tmpDir.appendingPathComponent("input.css")
  let cssContent = """
    @import "tailwindcss";

    .test {
        color: red;
    }
    """
  try cssContent.write(to: inputCSS, atomically: true, encoding: .utf8)

  let outputCSS = tmpDir.appendingPathComponent("output.css")

  let kaze = SwiftKaze(directory: tmpDir)
  try await kaze.run(
    input: inputCSS,
    output: outputCSS,
    in: tmpDir
  )

  #expect(FileManager.default.fileExists(atPath: outputCSS.path), "Output CSS file should be created")

  let outputContent = try String(contentsOf: outputCSS, encoding: .utf8)
  #expect(!outputContent.isEmpty, "Output should not be empty")
}

@Test func downloadAndRunWithMinify() async throws {
  let tmpDir = FileManager.default.temporaryDirectory
    .appendingPathComponent("SwiftKazeTest-\(UUID().uuidString)", isDirectory: true)

  defer {
    try? FileManager.default.removeItem(at: tmpDir)
  }

  try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

  // Create input CSS file
  let inputCSS = tmpDir.appendingPathComponent("input.css")
  let cssContent = """
    @import "tailwindcss";

    .test {
        color: red;
    }
    """
  try cssContent.write(to: inputCSS, atomically: true, encoding: .utf8)

  let outputCSS = tmpDir.appendingPathComponent("output.css")

  let kaze = SwiftKaze(directory: tmpDir)
  try await kaze.run(
    input: inputCSS,
    output: outputCSS,
    in: tmpDir,
    options: .minify
  )

  #expect(FileManager.default.fileExists(atPath: outputCSS.path), "Output CSS file should be created")
}

@Test func downloadCaching() async throws {
  let tmpDir = FileManager.default.temporaryDirectory
    .appendingPathComponent("SwiftKazeTest-\(UUID().uuidString)", isDirectory: true)

  defer {
    try? FileManager.default.removeItem(at: tmpDir)
  }

  // First download
  let downloader = Downloader()
  let firstPath = try await downloader.download(version: .latest, directory: tmpDir)
  #expect(FileManager.default.fileExists(atPath: firstPath.path))

  // Second download should use cache
  let secondPath = try await downloader.download(version: .latest, directory: tmpDir)
  #expect(firstPath == secondPath, "Should return same cached path")
}
