
import UIKit

class DeleteDeviceAlertView: UIView {

    var deleteDeviceBlock: (()->())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addViewOfXIB()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addViewOfXIB(){
        let nib = UINib(nibName: "DeleteDeviceAlertView", bundle: Bundle.main)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else{
            return
        }
        view.frame = UIScreen.main.bounds
        view.backgroundColor = COLORFROMRGB(r: 0, 0, 0, alpha: 0.5)
        self.addSubview(view)
    }
  

    @IBAction func clickNoButton(_ sender: Any) {
        removeFromSuperview()
    }
    
    @IBAction func clickYesButton(_ sender: Any) {
        removeFromSuperview()
        deleteDeviceBlock?()
    }
    
}
