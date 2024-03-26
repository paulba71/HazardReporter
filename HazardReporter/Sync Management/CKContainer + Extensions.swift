//
//  CKContainer + Extensions.swift
//  HazardReporter
//
//  Created by Paul Barnes on 25/03/2024.
//  Copyright © 2024 pluralsight. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

extension CKContainer {
    func fetchCloudKitRecordChanges (completion: @escaping ([RecordChange]) -> ()) {
        // Get existing change token
        let existingChangeToken = UserDefaults().serverChangeToken
        // CKFetchNotificationChangesOperation
        let notificationChangesOperation = CKFetchNotificationChangesOperation(previousServerChangeToken: existingChangeToken)
        // Cache change reasons
        var changeReasons = [CKRecordID:CKQueryNotificationReason]()
        notificationChangesOperation.notificationChangedBlock = { notification in
            if let n = notification as? CKQueryNotification, let recordID = n.recordID {
                changeReasons[recordID] = n.queryNotificationReason
            }
        }
        // Implement CKFetchNotificationChangesOperation's completion block
        notificationChangesOperation.fetchNotificationChangesCompletionBlock = { newChangeToken, error in
            guard error == nil else { return }
            guard changeReasons.count > 0 else { return }
            
            // Save new change token
            UserDefaults().serverChangeToken = newChangeToken
            // Split out the deleted recordIDs from the insterted/updated recordIDs
            var deletedIDs = [CKRecordID]()
            var insertedOrUpdatedIDs = [CKRecordID]()
            
            for (recordID, reason) in changeReasons {
                switch reason {
                case .recordDeleted:
                    deletedIDs.append(recordID)
                default:
                    insertedOrUpdatedIDs.append(recordID)
                }
            }
            // Fetch inserted/updated CKRecord instances based upon their recordIDs
            let fetchRecordsOperation = CKFetchRecordsOperation(recordIDs: insertedOrUpdatedIDs)
            fetchRecordsOperation.fetchRecordsCompletionBlock = { records, error in
                // Create an array of record changes using the RecordChange enum
                var changes: [RecordChange] = deletedIDs.map { RecordChange.deleted($0) }
                for (id, record) in records ?? [:] {
                    guard let reason = changeReasons[id] else { continue }
                    switch reason {
                    case .recordCreated:
                        changes.append(RecordChange.created(record))
                    case .recordUpdated:
                        changes.append(RecordChange.updated(record))
                    default:
                        fatalError("inserts and updates only in this block...")
                    }
                }
                // Pass the created [RecordChange] back to "whoever" started this whole process thru the completion closure
                completion(changes)
            }
            // Add operation to the database
            self.publicCloudDatabase.add(fetchRecordsOperation)
        }
        
        // Kick everything off by adding fetch notifications opertion (where everyhting else is nested within)
        // to the CKContainer (namely... _self_)
        self.add(notificationChangesOperation)
    }
}

public extension UserDefaults {
    // https://gist.github.com/ralcr/ce69a5a496e6619143a639ec55105e98
    var serverChangeToken: CKServerChangeToken? {
        get {
            guard let data = self.value(forKey: "ChangeToken") as? Data else {
                return nil
            }
            guard let token = NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken else {
                return nil
            }
            
            return token
        }
        set {
            if let token = newValue {
                let data = NSKeyedArchiver.archivedData(withRootObject: token)
                self.set(data, forKey: "ChangeToken")
                self.synchronize()
            } else {
                self.removeObject(forKey: "ChangeToken")
            }
        }
    }
}
