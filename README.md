# SwiftKaze

A Swift package to download and run the [Tailwind CSS](https://tailwindcss.com) CLI from Swift projects. Works with Tailwind CSS.

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
    output: URL(filePath: "public/styles/app.css"),
    in: URL(filePath: ".")
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
    let router = Router()

    // Compile Tailwind CSS on startup
    let kaze = SwiftKaze()
    try await kaze.run(
        input: Bundle.module.url(forResource: "app", withExtension: "css")!,
        output: URL(filePath: "public/styles/app.css"),
        in: URL(filePath: ".")
    )

    // Serve static files
    router.middlewares.add(FileMiddleware())

    // ... your routes

    return Application(router: router)
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
