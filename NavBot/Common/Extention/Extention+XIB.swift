

import Foundation
import UIKit

extension UIView{
    
    @IBInspectable
    var radius: CGFloat{
        get{
            layer.cornerRadius
        }
        set{
            layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable
    var myBorWidth: CGFloat{
        get{
            return layer.borderWidth
        }
        set{
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var myBorColor: UIColor{
        get{
            return UIColor.init(cgColor: layer.borderColor!)
        }
        set{
            layer.borderColor = newValue.cgColor
        }
    }
    
    @IBInspectable
    var shadowUIColor: UIColor{
        get{
            return UIColor(cgColor: self.layer.shadowColor ?? CGColor(red: 0, green: 0, blue: 0, alpha: 1.0))
        }
        set{
            self.layer.shadowColor = newValue.cgColor
        }
    }
}
