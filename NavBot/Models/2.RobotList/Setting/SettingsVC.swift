
import UIKit
import SystemConfiguration.CaptiveNetwork
import CoreLocation

class SettingsVC: UIViewController, CLLocationManagerDelegate{

    
    @IBOutlet weak var deviceTypeLogo: UIImageView!
    @IBOutlet weak var RobotNameLabel: UILabel!
    @IBOutlet weak var RobotNameLabelWidth: NSLayoutConstraint!
    
    @IBOutlet weak var deviceIdLabel: UILabel!
    
    @IBOutlet weak var serverLabel: UILabel!
    @IBOutlet weak var clientLabel: UILabel!
    
    @IBOutlet weak var wifiAddressView: UIView!
    @IBOutlet weak var wifiAddressLabel: UILabel!
    @IBOutlet weak var wifiAddressViewHeight: NSLayoutConstraint!//86
    
    @IBOutlet weak var clientContentView: UIView!
    @IBOutlet weak var clientContentViewHeight: NSLayoutConstraint!//172
    
    @IBOutlet weak var wifiNameTFD: UITextField!
    @IBOutlet weak var passwordTFD: UITextField!
    @IBOutlet weak var cloudTokenTFD: UITextField!
    @IBOutlet weak var OpenAiTokenTFD: UITextField!
    
    var current_device_info = [String: Any]()
    var uuid_this_v = ""
    //默认为Server
    //Server/Client
    var mode_type = "Server"
    var currentHUDMessage: MBProgressHUD!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        refreshUIWithModeType()
    }
    //MARK: 1.初始化页面
    func initUI(){
        
        uuid_this_v = "DeviceSettingVC_" + getRandomDigitsString()
        
        //在XIB中设置无效？
        serverLabel.layer.masksToBounds = true
        clientLabel.layer.masksToBounds = true
        
        //设置基础信息：
        /*
         [
         "battery_voltage": 5.524,
         "centigrade": 0,
         "expression": [],
         "pcb_version": 1,
         "openAI_token": Not yet implemented.,
         "name": navbot_en01_1111,
         "IP": 0.0.0.0,
         "mac": F8B3B7A12D0A,
         "type": get_device_info,
         "cloud_token": Not yet implemented.,
         "battery_level": 0,
         "charge": 0
         ]
         */
        //(0).获取用户信息：
        let device_info = jsonStringToDict(current_device_info["device_info"] as? String ?? "") ?? [String: Any]()
        
        //(1).Logo：
        let deviceName = current_device_info["name"] as? String ?? ""
        if deviceName.contains("en01"){
            deviceTypeLogo.image = UIImage(named: "device_icon_ES01")
        }
        if deviceName.contains("es02"){
            deviceTypeLogo.image = UIImage(named: "device_icon_ES02")
        }
        
        //(2).name：
        var nickName = deviceName
        if let current_nickName = device_info["name"] as? String,
           current_nickName.count > 0{
            nickName = current_nickName
        }
        RobotNameLabel.text = nickName
       
        //(3).Device ID:
        let deviceID = device_info["mac"] as? String ?? ""
        deviceIdLabel.text = "Device ID: " + deviceID
        
        //(4).Wifi-Mode: Server
        //Ip Address: 192.168.1.11（默认）
        let device_ip = device_info["IP"] as? String ?? "192.168.1.11"
        wifiAddressLabel.text = device_ip
        
        //(5).Wifi-Mode: Client
        getCurrentIphoneWifiInfi()
        //监听回到前台
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        //WiFiName
        if let WiFiName = device_info["WiFiName"] as? String{
            wifiNameTFD.text = WiFiName
        }
        //WiFiPassword
        if let WiFiPassword = device_info["WiFiPassword"] as? String{
            passwordTFD.text = WiFiPassword
        }
        //cloud_token
        if let cloud_token = device_info["cloud_token"] as? String{
            cloudTokenTFD.text = cloud_token
        }
        //openAI_token
        if let openAI_token = device_info["openAI_token"] as? String{
            OpenAiTokenTFD.text = openAI_token
        }
        
        //通知
        NotificationCenter.default.addObserver(self, selector: #selector(refreshDeviceInfo), name: NSNotification.Name(rawValue: "UpdateLocalDeviceList"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setWifiSuccess), name: NSNotification.Name(rawValue: "SetWifi_success"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setWifiFail), name: NSNotification.Name(rawValue: "SetWifi_fail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(saveCloudTokenSuccess), name: NSNotification.Name(rawValue: "SaveCloudToken_success"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(saveCloudTokenFail), name: NSNotification.Name(rawValue: "SaveCloudToken_fail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(saveOpenAITokenSuccess), name: NSNotification.Name(rawValue: "SaveOpenAIToken_success"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(saveOpenAITokenFail), name: NSNotification.Name(rawValue: "SaveOpenAIToken_fail"), object: nil)
        
    }
    @IBAction func clickBackButton(_ sender: Any) {
        dismiss(animated: true)
    }
    
    //MARK: 2.修改设备名称
    @IBAction func clickChangeRobotNameButton(_ sender: Any) {
        if BluetoothManager.shared.device_connected_status != .connected{
            MBProgressHUD.showTitleAndSubTitle(title: "Device not connected!", subTitle: "", view: view)
        }else{
            let alertView = ChangeTextFieldAlertView(frame: UIScreen.main.bounds)
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else{return}
            delegate.window?.addSubview(alertView)
            alertView.current_device_info = current_device_info
            if let deviceInfo = jsonStringToDict(current_device_info["device_info"] as? String ?? ""){
                let deviceName = current_device_info["name"] as? String ?? ""
                var nickName = deviceName
                if let current_nickName = deviceInfo["name"] as? String,
                   current_nickName.count > 0{
                    nickName = current_nickName
                }
                alertView.contentTFD.text = nickName
            }
        }
    }
    @objc func refreshDeviceInfo(){
        //从本地中获取该设备的信息
        let allScanedDevices = UserDefaults.standard.value(forKey: "allScanedDevices") as? [[String: Any]] ?? [[String: Any]]()
        var currentDeviceInfo = [String: Any]()
        for value in allScanedDevices{
            if (value["identifier"] as? String ?? "") == BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString{
                currentDeviceInfo = value
            }
        }
        //更新数据：
        current_device_info = currentDeviceInfo
        initUI()
    }
    //MARK: 3.校验设备--三步
    //(1).第一步-弹出询问弹窗:
    //-->点击按钮“Cancel”: 不发送指令
    //-->点击按钮“Start Calibration”: 发送指令(off_servo) + 下一步
    //(2).第二步-操作弹窗：
    //-->点击按钮“Cancel”: 发送指令(on_servo)
    //-->点击按钮“Next: 不发送指令 + 下一步
    //(3).第三步-操作弹窗：
    //-->进度条一分钟
    //-->点击按钮“Cancel”: 发送指令：on_servo
    //-->点击按钮“Next: 发送指令calibrate_servo + 下一步
    //(4).展示成功界面
    //-->进度条一分钟
    //-->展示成功页面
    @IBAction func clickAutomaticServoCalibrationDescribleButton(_ sender: Any) {
        MBProgressHUD.showTitleAndSubTitleLongTime(title: "Click to automatically calibrate the servo motors for proper alignment and movement.", subTitle: "", view: view)
    }
    //(1).弹出询问弹窗
    @IBAction func clickCalibrateButton(_ sender: Any) {
        let alertView = CalibrateAskAlertView(frame: UIScreen.main.bounds)
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else{return}
        delegate.window?.addSubview(alertView)
        alertView.clickStartCalibrateBlock = {
            if BluetoothManager.shared.device_connected_status != .connected{
                MBProgressHUD.ShowSuccessMBProgresssHUD(view: self.view, title: "Device not connected!") {
                    alertView.removeFromSuperview()
                }
            }else{
                alertView.removeFromSuperview()
                //弹出进度条弹窗
                OffServoBluetoothManager.shared.sendBluetoothDataWith(type: self.uuid_this_v)
                let alertView1 = CalibrateProgressingView(frame: UIScreen.main.bounds)
                guard let delegate1 = UIApplication.shared.delegate as? AppDelegate else{return}
                delegate1.window?.addSubview(alertView1)
                //模拟操作
                var number = 0
                let timer = Timer(timeInterval: 0.05, repeats: true) { timer in
                    if number > 100{
                        timer.invalidate()
                    }else{
                        alertView1.updateProgressViewWithNumber(progressNumber: number)
                    }
                    number += 1
                }
                RunLoop.current.add(timer, forMode: .common)
                //模拟操作完成
                alertView1.succeesBlock = {
                    self.startToFirstSetpCalibrate()
                }
            }
        }
    }
    //(2).第一步操作弹窗
    func startToFirstSetpCalibrate(){
        let alertView = CalibrateFirstStepView(frame: UIScreen.main.bounds)
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else{return}
        delegate.window?.addSubview(alertView)
        alertView.clickCancelButtonBlock = {
            if BluetoothManager.shared.device_connected_status != .connected{
                alertView.removeFromSuperview()
            }else{
                OnServoBluetoothManager.shared.sendBluetoothDataWith(type: self.uuid_this_v)
                alertView.removeFromSuperview()
            }
        }
        alertView.clickNextButtonBlock = {
            if BluetoothManager.shared.device_connected_status != .connected{
                MBProgressHUD.ShowSuccessMBProgresssHUD(view: self.view, title: "Device not connected!") {
                    alertView.removeFromSuperview()
                }
            }else{
                alertView.removeFromSuperview()
                self.startToSecondSetpCalibrate()
            }
        }
    }
    //(3).第二步操作弹窗
    func startToSecondSetpCalibrate(){
        let alertView = CalibrateSecondStepView(frame: UIScreen.main.bounds)
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else{return}
        delegate.window?.addSubview(alertView)
        alertView.clickCancelButtonBlock = {
            if BluetoothManager.shared.device_connected_status != .connected{
                alertView.removeFromSuperview()
            }else{
                OnServoBluetoothManager.shared.sendBluetoothDataWith(type: self.uuid_this_v)
                alertView.removeFromSuperview()
            }
        }
        alertView.clickNextButtonBlock = {
            if BluetoothManager.shared.device_connected_status != .connected{
                MBProgressHUD.ShowSuccessMBProgresssHUD(view: self.view, title: "Device not connected!") {
                    alertView.removeFromSuperview()
                }
            }else{
                alertView.removeFromSuperview()
                //弹出进度条弹窗
                CalibrateServoBuluetoothManager.shared.sendBluetoothDataWith(type: self.uuid_this_v)
                let alertView1 = CalibrateProgressingView(frame: UIScreen.main.bounds)
                guard let delegate1 = UIApplication.shared.delegate as? AppDelegate else{return}
                delegate1.window?.addSubview(alertView1)
                //模拟操作
                var number = 0
                let timer = Timer(timeInterval: 0.05, repeats: true) { timer in
                    if number > 100{
                        timer.invalidate()
                    }else{
                        alertView1.updateProgressViewWithNumber(progressNumber: number)
                    }
                    number += 1
                }
                RunLoop.current.add(timer, forMode: .common)
                //模拟操作完成
                alertView1.succeesBlock = {
                    self.endToSecondSetpCalibrate()
                }
            }
        }
    }
    //(4).结束校验:
    func endToSecondSetpCalibrate(){
        let alertView = CalibrateSuccessView(frame: UIScreen.main.bounds)
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else{return}
        delegate.window?.addSubview(alertView)
        DispatchQueue.main.asyncAfter(deadline: .now()+2.0, execute: {
            alertView.removeFromSuperview()
        })
    }
    //MARK: 3.切换Mode：Server/Client
    @IBAction func selectServerTap(_ sender: Any) {
        if mode_type == "Server"{
            return
        }
        mode_type = "Server"
        refreshUIWithModeType()
    }
    
    @IBAction func selectClientTap(_ sender: Any) {
        if mode_type == "Client"{
            return
        }
        mode_type = "Client"
        refreshUIWithModeType()
    }

    func refreshUIWithModeType(){
        getCurrentIphoneWifiInfi()
        if mode_type == "Server"{
            serverLabel.textColor = COLORFROMRGB(r: 0, 0, 0, alpha: 1)
            serverLabel.backgroundColor = COLORFROMRGB(r: 52, 199, 89, alpha: 1)
            clientLabel.textColor = COLORFROMRGB(r: 148, 151, 153, alpha: 1)
            clientLabel.backgroundColor = .clear
            
            wifiAddressView.isHidden = false
            wifiAddressViewHeight.constant = 86
            
            clientContentView.isHidden = true
            clientContentViewHeight.constant = 0
        }else if mode_type == "Client"{
            clientLabel.textColor = COLORFROMRGB(r: 0, 0, 0, alpha: 1)
            clientLabel.backgroundColor = COLORFROMRGB(r: 52, 199, 89, alpha: 1)
            serverLabel.textColor = COLORFROMRGB(r: 148, 151, 153, alpha: 1)
            serverLabel.backgroundColor = .clear
            
            wifiAddressView.isHidden = true
            wifiAddressViewHeight.constant = 0
            
            clientContentView.isHidden = false
            clientContentViewHeight.constant = 172
        }
    }
    
    //MARK: 4.处理iPhone当前的Wifi数据
    private var locationManager: CLLocationManager?
    func getCurrentIphoneWifiInfi(){
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        // iOS 13+ 必须请求位置权限
        locationManager?.requestWhenInUseAuthorization()
    }
    //去过去后台修改了wifi，然后回到了前台
    @objc func appWillEnterForeground(){
        print("回到前台")
        getCurrentIphoneWifiInfi()
    }
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if let wifiName = getCurrentSSID() {
                print("当前 Wi-Fi 名称: \(wifiName)")
                wifiNameTFD.text = wifiName
            } else {
                print("无法获取 Wi-Fi 名称")
                wifiNameTFD.text = ""
            }
        case .denied, .restricted:
            print("用户拒绝了定位权限，无法获取 Wi-Fi 名称")
            wifiNameTFD.text = ""
        case .notDetermined:
            print("权限未确定")
            wifiNameTFD.text = ""
        @unknown default:
            break
        }
    }
    //获取当前 Wi-Fi 名称 (SSID)
    func getCurrentSSID() -> String? {
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
            return nil
        }
        for interface in interfaces {
            if let unsafeInterfaceData = CNCopyCurrentNetworkInfo(interface as CFString) as NSDictionary? {
                if let ssid = unsafeInterfaceData["SSID"] as? String {
                    return ssid
                }
            }
        }
        return nil
    }
    
    //MARK: 5.Other Taps
    @IBAction func clickCloudTokenDescribleButton(_ sender: Any) {
        MBProgressHUD.showTitleAndSubTitleLongTime(title: "This token is used to authenticate and communicate securely with the cloud service.", subTitle: "", view: view)
    }

    @IBAction func clickOpenAiTokenDescribleButton(_ sender: Any) {
        MBProgressHUD.showTitleAndSubTitleLongTime(title: "This token allows communication with OpenAI services for voice control and AI features.", subTitle: "", view: view)
    }
    
    //MARK: 6.保存设备信息
    //MARK: 6.1.保存设备基本信息
    @IBAction func clickOKButton(_ sender: Any) {
        //6.1.保存Wifi信息
        //(1).Server:
        /*
         {“type”:”sys_wifi”; “state”: “server”;}
         */
        //(2).Client:
        /*
        {“type”:”sys_wifi”; “ssid”:”*************”; “password”:”***********”; “state”: “client”;}
        */
        if BluetoothManager.shared.device_connected_status != .connected{
            MBProgressHUD.showTitleAndSubTitle(title: "Device not connected!", subTitle: "", view: view)
            return
        }
        getCurrentIphoneWifiInfi()
        self.currentHUDMessage = MBProgressHUD.showJuHuaAndTitle(title: "Saving Wi-Fi settings...", view: view)
        DispatchQueue.main.asyncAfter(deadline: .now()+1.0, execute: {
            var paramDict = [String: Any]()
            if ((self.wifiNameTFD.text ?? "").count <= 0){
                //没有连接到Wi-Fi
                paramDict["type"] = "sys_wifi"
                paramDict["state"] = "close"
            }else if self.mode_type == "Server"{
                paramDict["type"] = "sys_wifi"
                paramDict["state"] = "server"
            }else if self.mode_type == "Client"{
                paramDict["type"] = "sys_wifi"
                paramDict["state"] = "client"
                paramDict["ssid"] = self.wifiNameTFD.text
                if ((self.passwordTFD.text ?? "").count <= 0){
                    MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
                    MBProgressHUD.showTitleAndSubTitle(title: "Don't get your current wifi passwod.", subTitle: "", view: self.view)
                    return
                }
                paramDict["password"] = self.passwordTFD.text
            }
            SetWifiBluetoothManager.shared.sendBluetoothDataWith(type: self.uuid_this_v, paramDict: paramDict)
        })
    }
    @objc func setWifiSuccess(){
        if SetWifiBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        //MBProgressHUD.showTitleAndSubTitle(title: "Wi-Fi settings saved successfully.", subTitle: "", view: view)
        //将数据保存进入本地数据中:
        //(1).判断本地中是否已经存在该设备了
        var allScanedDevices = UserDefaults.standard.value(forKey: "allScanedDevices") as? [[String: Any]] ?? [[String: Any]]()
        var currentIndex: Int? = nil
        for (index, value) in allScanedDevices.enumerated(){
            if (value["identifier"] as? String ?? "") == BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString{
                currentIndex = index
            }
        }
        if currentIndex == nil{
            //继续下一步
            saveCloudToken()
            return
        }
        //(2).获取当前设备的信息:
        var device_info = jsonStringToDict(current_device_info["device_info"] as? String ?? "") ?? [String: Any]()
        device_info["WiFiName"] = wifiNameTFD.text!
        device_info["WiFiPassword"] = passwordTFD.text!
        if let jsonData = try? JSONSerialization.data(withJSONObject: device_info, options: []){
            let jsonString = String(data: jsonData, encoding: .utf8)
            current_device_info["device_info"] = jsonString
        }
        
        //(3).替换本地数据：
        allScanedDevices[currentIndex!] = current_device_info
        
        //(4).存储本地数据:
        UserDefaults.standard.setValue(allScanedDevices, forKey: "allScanedDevices")
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateLocalDeviceList"), object: nil)
        print("设置页面--保存OpenAI Token--本地设备数据为：",allScanedDevices)
        
        
        saveCloudToken()
    }
    @objc func setWifiFail(){
        if SetWifiBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        MBProgressHUD.showTitleAndSubTitle(title: "Wi-Fi settings saved failed", subTitle: "", view: view)
        saveCloudToken()
    }
    
    //MARK: 6.2.保存Cloud Token
    func saveCloudToken(){
        if BluetoothManager.shared.device_connected_status != .connected{
            MBProgressHUD.showTitleAndSubTitle(title: "Device not connected!", subTitle: "", view: view)
            return
        }
        //判断Cloud Token是否改变了
        let device_info = jsonStringToDict(current_device_info["device_info"] as? String ?? "") ?? [String: Any]()
        let current_cloud_token = device_info["cloud_token"] as? String ?? ""
        if ((cloudTokenTFD.text ?? "") == current_cloud_token){
            saveOpenAIToken()
        }else{
            self.currentHUDMessage = MBProgressHUD.showJuHuaAndTitle(title: "Saving Cloud Token...", view: view)
            let paramDict = ["type": "set_cloud_token", "token": cloudTokenTFD.text!]
            SaveCloudTokenBluetoothManager.shared.sendBluetoothDataWith(type: uuid_this_v, paramDict: paramDict)
        }
    }
    @objc func saveCloudTokenSuccess(){
        if SaveCloudTokenBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        //MBProgressHUD.showTitleAndSubTitle(title: "Saving Cloud Token successfully.", subTitle: "", view: view)
        
        //将数据保存进入本地数据中:
        //(1).判断本地中是否已经存在该设备了
        var allScanedDevices = UserDefaults.standard.value(forKey: "allScanedDevices") as? [[String: Any]] ?? [[String: Any]]()
        var currentIndex: Int? = nil
        for (index, value) in allScanedDevices.enumerated(){
            if (value["identifier"] as? String ?? "") == BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString{
                currentIndex = index
            }
        }
        if currentIndex == nil{
            //继续下一步
            saveOpenAIToken()
            return
        }
        //(2).获取当前设备的信息:
        var device_info = jsonStringToDict(current_device_info["device_info"] as? String ?? "") ?? [String: Any]()
        device_info["cloud_token"] = cloudTokenTFD.text!
        if let jsonData = try? JSONSerialization.data(withJSONObject: device_info, options: []){
            let jsonString = String(data: jsonData, encoding: .utf8)
            current_device_info["device_info"] = jsonString
        }
        
        //(3).替换本地数据：
        allScanedDevices[currentIndex!] = current_device_info
        
        //(4).存储本地数据:
        UserDefaults.standard.setValue(allScanedDevices, forKey: "allScanedDevices")
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateLocalDeviceList"), object: nil)
        print("设置页面--保存Cloud Token--本地设备数据为：",allScanedDevices)
        
        //继续下一步
        saveOpenAIToken()
    }
    @objc func saveCloudTokenFail(){
        if SaveCloudTokenBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        MBProgressHUD.showTitleAndSubTitle(title: "Saving Cloud Token failed.", subTitle: "", view: view)
        saveOpenAIToken()
    }
    //MARK: 6.3.保存Open AI Cloud
    func saveOpenAIToken(){
        if BluetoothManager.shared.device_connected_status != .connected{
            MBProgressHUD.showTitleAndSubTitle(title: "Device not connected!", subTitle: "", view: view)
            return
        }
        //判断Open AI Token是否改变了
        let device_info = jsonStringToDict(current_device_info["device_info"] as? String ?? "") ?? [String: Any]()
        let current_openAI_token = device_info["openAI_token"] as? String ?? ""
        if ((OpenAiTokenTFD.text ?? "") != current_openAI_token){
            self.currentHUDMessage = MBProgressHUD.showJuHuaAndTitle(title: "Saving OpenAI Token...", view: view)
            let paramDict = ["type": "set_openai_token", "token": OpenAiTokenTFD.text!]
            SaveOpenAITokenBluetoothManager.shared.sendBluetoothDataWith(type: uuid_this_v, paramDict: paramDict)
        }
    }
    @objc func saveOpenAITokenSuccess(){
        if SaveOpenAITokenBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        //MBProgressHUD.showTitleAndSubTitle(title: "Saving OpenAI Token successfully.", subTitle: "", view: view)
        //将数据保存进入本地数据中:
        //(1).判断本地中是否已经存在该设备了
        var allScanedDevices = UserDefaults.standard.value(forKey: "allScanedDevices") as? [[String: Any]] ?? [[String: Any]]()
        var currentIndex: Int? = nil
        for (index, value) in allScanedDevices.enumerated(){
            if (value["identifier"] as? String ?? "") == BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString{
                currentIndex = index
            }
        }
        if currentIndex == nil{
            //继续下一步
            saveOpenAIToken()
            return
        }
        //(2).获取当前设备的信息:
        var device_info = jsonStringToDict(current_device_info["device_info"] as? String ?? "") ?? [String: Any]()
        device_info["openAI_token"] = OpenAiTokenTFD.text!
        if let jsonData = try? JSONSerialization.data(withJSONObject: device_info, options: []){
            let jsonString = String(data: jsonData, encoding: .utf8)
            current_device_info["device_info"] = jsonString
        }
        
        //(3).替换本地数据：
        allScanedDevices[currentIndex!] = current_device_info
        
        //(4).存储本地数据:
        UserDefaults.standard.setValue(allScanedDevices, forKey: "allScanedDevices")
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateLocalDeviceList"), object: nil)
        print("设置页面--保存OpenAI Token--本地设备数据为：",allScanedDevices)
    }
    @objc func saveOpenAITokenFail(){
        if SaveOpenAITokenBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        MBProgressHUD.showTitleAndSubTitle(title: "Saving OpenAI Token failed.", subTitle: "", view: view)
    }
}
