import Foundation

public class HelloWorld {
    let architectureDetector: ArchitectureDetector
    
    public init(architectureDetector: ArchitectureDetector = ArchitectureDetector()) {
        self.architectureDetector = architectureDetector
    }

    public func hello() -> String {
        return "Hello, World!"
    }
}

