
import UIKit

class CalibrateProgressingView: UIView {

    @IBOutlet weak var progressingView: UIView!
    @IBOutlet weak var progressingLabel: UILabel!
    @IBOutlet weak var progressingViewWidth: NSLayoutConstraint!
    
    var progressing_number = 0
    var succeesBlock: (()->())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addViewOfXIB()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addViewOfXIB(){
        let nib = UINib(nibName: "CalibrateProgressingView", bundle: Bundle.main)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else{
            return
        }
        view.frame = UIScreen.main.bounds
        view.backgroundColor = COLORFROMRGB(r: 235, 242, 250, alpha: 0.95)
        addSubview(view)
    }
  
    func updateProgressViewWithNumber(progressNumber: Int){
        if progressNumber >= 100{
            progressing_number = 100
        }else{
            progressing_number = progressNumber
        }
        
        progressingLabel.text = "\(progressing_number)%"
        progressingViewWidth.constant = CGFloat(progressing_number)/CGFloat(100)*CGFloat(300)
 
        if progressing_number >= 100{
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0, execute: {
                self.removeFromSuperview()
                self.succeesBlock?()
            })
        }
    }
}

