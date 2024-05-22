//
//  Storage.swift
//  SDK
//
//  Created by Christoph Scherbeck on 18.04.24.
//

import Foundation
import SwiftUI
import Combine

public class Config: ObservableObject {
    
    public static let shared = Config()
    @AppStorage("uci") public var uci:Bool = true
    
}

