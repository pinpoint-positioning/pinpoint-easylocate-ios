//
//  locations.swift
//  SDK
//
//  Created by Christoph Scherbeck on 27.04.23.
//

import Foundation
import CoreBluetooth

public class AsyncLocationStream: NSObject {
    
    public static let shared = AsyncLocationStream()

    
    var continuation: AsyncStream<TL_PositionResponse>.Continuation?

        public lazy var stream: AsyncStream<TL_PositionResponse> = {
            AsyncStream { (continuation: AsyncStream<TL_PositionResponse>.Continuation) -> Void in
                self.continuation = continuation
                /// Configure a termination callback to understand the lifetime of your stream.
                continuation.onTermination = { @Sendable status in
                    print("Stream terminated with status \(status)")
                }
            }
        }()
    
    

    }

