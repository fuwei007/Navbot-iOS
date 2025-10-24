
import UIKit

class ChangeTextFieldAlertView: UIView {

    @IBOutlet weak var contentViewBottomCons: NSLayoutConstraint!//24
    @IBOutlet weak var widgetTitleLabel: UILabel!
    @IBOutlet weak var contentTFD: UITextField!
    
    var current_device_info = [String: Any]()
    var uuid_this_v = ""
    var currentHUDMessage: MBProgressHUD!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addViewOfXIB()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addViewOfXIB(){
        let nib = UINib(nibName: "ChangeTextFieldAlertView", bundle: Bundle.main)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else{
            return
        }
        view.frame = UIScreen.main.bounds
        view.backgroundColor = COLORFROMRGB(r: 0, 0, 0, alpha: 0.5)
        self.addSubview(view)
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(clickCloseFunc(tap:)))
        self.addGestureRecognizer(tap)
        
        // 添加键盘监听
        NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(keyboardWillShow(_:)),
                    name: UIResponder.keyboardWillShowNotification,
                    object: nil
        )
        NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(keyboardWillHide(_:)),
                    name: UIResponder.keyboardWillHideNotification,
                    object: nil
        )
        
        uuid_this_v = "ChangeDeviceName_alertView_" + getRandomDigitsString()
        NotificationCenter.default.addObserver(self, selector: #selector(setDeviceNameSuccess), name: NSNotification.Name(rawValue: "SetDeviceName_success"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setDeviceNameFail), name: NSNotification.Name(rawValue: "SetDeviceName_fail"), object: nil)
    }
    @objc func clickCloseFunc(tap: UITapGestureRecognizer){
        let tapPoint = tap.location(in: self)
        let contentFrame = CGRect(x: kScreen_WIDTH/2-416/2, y: kScreen_HEIGHT-contentViewBottomCons.constant-206, width: 416, height: 206)
        if contentFrame.contains(tapPoint) {
            return
        }else{
            self.removeFromSuperview()
        }
    }
    // 键盘显示
    @objc func keyboardWillShow(_ notification: Notification) {
        print("🔼 键盘弹出")
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
          print("键盘高度：\(keyboardFrame.height)")
            contentViewBottomCons.constant = keyboardFrame.height - 30
       }
    }

    //键盘隐藏
    @objc func keyboardWillHide(_ notification: Notification) {
        contentViewBottomCons.constant = 24
    }
    //MARK: 1.发送命令--设置别名
    @IBAction func clickOkButton(_ sender: Any) {
        
        self.contentTFD.resignFirstResponder()
        
        if (contentTFD.text?.count == 0){
            MBProgressHUD.showErrorText(text: "Please enter name.", view: self)
            return
        }
        if BluetoothManager.shared.current_connecting_CBPeripheral?.state != .connected{
            MBProgressHUD.ShowSuccessMBProgresssHUD(view: self, title: "Device not connected!") {
                self.removeFromSuperview()
            }
            return
        }
        self.currentHUDMessage = MBProgressHUD.showJuHuaAndTitle(title: "Loading...", view: self)
        let send_param_dict = ["type":"set_name","name":contentTFD.text!]
        SetDeviceNameBluetoothManager.shared.sendBluetoothDataWith(type: uuid_this_v, send_param_dict: send_param_dict)
    }
    //MARK:2.通知--设置别名--成功
    @objc func setDeviceNameSuccess(){
        if (SetDeviceNameBluetoothManager.shared.fromVCType != uuid_this_v){
            return
        }
        //(1).判断本地中是否已经存在该设备了
        var allScanedDevices = UserDefaults.standard.value(forKey: "allScanedDevices") as? [[String: Any]] ?? [[String: Any]]()
        var currentIndex: Int? = nil
        for (index, value) in allScanedDevices.enumerated(){
            if (value["identifier"] as? String ?? "") == BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString{
                currentIndex = index
            }
        }
        if currentIndex == nil{
            MBProgressHUD.ShowSuccessMBProgresssHUD(view: self, title: "Successfully.") {
                DispatchQueue.main.async {
                    self.contentTFD.resignFirstResponder()
                    self.removeFromSuperview()
                }
            }
            return
        }
        //(2).将该设信息修改后重新存储：
        var current_connected_device = allScanedDevices[currentIndex!]
        current_connected_device["name"] = BluetoothManager.shared.current_connecting_CBPeripheral?.name ?? ""
        if let deviceInfo = jsonStringToDict(current_connected_device["device_info"] as? String ?? ""){
            var new_deviceInfo = deviceInfo
            new_deviceInfo["name"] = contentTFD.text!
            if let jsonData = try? JSONSerialization.data(withJSONObject: new_deviceInfo, options: []){
                let jsonString = String(data: jsonData, encoding: .utf8)
                current_connected_device["device_info"] = jsonString
            }
        }
        allScanedDevices[currentIndex!] = current_connected_device
        
        //(3).存储本地数据:
        UserDefaults.standard.setValue(allScanedDevices, forKey: "allScanedDevices")
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateLocalDeviceList"), object: nil)
        print("设备列表页面--设备成功连接--成功获取设备信息--本地设备数据为：",allScanedDevices)
        
        //(4).成功显示：
        MBProgressHUD.ShowSuccessMBProgresssHUD(view: self, title: "Successfully.") {
            DispatchQueue.main.async {
                self.contentTFD.resignFirstResponder()
                self.removeFromSuperview()
            }
        }
    }
    //MARK:2.通知--设置别名--失败
    @objc func setDeviceNameFail(){
        if (SetDeviceNameBluetoothManager.shared.fromVCType != uuid_this_v){
            return
        }
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        MBProgressHUD.showErrorText(text: "Failed to set device name.", view: self)
    }
    
    deinit {
           // 移除监听
           NotificationCenter.default.removeObserver(self)
       }
}
