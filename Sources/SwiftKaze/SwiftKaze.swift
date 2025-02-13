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
    
    public func operatingSystemName() -> String {
        var os: String!
        
        #if os(Windows)
                os = "Windows"
        #elseif os(macOS)
                os = "macOS"
        #elseif os(Linux)
                os = "Linux"
        #endif
        return os
    }
}

