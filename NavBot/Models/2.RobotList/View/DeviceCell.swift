
import UIKit

class DeviceCell: UICollectionViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    var cellDict = [String: Any]()
    var clickMoreButtonBlock: (()->())?

    func initCell(){
        deviceNameLabel.text = cellDict["name"] as? String ?? ""
    }
    
    @IBAction func clickMoreButton(_ sender: Any) {
        clickMoreButtonBlock?()
    }
    
    
}
