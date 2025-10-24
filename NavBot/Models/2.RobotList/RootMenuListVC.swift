import UIKit
import CoreBluetooth

class RootMenuListVC: UIViewController,UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ZYBluetoothHandlerDelegate{
    
    var myCollection: UICollectionView!
    var deviceListModels = [[String: Any]]()
    var uuid_this_v = ""
    
    var current_ScanedDevice = [[String: Any]]()
    
    var currentHUDMessage: MBProgressHUD!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ScheduledGetDeviceInfoManager.shared.startScheduledGetDeviceInfo()
    }
    var isFirst = true
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isFirst{
            initUI()
            initBluetooth()
            requestDeviceListData()
            isFirst = false
        }
    }
    //MARK: 1.初始化页面
    func initUI(){
        
        view.backgroundColor = UIColor(red: 237/255, green: 243/255, blue: 228/255, alpha: 1.0)
        
        let safe_insets = view.safeAreaInsets
        print("Top: \(safe_insets.top), Left: \(safe_insets.left), Bottom: \(safe_insets.bottom), Right: \(safe_insets.right)")
        
        let titileLabel = UILabel(frame: CGRect(x: safe_insets.left == 0 ? 20 : (safe_insets.left+10), y: safe_insets.top+22, width: 200, height: 25))
        titileLabel.textAlignment = .left
        titileLabel.textColor = .black
        titileLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        titileLabel.text = "My Robot"
        view.addSubview(titileLabel)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        let item_width_height = kScreen_HEIGHT-(safe_insets.top+54)-90
        layout.itemSize = CGSize(width: item_width_height, height: item_width_height)
        
        let collection_left = safe_insets.left == 0 ? 20.0 : safe_insets.left
        let collection_right = safe_insets.right == 0 ? 20.0 : safe_insets.right
        let collection_frame = CGRect(x: collection_left, y: safe_insets.top+54, width: kScreen_WIDTH-collection_left-collection_right, height: kScreen_HEIGHT-(safe_insets.top+54)-90)
        myCollection = UICollectionView(frame: collection_frame, collectionViewLayout: layout)
        myCollection.translatesAutoresizingMaskIntoConstraints = false
        myCollection.backgroundColor = .clear
        myCollection.register(UINib(nibName: "DeviceCell", bundle: Bundle.main), forCellWithReuseIdentifier: "DeviceCellID")
        myCollection.delegate = self
        myCollection.dataSource = self
        myCollection.showsHorizontalScrollIndicator = false
        myCollection.showsVerticalScrollIndicator = false
        view.addSubview(myCollection)
        
        let addButton = UIButton(type: .custom)
        addButton.frame = CGRect(x: kScreen_WIDTH-24-56, y: kScreen_HEIGHT-24-56, width: 56, height: 56)
        addButton.setImage(UIImage(named: "addDeviceButton"), for: .normal)
        addButton.addTarget(self, action: #selector(clickAddButton), for: .touchUpInside)
        view.addSubview(addButton)
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshDeviceLlist), name: NSNotification.Name(rawValue: "UpdateLocalDeviceList"), object: nil)
        
    }
    func initBluetooth(){
        NotificationCenter.default.addObserver(self, selector: #selector(alreadyConnectedDevice), name: NSNotification.Name(rawValue: "setNotifyValueSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getDeviceInfoSuccess), name: NSNotification.Name(rawValue: "getDeviceInfo_success"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getDeviceInfoFail), name: NSNotification.Name(rawValue: "getDeviceInfo_fail"), object: nil)
        uuid_this_v = "RootMenuListVC_" + getRandomDigitsString()
        BluetoothManager.shared.delegate = self
        BluetoothManager.shared.startScanBluetoothDevice(type: uuid_this_v)
    }
    func requestDeviceListData(){
        let allScanedDevices = UserDefaults.standard.value(forKey: "allScanedDevices") as? [[String: Any]] ?? [[String: Any]]()
        deviceListModels = allScanedDevices
        myCollection.reloadData()
        print("设备列表页面--设备列表数据：\(allScanedDevices)")
    }
    //MARK: 2.前往搜索设备界面
    @objc func clickAddButton(){
        let vc = ScanDeviceListVC()
        vc.backVCBlock = {
            BluetoothManager.shared.delegate = self
            BluetoothManager.shared.startScanBluetoothDevice(type: self.uuid_this_v)
        }
        self.present(vc, animated: true)
    }
    @objc func refreshDeviceLlist(){
        let allScanedDevices = UserDefaults.standard.value(forKey: "allScanedDevices") as? [[String: Any]] ?? [[String: Any]]()
        deviceListModels = allScanedDevices
        myCollection.reloadData()
        print("设备列表页面--刷新设备列表数据：\(allScanedDevices)")
    }
   //MARK: 3.列表回调方法：UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return deviceListModels.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DeviceCellID", for: indexPath) as! DeviceCell
        cell.cellDict = deviceListModels[indexPath.row]
        cell.initCell()
        cell.clickMoreButtonBlock = {
            let alertView = MoreAlertView(frame: UIScreen.main.bounds)
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else{return}
            delegate.window?.addSubview(alertView)
            //(1).更改别名：
            alertView.clickRenameBlock = {
                var current_device_connected = false
                let cell_data = self.deviceListModels[indexPath.row]
                if BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString == (cell_data["identifier"] as? String ?? ""),
                   BluetoothManager.shared.device_connected_status == .connected{
                    current_device_connected = true
                }
                if current_device_connected == true{
                    let alertView1 = ChangeTextFieldAlertView(frame: UIScreen.main.bounds)
                    guard let delegate1 = UIApplication.shared.delegate as? AppDelegate else{return}
                    delegate1.window?.addSubview(alertView1)
                    alertView1.current_device_info = cell_data
                    if let deviceInfo = jsonStringToDict(cell_data["device_info"] as? String ?? ""){
                        let deviceName = self.deviceListModels[indexPath.row]["name"] as? String ?? ""
                        var nickName = deviceName
                        if let current_nickName = deviceInfo["name"] as? String,
                           current_nickName.count > 0{
                            nickName = current_nickName
                        }
                        alertView1.contentTFD.text = nickName
                    }
                }else{
                    //此时要先去连接设备：
                    self.gotoConnectDevice(type: "changeName", cell_data: cell_data)
                }
            }
            //(2).前往设置界面
            alertView.clickSettingsBlock = {
                var current_device_connected = false
                let cell_data = self.deviceListModels[indexPath.row]
                if BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString == (cell_data["identifier"] as? String ?? ""),
                   BluetoothManager.shared.device_connected_status == .connected{
                    current_device_connected = true
                }
                if current_device_connected == true{
                    let vc = SettingsVC()
                    vc.current_device_info = cell_data
                    self.present(vc, animated: true)
                }else{
                    //此时要先去连接设备：
                    self.gotoConnectDevice(type: "setting", cell_data: cell_data)
                }
            }
            //(3).删除设备
            alertView.clickRemoveBlock = {
                let alertView1 = DeleteDeviceAlertView(frame: UIScreen.main.bounds)
                guard let delegate1 = UIApplication.shared.delegate as? AppDelegate else{return}
                delegate1.window?.addSubview(alertView1)
                alertView1.deleteDeviceBlock = {
                    var current_device_connected = false
                    let cell_data = self.deviceListModels[indexPath.row]
                    if BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString == (cell_data["identifier"] as? String ?? ""),
                       BluetoothManager.shared.device_connected_status == .connected{
                        current_device_connected = true
                    }
                    //先断开设备：
                    if current_device_connected == true{
                        BluetoothManager.shared.disconnectDevice()
                    }
                    //在删除设备数据：
                    var new_allDevices = [[String: Any]]()
                    for item in self.deviceListModels{
                        let new_item = item
                        if item["name"] as? String == cell_data["name"] as? String,
                           item["identifier"] as? String == cell_data["identifier"] as? String{
                        }else{
                            new_allDevices.append(new_item)
                        }
                    }
                    UserDefaults.standard.setValue(new_allDevices, forKey: "allScanedDevices")
                    UserDefaults.standard.synchronize()
                    self.deviceListModels = new_allDevices
                    self.myCollection.reloadData()
                }
            }
        }
        return cell
    }
    //changeName + setting + remoteControl
    var connect_device_action_type = ""
    func gotoConnectDevice(type: String, cell_data: [String: Any]){
        self.connect_device_action_type = type
        //1.在本地查找这个设备
        var isHaveThisDevice = false
        for item in self.current_ScanedDevice{
            if let current_CBPeripheral = item["device"] as? CBPeripheral,
               current_CBPeripheral.identifier.uuidString == cell_data["identifier"] as? String,
               current_CBPeripheral.name == cell_data["name"] as? String{
                isHaveThisDevice = true
                //2.如果找到这个设备
                print("Device found. Connecting now…")
                self.currentHUDMessage = MBProgressHUD.showJuHuaAndTitle(title: "Connecting...", view: self.view)
                BluetoothManager.shared.fromVCType = self.uuid_this_v
                BluetoothManager.shared.startConnectionDevice(device: current_CBPeripheral)
            }
        }
        //3.如果没有找到这个设备
        if !isHaveThisDevice{
            print("Device not found. Unable to connect.")
            let AlertVC = UIAlertController(title: "Device not found.", message: "Could you delete this device.", preferredStyle: .alert)
            let confirmBtn = UIAlertAction(title: "Yes", style: .default) { alert in
                var new_allDevices = [[String: Any]]()
                for item in self.deviceListModels{
                    let new_item = item
                    if item["name"] as? String == cell_data["name"] as? String,
                       item["identifier"] as? String == cell_data["identifier"] as? String{
                    }else{
                        new_allDevices.append(new_item)
                    }
                }
                UserDefaults.standard.setValue(new_allDevices, forKey: "allScanedDevices")
                UserDefaults.standard.synchronize()
                self.deviceListModels = new_allDevices
                self.myCollection.reloadData()
            }
            AlertVC.addAction(confirmBtn)
            let cancelBtn = UIAlertAction(title: "No", style: .cancel)
            AlertVC.addAction(cancelBtn)
            self.present(AlertVC, animated: true)
        }
        
    }
    //MARK: 4.点击设备
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //1.获取：当前设备信息和当前扫描到信息
        let cell_data = self.deviceListModels[indexPath.row]
        print("当前设备信息:\(cell_data)")
        //print("当前扫描到的信息:\(self.current_ScanedDevice)")
        
        //2.判断当前设备是否已经连接
        var current_device_connected = false
        if BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString == (cell_data["identifier"] as? String ?? ""),
           BluetoothManager.shared.device_connected_status == .connected{
            current_device_connected = true
        }
        
        //3.如果已经连接了设备，此时在本地的连接设备列表中是没有这个设备的，此时直接前往设备操控界面
        if current_device_connected == true{
            gotoRemoteControllerVC(currentDeviceInfo: cell_data)
            return
        }
        //4.如果此时还没有链接该设备，就去链接设备
        var isHaveThisDevice = false
        for item in self.current_ScanedDevice{
            if let current_CBPeripheral = item["device"] as? CBPeripheral,
               current_CBPeripheral.identifier.uuidString == cell_data["identifier"] as? String,
               current_CBPeripheral.name == cell_data["name"] as? String{
                isHaveThisDevice = true
                print("Device found. Connecting now…")
                self.currentHUDMessage = MBProgressHUD.showJuHuaAndTitle(title: "Connecting...", view: self.view)
                self.connect_device_action_type = "remoteControl"
                BluetoothManager.shared.fromVCType = self.uuid_this_v
                BluetoothManager.shared.startConnectionDevice(device: current_CBPeripheral)
            }
        }
        
        //5.如果没有找到这个设备
        if !isHaveThisDevice{
            print("Device not found. Unable to connect.")
            let AlertVC = UIAlertController(title: "Device not found.", message: "Could you delete this device.", preferredStyle: .alert)
            let confirmBtn = UIAlertAction(title: "Yes", style: .default) { alert in
                var new_allDevices = [[String: Any]]()
                for item in self.deviceListModels{
                    let new_item = item
                    if item["name"] as? String == cell_data["name"] as? String,
                       item["identifier"] as? String == cell_data["identifier"] as? String{
                    }else{
                        new_allDevices.append(new_item)
                    }
                }
                UserDefaults.standard.setValue(new_allDevices, forKey: "allScanedDevices")
                UserDefaults.standard.synchronize()
                self.deviceListModels = new_allDevices
                self.myCollection.reloadData()
            }
            AlertVC.addAction(confirmBtn)
            let cancelBtn = UIAlertAction(title: "No", style: .cancel)
            AlertVC.addAction(cancelBtn)
            self.present(AlertVC, animated: true)
        }
    }
    func gotoRemoteControllerVC(currentDeviceInfo: [String: Any]){
        //判断该设备的类型：ES01,EN02
        let deviceName = currentDeviceInfo["name"] as? String ?? ""
        if deviceName.contains("en01"){
            let vc = DeviceRemoteControlVC()
            vc.current_device_info = currentDeviceInfo
            vc.backVCBlock = {
                BluetoothManager.shared.delegate = self
                BluetoothManager.shared.startScanBluetoothDevice(type: self.uuid_this_v)
            }
            present(vc, animated: true)
        }
        if deviceName.contains("es02"){
            /*
            let vc = DeviceRemoteControlOfES02VC()
            vc.current_device_info = currentDeviceInfo
            vc.backVCBlock = {
                BluetoothManager.shared.delegate = self
                BluetoothManager.shared.startScanBluetoothDevice(type: self.uuid_this_v)
            }
            present(vc, animated: true)
            */
        }
    }
    
    //MARK: 5.蓝牙回调方法ZYBluetoothHandlerDelegate
    //MARK: 5.1.发现新设备
    func scanNewDevice(device: CBPeripheral) {
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        // Only display one type devices
        let all_Device_data = BluetoothManager.shared.allScanedDevices
        var origin_allModels = [[String: Any]]()
        for value in all_Device_data{
            // Only display specific devices
            if let device = value["device"] as? CBPeripheral,
               (device.name ?? "").contains("navbot"){
                var newDeviceValue = value
                origin_allModels.append(newDeviceValue)
            }
        }
        //Only update the view when the count changes, otherwise frequent refreshing may cause tap events on cells to be unresponsive
        if current_ScanedDevice.count != origin_allModels.count{
            current_ScanedDevice = origin_allModels
        }
    }
    //MARK: 5.2.连接设备已成功——此时还未监听服务和特征
    func connectDeviceSuccess(device: CBPeripheral) {
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
    }
    //MARK: 5.3.连接设备已失败——此时还未监听服务和特征
    func connectDeviceFailtrue(device: CBPeripheral) {
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        MBProgressHUD.showText(text: "Failed to connect to navbot.", view: view)
        BluetoothManager.shared.delegate = self
        BluetoothManager.shared.startScanBluetoothDevice(type: uuid_this_v)
    }
    //MARK: 5.4.断开设备连接
    func disconnectDevice(device: CBPeripheral) {
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        MBProgressHUD.showTitleAndSubTitle(title: "Device Disconnected.", subTitle: "", view: view)
        //(1).如果存在该设备，改变其状态：
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
        print("设备列表页面--设备断开连接--此时本地设备列表数据为：",allScanedDevices)
        
        //(2).重新开始扫描设备
        BluetoothManager.shared.delegate = self
        BluetoothManager.shared.startScanBluetoothDevice(type: uuid_this_v)
    }
    //MARK: 6.通知事件--链接设备成功通知事件--此时已经成功找到并开始监听服务和特征
    //changeName + setting + remoteControl
    @objc func alreadyConnectedDevice(){
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        gotoGetDeviceInfo()
    }
    //MARK: 7.连接成功后，需要获取一次设备信息:
     func gotoGetDeviceInfo(){
         GetDeviceInfoBluetoothManager.shared.sendBluetoothDataWith(type: uuid_this_v)
     }
     //MARK: 7.1.获取设备信息--成功
     @objc func getDeviceInfoSuccess(){
         if (GetDeviceInfoBluetoothManager.shared.fromVCType != uuid_this_v){
             return
         }
         MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
         print("设备列表页面--获取设备信息成功")
         
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
         /*
          [["isConnected": true, "identifier": "6D3B997D-5828-05CB-C98E-FC6A36C01574", "name": "navbot_en01-wz3h9a","device_info":{}]]
          */
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
         print("设备列表页面--设备成功连接--成功获取设备信息--本地设备数据为：",new_allScanedDevices)
      
         //(5).跳转页面
         if (self.connect_device_action_type == "changeName"){
             let alertView1 = ChangeTextFieldAlertView(frame: UIScreen.main.bounds)
             guard let delegate1 = UIApplication.shared.delegate as? AppDelegate else{return}
             delegate1.window?.addSubview(alertView1)
             alertView1.current_device_info = current_connected_device
             if let deviceInfo = jsonStringToDict(current_connected_device["device_info"] as? String ?? ""),
                let local_device_name = deviceInfo["name"] as? String{
                 alertView1.contentTFD.text = local_device_name
             }
         }
         if (self.connect_device_action_type == "setting"){
             let vc = SettingsVC()
             vc.current_device_info = current_connected_device
             self.present(vc, animated: true)
         }
         if (self.connect_device_action_type == "remoteControl"){
             gotoRemoteControllerVC(currentDeviceInfo: current_connected_device)
         }
     }
     //MARK: 7.2.获取设备信息--失败
     @objc func getDeviceInfoFail(){
         if (GetDeviceInfoBluetoothManager.shared.fromVCType != uuid_this_v){
             return
         }
         MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
         MBProgressHUD.showErrorText(text: "Failed to get device info.", view: view)
         //主动断开连接：
         BluetoothManager.shared.disconnectDevice()
     }
    deinit{
        NotificationCenter.default.removeObserver(self)
    }
}
