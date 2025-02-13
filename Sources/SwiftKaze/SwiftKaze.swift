import Foundation

public class HelloWorld {
    let architectureDetector: ArchitectureDetector
    
    init(architectureDetector: ArchitectureDetector = ArchitectureDetector()) {
        self.architectureDetector = architectureDetector
    }

    public func hello() -> String {
        return "Hello, World!"
    }
}

