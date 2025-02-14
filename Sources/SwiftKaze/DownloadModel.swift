import Foundation

public struct DownloadModel {
    let fileName: String
    
    public init(fileName: String) {
        self.fileName = fileName
    }
    
    public func destinationURL(allowsOverwrite: Bool = false) throws -> URL {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let fileURL = temporaryDirectoryURL.appendingPathComponent(self.fileName)
        
        guard allowsOverwrite == false else { return fileURL }
        guard (try? fileURL.checkResourceIsReachable()) == false else {
            throw FileError.fileAlreadyExists
        }
        
        return fileURL
    }
}

enum FileError: Error {
    case fileAlreadyExists
}
