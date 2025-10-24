
import UIKit
import CoreBluetooth

let SERVICE_UUID = "6E400011-B5A3-F393-E0A9-E50E24DCCA9E"//连接设备的此服务（UUID）
let CHARACTERISTIC_WRITE_UUID = "6E400012-B5A3-F393-E0A9-E50E24DCCA9E"//连接此服务的此特征（UUID），用于发送数据
let CHARACTERISTIC_NOTIFY_UUID = "6E400013-B5A3-F393-E0A9-E50E24DCCA9E"//连接此服务的此特征（UUID），用于接受数据

protocol ZYBluetoothHandlerDelegate: NSObjectProtocol{
    //扫描到新设备时调用方法
    func scanNewDevice(device: CBPeripheral)
    //连接设备成功回调方法
    func connectDeviceSuccess(device: CBPeripheral)
    //连接设备失败回调方法
    func connectDeviceFailtrue(device: CBPeripheral)
    //断开连接回调方法
    func disconnectDevice(device: CBPeripheral)
}
enum DeviceConnectedStatus{
    case notConnected
    case conencting
    case connected
    case notKnown
}

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager!//需要在单例初始化时创建，全局唯一
    var isScanning = false//是否正在扫描设备
    var allScanedDevices = [[String: Any]]()//扫描到的所有设备和它的距离
    //[[""device": CBPeripheral, "distance": float]]
    weak var delegate: ZYBluetoothHandlerDelegate?//代理方法
    
    var current_connecting_CBPeripheral: CBPeripheral?//正在和手机相连接的蓝牙设备
    var current_connecting_service: CBService? //正在和手机相连接的蓝牙设备-->指定的服务
    var current_connecting_read_character: CBCharacteristic? //正在和手机相连接的蓝牙设备-->指定的读取数据-特征对象
    var current_connecting_write_character: CBCharacteristic? //正在和手机相连接的蓝牙设备-->指定的写入数据-特征对象
    
    var device_connected_status: DeviceConnectedStatus = .notKnown//当前的状态,连接设备状态
    var isReceiveData = "notRecieved"//是否正在接收数据:notRecieved receiving
    var recieveData_type = ""//正在接受数据的类型，以便接收数据后进行操作
    var allRecieveData = [UInt8]()//已经接收到的数据
    var receiveData_Timer: Timer?//分段接受数据，0.5s没有接收下一段数据，则视为接收完成
    
    //重新连接：
    var isNeedAutoConnectDevice = false
    var isNeedAutoConnectDevice_curentDevice_name = ""
    var isNeedAutoConnectDevice_curentDevice_id = ""
    
    //现在是在那个页面操作：
    var fromVCType = ""
    

    //MARK: 1.初始化-单例
    static let shared = BluetoothManager()
    private override init(){
        super.init()
        print("初始化单例-实例对象：BluetoothManager")
        centralManager = CBCentralManager.init(delegate: self, queue: DispatchQueue.main)
    }
    
    //MARK: 2.开始扫描设备
    func startScanBluetoothDevice(type: String){
        // 停止上一次扫描
        stopScanBluetoothDevice()
        // 清空设备列表
        allScanedDevices = [[String: Any]]()
        // 页面标记
        fromVCType = type
        print("开始扫描设备:\(type)")
        // 停止后重新开始会重新扫描所有设备
        centralManager.scanForPeripherals(withServices: nil)
        // 扫描状态标记
        isScanning = true
    }
    //停止扫描
    func stopScanBluetoothDevice(){
        centralManager.stopScan()
    }
    //创建CBCentralManager，会回调centralManagerDidUpdateState方法
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state{
        case .unknown:
            print("未知状态")
        case .resetting:
            print("重置中")
        case .unsupported:
            print("平台不支持蓝牙")
        case .unauthorized:
            print("蓝牙权限未授权")
        case .poweredOff:
            print("蓝牙是关闭状态，需要打开才能连接蓝牙外设")
            //手机主动断开蓝牙设备后，会走此回调：
            if device_connected_status == .connected,
               current_connecting_CBPeripheral != nil{
                //(1).需要断开设备链接：
                disconnectDevice()
                //(2).在未链接蓝牙的情况下，不会走“断开连接”的回调，需要手动去触发方法
                self.delegate?.disconnectDevice(device: current_connecting_CBPeripheral!)
            }

        case .poweredOn:
            print("蓝牙已开启，允许连接蓝牙外设")
            //(2).扫描设备
            central.scanForPeripherals(withServices: nil)
            isScanning = true
            //withServices：nil表示扫描所有的蓝牙设备
            //每当扫描到新设备时，自动回调方法centralManager-didDiscover
        default:
            print("未知状态")
        }
    }
    //MARK: 回调方法--成功扫描到设备
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let device_name = peripheral.name else{return}
        //print("扫描到新设备：\(device_name), RSSI:\(getDistance(RSSI: RSSI))")
        //print("扫描到新设备：\(device_name)")
        var isExistInArray = false
        var isExistInArray_index: Int?
        for (index, value) in allScanedDevices.enumerated(){
            if let device = value["device"] as? CBPeripheral{
                if device.identifier == peripheral.identifier{
                    isExistInArray = true
                    isExistInArray_index = index
                }
            }
        }
        if !isExistInArray{
            let nowData: [String: Any] = ["device": peripheral]
            allScanedDevices.append(nowData)
            delegate?.scanNewDevice(device: peripheral)
        }else{
            let nowData: [String: Any] = ["device": peripheral]
            let range = isExistInArray_index!..<isExistInArray_index!+1
            allScanedDevices.replaceSubrange(range, with: [nowData])
            delegate?.scanNewDevice(device: peripheral)
        }
        //是否重新连接设备
        if isNeedAutoConnectDevice && isNeedAutoConnectDevice_curentDevice_name.count > 0{
            if device_name == isNeedAutoConnectDevice_curentDevice_name{
                startConnectionDevice(device: peripheral)
                isNeedAutoConnectDevice = false
                isNeedAutoConnectDevice_curentDevice_name = ""
                isNeedAutoConnectDevice_curentDevice_id = ""
            }
        }
    }
    //MARK: 3.开始连接设备
    func startConnectionDevice(device: CBPeripheral){
        //先断开上一个设备的连接
        if current_connecting_CBPeripheral != nil{
            print("当前设备的连接状态1:\(current_connecting_CBPeripheral!.state)")
            if device_connected_status == .connected ||
                device_connected_status == .conencting{
                print("断开正在连接的设备:\(current_connecting_CBPeripheral?.name ?? "")")
                centralManager.cancelPeripheralConnection(current_connecting_CBPeripheral!)
                device_connected_status = .notConnected
            }
            print("当前设备的连接状态2:\(device_connected_status)")
            if current_connecting_CBPeripheral?.state == .connecting ||
                current_connecting_CBPeripheral?.state == .connected{
                print("断开正在连接的设备2:\(current_connecting_CBPeripheral?.name ?? "")")
                centralManager.cancelPeripheralConnection(current_connecting_CBPeripheral!)
                device_connected_status = .notConnected
            }
        }
          
        print("开始连接新设备:\(device.name ?? "")")
        //开始连接设备
        centralManager.connect(device)
        device_connected_status = .conencting
    }
    //MARK: 回调方法--断开连接回调方法
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("断开连接:\(peripheral.name ?? "")")
        //此时回调方法
        device_connected_status = .notConnected
        delegate?.disconnectDevice(device: peripheral)
        //断开连接可以设置重新连接
        //central connectPeripheral:peripheral options:nil];
        //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "BluetoothIsDisconnected"), object: nil)
    }
    //MARK: 回调方法--连接设备失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("连接失败:\(peripheral.name ?? "")")
        delegate?.connectDeviceFailtrue(device: peripheral)
        device_connected_status = .notConnected
    }
    //MARK: 回调方法--连接设备成功-->去寻找服务
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("连接成功:\(peripheral.name ?? "")")
        //当前连接成功的外设对象
        self.current_connecting_CBPeripheral = peripheral
        //可以停止扫描，也可以不用停止扫描,不停止的话很耗电--不停止扫描吧，在退出页面是否手动停止扫描
        //centralManager.stopScan()
        //设置代理:CBPeripheralDelegate
        peripheral.delegate = self
        //调用自己的回调方法
        print("连接到设备:\(current_connecting_CBPeripheral?.state.rawValue)")
        if current_connecting_CBPeripheral?.state == .connected{
            device_connected_status = .connected
            delegate?.connectDeviceSuccess(device: peripheral)
            //*****连接成功后，此时通过外设对象，寻找服务，可以通过UUID寻找
            //自动回调方法--寻找特定服务/寻找所有服务
            //peripheral.discoverServices([CBUUID(string: SERVICE_UUID)])//无效，还是去寻找了所有的服务
            peripheral.discoverServices(nil)//寻找所有服务
        }
       
    }
    //MARK:  回调方法--寻找到服务-->扫描特定服务的特征值
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //遍历所有的服务
        guard let services = peripheral.services else{
            print("该外设没有服务")
            return
        }
        for value in services{
            print("遍历所有的服务：\(value)")
            if value.uuid.uuidString == SERVICE_UUID{
                //根据UUID寻找服务中的特征
                self.current_connecting_service = value
                //peripheral.discoverCharacteristics([CBUUID(string: CHARACTERISTIC_WRITE_UUID), CBUUID(string: CHARACTERISTIC_NOTIFY_UUID)], for: value)
                peripheral.discoverCharacteristics(nil, for: value)
            }
        }
    }
    //MARK:  回调方法--寻找到服务的特征值-->订阅读取特征
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else{
            print("该服务没有特征")
            return
        }
        for value in characteristics{
            print("遍历所有的特征：\(value)")
            // 从外设开发人员那里拿到不同特征的UUID，不同特征做不同事情，比如有读取数据的特征，也有写入数据的特征
            if value.uuid.uuidString == CHARACTERISTIC_NOTIFY_UUID{
                //获取蓝牙设备，监听指定特征（读取数据特征）
                self.current_connecting_read_character = value
                peripheral.setNotifyValue(true, for: self.current_connecting_read_character!)
            }
            if value.uuid.uuidString == CHARACTERISTIC_WRITE_UUID{
                self.current_connecting_write_character = value
            }
        }
    }
    //MARK:  回调方法--特征值的状态，发生了改变-->在这里判断:订阅读取特征是否成功
    //MARK:  接收到通知：setNotifyValueSuccess，连接设备流程走完
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil{
            print("订阅失败：\(error!),characteristic:\(characteristic)")
        }else{
            if characteristic.isNotifying{
                print("订阅成功")
                NotificationCenter.default.post(name: Notification.Name(rawValue: "setNotifyValueSuccess"), object: nil)
            }else{
                print("订阅取消")
            }
        }
    }
    
    //MARK: 4.中心设备给外设发送数据
    //发送数据都是发送一个二进制文件：[Byte]-->Data
    func writeDataToDevice(writeData: Data, dataType: String) -> Bool{
        //1.判断是否连接了设备
        if device_connected_status != .connected{
            print("没有连接设备1")
            return false
        }
        if current_connecting_CBPeripheral?.state != .connected{
            print("没有连接设备2:\(current_connecting_CBPeripheral?.state.rawValue)")
            return false
        }
        //2.判断是否正在接收数据
        if isReceiveData == "receiving"{
            print("正在接收数据")
            return false
        }
        //3.判断是否有连接的蓝牙设备
        if self.current_connecting_CBPeripheral == nil {
            return false
        }
        //4.判断写入特征值是否存在
        if self.current_connecting_write_character == nil{
            return false
        }
        //5.必须告诉单例，正在操作的数据类型，接收数据时才能对应上是谁发回来的数据
        if dataType.count == 0{
            return false
        }
        //6.
        
        //6.开始写入数据
        //写入最大数据的长度 每次发送20个数据
        var maxLength = self.current_connecting_CBPeripheral!.maximumWriteValueLength(for: .withResponse)
        if maxLength >= 20{
            maxLength = 20
        }
        recieveData_type = dataType
        allRecieveData = [UInt8]()//清空上一个接收的数据
        
        //7.写入数据--每次最多写入20字节数据,如果大于20字节需要多次写入数据
        var index = 0
        while(true){
            if index >= writeData.count{
                break
            }
            if index + maxLength >= writeData.count{
                let current_writeData = writeData.subdata(in: index..<(writeData.count))
                //current_connecting_CBPeripheral!.writeValue(current_writeData, for: current_connecting_write_character!, type: .withResponse)
                current_connecting_CBPeripheral!.writeValue(current_writeData, for: current_connecting_write_character!, type: .withResponse)
                
                let byteArray: [UInt8] = [UInt8](current_writeData)
                let comand_Hexadecimal = convertDecimalToHexadecimal(decimalBytes: byteArray)
                //print("本次尝试写入数据:",comand_Hexadecimal)
                break
            }else{
                let current_writeData = writeData.subdata(in: index..<(index+maxLength))
                //self.current_connecting_CBPeripheral!.writeValue(current_writeData, for: current_connecting_write_character!, type: .withResponse)
                self.current_connecting_CBPeripheral!.writeValue(current_writeData, for: current_connecting_write_character!, type: .withResponse)
                
                let byteArray: [UInt8] = [UInt8](current_writeData)
                let comand_Hexadecimal = convertDecimalToHexadecimal(decimalBytes: byteArray)
                //print("本次尝试写入数据:",comand_Hexadecimal)
                index += maxLength
            }
        }
        return true
    }
    //每一次写入数据的时候，系统都会回调这个方法
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil{
            print("写入数据成功")
        }else{
            print("写入数据发生错误:\(error.debugDescription)")
        }
    }
    //MARK: 5.中心设备接受到数据
    //MARK: 当收到通知：receiveAllDataFromReadCharacterSuccess，表示已经接收完此次的数据
    //分段获取数据，最后隔了0.5秒没有收到数据表示此次数据接收完成
    var allData_noType = [UInt8]()
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //拿到外设发送过来的数据
        //print("拿到外设发送过来的数据\(characteristic.value ?? Data()), type: \(self.recieveData_type)")
        let current_recieveData_type = self.recieveData_type
        if self.recieveData_type.count == 0{
            print("拿到外设发送过来的数据:但是没有页面接受它")
            //5.1.这种情况是没有页面接收，Pudcam设备主动发送数据，这里需要单独处理
            let data = characteristic.value
            if data != nil{
                isReceiveData = "receiving" //notRecieved receiving
                allData_noType.append(contentsOf: data!)
                //此时将倒计时，如果倒计时0.5秒后都没有再次收到消息，表示此时分段收取消息已经结束了,在收取消息阶段不应该再次写入数据获取读取数据
                if receiveData_Timer != nil{
                    receiveData_Timer!.invalidate()
                    receiveData_Timer = nil
                }
                receiveData_Timer = Timer(timeInterval: 0.5, repeats: false, block: { timer in
                    self.isReceiveData = "notRecieved"
                    //print("已经接收数据结束11：\(self.recieveData_type)")
                    //print("已经接收数据结束22：\(current_recieveData_type)")
                    //self.recieveData_type==null
                    //current_recieveData_type=not null
                    self.receiveData_Timer!.invalidate()
                    self.receiveData_Timer = nil
                    //处理这一次接收到的数据
                    self.handleDataFromDeviceOfNotType(allData: self.allData_noType)
                    //重置数据
                    self.allData_noType = [UInt8]()
                })
                RunLoop.current.add(self.receiveData_Timer!, forMode: .common)
          }
        }else{
            //5.2.这种情况是有页面接收，是由App先主动发送指令，然后等待设备返回的数据
            let data = characteristic.value
            if data != nil{
                isReceiveData = "receiving" //notRecieved receiving
                allRecieveData.append(contentsOf: data!)
                //此时将倒计时，如果倒计时0.5秒后都没有再次收到消息，表示此时分段收取消息已经结束了,在收取消息阶段不应该再次写入数据获取读取数据
                if receiveData_Timer != nil{
                    receiveData_Timer!.invalidate()
                    receiveData_Timer = nil
                }
                receiveData_Timer = Timer(timeInterval: 0.5, repeats: false, block: { timer in
                    self.isReceiveData = "notRecieved"
                    //print("已经接收数据结束11：\(self.recieveData_type)")
                    //print("已经接收数据结束22：\(current_recieveData_type)")
                    //self.recieveData_type==null
                    //current_recieveData_type=not null
                    self.recieveData_type = current_recieveData_type
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "receiveAllDataFromReadCharacterSuccess"), object: nil)
                    self.receiveData_Timer!.invalidate()
                    self.receiveData_Timer = nil
                })
                RunLoop.current.add(self.receiveData_Timer!, forMode: .common)
                //也可以根据是否返回0xff 0xbb为结尾 判断是否已经接收完数据，先用这种方法吧
          }
       }
    }
    //MARK: 6.断开设备，并删除所有数据
    func disconnectDevice(){
        if current_connecting_CBPeripheral != nil{
            print("当前设备的连接状态1:\(current_connecting_CBPeripheral!.state)")
            if device_connected_status == .connected ||
                device_connected_status == .conencting{
                print("断开正在连接的设备:\(current_connecting_CBPeripheral?.name ?? "")")
                centralManager.cancelPeripheralConnection(current_connecting_CBPeripheral!)
                device_connected_status = .notConnected
            }
            print("当前设备的连接状态2:\(device_connected_status)")
            if current_connecting_CBPeripheral?.state == .connecting ||
                current_connecting_CBPeripheral?.state == .connected{
                print("断开正在连接的设备2:\(current_connecting_CBPeripheral?.name ?? "")")
                centralManager.cancelPeripheralConnection(current_connecting_CBPeripheral!)
                device_connected_status = .notConnected
            }
        }
    }
    
    //MARK: 7.处理没有页面接收的数据--设备主动发送的数据
    func handleDataFromDeviceOfNotType(allData: [UInt8]){
        print("========================")
        let allReceiveData_bytes = allData
        let allReceiveData_Data = Data(bytes: allReceiveData_bytes, count: allReceiveData_bytes.count)
        let allReceiveData_ASII = convertDecimalToHexadecimal(decimalBytes: allReceiveData_bytes)
        print("处理没有页面接收的数据--设备主动发送的数据:\(allReceiveData_bytes.count)")
        print("处理没有页面接收的数据--设备主动发送的数据:\(allReceiveData_ASII)")
        print("========================")
        
        //2.1.获取Content内容: 每个包的Byte 6 ～～～Byte 20:
        var all_content_bytes = [UInt8]()
        var recieve_package_number = 0
        if (allReceiveData_bytes.count%20 == 0){
            recieve_package_number = allReceiveData_bytes.count/20 + 1
        }else{
            recieve_package_number = allReceiveData_bytes.count/20 + 1
        }
        for i in 0..<recieve_package_number{
            for j in 5+i*20..<20+i*20{
                if j < allReceiveData_bytes.count{
                    all_content_bytes.append(allReceiveData_bytes[j])
                }
            }
        }
        
        //2.2.过滤掉尾部多余的 0x0 （可选）
        all_content_bytes = all_content_bytes.filter { $0 != 0x0 }
        //let allReceiveData_ASII2 = convertDecimalToHexadecimal(decimalBytes: all_content_bytes)
        //print("SetWifi--收到的数据2:\(allReceiveData_ASII2)")
        
        //2.3.解析正文数据--JSON字符串
        let jsonData = Data(all_content_bytes)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("解析出的JSON字符串:", jsonString)
        } else {
            print("无法解析成UTF-8字符串")
            //NotificationCenter.default.post(name: Notification.Name(rawValue: "SetEmoji_fail"), object: nil)
            //return
        }
        // 2.4.解析正文数据--字典
        if let dict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
            print("解析成字典:", dict)
            //return
        }else {
            print("无法解析成字典")
        }
    }
    
    func handleJsonReslutFromDeviceOfNotType(resultDict: [String: Any]){
        
    }
    
    
}



