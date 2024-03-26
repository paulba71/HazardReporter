//
//  ChangeNotifications.swift
//  HazardReporter
//
//  Created by Paul Barnes on 23/03/2024.
//  Copyright © 2024 pluralsight. All rights reserved.
//

import Foundation
import CloudKit

let recordDidChangeLocally = Notification.Name(rawValue: "com.paulbarnes.cloudKitFundamentals.localKeyChange")
let recordDidChangeRemotely = Notification.Name(rawValue: "com.paulbarnes.cloudKitFundamentals.remoteKeyChange" )

enum RecordChange {
    case created(CKRecord)
    case updated(CKRecord)
    case deleted(CKRecordID)
}
