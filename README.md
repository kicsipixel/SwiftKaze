# SwiftKaze (風)

[![Swift](https://img.shields.io/badge/Swift-6.2%20|%206.1%20|%206.0-orange?logo=swift)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20Linux-blue?logo=swift)](https://swift.org)
[![CI](https://github.com/kicsipixel/SwiftKaze/actions/workflows/ci.yml/badge.svg)](https://github.com/kicsipixel/SwiftKaze/actions/workflows/ci.yml)

SwiftKaze takes its name from the Japanese word 風 (kaze), meaning “wind,” reflecting to [Tailwind CSS](https://tailwindcss.com).

This Swift package downloads and runs the Tailwind CSS CLI from Swift projects.

## Installation

Add SwiftKaze to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/kicsipixel/SwiftKaze.git", from: "0.1.0")
]
```

Then add it to your target:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "SwiftKaze", package: "SwiftKaze")
    ]
)
```

## Usage

### Basic Example

```swift
import SwiftKaze

let kaze = SwiftKaze()
// Locate app.css inside the module bundle
guard let inputURL = Bundle.module.url(forResource: "app", withExtension: "css") else {
      throw HTTPError(.notFound, message: "File not found.")
}

// Output path inside Public folder (outside the bundle)
let outputURL = URL(fileURLWithPath: "public/styles/app.css")

try await kaze.run(
        input: inputURL,
        output: outputURL,
        in: Bundle.module.bundleURL
)
```

### Pin to Specific Version

```swift
let kaze = SwiftKaze(version: .fixed("4.1.18"))

try await kaze.run(
    input: URL(filePath: "src/input.css"),
    output: URL(filePath: "dist/output.css"),
    in: URL(filePath: ".")
)
```

### Hummingbird Integration

```swift
import Hummingbird
import SwiftKaze

func buildApplication() async throws -> some ApplicationProtocol {
    let router = try buildRouter()

    // Compile Tailwind CSS on startup
    let kaze = SwiftKaze()
    try await kaze.run(
        input: Bundle.module.url(forResource: "app", withExtension: "css")!,
        output: URL(filePath: "public/styles/app.css"),
        in: URL(filePath: ".")
    )

    
/// Build router
func buildRouter() throws -> Router<AppRequestContext> {
  let router = Router(context: AppRequestContext.self)
  // Add middleware
  router.addMiddleware {
    // logging middleware
    LogRequestsMiddleware(.info)
    // serve static files
    FileMiddleware()
  }

  return router
}
```

### Include Generated CSS in Your Templates

Add the generated CSS file to your HTML template:

```html
<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" href="/styles/app.css">
</head>
<body>
    <!-- Your content with Tailwind classes -->
    <h1 class="text-3xl font-bold text-blue-600">Hello, Tailwind!</h1>
</body>
</html>
```

Make sure `FileMiddleware` is configured to serve from your `public` directory where the CSS is generated.

## Docker Support

In Docker, the `public/` directory is typically made read-only for security. Since SwiftKaze compiles CSS at runtime, this requires a different approach:

1. **Create a shared CSSSetup library** for CSS compilation logic
2. **Pre-compile CSS during Docker build** using a `PrepareCSS` tool
3. **Skip compilation at runtime** when the output directory is not writable

### Setup

#### 1. Create CSSSetup shared library

Add targets to `Package.swift`:

```swift
targets: [
    // Shared library for CSS compilation
    .target(
        name: "CSSSetup",
        dependencies: [
            .product(name: "SwiftKaze", package: "SwiftKaze"),
        ],
        path: "Sources/CSSSetup"
    ),
    .executableTarget(
        name: "App",
        dependencies: [
            // ... other deps ...
            "CSSSetup",
        ],
        // ...
    ),
    .executableTarget(
        name: "PrepareCSS",
        dependencies: [
            "CSSSetup",
        ],
        path: "Sources/PrepareCSS"
    ),
]
```

#### 2. Create Sources/CSSSetup/CSSSetup.swift

```swift
import Foundation
import SwiftKaze

public enum CSSSetup {
    public static func compileCSS(
        input: URL,
        output: URL,
        skipIfNotWritable: Bool = false
    ) async throws {
        let outputDir = output.deletingLastPathComponent()

        if skipIfNotWritable {
            let dirExists = FileManager.default.fileExists(atPath: outputDir.path)
            let isWritable = FileManager.default.isWritableFile(atPath: outputDir.path)
            if dirExists && !isWritable {
                return // Skip in Docker runtime
            }
        }

        try FileManager.default.createDirectory(
            at: outputDir,
            withIntermediateDirectories: true
        )

        let kaze = SwiftKaze()
        try await kaze.run(input: input, output: output, in: URL(filePath: "."))
    }
}
```

#### 3. Create Sources/PrepareCSS/main.swift

```swift
import CSSSetup
import Foundation

@main
struct PrepareCSS {
    static func main() async throws {
        try await CSSSetup.compileCSS(
            input: URL(filePath: "Sources/App/Resources/Styles/app.css"),
            output: URL(filePath: "public/styles/app.css")
        )
    }
}
```

#### 4. Use CSSSetup in `App+build.swift`:

```swift
import CSSSetup

try await CSSSetup.compileCSS(
    input: Bundle.module.url(forResource: "app", withExtension: "css")!,
    output: URL(filePath: "public/styles/app.css"),
    skipIfNotWritable: true  // Skip in Docker runtime
)
```

#### 5. Update Dockerfile

Add these lines to your Dockerfile **build** stage:

```dockerfile
# SwiftKaze: Copy PrepareCSS tool (used to compile Tailwind CSS during build)
RUN cp "$(swift build --package-path /build -c release --show-bin-path)/PrepareCSS" ./

# ... after copying resources, before copying public directory ...

# ================================
# SwiftKaze: Compile Tailwind CSS
# ================================
# Pre-compile CSS during build so public/ can be read-only at runtime.
WORKDIR /build
RUN /staging/PrepareCSS
WORKDIR /staging
# ================================
# End SwiftKaze
# ================================
```

### How It Works

| Environment | CSS Compilation |
|-------------|-----------------|
| Local dev   | Automatic on app startup (directory is writable) |
| Docker      | Pre-compiled during build, skipped at runtime (directory is read-only) |

## Requirements

- Swift 6.0+
- macOS 14+ or Linux (x64, arm64)

## Platform Notes

### Linux

The package uses `FoundationNetworking` for URLSession on Linux. Make sure you have the required system dependencies:

```bash
# Ubuntu/Debian
apt-get install libcurl4-openssl-dev
```
