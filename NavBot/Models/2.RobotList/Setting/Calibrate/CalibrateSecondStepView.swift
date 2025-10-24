
import UIKit

class CalibrateSecondStepView: UIView {

    @IBOutlet weak var contentGIFImageView: UIImageView!
    
    var clickNextButtonBlock: (()->())?
    var clickCancelButtonBlock: (()->())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addViewOfXIB()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func addViewOfXIB(){
        let nib = UINib(nibName: "CalibrateSecondStepView", bundle: Bundle.main)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else{
            return
        }
        view.frame = UIScreen.main.bounds
        view.backgroundColor = COLORFROMRGB(r: 0, 0, 0, alpha: 0.5)
        self.addSubview(view)
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(clickCloseFunc(tap:)))
        self.addGestureRecognizer(tap)
        
        let gifImage = try! UIImage(gifName: "Calibrate.gif")
        contentGIFImageView.setGifImage(gifImage)
    }
    @objc func clickCloseFunc(tap: UITapGestureRecognizer){
        let tapPoint = tap.location(in: self)
        let contentFrame = CGRect(x: kScreen_WIDTH/2-400/2, y: kScreen_HEIGHT/2-226/2, width: 400, height: 226)
        if contentFrame.contains(tapPoint) {
            return
        }else{
            self.removeFromSuperview()
        }
    }
    
    @IBAction func clickCancelButton(_ sender: Any) {
        clickCancelButtonBlock?()
    }
    @IBAction func clickNextStepButton(_ sender: Any) {
        clickNextButtonBlock?()
    }
    
    
}
