import Foundation

public struct DownloadModel {
    let fileName: String
    
    public init(fileName: String) {
        self.fileName = fileName
    }
    
    public func destinationURL(searchPath: FileManager.SearchPathDirectory = .documentDirectory, allowsOverwrite: Bool = false) throws -> URL {
        let fileURL = try FileManager.default.url(for: searchPath, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(self.fileName)
        
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

