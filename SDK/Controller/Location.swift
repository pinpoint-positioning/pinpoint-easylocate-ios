//
//  locations.swift
//  SDK
//
//  Created by Christoph Scherbeck on 27.04.23.
//


// In Progress
import Foundation
import CoreBluetooth

class AsyncLocationStream: NSObject {
    
    static let shared = AsyncLocationStream()
    
    
    var continuation: AsyncStream<TraceletPosition>.Continuation?
    
    public lazy var stream: AsyncStream<TraceletPosition> = {
        AsyncStream { (continuation: AsyncStream<TraceletPosition>.Continuation) -> Void in
            self.continuation = continuation
            continuation.onTermination = { @Sendable status in
                print("Stream terminated with status \(status)")
            }
        }
    }()
}

