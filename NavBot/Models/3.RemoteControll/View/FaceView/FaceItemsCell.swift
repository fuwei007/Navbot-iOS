

import UIKit

class FaceItemsCell: UICollectionViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    
    var modelDict = [String: Any]()

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    func initUI(){
        nameLabel.text = modelDict["name"] as? String ?? ""
        let currentIndex = modelDict["index"] as? Int ?? 0
        //print("index:\(currentIndex),nowCenterAndSelectedItem:\(nowCenterAndSelectedItem)")
        if (nowCenterAndSelectedItem == currentIndex){
            self.nameLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            self.nameLabel.font = UIFont.systemFont(ofSize: 20)
        }else{
            self.nameLabel.textColor = UIColor(red: 148/255, green: 151/255, blue: 153/255, alpha: 1)
            self.nameLabel.font = UIFont.systemFont(ofSize: 15)
        }
    }
}
