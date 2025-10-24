
import UIKit

class MoreAlertView: UIView {

    var clickRenameBlock:(()->())?
    var clickSettingsBlock:(()->())?
    var clickRemoveBlock:(()->())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addViewOfXIB()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addViewOfXIB(){
        let nib = UINib(nibName: "MoreAlertView", bundle: Bundle.main)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else{
            return
        }
        view.frame = UIScreen.main.bounds
        view.backgroundColor = COLORFROMRGB(r: 0, 0, 0, alpha: 0.5)
        self.addSubview(view)
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(clickCloseFunc(tap:)))
        self.addGestureRecognizer(tap)
    }
    @objc func clickCloseFunc(tap: UITapGestureRecognizer){
        let tapPoint = tap.location(in: self)
        let contentFrame = CGRect(x: kScreen_WIDTH/2-360/2, y: kScreen_HEIGHT-24-103, width: 360, height: 103)
        if contentFrame.contains(tapPoint) {
            return
        }else{
            self.removeFromSuperview()
        }
    }

    @IBAction func clickRenameButton(_ sender: Any) {
        self.removeFromSuperview()
        clickRenameBlock?()
    }
    
    @IBAction func clickSettingsButton(_ sender: Any) {
        self.removeFromSuperview()
        clickSettingsBlock?()
    }
    
    @IBAction func clickRemoveButton(_ sender: Any) {
        self.removeFromSuperview()
        clickRemoveBlock?()
    }
    
    
}
