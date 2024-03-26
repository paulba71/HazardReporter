import UIKit
import CloudKit

class ActiveHazardReportsViewController:    UIViewController,
    UITableViewDataSource,
    UITableViewDelegate
{
    
    @IBOutlet weak var tableView: UITableView!
    
    var hazardReports = [HazardReport] ()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NotificationCenter.default.addObserver(self, selector: #selector(handleLocalRecordChange), name: recordDidChangeLocally, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRemoteRecordChange), name: recordDidChangeRemotely, object: nil)
        
        let predicate = NSPredicate(format: "isResolved == 0")
        let activeHazardsQuery = CKQuery(recordType: "HazardReport", predicate: predicate)
        
        let creationDateSortDescriptor = NSSortDescriptor(key: "creationDate", ascending:   true)
        activeHazardsQuery.sortDescriptors=[creationDateSortDescriptor]
        
        CKContainer.default().publicCloudDatabase.perform(activeHazardsQuery,
                                                          inZoneWith: nil) { (records, error) in
            print (records)
            guard let records = records else {return}
            self.hazardReports = records.map { HazardReport(record:$0)}
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func processChanges (_ recordChanges: [RecordChange]) {
        // process changes
        for recordChange in recordChanges {
            switch recordChange {
            case .created(let createdCKRecord):
                let newHazardReport = HazardReport(record: createdCKRecord)
                guard newHazardReport.isResolved == false else { return }
                self.hazardReports.append(newHazardReport)
            case .deleted(let deletedCKRecordID):
                let exisitingHazardReportIndex = self.hazardReports.index{ (report) -> Bool in
                    report.cloudKitRecord.recordID.recordName == deletedCKRecordID.recordName
                }
                if let existingIndex = exisitingHazardReportIndex {
                    self.hazardReports.remove(at: existingIndex)
                }
                
            case .updated(let updatedCKRecord):
                // find existing hazard report in the data source array
                let exisitingHazardReportIndex = self.hazardReports.index{ (report) -> Bool in
                    report.cloudKitRecord.recordID.recordName == updatedCKRecord.recordID.recordName
                }
                // remove if updated hazard is now resolved
                // replace hazard report with the new one
                if let existingIndex = exisitingHazardReportIndex {
                    let updatedHazardReport = HazardReport(record: updatedCKRecord)
                    if updatedHazardReport.isResolved {
                        self.hazardReports.remove(at: existingIndex)
                    } else {
                        self.hazardReports[existingIndex] = updatedHazardReport
                    }
                }
            }
        }
        
        // Resort the list
        self.hazardReports.sort { firstReport, secondReport in
            firstReport.creationDate! < secondReport.creationDate!
        }
        
        // update UI ->
        // Refresh the table view
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    @objc func handleLocalRecordChange (_ notification: Notification) {
        guard let recordChange = notification.userInfo?["recordChange"] as? RecordChange else { return }
        
        self.processChanges([recordChange])
    }
    
    @objc func handleRemoteRecordChange (_ norification: Notification) {
        // fetch changes
        CKContainer.default().fetchCloudKitRecordChanges() { changes in
            self.processChanges(changes)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: recordDidChangeLocally, object: nil)
    }
    
    // MARK: TableView Data Source methods
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView,
                   titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return self.hazardReports.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "hazardReportCell",
                                                 for: indexPath)
        let dispHazardReport = self.hazardReports[indexPath.row]
        
        // Display date as main title
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM, yyyy"
        if let creationDate=dispHazardReport.creationDate {
            cell.textLabel?.text = dateFormatter.string(from: creationDate)
        }
        
        // Display description as detail text
        let hazardDetail = dispHazardReport.hazardDescription
        cell.detailTextLabel?.text = hazardDetail
        
        // Toggle icon of emergency
        if (dispHazardReport.isEmergency){
            cell.imageView?.image = UIImage(named: "emergency-hazard-icon")
        }
        else {
            cell.imageView?.image = UIImage(named: "hazard-icon")
        }
        
        //cell.textLabel?.text = "January 1, 2018"
        //cell.detailTextLabel?.text = "At the entrance to building 4 there's a puddle of water. I just about slipped and fell!"
        
        return cell
    }
    
    // MARK: TableView Delegate methods
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "hazardReportDetails":
            let destinationVC = segue.destination as! HazardReportDetailsViewController
            let selectedIndexPath = self.tableView.indexPathForSelectedRow!
            let selectedHazardReport = self.hazardReports[selectedIndexPath.row]
            destinationVC.hazardReport = selectedHazardReport
        case "addHazardReport":
            let navigationController = segue.destination as! UINavigationController
            _ = navigationController.viewControllers[0] as! EditHazardReportViewController
        default: break
        }
    }
}
