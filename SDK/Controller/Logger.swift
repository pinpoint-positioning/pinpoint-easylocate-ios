//Logger
   
class Logger {
    
    public static let shared = Logger()
    
    
    enum LogType {
        case Info
        case Warning
        case Error
    }
    
    func log(type:LogType, _ message: String,functionName: String = #function) {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        let dateString = dateFormatter.string(from: date)
        
        let documentDirectory = getDocumentsDirectory()
        let fileURL = documentDirectory.appendingPathComponent("log.txt")
        let content = "\n ------------------------ \n [\(type)] \(dateString): \(functionName) - \(message)"
        print ("Logged: \(content)")
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }
        
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            handle.seekToEndOfFile() // moving pointer to the end
            handle.write(content.data(using: .utf8)!) // adding content
            handle.closeFile() // closing the file
        } else {
            print("Error writing to log file.")
        }
    }
    
    
    
     func clearLogFile() {
        let documentDirectory = getDocumentsDirectory()
        let logFilePath = documentDirectory.appendingPathComponent("log.txt")
        do {
            try FileManager.default.removeItem(at: logFilePath)
        } catch {
            print("Error clearing log file: \(error.localizedDescription)")
        }
    }
    
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

}
