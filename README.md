# SwiftKaze

A Swift package to download and run the [Tailwind CSS](https://tailwindcss.com) CLI from Swift projects. Works with Tailwind CSS v4.

## Features

- Downloads Tailwind CSS binaries automatically from GitHub releases
- Caches binaries by version to avoid repeated downloads
- Supports macOS (arm64, x64) and Linux
- Full Swift 6 concurrency support (`Sendable`, `async/await`)
- Minimal dependencies (only swift-log)

## Installation

Add SwiftKaze to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/kicsipixel/SwiftKaze.git", from: "0.0.1")
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

try await kaze.run(
    input: URL(filePath: "Resources/Styles/app.css"),
    output: URL(filePath: "Public/styles/app.css"),
    in: URL(filePath: ".")
)
```

### With Options

```swift
let kaze = SwiftKaze(version: .fixed("4.1.18"))

try await kaze.run(
    input: URL(filePath: "src/input.css"),
    output: URL(filePath: "dist/output.css"),
    in: URL(filePath: "."),
    options: .minify, .sourceMap
)
```

### Watch Mode

```swift
try await kaze.run(
    input: inputCSS,
    output: outputCSS,
    in: projectDir,
    options: .watch
)
```

### Hummingbird Integration

```swift
import Hummingbird
import SwiftKaze

func buildApplication() async throws -> some ApplicationProtocol {
    let router = Router()

    // Compile Tailwind CSS on startup
    let kaze = SwiftKaze()
    try await kaze.run(
        input: URL(filePath: "Resources/Styles/app.css"),
        output: URL(filePath: "Public/styles/app.css"),
        in: URL(filePath: "."),
        options: .minify
    )

    // Serve static files
    router.middlewares.add(FileMiddleware())

    // ... your routes

    return Application(router: router)
}
```

For development with watch mode, run Tailwind in a separate task:

```swift
// In development, watch for changes
Task {
    try await kaze.run(
        input: inputCSS,
        output: outputCSS,
        in: projectDir,
        options: .watch
    )
}
```

## API Reference

### SwiftKaze

```swift
public init(
    version: TailwindVersion = .latest,
    directory: URL? = nil  // Where to store downloaded binaries
)
```

### TailwindVersion

```swift
public enum TailwindVersion {
    case latest              // Uses latest release from GitHub
    case fixed(String)       // e.g., "4.1.18" or "v4.1.18"
}
```

### Run Options

| Option | Description |
|--------|-------------|
| `.watch` | Watch for file changes and rebuild automatically |
| `.watchAlways` | Watch mode that keeps running when stdin closes |
| `.minify` | Minify the output CSS |
| `.optimize` | Optimize output without minifying |
| `.sourceMap` | Generate a source map |
| `.cwd(URL)` | Set the current working directory |

### Input CSS (Tailwind v4)

Tailwind CSS v4 uses CSS-based configuration. Your input CSS file should look like:

```css
@import "tailwindcss";

/* Your custom styles */
.btn {
    @apply px-4 py-2 rounded;
}
```

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
