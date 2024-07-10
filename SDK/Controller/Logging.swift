import OSLog
import Foundation
import UIKit

public class Logging {
    
    public static let shared = Logging()
    private let config = Config.shared
    
    private init() {}
    
    public func log(type: LogType, _ message: String, functionName: String = #function) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy HH:mm:ss"
        let dateString = dateFormatter.string(from: Date())
        let content = "[\(type)] \(dateString): \(functionName) - \(message)\n"
        
        // Log to OS
        Logger.debug.error("\(content)")
        
        // Optionally log to file
        if config.logToFile {
            logToFile(content)
        }
    }
    
    private func logToFile(_ content: String) {
        let fileURL = getDocumentsDirectory().appendingPathComponent("log.txt")
        
        do {
            let previousContent = try String(contentsOf: fileURL)
            let newContent = content + previousContent
            try newContent.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error writing to log file: \(error)")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    public func clearLogFile() {
        let logFilePath = getDocumentsDirectory().appendingPathComponent("log.txt")
        do {
            try FileManager.default.removeItem(at: logFilePath)
        } catch {
            print("Error clearing log file: \(error.localizedDescription)")
        }
    }
}

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!
    
    /// Logs the view cycles like a view that appeared.
    static let viewCycle = Logger(subsystem: subsystem, category: "viewcycle")
    
    /// All logs related to tracking and analytics.
    static let statistics = Logger(subsystem: subsystem, category: "statistics")
    
    static let debug = Logger(subsystem: subsystem, category: "appdebug")
}
