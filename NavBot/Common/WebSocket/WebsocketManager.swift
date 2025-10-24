
import Foundation

class WebsocketManager: NSObject {
    
    //MARK: 1.初始化-单例:
    static let shared = WebsocketManager()
    private override init(){
        super.init()
    }
    
    //MARK: 2.连接WebSocket(重新链接):
    var webSocketTask: URLSessionWebSocketTask?
    var isConnected = false
    var sendParamDict_type = ""
    var fromVCType = ""
    func startToConnect(url_string: String, fromVC: String){
        //(1).获取连接地址
        guard let connectUrl = URL(string: url_string) else{
            print("获取连接地址失败")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ConnectWebsocketFail"), object: nil)
            return
        }
        //(2).断开旧链接
        if (isConnected == true && webSocketTask != nil){
            webSocketTask?.cancel(with: .goingAway, reason: nil)
            isConnected = false
            webSocketTask = nil
        }
        //(3).开始连接
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: connectUrl)
        webSocketTask?.resume()
        isConnected = true
        sendParamDict_type = ""
        fromVCType = fromVC
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ConnectWebsocketSuccess"), object: nil)
        //(4).开始监听消息
        listen()
    }
    
    //MARK: 3.接收消息
    func listen() {
        guard isConnected else { return }
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    //print("收到文本消息: \(text)")
                    self.handleMessage(message_string: text)
                case .data(let data):
                    print("收到二进制消息: \(data)")
                @unknown default:
                    print("收到未知消息")
                }
            case .failure(let error):
                print("接收消息失败: \(error)")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "WebsocketDisconnected"), object: nil)
                self.isConnected = false
                sendParamDict_type = ""
            }
            // 持续监听
            self.listen()
        }
    }
    //MARK: 4.处理消息
    func handleMessage(message_string: String){
        let data = message_string.data(using: .utf8) ?? Data()
        guard let result_dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            print("处理--收到消息--解析数据失败")
            return
        }
        if sendParamDict_type.count <= 0 {
            print("处理--收到消息--发送消息类型缺失")
            return
        }
        print("处理--收到消息: \(result_dict)")
        print("此时发送的消息类型为: \(sendParamDict_type)")
        if (sendParamDict_type == "StandBy"){
            if result_dict["status"] as? String ?? "" == "ok"{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SetDeviceStandByWithSocketSuccess"), object: nil)
            }else{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SetDeviceStandByWithSocketFail"), object: nil)
            }
        }
        if (sendParamDict_type == "AdjustDeviceHeight"){
            if result_dict["status"] as? String ?? "" == "ok"{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AdjustDeviceHeightWithSocketSuccess"), object: nil)
            }else{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AdjustDeviceHeightWithSocketFail"), object: nil)
            }
        }
        if (sendParamDict_type == "JumpDevice"){
            if result_dict["status"] as? String ?? "" == "ok"{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "JumpDeviceWithSocketSuccess"), object: nil)
            }else{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "JumpDeviceWithSocketFail"), object: nil)
            }
        }
        
        if (sendParamDict_type == "ChangePosition"){
            if result_dict["status"] as? String ?? "" == "ok"{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ChangePositionWithSocketSuccess"), object: nil)
            }else{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ChangePositionWithSocketFail"), object: nil)
            }
        }
    }
    //MARK: 5.发送消息
    func sendCommad(paramDict: [String: Any], sendCommandType: String) {
        guard isConnected else {
            print("WebSocket: 未连接，发送失败")
            return
        }
        var sendCommad_string = ""
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: paramDict, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                sendCommad_string = jsonString
            }
        } catch {
            print("字典转 JSON 失败: \(error)")
            return
        }
        print("开始发送消息: \(paramDict)")
        webSocketTask?.send(.string(sendCommad_string)) { error in
            if let error = error {
                print("发送消息失败: \(error)")
                self.sendParamDict_type = ""
            } else {
                print("发送消息成功: \(paramDict)")
                self.sendParamDict_type = sendCommandType
            }
        }
    }
    //MARK: 6.主动断开连接：
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        webSocketTask = nil
        sendParamDict_type = ""
    }
    deinit{
        disconnect()
    }
}
