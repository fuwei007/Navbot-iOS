
import Foundation

class JumpBluetoothManager: NSObject {
    
    var isHaveRecievedData_first = false
    var isHaveRecievedData_second = false
    var fromVCType = ""
    
    //MARK: 1.初始化-单例
    static let shared = JumpBluetoothManager()
    private override init(){
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(receivedAllDataFromPudcamDevice), name: Notification.Name(rawValue: "receiveAllDataFromReadCharacterSuccess"), object: nil)
    }
    //MARK: 2.包装数据并发送数据
    //分两步：
    //发送jump==1的指令
    //成功后再发送jump==0的指令
    //MARK: 2.1.发送jump==1的指令
    func sendBluetoothDataWith(type: String){
        
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
        command_bytes.append(0x01)
        //Byte14 --> joy_y --> The Y-axis data of the joystick, with a value range of -100 to 100.
        command_bytes.append(0x00)
        //Byte15 --> joy_x --> The X-axis data of the joystick, with a value range of -100 to 100.
        command_bytes.append(0x00)
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
        print("发送蓝牙指令\n-->Type: Jump_First_Step\n-->页面类型:\(fromVCType)\n-->指令：\(comand_Hexadecimal)")
        print("<====================>")
        
        //2.将16进制数据转为Data
        let command_Data = Data(bytes: command_bytes, count: command_bytes.count)
        
        //3.发送二进制数据
        isHaveRecievedData_first = false
        if !BluetoothManager.shared.writeDataToDevice(writeData: command_Data, dataType: "deviceJump_first_step"){
            //print("SetTimePudcam--\(type)--发送命令失败")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "deviceJump_fail"), object: nil)
        }else{
            //现在等待返回数据--如果10秒内没有返回数据，就认为失败了
            DispatchQueue.main.asyncAfter(deadline: .now()+10.0, execute: {
                if !self.isHaveRecievedData_first{
                    print("deviceJump_first_step--10秒内设备没有返回信息，直接认为操作失败了")
                    BluetoothManager.shared.isReceiveData = "notRecieved"
                    BluetoothManager.shared.recieveData_type = ""
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "deviceJump_fail"), object: nil)
                }
            })
        }
    }
    //MARK: 2.2.发送jump==1的指令成功 + 发送jump==0的指令成功
    @objc func receivedAllDataFromPudcamDevice(){
        if BluetoothManager.shared.recieveData_type == "deviceJump_first_step"{
            //结束此次指令
            BluetoothManager.shared.isReceiveData = "notRecieved"
            BluetoothManager.shared.recieveData_type = ""
            //接收到数据
            isHaveRecievedData_first = true
            //解析数据
            let allReceiveData_bytes = BluetoothManager.shared.allRecieveData
            let allReceiveData_ASII = convertDecimalToHexadecimal(decimalBytes: allReceiveData_bytes)
            print("Jump_First_Step--收到的数据:\(allReceiveData_ASII)")
            //目前只要接收到的数据和发送的数据是一样的，就认为成功了
            //去发送第二段的蓝牙指令
            sendBluetoothSecondStepDataWith(type: fromVCType)
        }else if BluetoothManager.shared.recieveData_type == "deviceJump_second_step"{
            //结束此次指令
            BluetoothManager.shared.isReceiveData = "notRecieved"
            BluetoothManager.shared.recieveData_type = ""
            //接收到数据
            isHaveRecievedData_second = true
            //解析数据
            let allReceiveData_bytes = BluetoothManager.shared.allRecieveData
            let allReceiveData_ASII = convertDecimalToHexadecimal(decimalBytes: allReceiveData_bytes)
            print("Jump_Second_Step--收到的数据:\(allReceiveData_ASII)")
            //目前只要接收到的数据和发送的数据是一样的，就认为成功了
            NotificationCenter.default.post(name: Notification.Name(rawValue: "deviceJump_success"), object: nil)
        }
        
    }
    //MARK: 2.3.发送jump==0的指令
    func sendBluetoothSecondStepDataWith(type: String){
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
        command_bytes.append(0x00)
        //Byte7 --> height --> The height of the robot, with a value range of 32 to 85.
        let device_height = BaseHeightBluetoothManager.shared.baseHeight_current
        command_bytes.append(UInt8(device_height))
        //Byte8 --> linear_H --> Linear speed, with a value range of -200 to 200.
        command_bytes.append(0x00)
        //Byte9 --> linear_Y --> Linear speed, with a value range of -200 to 200.
        command_bytes.append(0x00)
        //Byte10 --> angular --> The angular velocity of the robot, with a value range of -100 to 100.
        command_bytes.append(0x00)
        //Byte11 --> stable --> The stable state of the robot: 1 on, 0 off
        command_bytes.append(0x01)
        //Byte12 --> mode --> Fixed: 0x01
        command_bytes.append(0x01)
        //Byte13 --> dir --> The movement direction of the robot is defaulted to 0, jump:1
        command_bytes.append(0x00)
        //Byte14 --> joy_y --> The Y-axis data of the joystick, with a value range of -100 to 100.
        command_bytes.append(0x00)
        //Byte15 --> joy_x --> The X-axis data of the joystick, with a value range of -100 to 100.
        command_bytes.append(0x00)
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
        print("发送蓝牙指令\n-->Type: Jump_Second_Step\n-->页面类型:\(fromVCType)\n-->指令：\(comand_Hexadecimal)")
        print("<====================>")
        
        //2.将16进制数据转为Data
        let command_Data = Data(bytes: command_bytes, count: command_bytes.count)
        
        //3.发送二进制数据
        isHaveRecievedData_second = false
        if !BluetoothManager.shared.writeDataToDevice(writeData: command_Data, dataType: "deviceJump_second_step"){
            //print("SetTimePudcam--\(type)--发送命令失败")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "deviceJump_fail"), object: nil)
        }else{
            //现在等待返回数据--如果10秒内没有返回数据，就认为失败了
            DispatchQueue.main.asyncAfter(deadline: .now()+10.0, execute: {
                if !self.isHaveRecievedData_second{
                    print("10秒内设备没有返回信息，直接认为操作失败了")
                    BluetoothManager.shared.isReceiveData = "notRecieved"
                    BluetoothManager.shared.recieveData_type = ""
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "deviceJump_fail"), object: nil)
                }
            })
        }
    }
    
}
