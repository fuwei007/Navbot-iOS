import Foundation

class CalibrateServoBuluetoothManager: NSObject {
    
    var isHaveRecievedData = false
    var fromVCType = ""
    var origin_send_command_number = 0
    var currentDeviceInfo = [String: Any]()
  
    //MARK: 1.初始化-单例
    static let shared = CalibrateServoBuluetoothManager()
    private override init(){
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(receivedAllDataFromPudcamDevice), name: Notification.Name(rawValue: "receiveAllDataFromReadCharacterSuccess"), object: nil)
    }
    //MARK: 2.包装数据并发送数据
    func sendBluetoothDataWith(type: String){
        fromVCType = type
        
        //1.参数数据转为[UInt8] (byte array)
        var param_command_bytes = [UInt8]()
        let param_dict: [String: Any] = ["type": "calibrate_servo"]
        do{
            let param_data = try JSONSerialization.data(withJSONObject: param_dict, options: [])
            let param_byte_array = [UInt8](param_data)
            param_command_bytes = param_byte_array
        }catch{
            print("转化数据--失败")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "calibrate_servo_fail"), object: nil)
        }
        
        //2.拼接指令：
        var command_bytes: [UInt8] = [UInt8]()
        //2.1.一共几个包
        var number_package: Int = 0
        if param_command_bytes.count % 15 == 0{
            number_package = param_command_bytes.count/15
        }else{
            number_package = param_command_bytes.count/15  + 1
        }
        //2.2.开始拼接包
        for i in 0..<number_package{
            //Byte1 --> Header1 --> 0x55
            command_bytes.append(0x55)
            //Byte2 --> Header2 --> 0xAA
            command_bytes.append(0xAA)
            //Byte3 --> Command Type --> 0x02
            //0x02表示，后面的数据为JSON类型
            command_bytes.append(0x02)
            //Byte4 --> Remaining--> 0x00
            //分包的索引 从大到小 ，如果两包的话就是01到00
            command_bytes.append(UInt8(number_package-i-1))
            //Byte5 --> Null --> 0x00
            command_bytes.append(0x00)
            //Byte 6 ～～～Byte 20:
            //Body data: JSON body,Transmission can be subcontracted.
            for j in (0+i*15)..<(15+i*15){
                if j < param_command_bytes.count{
                    command_bytes.append(param_command_bytes[j])
                }else{
                    command_bytes.append(0x00)
                }
            }
        }
        
        print("<====================>")
        let comand_Hexadecimal = convertDecimalToHexadecimal(decimalBytes: command_bytes)
        print("发送蓝牙指令\n-->Type: Calibrate Servo\n-->页面类型:\(fromVCType)\n-->指令：\(comand_Hexadecimal)")
        print("<====================>")
        
        //3.将16进制数据转为Data
        origin_send_command_number = command_bytes.count
        let command_Data = Data(bytes: command_bytes, count: command_bytes.count)
        
        //4.发送二进制数据
        isHaveRecievedData = false
        if !BluetoothManager.shared.writeDataToDevice(writeData: command_Data, dataType: "calibrate_servo"){
            //print("getDeviceInfo--\(type)--发送命令失败")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "calibrate_servo_fail"), object: nil)
        }else{
            //现在等待返回数据--如果10秒内没有返回数据，就认为失败了
            DispatchQueue.main.asyncAfter(deadline: .now()+10.0, execute: {
                if !self.isHaveRecievedData{
                    print("Calibrate Servo_step--10秒内设备没有返回信息，直接认为操作失败了")
                    BluetoothManager.shared.isReceiveData = "notRecieved"
                    BluetoothManager.shared.recieveData_type = ""
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "calibrate_servo_fail"), object: nil)
                }
            })
        }
    }
    //MARK: 2.2.发送指令成功
    @objc func receivedAllDataFromPudcamDevice(){
        if BluetoothManager.shared.recieveData_type != "calibrate_servo"{
            return
        }
        BluetoothManager.shared.isReceiveData = "notRecieved"
        BluetoothManager.shared.recieveData_type = ""
        
        //1.接收到数据
        isHaveRecievedData = true
        
        //2.解析数据
        let allReceiveData_bytes = BluetoothManager.shared.allRecieveData
        let allReceiveData_ASII = convertDecimalToHexadecimal(decimalBytes: allReceiveData_bytes)
        print("CalibrateServo--收到的数据:\(allReceiveData_ASII)")
        
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
        //print("Calibrate_Servo--收到的数据2:\(allReceiveData_ASII2)")
        
        //2.3.解析正文数据--JSON字符串
        let jsonData = Data(all_content_bytes)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("解析出的JSON字符串:", jsonString)
        } else {
            print("无法解析成UTF-8字符串")
            //NotificationCenter.default.post(name: Notification.Name(rawValue: "calibrate_servo_fail"), object: nil)
            //return
        }
        // 2.4.解析正文数据--字典
        if let dict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
            print("解析成字典:", dict)
            //NotificationCenter.default.post(name: Notification.Name(rawValue: "calibrate_servo_fail"), object: nil)
            //return
        }else {
            print("无法解析成字典")
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "calibrate_servo_success"), object: nil)
    }
    
}



