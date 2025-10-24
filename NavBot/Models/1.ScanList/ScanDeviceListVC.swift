
import UIKit
import CoreBluetooth

class ScanDeviceListVC: UIViewController, ZYBluetoothHandlerDelegate, UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var myTableView: UITableView!
    
    var allModels = [[String: Any]]()
    var uuid_this_v = ""
    var currentHUDMessage: MBProgressHUD!
    var backVCBlock: (()->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        startScanBluetoothDevice()
    }
    
    @IBAction func clickBackTap(_ sender: Any) {
        dismiss(animated: true)
    }
    
    func initUI(){
        NotificationCenter.default.addObserver(self, selector: #selector(alreadyConnectedDevice), name: NSNotification.Name(rawValue: "setNotifyValueSuccess"), object: nil)
        myTableView.register(UINib(nibName: "SearchingDeviceCell", bundle: .main), forCellReuseIdentifier: "SearchingDeviceCellID")
        myTableView.delegate = self
        myTableView.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(getDeviceInfoSuccess), name: NSNotification.Name(rawValue: "getDeviceInfo_success"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getDeviceInfoFail), name: NSNotification.Name(rawValue: "getDeviceInfo_fail"), object: nil)
    }
    //MARK: 1.开始扫描蓝牙设备
    func startScanBluetoothDevice(){
        uuid_this_v = "ScanDeviceListVC_" + getRandomDigitsString()
        BluetoothManager.shared.delegate = self
        BluetoothManager.shared.startScanBluetoothDevice(type: uuid_this_v)
    }
    //MARK: 2.蓝牙相关回调代理事件--ZYBluetoothHandlerDelegate
    //MARK: 2.1.发现新设备
    func scanNewDevice(device: CBPeripheral) {
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        let all_Device_data = BluetoothManager.shared.allScanedDevices
        var origin_allModels = [[String: Any]]()
        for value in all_Device_data{
            //显示特定设备
            if let device = value["device"] as? CBPeripheral,
               (device.name ?? "").contains("navbot"){
                var newDeviceValue = value
                newDeviceValue["isConnected"] = false
                origin_allModels.append(newDeviceValue)
            }
            //显示所有设备
            //origin_allModels.append(value)
        }
        //仅在计数发生变化时更新视图，否则频繁刷新可能会导致单元格的点击事件无响应。
        if allModels.count != origin_allModels.count{
            allModels = origin_allModels
            myTableView.reloadData()
        }
    }
    //MARK: 2.2.连接设备已成功——此时还未监听服务和特征
    func connectDeviceSuccess(device: CBPeripheral) {
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
    }
    //MARK: 2.3.连接设备已失败——此时还未监听服务和特征
    func connectDeviceFailtrue(device: CBPeripheral) {
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        MBProgressHUD.showText(text: "Failed to connect to navbot.", view: view)
    }
    //MARK: 2.4.断开设备连接
    func disconnectDevice(device: CBPeripheral) {
        if BluetoothManager.shared.fromVCType != uuid_this_v{
           return
        }
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        //[["isConnected": true, "identifier": "6D3B997D-5828-05CB-C98E-FC6A36C01574", "name": "navbot_en01-wz3h9a","device_info":{}]]
        //如果存在该设备，改变其状态：
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
        
        print("搜索设备页面--设备断开连接--本地设备数据为：",allScanedDevices)
    }
    //MARK: 3.通知事件--链接设备成功通知事件--此时已经成功找到并开始监听服务和特征
    @objc func alreadyConnectedDevice(){
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        print("链接设备成功通知事件--此时已经成功找到并开始监听服务和特征")
        gotoGetDeviceInfo()
    }
    
    //MARK: 4.列表回调代理事件--UITableViewDelegate, UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.allModels.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchingDeviceCellID", for: indexPath) as? SearchingDeviceCell ?? SearchingDeviceCell()
        cell.selectionStyle = .none
        cell.cellDict = allModels[indexPath.row]
        cell.initCell()
        return cell
    }
    //MARK: 4.1.点击设备并开始连接设备:
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let currentDevice = allModels[indexPath.row]["device"] as? CBPeripheral else{return}
        if (currentDevice.name ?? "").contains("navbot"){
            self.currentHUDMessage = MBProgressHUD.showJuHuaAndTitle(title: "Connecting...", view: self.view)
            BluetoothManager.shared.startConnectionDevice(device: currentDevice)
        }else{
            MBProgressHUD.showText(text: "Please select NavBot devcie.", view: self.view)
        }
    }
    
   //MARK: 5.连接成功后，需要获取一次设备信息:
    func gotoGetDeviceInfo(){
        GetDeviceInfoBluetoothManager.shared.sendBluetoothDataWith(type: uuid_this_v)
    }
    //MARK: 5.1.获取设备信息--成功
    @objc func getDeviceInfoSuccess(){
        if (GetDeviceInfoBluetoothManager.shared.fromVCType != uuid_this_v){
            return
        }
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        print("获取设备信息成功")
        
        //(1).首先判断本地中是否已经存在该设备了。有的话先删除
        var allScanedDevices = UserDefaults.standard.value(forKey: "allScanedDevices") as? [[String: Any]] ?? [[String: Any]]()
        var currentIndex: Int? = nil
        for (index, value) in allScanedDevices.enumerated(){
            if (value["identifier"] as? String ?? "") == BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString{
                currentIndex = index
            }
        }
        if currentIndex != nil{
            print("本地数据中已经存在该设备了，现在将它删除")
            allScanedDevices.remove(at: currentIndex!)
        }
        
        var new_allScanedDevices = [[String: Any]]()
        //(2).其他设备都应该变为：未连接
        for item in allScanedDevices{
            var newItem = item
            newItem["isConnected"] = false
            new_allScanedDevices.append(newItem)
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
        new_allScanedDevices.insert(current_connected_device, at: 0)
        
        //(4).存储本地数据:
        UserDefaults.standard.setValue(new_allScanedDevices, forKey: "allScanedDevices")
        UserDefaults.standard.synchronize()
        print("搜索设备页面--设备成功连接--成功获取设备信息--本地设备数据为：",new_allScanedDevices)
     
        //(5).发送通知，刷新本地设备列表，返回上一页
        MBProgressHUD.ShowSuccessMBProgresssHUD(view: view, title: "Successfully Connected.") {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateLocalDeviceList"), object: nil)
                self.backVCBlock?()
                self.dismiss(animated: true)
            }
        }
    }
    //MARK: 5.2.获取设备信息--失败
    @objc func getDeviceInfoFail(){
        if (GetDeviceInfoBluetoothManager.shared.fromVCType != uuid_this_v){
            return
        }
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        MBProgressHUD.showErrorText(text: "Failed to get device info.", view: view)
        print("获取设备信息失败")
        
        //主动断开连接：
        BluetoothManager.shared.disconnectDevice()
    }
    deinit{
        NotificationCenter.default.removeObserver(self)
    }
  

}
