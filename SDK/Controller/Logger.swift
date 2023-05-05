import SwiftUI


public class Logger {
    
    public static let shared = Logger()
    
    public let logFileName = "error_log.txt"
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    public lazy var logFileURL: URL = {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let logFileURL = documentsURL.appendingPathComponent(logFileName)
        return logFileURL
    }()
    
    public func log(error: String) {
        let logEntry = "\(dateFormatter.string(from: Date())): \(error)\n"
        print(logEntry)
        
        do {
            let fileHandle = try FileHandle(forWritingTo: logFileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(logEntry.data(using: .utf8)!)
            fileHandle.closeFile()
        } catch {
            print("Error writing to log file: \(error)")
        }
    }
    
    public func readLogFile() -> String? {
        do {
            let logText = try String(contentsOf: logFileURL, encoding: .utf8)
            return logText
        } catch {
            print("Error reading log file: \(error)")
            return nil
        }
    }
    
    public func openLogFile() {
        if FileManager.default.fileExists(atPath: logFileURL.path) {
            let activityViewController = UIActivityViewController(activityItems: [logFileURL], applicationActivities: nil)
            UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
        } else {
            print("Log file not found")
        }
    }
    
    public func saveLogFile() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let newFileURL = documentsURL.appendingPathComponent(logFileName)
        
        do {
            try FileManager.default.copyItem(at: logFileURL, to: newFileURL)
            let activityViewController = UIActivityViewController(activityItems: [newFileURL], applicationActivities: nil)
            UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
        } catch {
            print("Error saving log file: \(error)")
        }
    }
}
