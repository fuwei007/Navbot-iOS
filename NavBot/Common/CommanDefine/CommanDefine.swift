import Foundation
import UIKit


var kMain_Screen: UIScreen{
    if #available(iOS 13.0.0, *){
        if (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen != nil{
            return ((UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen)!
        }else{
            return UIScreen.main
        }
    }else{
        return UIScreen.main
    }
}
let kScreen_WIDTH = kMain_Screen.bounds.size.width
let kScreen_HEIGHT = kMain_Screen.bounds.size.height

var isFullScreen: Bool {
    if #available(iOS 11, *) {
          guard let w = UIApplication.shared.delegate?.window, let unwrapedWindow = w else {
              return false
          }
          
          if unwrapedWindow.safeAreaInsets.left > 0 || unwrapedWindow.safeAreaInsets.bottom > 0 {
              print(unwrapedWindow.safeAreaInsets)
              return true
          }
    }
    return false
}

let kTabBarHeight: CGFloat = isFullScreen ? (49.0 + 34.0) : (49.0)

let kStatusBarHeight: CGFloat = isFullScreen ? (44.0) : (20.0)

let kNavBarHeight: CGFloat = 44.0

let kNavBarAndStatusBarHeight: CGFloat = isFullScreen ? (88.0) : (64.0)


func COLORFROMRGB(r:CGFloat,_ g:CGFloat,_ b:CGFloat, alpha:CGFloat) -> UIColor{
    return UIColor(red: (r)/255.0, green: (g)/255.0, blue: (b)/255.0, alpha: alpha)
}

func safeTop() -> CGFloat {
    if #available(iOS 13.0, *) {
        let scene = UIApplication.shared.connectedScenes.first
        guard let windowScene = scene as? UIWindowScene else { return 0 }
        guard let window = windowScene.windows.first else { return 0 }
        return window.safeAreaInsets.top
    } else if #available(iOS 11.0, *) {
        guard let window = UIApplication.shared.windows.first else { return 0 }
        return window.safeAreaInsets.top
    }
    return 44.0
}

func safeBottom() -> CGFloat {
    if #available(iOS 13.0, *) {
        let scene = UIApplication.shared.connectedScenes.first
        guard let windowScene = scene as? UIWindowScene else { return 0 }
        guard let window = windowScene.windows.first else { return 0 }
        return window.safeAreaInsets.bottom
    } else if #available(iOS 11.0, *) {
        guard let window = UIApplication.shared.windows.first else { return 0 }
        return window.safeAreaInsets.bottom
    }
    return 0
}

func creatImageWithColor(color:UIColor)->UIImage{
    let rect = CGRect(x:0,y:0,width:1,height:1)
    UIGraphicsBeginImageContext(rect.size)
    let context = UIGraphicsGetCurrentContext()
    context?.setFillColor(color.cgColor)
    context!.fill(rect)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
}

func getTopViewController() -> UIViewController? {
    guard let window = UIApplication.shared.keyWindow else {
        return nil
    }
    var topController = window.rootViewController
    while let presentedController = topController?.presentedViewController {
        topController = presentedController
    }
    return topController
}

func customPresentVC(fromVC: UIViewController, toVC: UIViewController){
    toVC.modalPresentationStyle = .fullScreen
    fromVC.present(toVC, animated: true)
}

func getCurrentVc() -> UIViewController{
    let rootVc = UIApplication.shared.keyWindow?.rootViewController
    let currentVc = getCurrentVcFrom(rootVc!)
    return currentVc
}
func getCurrentVcFrom(_ rootVc:UIViewController) -> UIViewController{
   var currentVc:UIViewController
   var rootCtr = rootVc
   if(rootCtr.presentedViewController != nil) {
     rootCtr = rootVc.presentedViewController!
   }
   if rootVc.isKind(of:UITabBarController.classForCoder()) {
     currentVc = getCurrentVcFrom((rootVc as! UITabBarController).selectedViewController!)
   }else if rootVc.isKind(of:UINavigationController.classForCoder()){
      currentVc = getCurrentVcFrom((rootVc as! UINavigationController).visibleViewController!)
   }else{
     currentVc = rootCtr
   }
   return currentVc
}
func getRandomDigitsString() -> String {
    var result = ""
    for _ in 0..<15 {
        let randomDigit = Int.random(in: 0...9)
        result += String(randomDigit)
    }
    return result
}

