
import UIKit
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        initIQKeyboardManagerSwift()
        handleLocalSavedDeivceData()
        
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        
        
        let vc = RootMenuListVC()
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
        
        
        /*
        let vc = DeviceRemoteControlVC()
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
        */
        
        return true
    }

    //MARK: Handle Local Saved DeivceData
    func handleLocalSavedDeivceData(){
        //UserDefaults.standard.removeObject(forKey: "allScanedDevices")
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
    }

    //MARK: Third SDK---IQKeyboardManager
    func initIQKeyboardManagerSwift(){
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true // 启用点击非输入区域收起键盘
        IQKeyboardManager.shared.enableAutoToolbar = true  // ✅ 启用工具栏（包含 Done 按钮）
    
    }

}

