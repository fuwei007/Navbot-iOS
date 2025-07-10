
import Foundation
import UIKit

let HUD_Duration_Infinite = -1
let HUD_Duration_Normal = 2.0
let HUD_Duration_Short = 0.5
let HUD_Duration_Success = 1.0
let HUD_Duration_Long_fail = 10.0

typealias MBSuccessBlock = ()->()

extension MBProgressHUD {
    
    class func showJuHua(view: UIView) -> MBProgressHUD{
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.isUserInteractionEnabled = false
        hud.bezelView.style = .blur
        UIActivityIndicatorView.appearance(whenContainedInInstancesOf: [MBProgressHUD.self]).color = .black
        return hud
    }
    
    class func showSaveDataSuccessText(text: String, view: UIView){
        var hud = MBProgressHUD()
        hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.isUserInteractionEnabled = false
        hud.bezelView.style = .solidColor
        hud.mode = .text
        hud.detailsLabel.text = text
        hud.detailsLabel.textColor = .white
        hud.detailsLabel.font = UIFont(name: "Helvetica-Bold", size: 22)
        hud.detailsLabel.textColor = COLORFROMRGB(r: 108, 186, 170, alpha: 1)
        hud.hide(animated: true, afterDelay: HUD_Duration_Normal)
    }
    
    class func showText(text: String, view: UIView){
        var hud = MBProgressHUD()
        hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.isUserInteractionEnabled = false
        hud.bezelView.style = .solidColor
        hud.mode = .text
        hud.detailsLabel.text = text
        hud.detailsLabel.textColor = .black
        hud.hide(animated: true, afterDelay: HUD_Duration_Normal)
    }
    class func showErrorText(text: String, view: UIView){
        var hud = MBProgressHUD()
        hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.isUserInteractionEnabled = false
        hud.bezelView.style = .solidColor
        hud.mode = .text
        hud.label.text = text
        hud.label.textColor = UIColor.red
        hud.hide(animated: true, afterDelay: HUD_Duration_Normal)
    }
    
    class func showTitleAndSubTitle(title: String, subTitle: String, view: UIView){
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.isUserInteractionEnabled = false
        hud.mode = .text
        hud.label.text = title
        hud.detailsLabel.text = subTitle
        hud.hide(animated: true, afterDelay: HUD_Duration_Normal)
    }
    
    class func showJuHuaAndTitle(title: String,view: UIView)  -> MBProgressHUD{
        let hud = MBProgressHUD()
        hud.isUserInteractionEnabled = false
        hud.label.text = title
        hud.label.textColor = .white
        hud.backgroundColor = COLORFROMRGB(r: 0, 0, 0, alpha: 0.4)
        hud.bezelView.style = .solidColor
        hud.bezelView.backgroundColor = .clear
        UIActivityIndicatorView.appearance(whenContainedInInstancesOf: [MBProgressHUD.self]).color = .white
        hud.removeFromSuperViewOnHide = true
        hud.show(animated: true)
        view.addSubview(hud)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+HUD_Duration_Long_fail) {
            for value in view.subviews{
                if value == hud{
                    if hud.isHidden == false{
                        print("Request timed out, auto-hide.")
                        nowHiddenMBProgressHUD(hud)
                        MBProgressHUD.showErrorText(text: "Request Data Timeout", view: view)
                    }
                }
            }
        }
        
        return hud
    }
    
    class func showJuHuaAndTitleAndSubTitle(title: String,subTitle: String,view: UIView)  -> MBProgressHUD{
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.isUserInteractionEnabled = false
        hud.label.text = title
        hud.detailsLabel.text = subTitle
        return hud
    }
    class func nowHiddenMBProgressHUD(_ hud: MBProgressHUD){
        hud.hide(animated: true)
    }
    class func ShowSuccessMBProgresssHUD(view: UIView, title: String, block:@escaping()->()){
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.isUserInteractionEnabled = true
        hud.mode = .text
        hud.label.text = title
        hud.hide(animated: true, afterDelay: HUD_Duration_Success)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+HUD_Duration_Success) {
            block()
        }
    }
    
    class func showTiShiTitleAndSubTitle(title: String, subTitle: String, view: UIView){
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.isUserInteractionEnabled = false
        hud.mode = .text
        hud.label.text = title
        hud.label.textColor = .white
        hud.detailsLabel.text = subTitle
        hud.hide(animated: true, afterDelay: 5.0)
    }
    class func showTiShiTitleAndSubTitleOfLogin(title: String, subTitle: String, view: UIView){
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.isUserInteractionEnabled = false
        hud.mode = .text
        hud.label.text = title
        hud.detailsLabel.text = subTitle
        hud.hide(animated: true, afterDelay: 4.0)
    }

    class func MoniCaoZuoMBProgresssHUD(view: UIView, title: String, block:@escaping()->()){
        var hud = MBProgressHUD()
        hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.isUserInteractionEnabled = false
        hud.bezelView.style = .solidColor
        hud.mode = .text
        hud.label.text = title
        hud.label.textColor = .white
        hud.hide(animated: true, afterDelay: 2.0)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+2.0) {
            block()
        }
    }
    
    class func MoniCaoZuoMBProgresssHUDWithText(view: UIView, title: String)  -> MBProgressHUD{
        var hud = MBProgressHUD()
        hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.isUserInteractionEnabled = false
        hud.bezelView.style = .solidColor
        hud.mode = .text
        hud.label.text = title
        hud.label.textColor = .white
        return hud
    }
    
    class func showJuHuaAndTitleWithSeconds(title: String,view: UIView){
        let hud = MBProgressHUD()
        hud.isUserInteractionEnabled = false
        hud.label.text = title
        hud.label.textColor = .white
        hud.backgroundColor = COLORFROMRGB(r: 0, 0, 0, alpha: 0.4)
        hud.bezelView.style = .solidColor
        hud.bezelView.backgroundColor = .clear
        UIActivityIndicatorView.appearance(whenContainedInInstancesOf: [MBProgressHUD.self]).color = .white
        hud.removeFromSuperViewOnHide = true
        hud.show(animated: true)
        view.addSubview(hud)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+3) {
            for value in view.subviews{
                if value == hud{
                    if hud.isHidden == false{
                       nowHiddenMBProgressHUD(hud)
                    }
                }
            }
        }
    }
    
}


