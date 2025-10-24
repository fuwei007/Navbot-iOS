
import UIKit

class CalibrateSuccessView: UIView {

    @IBOutlet weak var successView: UIView!
    
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        addViewOfXIB()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addViewOfXIB(){
        let nib = UINib(nibName: "CalibrateSuccessView", bundle: Bundle.main)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else{
            return
        }
        view.frame = UIScreen.main.bounds
        view.backgroundColor = COLORFROMRGB(r: 235, 242, 250, alpha: 0.95)
        addSubview(view)
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(clickCloseFunc(tap:)))
        addGestureRecognizer(tap)
    }
    @objc func clickCloseFunc(tap: UITapGestureRecognizer){
        removeFromSuperview()
    }
    
}

