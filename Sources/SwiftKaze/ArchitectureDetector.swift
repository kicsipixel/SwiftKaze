import Foundation

public enum CPUArchitecture: String {
    case aarch64 = "aarch64"
    case arm64 = "arm64"
    case armv7 = "armv7"
    case x86_64 = "x86_64"
}

public final class ArchitectureDetector {
    
    public init() { }
    
    public func getMachineArchitecture() -> CPUArchitecture? {
        let getArchitectureTask = Process()
        getArchitectureTask.launchPath = "/usr/bin/uname"
        getArchitectureTask.arguments = ["-m"]
        
        let pipe = Pipe()
        getArchitectureTask.standardOutput = pipe
        getArchitectureTask.launch()
        getArchitectureTask.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            return CPUArchitecture(rawValue: output.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return nil
    }
    
    public func operatingSystemName() -> String {
        var os: String!
        
        #if os(Windows)
                os = "Windows"
        #elseif os(macOS)
                os = "macOS"
        #else
                os = "Linux"
        #endif
        return os
    }
}
