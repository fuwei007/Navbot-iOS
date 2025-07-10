
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
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


}

