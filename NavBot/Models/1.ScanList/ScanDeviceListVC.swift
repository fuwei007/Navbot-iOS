
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
        initBluetooth()
        startScanBluetoothDevice()
    }
    @IBAction func clickBackTap(_ sender: Any) {
        dismiss(animated: true)
    }
    //MARK: 1.Init blutooth manager and start scan blutooth device
    func initBluetooth(){
        NotificationCenter.default.addObserver(self, selector: #selector(alreadyConnectedDevice), name: NSNotification.Name(rawValue: "setNotifyValueSuccess"), object: nil)
        myTableView.register(UINib(nibName: "SearchingDeviceCell", bundle: .main), forCellReuseIdentifier: "SearchingDeviceCellID")
        myTableView.delegate = self
        myTableView.dataSource = self
    }
    func startScanBluetoothDevice(){
        uuid_this_v = "ScanDeviceListVC_" + getRandomDigitsString()
        BluetoothManager.shared.delegate = self
        BluetoothManager.shared.startScanBluetoothDevice(type: uuid_this_v)
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
            if let device = value["device"] as? CBPeripheral,
               (device.name ?? "").contains("navbot"){
                var newDeviceValue = value
                newDeviceValue["isConnected"] = false
                origin_allModels.append(value)
            }
            //Display all devices
            //origin_allModels.append(value)
        }
        //Only update the view when the count changes, otherwise frequent refreshing may cause tap events on cells to be unresponsive
        if allModels.count != origin_allModels.count{
            allModels = origin_allModels
            myTableView.reloadData()
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
        MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage)
        var allScanedDevices = [[String: Any]]()
        for item in allModels{
            if let currentDevice = item["device"] as? CBPeripheral,
               (currentDevice.name ?? "").contains("navbot"){
                var newItem = [String: Any]()
                newItem["identifier"] = currentDevice.identifier.uuidString
                newItem["name"] = currentDevice.name
                if currentDevice.identifier.uuidString == BluetoothManager.shared.current_connecting_CBPeripheral?.identifier.uuidString{
                    newItem["isConnected"] = false
                }else{
                    newItem["isConnected"] = item["isConnected"] as? Bool ?? false
                }
                allScanedDevices.append(newItem)
            }
        }
        UserDefaults.standard.setValue(allScanedDevices, forKey: "allScanedDevices")
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateLocalDeviceList"), object: nil)
    }
    //MARK: Connected Device Success
    //Successfully connected to the device -- Set Notify Success
    @objc func alreadyConnectedDevice(){
        if BluetoothManager.shared.fromVCType != uuid_this_v{
            return
        }
        var allScanedDevices = [[String: Any]]()
        for item in allModels{
            if let currentDevice = item["device"] as? CBPeripheral,
               (currentDevice.name ?? "").contains("navbot"){
                var newItem = [String: Any]()
                newItem["identifier"] = currentDevice.identifier.uuidString
                newItem["name"] = currentDevice.name
                if currentDevice.identifier == BluetoothManager.shared.current_connecting_CBPeripheral?.identifier{
                    newItem["isConnected"] = true
                }else{
                    newItem["isConnected"] = false
                }
                allScanedDevices.append(newItem)
            }
        }
        UserDefaults.standard.setValue(allScanedDevices, forKey: "allScanedDevices")
        UserDefaults.standard.synchronize()
            MBProgressHUD.ShowSuccessMBProgresssHUD(view: view, title: "Successfully Connected.") {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateLocalDeviceList"), object: nil)
                self.backVCBlock?()
                self.dismiss(animated: true)
            }
        }
    }
    
    //MARK: UITableViewDelegate, UITableViewDataSource
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
    //MARK: 2. Select a device from the device list and manually connect:
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let currentDevice = allModels[indexPath.row]["device"] as? CBPeripheral else{return}
        if (currentDevice.name ?? "").contains("navbot"){
            self.currentHUDMessage = MBProgressHUD.showJuHuaAndTitle(title: "Connecting...", view: self.view)
            BluetoothManager.shared.startConnectionDevice(device: currentDevice)
        }else{
            MBProgressHUD.showText(text: "Please select NavBot devcie.", view: self.view)
        }
    }
    deinit{
        NotificationCenter.default.removeObserver(self)
    }
  

}
