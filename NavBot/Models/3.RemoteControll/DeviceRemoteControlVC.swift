
import UIKit
import CoreBluetooth

class DeviceRemoteControlVC: UIViewController, ZYBluetoothHandlerDelegate {

    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var directionalControllerView: UIView!
    @IBOutlet weak var powerButton: UIButton!
    @IBOutlet weak var standbySiwtchButton: UISwitch!
    
    var uuid_this_v = ""
    var currentHUDMessage: MBProgressHUD!
    var backVCBlock: (()->())?
    var current_ScanedDevice = [[String: Any]]()
    
    
    lazy var sliderViewOfBaseHeight = {
        let view = MySliderView(frame: CGRect(x: kScreen_WIDTH/2-200+48, y: safeTop()+60+20, width: 100, height: kScreen_HEIGHT-140))
        view.titleLabel.text = "Base Height"
        view.minimumProgressValue = 32.0
        view.maxProgressValue = 85.0
        view.unitValue = "mm"
        view.endTapgestureWithValue = {progressValue in
            if BluetoothManager.shared.current_connecting_CBPeripheral?.state != .connected{
                self.updateCurrentStatusInDevice()
                MBProgressHUD.showTitleAndSubTitle(title: "Device not connected!", subTitle: "", view: self.view)
            }else{
                if !StandbyBluetoothManager.shared.current_isStandByStatuse{
                    self.updateCurrentStatusInDevice()
                    MBProgressHUD.showTitleAndSubTitle(title: "Please turn on the ‘ROBOT GO’ button first.", subTitle: "", view: self.view)
                    return
                }
                BaseHeightBluetoothManager.shared.baseHeight_willChanged = Int32(progressValue)
                BaseHeightBluetoothManager.shared.sendBluetoothDataWith(type: self.uuid_this_v)
            }
        }
        return view
    }()
    
    lazy var sliderViewOfRoll = {
        let view = MySliderView(frame: CGRect(x: kScreen_WIDTH/2-200+100+48, y: safeTop()+60+20, width: 100, height: kScreen_HEIGHT-140))
        view.titleLabel.text = "Roll"
        view.minimumProgressValue = 0.0
        view.maxProgressValue = 100.0
        view.unitValue = "°"
        view.endTapgestureWithValue = { progressValue in
            print("Roll-->Invoke the callback to send the command：",progressValue)
        }
        return view
    }()
    
    lazy var sliderViewOfLinearVel = {
        let view = MySliderView(frame: CGRect(x: kScreen_WIDTH/2-200+200+48, y: safeTop()+60+20, width: 100, height: kScreen_HEIGHT-140))
        view.titleLabel.text = "Linear Vel"
        view.minimumProgressValue = 0.0
        view.maxProgressValue = 100.0
        view.unitValue = "mm/s"
        view.endTapgestureWithValue = { progressValue in
            print("Linear Vel-->Invoke the callback to send the command：",progressValue)
        }
        return view
    }()
    
    lazy var sliderViewOfAngularVel = {
        let view = MySliderView(frame: CGRect(x: kScreen_WIDTH/2-200+300+48, y: safeTop()+60+20, width: 100, height: kScreen_HEIGHT-140))
        view.titleLabel.text = "Angular Vel"
        view.minimumProgressValue = 0.0
        view.maxProgressValue = 100.0
        view.unitValue = "°/s"
        view.endTapgestureWithValue = { progressValue in
            print("Angular Vel-->Invoke the callback to send the command：",progressValue)
        }
        return view
    }()
    
    lazy var directionalControlView = {
        let view = DirectionalControlView(frame: CGRect(x: 0, y: 0, width: 120, height:120))
        view.updateCoordinateSystemPoint = { coordinatePoint in
            print("Updating coordinates.:\(coordinatePoint)")
            if BluetoothManager.shared.current_connecting_CBPeripheral?.state != .connected{
                MBProgressHUD.showTitleAndSubTitle(title: "Device not connected!", subTitle: "", view: self.view)
            }else{
                if !StandbyBluetoothManager.shared.current_isStandByStatuse{
                    MBProgressHUD.showTitleAndSubTitle(title: "Please turn on the ‘ROBOT GO’ button first.", subTitle: "", view: self.view)
                    return
                }
                // Original coordinate X range: -60 <--> 60
                // Original coordinate Y range: -60 <--> 60
                // Device coordinate X range:   -100 <--> 100
                // Device coordinate Y range:   -100 <--> 100
                ChangePositionBluetoothManager.shared.x_willChanged = Int32(coordinatePoint.x*100/60)
                ChangePositionBluetoothManager.shared.y_willChanged = Int32(coordinatePoint.y*100/60)
                ChangePositionBluetoothManager.shared.sendBluetoothDataWith(type: self.uuid_this_v)
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

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        initBluetooth()
        requestDeviceInfo()
        addAllNotifications()
        startScanBluetoothDevice()
    }
    
    func initUI(){
        deviceNameLabel.text = BluetoothManager.shared.current_connecting_CBPeripheral?.name ?? "Robot Name"
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: kScreen_WIDTH, height: kScreen_HEIGHT)
        gradientLayer.colors = [
            COLORFROMRGB(r: 224, 239, 255, alpha: 1).cgColor,
            COLORFROMRGB(r: 255, 255, 255, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        standbySiwtchButton.contentScaleFactor = 0.7
        standbySiwtchButton.isOn = false
        
        view.addSubview(self.sliderViewOfBaseHeight)
        view.addSubview(self.sliderViewOfRoll)
        view.addSubview(self.sliderViewOfLinearVel)
        view.addSubview(self.sliderViewOfAngularVel)
        
        directionalControllerView.addSubview(self.directionalControlView)
    }
    //MARK: 1.Init blutooth manager and start scan blutooth device
    func initBluetooth(){
        NotificationCenter.default.addObserver(self, selector: #selector(alreadyConnectedDevice), name: NSNotification.Name(rawValue: "setNotifyValueSuccess"), object: nil)
    }
    func startScanBluetoothDevice(){
        uuid_this_v = "DeviceRemoteController_" + getRandomDigitsString()
        BluetoothManager.shared.fromVCType = uuid_this_v
        BluetoothManager.shared.delegate = self
    }
    //MARK: 2.ZYBluetoothHandlerDelegate
    //2.1.Discovered a new device
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
    //2.2.Successfully connected to the device -- not set notify
    func connectDeviceSuccess(device: CBPeripheral) {
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
    }
    //2.3.Failed to connect to the device
    func connectDeviceFailtrue(device: CBPeripheral) {
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        MBProgressHUD.showText(text: "Failed to connect to navbot.", view: view)
    }
    //2.4.Device disconnected
    func disconnectDevice(device: CBPeripheral) {
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        let deviceListModels = UserDefaults.standard.value(forKey: "allScanedDevices") as? [[String: Any]] ?? [[String: Any]]()
        print("allScanedDevices：\(deviceListModels)")
        var new_allDevices = [[String: Any]]()
        for item in deviceListModels{
            var new_item = item
            new_item["isConnected"] = false
            new_allDevices.append(new_item)
        }
        UserDefaults.standard.setValue(new_allDevices, forKey: "allScanedDevices")
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateLocalDeviceList"), object: nil)
        if BluetoothManager.shared.device_connected_status == .connected{
            powerButton.setImage(UIImage(named: "control_power"), for: .normal)
        }else{
            powerButton.setImage(UIImage(named: "device_off"), for: .normal)
        }
        BluetoothManager.shared.startScanBluetoothDevice(type: uuid_this_v)
    }
    //MARK: 3.Connected Device Success
    //Successfully connected to the device -- Set Notify Success
    @objc func alreadyConnectedDevice(){
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        MBProgressHUD.ShowSuccessMBProgresssHUD(view: view, title: "Successfully Connected.") {}
        if BluetoothManager.shared.current_connecting_CBPeripheral?.state == .connected{
            powerButton.setImage(UIImage(named: "control_power"), for: .normal)
        }else{
            powerButton.setImage(UIImage(named: "device_off"), for: .normal)
        }
    }
    //MARK: Get Device Current Info
    func requestDeviceInfo(){
        if BluetoothManager.shared.current_connecting_CBPeripheral?.state == .connected{
            powerButton.setImage(UIImage(named: "control_power"), for: .normal)
        }else{
            powerButton.setImage(UIImage(named: "device_off"), for: .normal)
        }
        //Get Data Success, Then:
        sliderViewOfBaseHeight.updateProgressValue(progressValue: 32.0)
        
        //Not Use These Slider
        sliderViewOfRoll.updateProgressValue(progressValue: 0.0)
        sliderViewOfRoll.isUserInteractionEnabled = false
        sliderViewOfLinearVel.updateProgressValue(progressValue: 0.0)
        sliderViewOfLinearVel.isUserInteractionEnabled = false
        sliderViewOfAngularVel.updateProgressValue(progressValue: 0.0)
        sliderViewOfAngularVel.isUserInteractionEnabled = false
    }
    func updateCurrentStatusInDevice(){
        DispatchQueue.main.async {
            self.sliderViewOfBaseHeight.updateProgressValue(progressValue: Float(BaseHeightBluetoothManager.shared.baseHeight_current))
        }
    }
   
    //MARK: Taps
    @IBAction func clickBackButton(_ sender: Any) {
        backVCBlock?()
        dismiss(animated: true)
    }
    //MARK: 4.Power On/Off
    @IBAction func clickPowerButton(_ sender: Any) {
         if BluetoothManager.shared.device_connected_status == .connected{
             BluetoothManager.shared.fromVCType = self.uuid_this_v
             BluetoothManager.shared.disconnectDevice()
         }else if BluetoothManager.shared.device_connected_status == .notConnected{
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
    @IBAction func clickJumpButton(_ sender: Any) {
        if BluetoothManager.shared.device_connected_status != .connected{
            MBProgressHUD.showTitleAndSubTitle(title: "Device not connected!", subTitle: "", view: self.view)
            return
        }
        if !StandbyBluetoothManager.shared.current_isStandByStatuse{
            MBProgressHUD.showTitleAndSubTitle(title: "Please turn on the ‘ROBOT GO’ button first.", subTitle: "", view: self.view)
            return
        }
        JumpBluetoothManager.shared.sendBluetoothDataWith(type: uuid_this_v)
    }
    @IBAction func changeStandbyStatusSwitchBUtton(_ sender: Any) {
        if standbySiwtchButton.isOn{
            StandbyBluetoothManager.shared.will_isStandByStatuse = true
        }else{
            StandbyBluetoothManager.shared.will_isStandByStatuse = false
        }
        StandbyBluetoothManager.shared.sendBluetoothDataWith(type: uuid_this_v)
    }
    
    //MARK: 5.添加所有通知:
    func addAllNotifications(){
        NotificationCenter.default.addObserver(self, selector: #selector(SetupBaseHeightFail), name: Notification.Name(rawValue: "SetupBaseHeight_fail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SetupBaseHeightSuccess), name: Notification.Name(rawValue: "SetupBaseHeigh_success"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceJumpFail), name: Notification.Name(rawValue: "deviceJump_fail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceJumpSuccess), name: Notification.Name(rawValue: "deviceJump_success"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changeDevicePositionFail), name: Notification.Name(rawValue: "ChangeDevicePosition_fail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changeDevicePositionSuccess), name: Notification.Name(rawValue: "ChangeDevicePosition_success"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changeDevicePositionSuccess), name: Notification.Name(rawValue: "standbyDevice_fail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changeDevicePositionSuccess), name: Notification.Name(rawValue: "standbyDevice_success"), object: nil)
    }
    //MARK: 5.1.Modify device height -- callback
    //MARK: -->Success
    @objc func SetupBaseHeightSuccess(){
        if BaseHeightBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        print("Modify device height--Success")
    }
    //MARK: -->Fail
    @objc func SetupBaseHeightFail(){
        if BaseHeightBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        print("Modify device height--Fail")
    }
    //MARK: 5.2.Device jump -- callback
    //MARK: -->Success
    @objc func deviceJumpSuccess(){
        if JumpBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        print("Device jump--Success")
    }
    //MARK: -->Fail
    @objc func deviceJumpFail(){
        if JumpBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        print("Device jump--Fail")
    }
    //MARK: 5.3.Adjust position -- callback
    //MARK: -->Success
    @objc func changeDevicePositionSuccess(){
        if ChangePositionBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        print("Adjust position--Success")
    }
    //MARK: -->Fail
    @objc func changeDevicePositionFail(){
        if ChangePositionBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        print("Adjust position--Fail")
    }
    //MARK: 5.4.Standby Device -- callback
    //MARK: -->Success
    @objc func standbyDeviceSuccess(){
        if StandbyBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        print("Standby Device--Success")
        self.standbySiwtchButton.isOn = StandbyBluetoothManager.shared.current_isStandByStatuse
    }
    //MARK: -->Fail
    @objc func standbyDevicenFail(){
        if StandbyBluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        print("Standby Device--Fail")
        self.standbySiwtchButton.isOn = StandbyBluetoothManager.shared.current_isStandByStatuse
    }
    deinit{
        NotificationCenter.default.removeObserver(self)
    }
}
