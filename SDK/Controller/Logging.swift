import OSLog
import Foundation
import UIKit


 public enum LogType {
    case info
    case warning
    case error
    
}

public class Logging {
    
    public static let shared = Logging()
    
    let config = Config.shared
    public init() {}
    

    public func log(type: LogType, _ message: String, functionName: String = #function) {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy HH:mm:ss"
        let dateString = dateFormatter.string(from: date)
        let content = "[\(type)] \(dateString): \(functionName) - \(message)\n"
        
       // Log to OS
        Logger.debug.error("\(content)")
        
        // Optionally log to file
        if config.logToFile{
            logToFile(content)
        }
    }
    
    private func logToFile(_ content: String) {
        let documentDirectory = getDocumentsDirectory()
        let fileURL = documentDirectory.appendingPathComponent("log.txt")
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }
        
        do {
            let previousContent = try String(contentsOf: fileURL)
            
            let newContent = content + previousContent
            
            try newContent.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error writing to log file: \(error)")
        }
    }

    

    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }


    public func openDir() {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filename = getDocumentsDirectory().appendingPathComponent("positionLog\(Date()).txt")
        
        if let sharedUrl = URL(string: "shareddocuments://\(documentsUrl.path)") {
            if UIApplication.shared.canOpenURL(sharedUrl) {
                UIApplication.shared.open(filename, options: [:])
            }
        }
    }
    
    
    public func clearLogFile() {
        let documentDirectory = getDocumentsDirectory()
        let logFilePath = documentDirectory.appendingPathComponent("log.txt")
        do {
            try FileManager.default.removeItem(at: logFilePath)
        } catch {
            print("Error clearing log file: \(error.localizedDescription)")
        }
    }

}


extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs the view cycles like a view that appeared.
    static let viewCycle = Logger(subsystem: subsystem, category: "viewcycle")

    /// All logs related to tracking and analytics.
    static let statistics = Logger(subsystem: subsystem, category: "statistics")
    
    static let debug = Logger(subsystem: subsystem, category: "appdebug")
}
