//
//  HazardReport.swift
//  HazardReporter
//
//  Created by Paul Barnes on 21/03/2024.
//  Copyright © 2024 pluralsight. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

public struct HazardReport {
    public var hazardDescription: String
    public var hazardLocation: CLLocation?
    public var hazardPhoto: UIImage?
    public var isEmergency: Bool
    public var isResolved: Bool
    
    public var creationDate: Date? // assigned by iCloud
    public var modificationDate: Date? // assigned by iCloud
    
    public var encodedSystemFeilds: Data?
    
    init(hazardDescription: String, hazardLocation: CLLocation? = nil, hazardPhoto: UIImage? = nil, isEmergency: Bool, isResolved: Bool) {
        self.hazardDescription = hazardDescription
        self.hazardLocation = hazardLocation
        self.hazardPhoto = hazardPhoto
        self.isEmergency = isEmergency
        self.isResolved = isResolved
    }
    
    init (record: CKRecord) {
        // Data --> Coder
        // use coder to encode system fields
        // Assign
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWith: data)
        coder.requiresSecureCoding = true
        record.encodeSystemFields(with: coder)
        coder.finishEncoding()
        self.encodedSystemFeilds = data as Data
        
        
        self.hazardDescription = record["hazardDescription"] as! String
        self.hazardLocation = record["hazardLocation"] as? CLLocation
        // Asset --> File URL
        // File URL --> Data UIImage
        // Date --> UIImage
        if let photoAsset = record["hazardPhoto"] as? CKAsset {
            let photoData = try? Data(contentsOf: photoAsset.fileURL)
            self.hazardPhoto = UIImage(data: photoData!)
        }
        self.isEmergency = record["isEmergency"] as! Bool
        self.isResolved = record["isResolved"] as! Bool
        
        self.creationDate = record.creationDate
        self.modificationDate = record.modificationDate
    }
    
    public var cloudKitRecord: CKRecord {
        var hazardReport: CKRecord
        if let systemFields = self.encodedSystemFeilds{
            // Decoder --> CKRecord
            let decoder = NSKeyedUnarchiver(forReadingWith: systemFields)
            decoder.requiresSecureCoding = true
            hazardReport = CKRecord(coder: decoder)!
            decoder.finishDecoding()
            
        } else {
            hazardReport = CKRecord(recordType: "HazardReport")
        }
        
        hazardReport["isEmergency"] = self.isEmergency as NSNumber
        hazardReport["hazardDescription"] = self.hazardDescription as NSString
        if let location = self.hazardLocation {
            hazardReport["hazardLocation"] = self.hazardLocation
        }
        hazardReport["isResolved"] = self.isResolved as NSNumber
        
        if let hazardPhoto = self.hazardPhoto {
            // Generate unique file name
            let hazardPhotoFileName = ProcessInfo.processInfo.globallyUniqueString + ".jpg"
            
            // Create URL in temp directory
            let hazardPhotoFileURL = URL.init(fileURLWithPath: NSTemporaryDirectory())
                                        .appendingPathComponent(hazardPhotoFileName)
            
            // Make JPEG
            let hazardPhotoData = UIImageJPEGRepresentation(hazardPhoto, 0.70)
            
            // Write to disk
            do {
                try hazardPhotoData?.write(to: hazardPhotoFileURL)
            } catch {
                print("Could not save hazard photo to disk")
            }
            
            // Convert to CKAsset and store with CKRecord
            // Removed to see if this is causing an error...
            hazardReport["hazardPhoto"] = CKAsset(fileURL: hazardPhotoFileURL)
            
        }
        
        return hazardReport
    }
}
