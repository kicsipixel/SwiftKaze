import Foundation

public class SwiftKaze {
    let architectureDetector: ArchitectureDetector
    
    public init(architectureDetector: ArchitectureDetector = ArchitectureDetector()) {
        self.architectureDetector = architectureDetector
    }
    
    /// Returns the architecture name
    public func binaryName() -> String? {
        guard let architecture = architectureDetector.getMachineArchitecture() else {
            return nil
        }
        
        return architecture.rawValue
    }
}

