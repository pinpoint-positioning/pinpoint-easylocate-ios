//
//  SiteFileManager.swift
//  SDK
//
//  Created by Christoph Scherbeck on 15.05.23.
//

import Foundation
import ZIPFoundation
import SwiftUI


public class SiteFileManager {
    
    public init(){}
    
    
    let fileManager = FileManager()
    
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    
    
  
    
    
    public func unarchiveFile(sourceFile:URL, completion: @escaping (URL) -> Void) {
      
        let progress = Progress()
        var destinationURL = getDocumentsDirectory()
        destinationURL.appendPathComponent("unzipData")
        do {
            
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            print("folder created")
            try fileManager.unzipItem(at: sourceFile, to: destinationURL, progress: progress)
            print ("extracted")
            completion(destinationURL)
            
        } catch {
            print("unzip \(error)")
            completion(destinationURL)
        }
        

    }
    
    
    func moveAndRenameFiles (path:URL) -> [String]? {
    ß09
        let path =  path
        print ("Pfad: \(path)")
        do {
            let items = try fileManager.contentsOfDirectory(atPath: path.absoluteString)

            for item in items {
                print("Found \(item)")
            }
            return items
        } catch {
            print(error)
            return nil
           
        }
        
    }
    
    
    public func processSiteFile (sourceFile:URL) {
     
        unarchiveFile(sourceFile: sourceFile) { path in
            self.moveAndRenameFiles(path: path)
        }
        
    }
    
    
    
    //ParseJsonFile
    
    public func loadJson(filename siteFileName: String) -> SiteFile? {
        do {
            var destinationURL = getDocumentsDirectory()
            destinationURL.appendPathComponent("unzipData")
            
            let data = try Data(contentsOf: destinationURL.appendingPathComponent(siteFileName))
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode(SiteFile.self, from: data)
            print(jsonData)
            getFloorImage()
            return jsonData
            
        } catch {
            print("error:\(error)")
        }
        
        
        return nil
    }
    
    
    
    
    public func getFloorImage_old() -> Image?{
        
        var destinationURL = getDocumentsDirectory()
        destinationURL.appendPathComponent("unzipData/university_4.png")
        if let uiimage = UIImage(contentsOfFile: destinationURL.absoluteString) {
            print("gotimage")
            print (destinationURL.absoluteString)
            return  Image(uiImage: uiimage )
            
        } else {
            print("got nothing")
            print(destinationURL.absoluteString)
            return nil
        }
        
       

    }
    
    
    public func getFloorImage() -> UIImage? {
        var destinationURL = getDocumentsDirectory()
        destinationURL.appendPathComponent("unzipData/floor.png")
        
        do {
            let imageData = try Data(contentsOf: destinationURL)
            return UIImage(data: imageData)
        } catch {
            print("Error loading image : \(error)")
        }
        return nil
    }
    
    
    
    
}
