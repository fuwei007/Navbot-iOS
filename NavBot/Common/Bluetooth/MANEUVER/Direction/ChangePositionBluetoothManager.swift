
import Foundation

class ChangePositionBluetoothManager: NSObject {
    
    var isHaveRecievedData = false
    var isSendingData = false
    var fromVCType = ""
    
    var x_current: Int32 = 0
    var y_current: Int32 = 0
    
    var x_willChanged: Int32 = 0
    var y_willChanged: Int32 = 0
    
    
    //MARK: 1.初始化-单例
    static let shared = ChangePositionBluetoothManager()
    private override init(){
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(receivedAllDataFromPudcamDevice), name: Notification.Name(rawValue: "receiveAllDataFromReadCharacterSuccess"), object: nil)
    }
    //MARK: 2.包装数据并发送数据
    func sendBluetoothDataWith(type: String){
        
        if isSendingData{
            return
        }
        
        fromVCType = type
        
        //1.拼接16进制数据-蓝牙指令
        var command_bytes: [UInt8] = [UInt8]()
        //Byte1 --> Header1 --> 0x55
        //Byte2 --> Header2 --> 0xAA
        command_bytes.append(0x55)
        command_bytes.append(0xAA)
        //Byte3 --> Null --> 0x00
        //Byte4 --> Null --> 0x00
        //Byte5 --> Null --> 0x00
        command_bytes.append(0x00)
        command_bytes.append(0x00)
        command_bytes.append(0x00)
        //Byte6 --> roll --> Rolling Angle, value range -30 to 30.
        command_bytes.append(UInt8(bitPattern: Int8(RollBluetoothManager.shared.current_roll)))
        //Byte7 --> height --> The height of the robot, with a value range of 32 to 85.
        let device_height = BaseHeightBluetoothManager.shared.baseHeight_current
        command_bytes.append(UInt8(device_height))
        //Byte8 --> linear_H --> Linear speed, with a value range of -200 to 200.
        //Byte9 --> linear_L --> Linear speed, with a value range of -200 to 200.
        let (linear_H, linear_L) = encodeLinear(Int16(LinearVelBluetoothManager.shared.current_Linear_Vel))
        command_bytes.append(linear_H)
        command_bytes.append(linear_L)
        //Byte10 --> angular --> The angular velocity of the robot, with a value range of -100 to 100.
        command_bytes.append(UInt8(bitPattern: Int8(AngularVelBluetoothManager.shared.current_Angular_Vel)))
        //Byte11 --> stable --> The stable state of the robot: 1 on, 0 off
        //Must is 1
        command_bytes.append(0x01)
        //Byte12 --> mode --> Fixed: 0x01
        command_bytes.append(0x01)
        //Byte13 --> dir --> The movement direction of the robot is defaulted to 0, jump:1
        command_bytes.append(0x00)
        //Byte14 --> joy_y --> The Y-axis data of the joystick, with a value range of -100 to 100.
        print("y---->:\(y_willChanged)")
        //在 y_willChanged 是正数时（0～127），它们得到的十六进制值是一样的。
        //但是在 负数时（-1 到 -128）,会自动通过补码方式获取到负数的十六进制值。
        command_bytes.append(UInt8(bitPattern: Int8(y_willChanged)))
        //Byte15 --> joy_x --> The X-axis data of the joystick, with a value range of -100 to 100.
        print("x---->:\(x_willChanged)")
        command_bytes.append(UInt8(bitPattern: Int8(x_willChanged)))
        //Byte16 --> Null --> 0x00
        command_bytes.append(0x00)
        //Byte17 --> Null --> 0x00
        command_bytes.append(0x00)
        //Byte18 --> Null --> 0x00
        command_bytes.append(0x00)
        //Byte19 --> Null --> 0x00
        command_bytes.append(0x00)
        //Byte20 --> Null --> 0x00
        command_bytes.append(0x00)
        
        print("<====================>")
        let comand_Hexadecimal = convertDecimalToHexadecimal(decimalBytes: command_bytes)
        print("发送蓝牙指令\n-->Type: Change Position\n-->页面类型:\(fromVCType)\n-->指令：\(comand_Hexadecimal)")
        print("<====================>")
        
        //2.将16进制数据转为Data
        let command_Data = Data(bytes: command_bytes, count: command_bytes.count)
        
        //3.发送二进制数据
        isHaveRecievedData = false
        isSendingData = true
        
        if !BluetoothManager.shared.writeDataToDevice(writeData: command_Data, dataType: "ChangeDevicePosition"){
            //print("SetTimePudcam--\(type)--发送命令失败")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ChangeDevicePosition_fail"), object: nil)
        }else{
            //现在等待返回数据--如果10秒内没有返回数据，就认为失败了
            DispatchQueue.main.asyncAfter(deadline: .now()+5.0, execute: {
                if self.isHaveRecievedData == false{
                    print("5秒内设备没有返回信息，直接认为操作失败了")
                    BluetoothManager.shared.isReceiveData = "notRecieved"
                    BluetoothManager.shared.recieveData_type = ""
                    self.isSendingData = false
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "ChangeDevicePosition_fail"), object: nil)
                }
            })
        }
    }
    //MARK: 3.完成接收数据
    @objc func receivedAllDataFromPudcamDevice(){
        if BluetoothManager.shared.recieveData_type != "ChangeDevicePosition"{
            return
        }
        //结束此次指令
        BluetoothManager.shared.isReceiveData = "notRecieved"
        BluetoothManager.shared.recieveData_type = ""
        //接收到数据
        isHaveRecievedData = true
        //解析数据
        let allReceiveData_bytes = BluetoothManager.shared.allRecieveData
        let allReceiveData_ASII = convertDecimalToHexadecimal(decimalBytes: allReceiveData_bytes)
        print("SetupBaseHeigh--收到的数据:\(allReceiveData_ASII)")
        //目前只要接收到的数据和发送的数据是一样的，就认为成功了
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ChangeDevicePosition_success"), object: nil)
        //刷新数据
        x_current = x_willChanged
        y_current = y_willChanged
        //可以执行下一个命令了
        isSendingData = false
    }
}
