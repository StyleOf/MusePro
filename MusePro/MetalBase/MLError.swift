import Foundation

enum MLError: Error {
    
    case initializationError
    
    case fileNotExists(String)
    
    case imageNotExists(String)
    
    case convertPNGDataFailed
    
    case fileDamaged
    
    case directoryNotEmpty(URL)
    
    case textureCreationError
    
    case simulatorUnsupported
    
    case textureCreationFailed
}
