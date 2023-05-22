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
    let logger = Logger.shared
        
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    
    
  
    
    // Unzip Sitefile to documentsfolder/sitefiles/sitefilename/
    
    public func unarchiveFile(sourceFile:URL) async -> Bool {
      
        var destinationURL = getDocumentsDirectory()
        destinationURL.appendPathComponent("sitefiles")
        destinationURL.appendPathComponent(sourceFile.lastPathComponent)
        do {
            
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            print("folder created")
            try fileManager.unzipItem(at: sourceFile, to: destinationURL)
            try await Task.sleep(nanoseconds: 2_000_000_000)
            if let items = moveAndRenameFiles(path: destinationURL) {
                for item in items {
                    print("Found \(item)")
                }
                return true
            }
            
        } catch {
            print("unzip \(error)")
            return false
        }
        return true
    }
    
    
    
    public func getSitefilesList() -> [String] {
        var destinationURL = getDocumentsDirectory()
        destinationURL.appendPathComponent("sitefiles")
        var list = [String]()
        
        do {
            let items = try fileManager.contentsOfDirectory(atPath: destinationURL.path)
            for item in items {
                print (item)
                list.append(item)
            }

        } catch {
            print (error)
        }
        return list
    }
    
    
    
    
    // rename floorplan and json file to standardized names
    
    func moveAndRenameFiles (path:URL) -> [String]? {
    
        let path =  path
        do {
            let items = try fileManager.contentsOfDirectory(atPath: path.path)

            for item in items {
                let fileType = NSURL(fileURLWithPath: item).pathExtension
                if let fileType = fileType {
                    switch fileType {
                    case "png" :
                        do {
                            try fileManager.moveItem(atPath: path.appendingPathComponent(item).path, toPath: path.appendingPathComponent("floorplan.png").path)
                            logger.log(type: .Info, "Copied file from \(path.appendingPathComponent(item).path) to \(path.appendingPathComponent("floorplan.png").path) ")
                        } catch let error as NSError {
                            logger.log(type: .Error, "Error while copy file from \(path.appendingPathComponent(item).path) to \(path.appendingPathComponent("floorplan.png").path): \(error)")
                        }
                    case "json" :
                        do {
                            try fileManager.moveItem(atPath: path.appendingPathComponent(item).path, toPath: path.appendingPathComponent("sitedata.json").path)
                            logger.log(type: .Info, "Copied file from \(path.appendingPathComponent(item).path) to \(path.appendingPathComponent("sitedata.json").path) ")
                        } catch let error as NSError {
                            logger.log(type: .Error, "Error while copy file from \(path.appendingPathComponent(item).path) to \(path.appendingPathComponent("floorplan.png").path): \(error)")
                        }
                    default:
                        break
                        
                    }
                }
            }
            return items
        } catch {
            print(error)
            return nil
           
        }
        
    }
    

    //ParseJsonFile
    
    public func loadJson(siteFileName: String) -> SiteData? {
        do {
            var destinationURL = getDocumentsDirectory()
            destinationURL.appendPathComponent("sitefiles")
            destinationURL.appendPathComponent(siteFileName)
            
            let data = try Data(contentsOf: destinationURL.appendingPathComponent("sitedata.json"))
            let decoder = JSONDecoder()
            var jsonData = try decoder.decode(SiteData.self, from: data)
           // jsonData.siteFileName = siteFileName
            return jsonData
            
        } catch {
            print("error:\(error)")
        }

        return nil
    }

    
    // Get the floor image file
    
    public func getFloorImage(siteFileName:String) -> UIImage? {
        var destinationURL = getDocumentsDirectory()
        destinationURL.appendPathComponent("sitefiles")
        destinationURL.appendPathComponent(siteFileName)
        destinationURL.appendPathComponent("floorplan.png")
        
        do {
            let imageData = try Data(contentsOf: destinationURL)
            return UIImage(data: imageData)
        } catch {
            print("Error loading image : \(error)")
        }
        return nil
    }
  
}
