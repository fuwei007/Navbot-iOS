
import UIKit

class DeviceCell: UICollectionViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var deviceTypeIcon: UIImageView!
    
    //Type--Greed:
    //背景色为：91 209 131
    //背景图片为：power_green_empty
    //Type--Red:
    //背景色为：252 33 37
    //背景图片为：power_red_empty
    @IBOutlet weak var battaryFatherView: UIView!
    @IBOutlet weak var battaryTypeIcon: UIImageView!
    @IBOutlet weak var battaryProgressView: UIView!
    //总长度为24
    @IBOutlet weak var battaryProgressViewWidth: NSLayoutConstraint!
    

    var cellDict = [String: Any]()
    var clickMoreButtonBlock: (()->())?

    func initCell(){
        
        deviceNameLabel.text = cellDict["name"] as? String ?? ""
        
        let deviceName = cellDict["name"] as? String ?? ""
        if deviceName.contains("en01"){
            deviceTypeIcon.image = UIImage(named: "device_icon_ES01")
        }
        if deviceName.contains("es02"){
            deviceTypeIcon.image = UIImage(named: "device_icon_ES02")
        }
         
        battaryTypeIcon.image = UIImage(named: "power_unknown")
        battaryTypeIcon.contentMode = .scaleAspectFill
        battaryProgressView.isHidden = true
        
        //充电状态显示：
        if let deviceInfo = jsonStringToDict(cellDict["device_info"] as? String ?? ""){
            //print("设备信息:\(deviceInfo)")
            //1.这里如果有别名，显示设备的别名
             if let device_name = deviceInfo["name"] as? String,
                device_name.count > 0{
                deviceNameLabel.text = device_name
            }
            //2.判断设备是否链接
            let isConnected = cellDict["isConnected"] as? Bool ?? false
            if isConnected == true{
                //判断是否在充电
                let charge = deviceInfo["charge"] as? Bool ?? false
                if charge == true{
                    //3.如果在充电，则显示充电：charge
                    battaryTypeIcon.image = UIImage(named: "power_charging")
                    battaryTypeIcon.contentMode = .scaleAspectFill
                    battaryProgressView.isHidden = true
                }else{
                    //4.没有充电，则显示电量：
                    let battery_level = deviceInfo["battery_level"] as? Int ?? 0
                    battaryTypeIcon.contentMode = .scaleAspectFit
                    battaryProgressView.isHidden = false
                    if battery_level < 20{
                        battaryTypeIcon.image = UIImage(named: "power_red_empty")
                        battaryProgressView.backgroundColor = COLORFROMRGB(r: 252, 33, 37, alpha: 1)
                        battaryProgressViewWidth.constant = CGFloat(24 * Float(battery_level)/Float(100))
                    }else{
                        battaryTypeIcon.image = UIImage(named: "power_green_empty")
                        battaryProgressView.backgroundColor = COLORFROMRGB(r: 91, 209, 131, alpha: 1)
                        battaryProgressViewWidth.constant = CGFloat(24 * Float(battery_level)/Float(100))
                    }
                }
            }
        }
        
    }
    
    @IBAction func clickMoreButton(_ sender: Any) {
        clickMoreButtonBlock?()
    }
    
    
}
