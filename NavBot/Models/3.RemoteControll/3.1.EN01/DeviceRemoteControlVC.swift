
import UIKit
import CoreBluetooth

class DeviceRemoteControlVC: UIViewController, ZYBluetoothHandlerDelegate {
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    
    @IBOutlet weak var power_background_icon: UIImageView!
    @IBOutlet weak var power_content_view: UIView!
    @IBOutlet weak var power_content_view_width: NSLayoutConstraint!
    
    @IBOutlet weak var standbySiwtchButton: UISwitch!
    
    @IBOutlet weak var bluetoothItem: UIView!
    @IBOutlet weak var bluetoothIcon: UIImageView!
    @IBOutlet weak var wifiItem: UIView!
    @IBOutlet weak var wifiIcon: UIImageView!
    
    @IBOutlet weak var directionalControllerView: UIView!
    
    @IBOutlet weak var powerButton: UIButton!
    
    @IBOutlet weak var faceView: UIView!
    @IBOutlet weak var faceIcon: UIImageView!
    @IBOutlet weak var faceLabel: UILabel!
    
    lazy var sliderViewOfBaseHeight = {
        let view = MySliderView(frame: CGRect(x: kScreen_WIDTH/2-200+28, y: safeTop()+60+20, width: 100, height: kScreen_HEIGHT-140))
        view.titleLabel.text = "Base Height"
        view.minimumProgressValue = 32.0
        view.maxProgressValue = 85.0
        view.unitValue = "mm"
        view.endTapgestureWithValue = {progressValue in
            self.adjustDeviceHeight(progressValue: progressValue)
        }
        return view
    }()
    
    lazy var sliderViewOfRoll = {
        let view = MySliderView(frame: CGRect(x: kScreen_WIDTH/2-200+28+100, y: safeTop()+60+20, width: 100, height: kScreen_HEIGHT-140))
        view.titleLabel.text = "Roll"
        view.minimumProgressValue = -30.0
        view.maxProgressValue = 30.0
        view.unitValue = "°"
        view.endTapgestureWithValue = { progressValue in
            print("Roll-->Invoke the callback to send the command：",progressValue)
            self.adjustDeviceRoll(progressValue: progressValue)
        }
        return view
    }()
    
    lazy var sliderViewOfLinearVel = {
        let view = MySliderView(frame: CGRect(x: kScreen_WIDTH/2-200+28+200, y: safeTop()+60+20, width: 100, height: kScreen_HEIGHT-140))
        view.titleLabel.text = "Linear Vel"
        view.minimumProgressValue = -200.0
        view.maxProgressValue = 200.0
        view.unitValue = "mm/s"
        view.endTapgestureWithValue = { progressValue in
            print("Linear Vel-->Invoke the callback to send the command：",progressValue)
            self.adjustDeviceLinearVel(progressValue: progressValue)
        }
        return view
    }()
    
    lazy var sliderViewOfAngularVel = {
        let view = MySliderView(frame: CGRect(x: kScreen_WIDTH/2-200+28+300, y: safeTop()+60+20, width: 100, height: kScreen_HEIGHT-140))
        view.titleLabel.text = "Angular Vel"
        view.minimumProgressValue = -100.0
        view.maxProgressValue = 100.0
        view.unitValue = "°/s"
        view.endTapgestureWithValue = { progressValue in
            print("Angular Vel-->Invoke the callback to send the command：",progressValue)
            self.adjustDeviceAngularVel(progressValue: progressValue)
        }
        return view
    }()
    
    lazy var directionalControlView = {
        let view = DirectionalControlView(frame: CGRect(x: 0, y: 0, width: 120, height:120))
        view.updateCoordinateSystemPoint = { coordinatePoint in
            print("Updating coordinates.:\(coordinatePoint)")
            //(1).判断是否连接设备:
            var currenDeviceIsConnected = false
            if BluetoothManager.shared.device_connected_status == .connected,
               (BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString ?? "") == (self.current_device_info["identifier"] as? String ?? ""){
                currenDeviceIsConnected = true
            }
            if (currenDeviceIsConnected == false){
                MBProgressHUD.showTitleAndSubTitle(title: "Device not connected!", subTitle: "", view: self.view)
                return
            }
            //(2).判断是否开启了平衡:
            if !StandbyBluetoothManager.shared.current_isStandByStatuse{
                MBProgressHUD.showTitleAndSubTitle(title: "Please turn on the ‘ROBOT GO’ button first.", subTitle: "", view: self.view)
                return
            }
            //(3).设置转向
            // Original coordinate X range: -60 <--> 60
            // Original coordinate Y range: -60 <--> 60
            // Device coordinate X range:   -100 <--> 100
            // Device coordinate Y range:   -100 <--> 100
            if (self.mode_type == "Bluetooth"){
                ChangePositionBluetoothManager.shared.x_willChanged = Int32(coordinatePoint.x*100/60)
                ChangePositionBluetoothManager.shared.y_willChanged = Int32(coordinatePoint.y*100/60)
                ChangePositionBluetoothManager.shared.sendBluetoothDataWith(type: self.uuid_this_v)
            }else{
                let param_dict = ["stable":1,"mode":"basic","dir":"stop","joy_y": "\(Int32(coordinatePoint.y*100/60))","joy_x": "\(Int32(coordinatePoint.x*100/60))"]
                WebsocketManager.shared.sendCommad(paramDict: param_dict, sendCommandType: "ChangePosition")
            }
        }
        view.endUpdateCoordinateSystemPoint = { coordinatePoint in
            print("Update coordinates when dragging ends:\(coordinatePoint)")
            if BluetoothManager.shared.current_connecting_CBPeripheral?.state != .connected{
                MBProgressHUD.showTitleAndSubTitle(title: "Device not connected!", subTitle: "", view: self.view)
            }else{
                if !StandbyBluetoothManager.shared.current_isStandByStatuse{
                    MBProgressHUD.showTitleAndSubTitle(title: "Please turn on the ‘ROBOT GO’ button first.", subTitle: "", view: self.view)
                    return
                }
                //Force send termination command
                if ChangePositionBluetoothManager.shared.isSendingData{
                    ChangePositionBluetoothManager.shared.isSendingData = false
                }
                if (BluetoothManager.shared.isReceiveData == "receiving"){
                    BluetoothManager.shared.isReceiveData = "notRecieved"
                }
                ChangePositionBluetoothManager.shared.x_willChanged = 0
                ChangePositionBluetoothManager.shared.y_willChanged = 0
                ChangePositionBluetoothManager.shared.sendBluetoothDataWith(type: self.uuid_this_v)
            }
        }
        return view
    }()
    
    
    var current_device_info = [String: Any]()
    var mode_type = "Bluetooth"
    
    var uuid_this_v = ""
    var currentHUDMessage: MBProgressHUD!
    var backVCBlock: (()->())?
    var current_ScanedDevice = [[String: Any]]()
    
    var connect_websocket_url_string = "wss://hub.navbot.com/ws/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        initBluetooth()
        requestDeviceInfo()
    }
    
    //MARK: 1.初始化页面
    func initUI(){
        
        print("EN01远程操控界面--DviceInfo:\(current_device_info)")
        //(1).渐变色背景
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: kScreen_WIDTH, height: kScreen_HEIGHT)
        gradientLayer.colors = [
            COLORFROMRGB(r: 224, 239, 255, alpha: 1).cgColor,
            COLORFROMRGB(r: 255, 255, 255, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        //(2).设备名称:
        let device_info = jsonStringToDict(current_device_info["device_info"] as? String ?? "") ?? [String: Any]()
        let deviceName = current_device_info["name"] as? String ?? ""
        var nickName = deviceName
        if let current_nickName = device_info["name"] as? String,
           current_nickName.count > 0{
            nickName = current_nickName
        }
        deviceNameLabel.text = nickName
        
        //(3).电量
        //判断设备是否已经链接：
        var currenDeviceIsConnected = false
        if BluetoothManager.shared.device_connected_status == .connected,
           (BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString ?? "") == (current_device_info["identifier"] as? String ?? ""){
            currenDeviceIsConnected = true
        }
        if (currenDeviceIsConnected == false){
            power_background_icon.image = UIImage(named: "power_unknown")
            power_background_icon.contentMode = .scaleAspectFill
            power_content_view.isHidden = true
        }else{
            //判断是否在充电
            let charge = device_info["charge"] as? Bool ?? false
            if (charge == false){
                let battery_level = device_info["battery_level"] as? Int ?? 0
                power_background_icon.contentMode = .scaleAspectFit
                power_content_view.isHidden = false
                if battery_level < 20{
                    power_background_icon.image = UIImage(named: "power_red_empty")
                    power_content_view.backgroundColor = COLORFROMRGB(r: 252, 33, 37, alpha: 1)
                    power_content_view_width.constant = CGFloat(24 * Float(battery_level)/Float(100))
                }else{
                    power_background_icon.image = UIImage(named: "power_green_empty")
                    power_content_view.backgroundColor = COLORFROMRGB(r: 91, 209, 131, alpha: 1)
                    power_content_view_width.constant = CGFloat(24 * Float(battery_level)/Float(100))
                }
            }else{
                power_background_icon.image = UIImage(named: "power_charging")
                power_background_icon.contentMode = .scaleAspectFill
                power_content_view.isHidden = true
            }
        }
        
        //(4).设备是否准备好：保持/关闭--设备平衡
        standbySiwtchButton.contentScaleFactor = 0.7
        standbySiwtchButton.isOn = false
        
        //(5).切换Wifi/Bluetooth
        mode_type = "Bluetooth"
        refreshUIWithModeType()
        
        //(6).设备链接开关
        powerButton.setImage((currenDeviceIsConnected ? UIImage(named: "devic_open") : UIImage(named: "device_off")), for: .normal)
        
        //(7).表情视图--默认图标和表情
        faceIcon.image = UIImage(named: "Robot_face_default")
        faceLabel.text = "Emoji"
        
        //(8).操作设备参数
        view.addSubview(self.sliderViewOfBaseHeight)
        view.addSubview(self.sliderViewOfRoll)
        view.addSubview(self.sliderViewOfLinearVel)
        view.addSubview(self.sliderViewOfAngularVel)
        
        //(9).操作设备转向
        directionalControllerView.addSubview(self.directionalControlView)
    }
    //MARK: 2.初始化蓝牙
    func initBluetooth(){
        
        uuid_this_v = "DeviceRemoteController_" + getRandomDigitsString()
        
        BluetoothManager.shared.fromVCType = uuid_this_v
        BluetoothManager.shared.delegate = self
        
        //添加所有蓝牙相关通知：
        NotificationCenter.default.addObserver(self, selector: #selector(alreadyConnectedDevice), name: NSNotification.Name(rawValue: "setNotifyValueSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getDeviceInfoFail), name: NSNotification.Name(rawValue: "getDeviceInfo_fail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getDeviceInfoSuccess), name: NSNotification.Name(rawValue: "getDeviceInfo_success"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(SetupBaseHeightFail), name: Notification.Name(rawValue: "SetupBaseHeight_fail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SetupBaseHeightSuccess), name: Notification.Name(rawValue: "SetupBaseHeigh_success"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SetupRollFail), name: Notification.Name(rawValue: "SetupRoll_fail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SetupRollSuccess), name: Notification.Name(rawValue: "SetupRoll_success"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SetupLinearVelFail), name: Notification.Name(rawValue: "SetupLinearVel_fail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SetupLinearVelSuccess), name: Notification.Name(rawValue: "SetupLinearVel_success"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SetupAngularVelFail), name: Notification.Name(rawValue: "SetupAngularVel_fail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SetupAngularVelSuccess), name: Notification.Name(rawValue: "SetupAngularVel_success"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(deviceJumpFail), name: Notification.Name(rawValue: "deviceJump_fail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceJumpSuccess), name: Notification.Name(rawValue: "deviceJump_success"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changeDevicePositionFail), name: Notification.Name(rawValue: "ChangeDevicePosition_fail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changeDevicePositionSuccess), name: Notification.Name(rawValue: "ChangeDevicePosition_success"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(standbyDevicenFail), name: Notification.Name(rawValue: "standbyDevice_fail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(standbyDeviceSuccess), name: Notification.Name(rawValue: "standbyDevice_success"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getExpressionFail), name: Notification.Name(rawValue: "GetExpression_fail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getExpressionSuccess), name: Notification.Name(rawValue: "GetExpression_success"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showExpressionFail), name: Notification.Name(rawValue: "ShowExpression_fail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showExpressionSuccess), name: Notification.Name(rawValue: "ShowExpression_success"), object: nil)
        
        //长链接--Socket---相关通知
        NotificationCenter.default.addObserver(self, selector: #selector(connectWebSocketFail), name: Notification.Name(rawValue: "ConnectWebsocketFail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(connectWebSocketSuccess), name: Notification.Name(rawValue: "ConnectWebsocketSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(webSocketDisconnected), name: Notification.Name(rawValue: "WebsocketDisconnected"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(setDeviceStandByWithSocketSuccess), name: Notification.Name(rawValue: "SetDeviceStandByWithSocketSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setDeviceStandByWithSocketFail), name: Notification.Name(rawValue: "SetDeviceStandByWithSocketFail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustDeviceHeightWithSocketSuccess), name: Notification.Name(rawValue: "AdjustDeviceHeightWithSocketSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustDeviceHeightWithSocketFail), name: Notification.Name(rawValue: "AdjustDeviceHeightWithSocketFail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(jumpDeviceWithSocketSuccess), name: Notification.Name(rawValue: "JumpDeviceWithSocketSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(jumpDeviceWithSocketFail), name: Notification.Name(rawValue: "JumpDeviceWithSocketFail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changePositionWithSocketSuccess), name: Notification.Name(rawValue: "ChangePositionWithSocketSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changePositionWithSocketFail), name: Notification.Name(rawValue: "ChangePositionWithSocketFail"), object: nil)
    }
    
    //MARK: 3.获取设备相关参数信息（每次重新链接都重置为默认状态）
    func requestDeviceInfo(){
        sliderViewOfBaseHeight.updateProgressValue(progressValue: 32.0)
        BaseHeightBluetoothManager.shared.baseHeight_current = 32
        BaseHeightBluetoothManager.shared.baseHeight_willChanged = 32
        
        sliderViewOfRoll.updateProgressValue(progressValue: 0)
        RollBluetoothManager.shared.current_roll = 0
        RollBluetoothManager.shared.will_roll = 0
        
        sliderViewOfLinearVel.updateProgressValue(progressValue: 100.0)
        LinearVelBluetoothManager.shared.current_Linear_Vel = 100
        LinearVelBluetoothManager.shared.will_Linear_Vel = 100
        
        sliderViewOfAngularVel.updateProgressValue(progressValue: 50.0)
        AngularVelBluetoothManager.shared.current_Angular_Vel = 50
        AngularVelBluetoothManager.shared.will_Angular_Vel = 50
    }
    @IBAction func clickBackButton(_ sender: Any) {
        backVCBlock?()
        dismiss(animated: true)
    }
    
    //MARK: 4.链接设备/断开连接
    @IBAction func clickPowerButton(_ sender: Any) {
        var currenDeviceIsConnected = false
        if BluetoothManager.shared.device_connected_status == .connected,
           (BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString ?? "") == (current_device_info["identifier"] as? String ?? ""){
            currenDeviceIsConnected = true
        }
        if (currenDeviceIsConnected == true){
            //1.已连接--去断开设备
            BluetoothManager.shared.fromVCType = self.uuid_this_v
            BluetoothManager.shared.disconnectDevice()
        }else{
            //2.未连接--去连接设备
            var isHaveThisDevice = false
            for item in self.current_ScanedDevice{
                if let current_CBPeripheral = item["device"] as? CBPeripheral,
                   current_CBPeripheral.identifier.uuidString == BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString,
                   current_CBPeripheral.name == BluetoothManager.shared.current_connecting_CBPeripheral?.name{
                    isHaveThisDevice = true
                    self.currentHUDMessage = MBProgressHUD.showJuHuaAndTitle(title: "Connecting...", view: self.view)
                    BluetoothManager.shared.startConnectionDevice(device: current_CBPeripheral)
                }
            }
            if !isHaveThisDevice{
                let AlertVC = UIAlertController(title: "Device not found.", message: "Does it return the device list?", preferredStyle: .alert)
                let confirmBtn = UIAlertAction(title: "Yes", style: .default) { alert in
                    self.clickBackButton(UIButton())
                }
                AlertVC.addAction(confirmBtn)
                let cancelBtn = UIAlertAction(title: "No", style: .cancel)
                AlertVC.addAction(cancelBtn)
                self.present(AlertVC, animated: true)
            }
        }
    }
    //切换设备链接状态时，更新视图
    func refreshUIForChangeDeviceConnectedStatus(){
        let device_info = jsonStringToDict(current_device_info["device_info"] as? String ?? "") ?? [String: Any]()
        
        //(1).设备名称:
        let deviceName = current_device_info["name"] as? String ?? ""
        var nickName = deviceName
        if let current_nickName = device_info["name"] as? String,
           current_nickName.count > 0{
            nickName = current_nickName
        }
        deviceNameLabel.text = nickName
        
        //(2).电量
        //判断设备是否已经链接：
        var currenDeviceIsConnected = false
        if BluetoothManager.shared.device_connected_status == .connected,
           (BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString ?? "") == (current_device_info["identifier"] as? String ?? ""){
            currenDeviceIsConnected = true
        }
        if (currenDeviceIsConnected == false){
            power_background_icon.image = UIImage(named: "power_unknown")
            power_background_icon.contentMode = .scaleAspectFill
            power_content_view.isHidden = true
        }else{
            //判断是否在充电
            let charge = device_info["charge"] as? Bool ?? false
            if (charge == false){
                let battery_level = device_info["battery_level"] as? Int ?? 0
                power_background_icon.contentMode = .scaleAspectFit
                power_content_view.isHidden = false
                if battery_level < 20{
                    power_background_icon.image = UIImage(named: "power_red_empty")
                    power_content_view.backgroundColor = COLORFROMRGB(r: 252, 33, 37, alpha: 1)
                    power_content_view_width.constant = CGFloat(24 * Float(battery_level)/Float(100))
                }else{
                    power_background_icon.image = UIImage(named: "power_green_empty")
                    power_content_view.backgroundColor = COLORFROMRGB(r: 91, 209, 131, alpha: 1)
                    power_content_view_width.constant = CGFloat(24 * Float(battery_level)/Float(100))
                }
            }else{
                power_background_icon.image = UIImage(named: "power_charging")
                power_background_icon.contentMode = .scaleAspectFill
                power_content_view.isHidden = true
            }
        }
        
        //(3).设备是否准备好：保持/关闭--设备平衡
        standbySiwtchButton.contentScaleFactor = 0.7
        standbySiwtchButton.isOn = false
        
        //(4).切换Wifi/Bluetooth
        mode_type = "Bluetooth"
        refreshUIWithModeType()
        
        //(5).设备链接开关
        powerButton.setImage((currenDeviceIsConnected ? UIImage(named: "devic_open") : UIImage(named: "device_off")), for: .normal)
        
        //(6).表情视图--默认图标和表情
        faceIcon.image = UIImage(named: "Robot_face_default")
        faceLabel.text = "Emoji"
        
        //(7).重置设备参数为初始化状态：
        requestDeviceInfo()
    }
    
    //MARK: 5.操作--开启/关闭--设备平衡
    @IBAction func changeStandbyStatusSwitchBUtton(_ sender: Any) {
        
        var currenDeviceIsConnected = false
        if BluetoothManager.shared.device_connected_status == .connected,
           (BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString ?? "") == (current_device_info["identifier"] as? String ?? ""){
            currenDeviceIsConnected = true
        }
        if (currenDeviceIsConnected == false){
            MBProgressHUD.showTitleAndSubTitle(title: "Device not connected!", subTitle: "", view: self.view)
            standbySiwtchButton.isOn = !standbySiwtchButton.isOn
            return
        }
        
        if mode_type == "Bluetooth"{
            if standbySiwtchButton.isOn{
                StandbyBluetoothManager.shared.will_isStandByStatuse = true
            }else{
                StandbyBluetoothManager.shared.will_isStandByStatuse = false
            }
            StandbyBluetoothManager.shared.sendBluetoothDataWith(type: uuid_this_v)
        }else{
            var param_dict = [String: Any]()
            if standbySiwtchButton.isOn{
                param_dict["stable"] = 1
            }else{
                param_dict["stable"] = 0
            }
            WebsocketManager.shared.sendCommad(paramDict: param_dict, sendCommandType: "StandBy")
        }
    }
    
    //MARK: 6.切换Wifi/Bluetooth
    @IBAction func selectBluetoothTap(_ sender: Any) {
        if mode_type == "Bluetooth"{
            return
        }
        mode_type = "Bluetooth"
        refreshUIWithModeType()
    }
    @IBAction func selectWifiTap(_ sender: Any) {
        if mode_type == "Wifi"{
            return
        }
        let device_info = jsonStringToDict(current_device_info["device_info"] as? String ?? "") ?? [String: Any]()
        if let cloud_token = device_info["cloud_token"] as? String,
           cloud_token.count > 0{
            connect_websocket_url_string = "wss://hub.navbot.com/ws/" + cloud_token
            mode_type = "Wifi"
            refreshUIWithModeType()
        }else{
            MBProgressHUD.showTitleAndSubTitle(title: "Please set the cloud token in setting page.", subTitle: "", view: view)
        }
    }
    func refreshUIWithModeType(){
        if mode_type == "Bluetooth"{
            bluetoothItem.backgroundColor = UIColor.white
            bluetoothIcon.tintColor = COLORFROMRGB(r: 0, 0, 0, alpha: 1)
            wifiItem.backgroundColor = .clear
            wifiIcon.tintColor = COLORFROMRGB(r: 148, 151, 153, alpha: 1)
            //断开长链接
            WebsocketManager.shared.disconnect()
            //显示视图
            sliderViewOfRoll.isHidden = false
            sliderViewOfLinearVel.isHidden = false
            sliderViewOfAngularVel.isHidden = false
            faceView.isHidden = false
        }else if mode_type == "Wifi"{
            bluetoothItem.backgroundColor = UIColor.clear
            bluetoothIcon.tintColor = COLORFROMRGB(r: 148, 151, 153, alpha: 1)
            wifiItem.backgroundColor = UIColor.white
            wifiIcon.tintColor = COLORFROMRGB(r: 0, 0, 0, alpha: 1)
            //开始长链接
            self.currentHUDMessage = MBProgressHUD.showJuHuaAndTitle(title: "Connect WebSocket...", view: view)
            WebsocketManager.shared.startToConnect(url_string: connect_websocket_url_string, fromVC: uuid_this_v)
            //隐藏视图:
            sliderViewOfRoll.isHidden = true
            sliderViewOfLinearVel.isHidden = true
            sliderViewOfAngularVel.isHidden = true
            faceView.isHidden = true
        }
    }
    
    //MARK: 7.切换表情
    @IBAction func selectFaceViewTap(_ sender: Any) {
        //(1).判断是否连接设备:
        var currenDeviceIsConnected = false
        if BluetoothManager.shared.device_connected_status == .connected,
           (BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString ?? "") == (current_device_info["identifier"] as? String ?? ""){
            currenDeviceIsConnected = true
        }
        if (currenDeviceIsConnected == false){
            MBProgressHUD.showTitleAndSubTitle(title: "Device not connected!", subTitle: "", view: self.view)
            return
        }
        self.currentHUDMessage = MBProgressHUD.showJuHuaAndTitle(title: "Loading...", view: view)
        GetExpressionBluetoothManager.shared.sendBluetoothDataWith(type: uuid_this_v, paramDict: ["type": "get_expression"])
    }
    //MARK: 8.设备起跳
    @IBAction func clickJumpButton(_ sender: Any) {
        //(1).判断是否连接设备:
        var currenDeviceIsConnected = false
        if BluetoothManager.shared.device_connected_status == .connected,
           (BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString ?? "") == (current_device_info["identifier"] as? String ?? ""){
            currenDeviceIsConnected = true
        }
        if (currenDeviceIsConnected == false){
            MBProgressHUD.showTitleAndSubTitle(title: "Device not connected!", subTitle: "", view: self.view)
            return
        }
        //(2).判断是否开启了平衡:
        if !StandbyBluetoothManager.shared.current_isStandByStatuse{
            MBProgressHUD.showTitleAndSubTitle(title: "Please turn on the ‘ROBOT GO’ button first.", subTitle: "", view: self.view)
            return
        }
        //(3).去起跳
        if mode_type == "Bluetooth"{
            JumpBluetoothManager.shared.sendBluetoothDataWith(type: uuid_this_v)
        }else{
            let param_dict: [String: Any] = ["dir":"jump","mode":"basic","stable":1]
            WebsocketManager.shared.sendCommad(paramDict: param_dict, sendCommandType: "JumpDevice")
        }
        
    }
    
    //MARK: 9.调整设备参数：
    //9.0.重置设备的初始状态--如果设置失败了就返回当前设备的状态
    func updateCurrentStatusInDevice(){
        DispatchQueue.main.async {
            self.sliderViewOfBaseHeight.updateProgressValue(progressValue: Float(BaseHeightBluetoothManager.shared.baseHeight_current))
            self.sliderViewOfRoll.updateProgressValue(progressValue: Float(RollBluetoothManager.shared.current_roll))
            self.sliderViewOfLinearVel.updateProgressValue(progressValue: Float(LinearVelBluetoothManager.shared.current_Linear_Vel))
            self.sliderViewOfAngularVel.updateProgressValue(progressValue: Float(AngularVelBluetoothManager.shared.current_Angular_Vel))
        }
    }
    //MARK: 9.1.调整设备的足部高度
    func adjustDeviceHeight(progressValue: Float){
        //(1).判断是否连接设备:
        var currenDeviceIsConnected = false
        if BluetoothManager.shared.device_connected_status == .connected,
           (BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString ?? "") == (current_device_info["identifier"] as? String ?? ""){
            currenDeviceIsConnected = true
        }
        if (currenDeviceIsConnected == false){
            self.updateCurrentStatusInDevice()
            MBProgressHUD.showTitleAndSubTitle(title: "Device not connected!", subTitle: "", view: self.view)
            return
        }
        //(2).判断是否开启了平衡:
        if !StandbyBluetoothManager.shared.current_isStandByStatuse{
            self.updateCurrentStatusInDevice()
            MBProgressHUD.showTitleAndSubTitle(title: "Please turn on the ‘ROBOT GO’ button first.", subTitle: "", view: self.view)
            return
        }
        //(3).调整设备的足部高度
        if mode_type == "Bluetooth"{
            BaseHeightBluetoothManager.shared.baseHeight_willChanged = Int(progressValue)
            BaseHeightBluetoothManager.shared.sendBluetoothDataWith(type: self.uuid_this_v)
        }else{
            let param_dict: [String: Any] = ["height": Int(progressValue), "stable": 1,"mode": "basic"]
            WebsocketManager.shared.sendCommad(paramDict: param_dict, sendCommandType: "AdjustDeviceHeight")
        }
        
    }
    //MARK: 9.2.调整设备的Roll
    func adjustDeviceRoll(progressValue: Float){
        //(1).判断是否连接设备:
        var currenDeviceIsConnected = false
        if BluetoothManager.shared.device_connected_status == .connected,
           (BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString ?? "") == (current_device_info["identifier"] as? String ?? ""){
            currenDeviceIsConnected = true
        }
        if (currenDeviceIsConnected == false){
            self.updateCurrentStatusInDevice()
            MBProgressHUD.showTitleAndSubTitle(title: "Device not connected!", subTitle: "", view: self.view)
            return
        }
        //(2).判断是否开启了平衡:
        if !StandbyBluetoothManager.shared.current_isStandByStatuse{
            self.updateCurrentStatusInDevice()
            MBProgressHUD.showTitleAndSubTitle(title: "Please turn on the ‘ROBOT GO’ button first.", subTitle: "", view: self.view)
            return
        }
        //(3).调整设备的足部高度
        RollBluetoothManager.shared.will_roll = Int(progressValue)
        RollBluetoothManager.shared.sendBluetoothDataWith(type: self.uuid_this_v)
    }
    //MARK: 9.3.调整设备的Linear Vel
    func adjustDeviceLinearVel(progressValue: Float){
        //(1).判断是否连接设备:
        var currenDeviceIsConnected = false
        if BluetoothManager.shared.device_connected_status == .connected,
           (BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString ?? "") == (current_device_info["identifier"] as? String ?? ""){
            currenDeviceIsConnected = true
        }
        if (currenDeviceIsConnected == false){
            self.updateCurrentStatusInDevice()
            MBProgressHUD.showTitleAndSubTitle(title: "Device not connected!", subTitle: "", view: self.view)
            return
        }
        //(2).判断是否开启了平衡:
        if !StandbyBluetoothManager.shared.current_isStandByStatuse{
            self.updateCurrentStatusInDevice()
            MBProgressHUD.showTitleAndSubTitle(title: "Please turn on the ‘ROBOT GO’ button first.", subTitle: "", view: self.view)
            return
        }
        //(3).调整设备的足部高度
        LinearVelBluetoothManager.shared.will_Linear_Vel = Int(progressValue)
        LinearVelBluetoothManager.shared.sendBluetoothDataWith(type: self.uuid_this_v)
    }
    //MARK: 9.4.调整设备的Angular Vel
    func adjustDeviceAngularVel(progressValue: Float){
        //(1).判断是否连接设备:
        var currenDeviceIsConnected = false
        if BluetoothManager.shared.device_connected_status == .connected,
           (BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString ?? "") == (current_device_info["identifier"] as? String ?? ""){
            currenDeviceIsConnected = true
        }
        if (currenDeviceIsConnected == false){
            self.updateCurrentStatusInDevice()
            MBProgressHUD.showTitleAndSubTitle(title: "Device not connected!", subTitle: "", view: self.view)
            return
        }
        //(2).判断是否开启了平衡:
        if !StandbyBluetoothManager.shared.current_isStandByStatuse{
            self.updateCurrentStatusInDevice()
            MBProgressHUD.showTitleAndSubTitle(title: "Please turn on the ‘ROBOT GO’ button first.", subTitle: "", view: self.view)
            return
        }
        //(3).调整设备的足部高度
        AngularVelBluetoothManager.shared.will_Angular_Vel = Int(progressValue)
        AngularVelBluetoothManager.shared.sendBluetoothDataWith(type: self.uuid_this_v)
    }
    
    //MARK: 9.蓝牙相关--代理回调
    //9.1.发现新设备
    func scanNewDevice(device: CBPeripheral) {
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        // Only display one type devices
        let all_Device_data = BluetoothManager.shared.allScanedDevices
        var origin_allModels = [[String: Any]]()
        for value in all_Device_data{
            // Only display specific devices
            /*
            if let device = value["device"] as? CBPeripheral,
               (device.name ?? "").contains("nov"){
                var newDeviceValue = value
                newDeviceValue["isConnected"] = false
                origin_allModels.append(value)
            }*/
            //Display all devices
            origin_allModels.append(value)
        }
        //Only update the view when the count changes, otherwise frequent refreshing may cause tap events on cells to be unresponsive
        if current_ScanedDevice.count != origin_allModels.count{
            current_ScanedDevice = origin_allModels
        }
    }
    //9.2.连接设备已成功——此时还未监听服务和特征
    func connectDeviceSuccess(device: CBPeripheral) {
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
    }
    //9.3.连接设备已失败——此时还未监听服务和特征
    func connectDeviceFailtrue(device: CBPeripheral) {
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        MBProgressHUD.showText(text: "Failed to connect to navbot.", view: view)
    }
    //9.4.断开设备连接
    func disconnectDevice(device: CBPeripheral) {
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        MBProgressHUD.showTitleAndSubTitle(title: "Device Disconnected.", subTitle: "", view: view)
        //(1).如果存在该设备，改变其状态，并重新保存数据
        var allScanedDevices = UserDefaults.standard.value(forKey: "allScanedDevices") as? [[String: Any]] ?? [[String: Any]]()
        var currentIndex: Int?
        var currentDeviceInfo = [String: Any]()
        for (index, value) in allScanedDevices.enumerated(){
            if (value["identifier"] as? String ?? "") == device.identifier.uuidString{
                currentIndex = index
                currentDeviceInfo = value
                currentDeviceInfo["isConnected"] = false
            }
        }
        if currentIndex != nil && currentIndex! < allScanedDevices.count{
            allScanedDevices[currentIndex!] = currentDeviceInfo
        }
        UserDefaults.standard.setValue(allScanedDevices, forKey: "allScanedDevices")
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateLocalDeviceList"), object: nil)
        print("远程操作页面--设备断开连接--此时本地设备列表数据为：",allScanedDevices)
        
        //(2).重新开始扫描设备
        BluetoothManager.shared.delegate = self
        BluetoothManager.shared.startScanBluetoothDevice(type: uuid_this_v)
        
        //(3).更新当前页面的数据，并更新视图:
        //更新数据
        current_device_info["isConnected"] = false
        //更新UI
        refreshUIForChangeDeviceConnectedStatus()
    }
    //MARK: 10.蓝牙相关通知：
    //MARK: 10.1.通知事件--链接设备成功通知事件--此时已经成功找到并开始监听服务和特征
    @objc func alreadyConnectedDevice(){
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        //现在去获取设备信息
        GetDeviceInfoBluetoothManager.shared.sendBluetoothDataWith(type: uuid_this_v)
    }
    //MARK: 10.2.获取设备信息：
    @objc func getDeviceInfoSuccess(){
        if (GetDeviceInfoBluetoothManager.shared.fromVCType != uuid_this_v){
            return
        }
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        MBProgressHUD.ShowSuccessMBProgresssHUD(view: view, title: "Successfully Connected.") {}
        print("ES01设备操控页面--获取设备信息成功")
        
        //(1).其他设备都应该变为：未连接
        var new_allScanedDevices = [[String: Any]]()
        var allScanedDevices = UserDefaults.standard.value(forKey: "allScanedDevices") as? [[String: Any]] ?? [[String: Any]]()
        for item in allScanedDevices{
            var newItem = item
            newItem["isConnected"] = false
            new_allScanedDevices.append(newItem)
        }
        //(2).判断本地中是否已经存在该设备了
        var currentIndex: Int? = nil
        for (index, value) in allScanedDevices.enumerated(){
            if (value["identifier"] as? String ?? "") == BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString{
                currentIndex = index
            }
        }
        //(3).将该设备重新加入本地设备：
        var current_connected_device = [String: Any]()
        current_connected_device["identifier"] = BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString ?? ""
        current_connected_device["isConnected"] = true
        current_connected_device["name"] = BluetoothManager.shared.current_connecting_CBPeripheral?.name ?? ""
        //UserDefaults存醋数据不能嵌套字典，所以需要转换数据类型：
        if let jsonData = try? JSONSerialization.data(withJSONObject: GetDeviceInfoBluetoothManager.shared.currentDeviceInfo, options: []){
            let jsonString = String(data: jsonData, encoding: .utf8)
            current_connected_device["device_info"] = jsonString
        }
        if (currentIndex == nil){
            new_allScanedDevices.insert(current_connected_device, at: 0)
        }else{
            new_allScanedDevices[currentIndex!] = current_connected_device
        }
        
        //(4).存储本地数据:
        UserDefaults.standard.setValue(new_allScanedDevices, forKey: "allScanedDevices")
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateLocalDeviceList"), object: nil)
        //print("设备成功连接--成功获取设备信息--本地设备数据为：",new_allScanedDevices)
     
        //(5).更新本页面数据和视图
        current_device_info = current_connected_device
        refreshUIForChangeDeviceConnectedStatus()
    }
    @objc func getDeviceInfoFail(){
        if (GetDeviceInfoBluetoothManager.shared.fromVCType != uuid_this_v){
            return
        }
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        MBProgressHUD.showErrorText(text: "Failed to get device info.", view: view)
        //主动断开连接：
        BluetoothManager.shared.disconnectDevice()
    }
    //MARK: 10.3.回调函数: 关闭/开启--设备平衡
    @objc func standbyDeviceSuccess(){
        if StandbyBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        self.standbySiwtchButton.isOn = StandbyBluetoothManager.shared.current_isStandByStatuse
    }
    @objc func standbyDevicenFail(){
        if StandbyBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        self.standbySiwtchButton.isOn = StandbyBluetoothManager.shared.current_isStandByStatuse
    }
    
    //MARK: 10.3.回调函数: 设置设备足高
    @objc func SetupBaseHeightSuccess(){
        if BaseHeightBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
    }
    @objc func SetupBaseHeightFail(){
        if BaseHeightBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        MBProgressHUD.showErrorText(text: "Failed to set height.", view: self.view)
        self.updateCurrentStatusInDevice()
    }
    //MARK: 10.4.回调函数: 设置Roll
    @objc func SetupRollSuccess(){
        if RollBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
    }
    @objc func SetupRollFail(){
        if RollBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        MBProgressHUD.showErrorText(text: "Failed to set roll.", view: self.view)
        self.updateCurrentStatusInDevice()
    }
    //MARK: 10.5.回调函数: 设置Linear Vel
    @objc func SetupLinearVelSuccess(){
        if LinearVelBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
    }
    @objc func SetupLinearVelFail(){
        if LinearVelBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        MBProgressHUD.showErrorText(text: "Failed to set Linear Vel.", view: self.view)
        self.updateCurrentStatusInDevice()
    }
    //MARK: 10.6.回调函数: 设置Angular Vel
    @objc func SetupAngularVelSuccess(){
        if AngularVelBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
    }
    @objc func SetupAngularVelFail(){
        if AngularVelBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        MBProgressHUD.showErrorText(text: "Failed to set Angular Vel.", view: self.view)
        self.updateCurrentStatusInDevice()
    }
    //MARK: 10.7.回调函数: 设备起跳
    @objc func deviceJumpSuccess(){
        if JumpBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
    }
    @objc func deviceJumpFail(){
        if JumpBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        MBProgressHUD.showErrorText(text: "Failed to jump.", view: self.view)
    }
    //MARK: 10.8.回调函数: 设备转向
    @objc func changeDevicePositionSuccess(){
        if ChangePositionBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
    }
    @objc func changeDevicePositionFail(){
        if ChangePositionBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        print("Adjust position--Fail")
    }
    //MARK: 10.9.回调函数: 设置表情：
    @objc func getExpressionFail(){
        if GetExpressionBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        MBProgressHUD.showTitleAndSubTitle(title: "Get Emoji Files Fail.", subTitle: "", view: view)
    }
    @objc func getExpressionSuccess(){
        if GetExpressionBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        
        if GetExpressionBluetoothManager.shared.current_Emoji_files.count == 0{
            MBProgressHUD.showErrorText(text: "Don't get emoji files.", view: self.view)
            return
        }
        let alertView = SelectFaceItemAlertView(frame: UIScreen.main.bounds)
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else{return}
        delegate.window?.addSubview(alertView)
        alertView .selectedFaceSuccessBlock = { selectedFaceData in
            print("选中表情：\(selectedFaceData)")
            //(1).判断是否连接设备:
            var currenDeviceIsConnected = false
            if BluetoothManager.shared.device_connected_status == .connected,
               (BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString ?? "") == (self.current_device_info["identifier"] as? String ?? ""){
                currenDeviceIsConnected = true
            }
            if (currenDeviceIsConnected == false){
                MBProgressHUD.showTitleAndSubTitle(title: "Device not connected!", subTitle: "", view: self.view)
                return
            }
            //(2).判断是否开启了平衡:
            if !StandbyBluetoothManager.shared.current_isStandByStatuse{
                //MBProgressHUD.showTitleAndSubTitle(title: "Please turn on the ‘ROBOT GO’ button first.", subTitle: "", view: self.view)
                //return
            }
            //(3).获取设置的文件名称：
            let image_name = selectedFaceData["name"] as? String ?? ""
            //(4).发送的指令内容：
            var send_paramDict = [String: Any]()
            send_paramDict["type"] = "show_expression"
            //"file" 后输入文件名；
            send_paramDict["file"] = image_name + ".bin"
            //"time" 表示持续时间，如果取值为 0，则表示持续显示，不会自动结束。
            send_paramDict["time"] = 0
            //(5).发送指令,设置表情:
            //print("展示表情--参数:\(send_paramDict)")
            ShowExpressionBluetoothManager.shared.sendBluetoothDataWith(type: self.uuid_this_v, paramDict: send_paramDict)
        }
    }
    @objc func showExpressionFail(){
        if ShowExpressionBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        NotificationCenter.default.post(name: NSNotification.Name("setFaceEnd"), object: nil)
        MBProgressHUD.showTitleAndSubTitle(title: "Set Emoji Fail.", subTitle: "", view: view)
    }
    @objc func showExpressionSuccess(){
        if ShowExpressionBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        NotificationCenter.default.post(name: NSNotification.Name("setFaceEnd"), object: nil)
        let imageName = (ShowExpressionBluetoothManager.shared.current_Emoji_paramDict["file"] as? String ?? "").components(separatedBy: ".")[0] + ".gif"
        if imageName.count == 0{
            self.faceIcon.stopAnimatingGif() // 停止动画
            self.faceIcon.clear()            // 清除 GIF 缓存和帧动画
            self.faceIcon.image = nil        // 清除当前图像（可选）
        }
        if let showGif = try? UIImage(gifName: imageName) {
            self.faceIcon.setGifImage(showGif, loopCount: -1)
            self.faceIcon.startAnimatingGif()
        } else {
            self.faceIcon.stopAnimatingGif() // 停止动画
            self.faceIcon.clear()            // 清除 GIF 缓存和帧动画
            self.faceIcon.image = nil        // 清除当前图像（可选）
        }
        print("当前图标：\(ShowExpressionBluetoothManager.shared.current_Emoji_paramDict)")
        let name = (ShowExpressionBluetoothManager.shared.current_Emoji_paramDict["file"] as? String ?? "").components(separatedBy: ".")[0]
        self.faceLabel.text = name
    }
    
    //MARK: 11.WebSocket--回调
    //MARK: 11.1.链接成功
    @objc func connectWebSocketSuccess(){
        if (WebsocketManager.shared.fromVCType != uuid_this_v){
            return
        }
        DispatchQueue.main.async {
            if (self.currentHUDMessage != nil){
                MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage!)
            }
        }
    }
    //MARK: 11.2.链接失败
    @objc func connectWebSocketFail(){
        if (WebsocketManager.shared.fromVCType != uuid_this_v){
            return
        }
        DispatchQueue.main.async {
            if (self.currentHUDMessage != nil){
                MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage!)
            }
            MBProgressHUD.showTitleAndSubTitle(title: "Connect WebSocket Fail.", subTitle: "", view: self.view)
            self.selectBluetoothTap(UIButton())
        }
    }
    //MARK: 11.3.连接中断
    @objc func webSocketDisconnected(){
        if (WebsocketManager.shared.fromVCType != uuid_this_v){
            return
        }
        if mode_type == "Wifi"{
            DispatchQueue.main.async {
                MBProgressHUD.ShowSuccessMBProgresssHUD(view: self.view, title: "WebSocket Disconnected.") {
                    self.selectBluetoothTap(UIButton())
                }
            }
        }
    }
    //MARK: 11.4.Socket-回调函数: 关闭/开启--设备平衡
    @objc func setDeviceStandByWithSocketSuccess(){
        if (WebsocketManager.shared.fromVCType != uuid_this_v){
            return
        }
        print("Socket-回调函数: 关闭/开启--设备平衡--成功")
        DispatchQueue.main.async {
            StandbyBluetoothManager.shared.current_isStandByStatuse = self.standbySiwtchButton.isOn
        }
    }
    @objc func setDeviceStandByWithSocketFail(){
        if (WebsocketManager.shared.fromVCType != uuid_this_v){
            return
        }
        print("Socket-回调函数: 关闭/开启--设备平衡--失败")
        DispatchQueue.main.async {
            MBProgressHUD.showErrorText(text: "Failed to set robot.", view: self.view)
            self.standbySiwtchButton.isOn = !self.standbySiwtchButton.isOn
            StandbyBluetoothManager.shared.current_isStandByStatuse = self.standbySiwtchButton.isOn
        }
    }
    //MARK: 11.5.Socket-回调函数: 调整设备足部高度
    @objc func adjustDeviceHeightWithSocketSuccess(){
        if (WebsocketManager.shared.fromVCType != uuid_this_v){
            return
        }
        print("Socket-回调函数: 调整设备足部高度--成功")
        DispatchQueue.main.async {
            BaseHeightBluetoothManager.shared.baseHeight_current = Int(self.sliderViewOfBaseHeight.currentProgressValue)
        }
        
    }
    @objc func adjustDeviceHeightWithSocketFail(){
        if (WebsocketManager.shared.fromVCType != uuid_this_v){
            return
        }
        print("Socket-回调函数: 调整设备足部高度--失败")
        DispatchQueue.main.async {
            MBProgressHUD.showErrorText(text: "Failed to set height.", view: self.view)
            self.updateCurrentStatusInDevice()
        }
    }
    //MARK: 11.6.Socket-回调函数: 设备起跳
    @objc func jumpDeviceWithSocketSuccess(){
        if (WebsocketManager.shared.fromVCType != uuid_this_v){
            return
        }
        print("Socket-回调函数: 设备起跳--成功")
    }
    @objc func jumpDeviceWithSocketFail(){
        if (WebsocketManager.shared.fromVCType != uuid_this_v){
            return
        }
        print("Socket-回调函数: 设备起跳--失败")
        DispatchQueue.main.async {
            MBProgressHUD.showErrorText(text: "Failed to jump.", view: self.view)
        }
    }
    //MARK: 11.7.Socket-回调函数: 改变位置
    @objc func changePositionWithSocketSuccess(){
        if (WebsocketManager.shared.fromVCType != uuid_this_v){
            return
        }
        print("Socket-回调函数: 改变位置--成功")
    }
    @objc func changePositionWithSocketFail(){
        if (WebsocketManager.shared.fromVCType != uuid_this_v){
            return
        }
        print("Socket-回调函数: 改变位置--失败")
    }
    deinit{
        NotificationCenter.default.removeObserver(self)
    }
}


