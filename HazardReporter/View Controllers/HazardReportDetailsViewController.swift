import UIKit
import MapKit
import CloudKit

class HazardReportDetailsViewController: UIViewController {
    @IBOutlet weak var emergencyIndicatorLabel: UILabel!
    @IBOutlet weak var hazardDescriptionLabel: UILabel!
    @IBOutlet weak var hazardImageView: UIImageView!
    @IBOutlet weak var hazardLocationMapView: MKMapView!
    
    var hazardReport: HazardReport!
    
    fileprivate func refreshView() {
        emergencyIndicatorLabel.isHidden = (self.hazardReport.isEmergency) == false
        hazardDescriptionLabel.text = self.hazardReport.hazardDescription
        
        if let hazardPhoto = hazardReport.hazardPhoto {
            hazardImageView.image = hazardPhoto
        }
        
        
        if let  location = hazardReport.hazardLocation {
            let hazardRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 1000, 1000)
            hazardLocationMapView.setRegion(hazardRegion, animated: true)
            
            let annotation = MKPointAnnotation()
            annotation.title = "Hazard!"
            annotation.coordinate = location.coordinate
            
            hazardLocationMapView.addAnnotation(annotation)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleLocalRecordChange), name: recordDidChangeLocally, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRemoteRecordChange), name: recordDidChangeRemotely, object: nil)
        
        refreshView()
    }
    
    deinit {
            NotificationCenter.default.removeObserver(self,
                                                      name: recordDidChangeLocally,
                                                      object: nil)
        }
    
    
    @objc func handleLocalRecordChange (_ notification: Notification) {
        guard let recordChange = notification.userInfo?["recordChange"] as? RecordChange else { return }
        
        switch recordChange {
        case .updated(let updatedCKRecord):
            guard updatedCKRecord.recordID.recordName == self.hazardReport.cloudKitRecord.recordID.recordName else { return }
            self.hazardReport = HazardReport(record: updatedCKRecord)
            
            DispatchQueue.main.async {
                self.refreshView()
            }
            
        default:
            break
        }
    }
    
    @objc func handleRemoteRecordChange(_ notification: Notification) {
            //CKContainer.default().fetchCloudKitRecordChanges() { changes in
            //    self.processRecordChanges(changes)
            //}
        }
    
    func processRecordChanges(_ recordChanges: [RecordChange]) {
            for recordChange in recordChanges {
                switch recordChange {
                case .updated(let record):
                    guard record.recordID == self.hazardReport.cloudKitRecord.recordID else { continue }
                    
                    self.hazardReport = HazardReport(record: record)
                default: continue
                }
            }
            
            DispatchQueue.main.async {
                self.refreshView()
            }
        }
    
    
    
    // MARK: - Delete Hazard Report
    @IBAction func deleteButtonTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Delete Hazard Report",
                                                message: "Are you sure you want to delete this hazard report?",
                                                preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) {
            (_) -> Void in
            
            let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [self.hazardReport.cloudKitRecord.recordID])
            
            deleteOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                guard let deletedRecordID = deletedRecordIDs?[0] else { return }
                NotificationCenter.default.post(name: recordDidChangeLocally, object: self, userInfo: ["recordChange" : RecordChange.deleted(deletedRecordID) ])
            }
            
            CKContainer.default().publicCloudDatabase.add(deleteOperation)
            
            let _ = self.navigationController?.popViewController(animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Resolve Hazard Report
    @IBAction func resolveButtonTapped(_ sender: UIBarButtonItem) {
        self.hazardReport.isResolved = true
        let modifyOperation = CKModifyRecordsOperation(recordsToSave: [self.hazardReport.cloudKitRecord], recordIDsToDelete: nil)
        modifyOperation.modifyRecordsCompletionBlock = {
            savedRecords, deletedRecordIDs, error in
                guard let updatedRecordID = savedRecords?[0] else { return }
                NotificationCenter.default.post(name: recordDidChangeLocally, object: self, userInfo: ["recordChange" : RecordChange.updated(updatedRecordID) ])
        }
        CKContainer.default().publicCloudDatabase.add(modifyOperation)
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "editHazardReport":
            let navigationController = segue.destination as! UINavigationController
            let destinationVC = navigationController.viewControllers[0] as! EditHazardReportViewController
            
            destinationVC.hazardReportToEdit = self.hazardReport
        default: break
        }
    }
}
