

import UIKit

class SelectFaceItemAlertView: UIView {
    var selectedFaceSuccessBlock:(([String: Any])->())?
    var currentHUDMessage: MBProgressHUD?
    
    lazy var faceContentView = {
        let view = FaceItemsContentView(frame: CGRect(x: kScreen_WIDTH/2-(kScreen_HEIGHT-24*2)/354*480/2, y: 24, width: (kScreen_HEIGHT-24*2)/354*480, height: kScreen_HEIGHT-24*2))
        view .selectedFaceSuccessBlock = { selectedFaceData in
            //print("选中表情：\(selectedFaceData)")
            //self.removeFromSuperview()
            self.currentHUDMessage = MBProgressHUD.showJuHuaAndTitle(title: "Loading", view: self)
            self.selectedFaceSuccessBlock?(selectedFaceData)
        }
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func initUI(){

        backgroundColor = COLORFROMRGB(r: 0, 0, 0, alpha: 0.5)
    
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(clickCloseFunc(tap:)))
        self.addGestureRecognizer(tap)
        
        addSubview(self.faceContentView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(closeShowAlertView), name: Notification.Name("setFaceEnd"), object: nil)
        
    }
    @objc func clickCloseFunc(tap: UITapGestureRecognizer){
        let tapPoint = tap.location(in: self)
        let contentFrame = CGRect(x: kScreen_WIDTH/2-(kScreen_HEIGHT-24*2)/354*480/2, y: 24, width: (kScreen_HEIGHT-24*2)/354*480, height: kScreen_HEIGHT-24*2)
        if contentFrame.contains(tapPoint) {
            return
        }else{
            self.removeFromSuperview()
        }
    }
    
    @objc func closeShowAlertView(){
        if (currentHUDMessage != nil){
            DispatchQueue.main.async(execute: {
                MBProgressHUD.nowHiddenMBProgressHUD(self.currentHUDMessage!)
            })
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
