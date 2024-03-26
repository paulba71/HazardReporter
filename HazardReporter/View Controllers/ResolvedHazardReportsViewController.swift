import UIKit
import CloudKit

class ResolvedHazardReportsViewController:     
    UIViewController,
    UITableViewDataSource,
    UITableViewDelegate
{
    
    @IBOutlet weak var tableView: UITableView!
    var hazardReports = [HazardReport]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRemoteRecordChange), name: recordDidChangeRemotely, object: nil)
        
        let predicate = NSPredicate(format: "isResolved != 0")
        let resolvedHazardsQuery = CKQuery(recordType: "HazardReport", predicate: predicate)
        
        let modificationDateSortDescriptor = NSSortDescriptor(key: "modificationDate", ascending: false)
        
        resolvedHazardsQuery.sortDescriptors = [modificationDateSortDescriptor]
        
        CKContainer.default().publicCloudDatabase.perform(resolvedHazardsQuery,
                                                          inZoneWith: nil)
        { (records, error) in
            guard let records = records else {return}
            self.hazardReports = records.map { HazardReport(record:$0) }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    @objc func handleRemoteRecordChange (_ norification: Notification) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        // Display date as main text
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd, yyyy"
        
        if let creationDate = dispHazardReport.creationDate {
            cell.textLabel?.text = dateFormatter.string(from: creationDate)
        }
        // Display description as detail text
        cell.detailTextLabel?.text = dispHazardReport.hazardDescription
        
        return cell
    }
    
    // MARK: TableView Delegate methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "resolvedHazardDetails":
            let destinationVC = segue.destination as! HazardReportDetailsViewController
            
            let selectedIndexPath = tableView.indexPathForSelectedRow!
            let selectedHazardReport = hazardReports[selectedIndexPath.row]
            
            destinationVC.hazardReport = selectedHazardReport
        default: break
        }
    }
    
}
