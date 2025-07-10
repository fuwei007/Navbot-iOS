
import UIKit

class MySliderView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var bottomView: UIView!
    var progressView: UIView!
    var tapView: UIView!
    var progressLabel: UILabel!
    var titleLabel: UILabel!

    var currentProgressValue: Float = 0.0
    var minimumProgressValue: Float = 0.0
    var maxProgressValue: Float = 100.0
    var unitValue = "mm"
    
    var endTapgestureWithValue: ((Float)->())?
    
    func initUI(){
        
        //1.最底部的view--灰色
        bottomView = UIView(frame: CGRect(x: bounds.size.width/2-24/2, y: 0, width: 24, height: bounds.size.height-60))
        bottomView.backgroundColor = COLORFROMRGB(r: 0, 0, 0, alpha: 0.06)
        bottomView.layer.cornerRadius = 12
        addSubview(bottomView)
        
        //2.progreee的值显示View--蓝色
        let progressView_height = (Float(bounds.size.height)-60.0) * (currentProgressValue-minimumProgressValue)/(maxProgressValue-minimumProgressValue)
        progressView = UIView(frame: CGRect(x: bounds.size.width/2-24/2, y: bounds.size.height-60-CGFloat(progressView_height), width: 24, height: CGFloat(progressView_height)))
        progressView.backgroundColor = COLORFROMRGB(r: 0, 122, 255, alpha: 1)
        progressView.layer.cornerRadius = 12
        addSubview(progressView)
        
        //3.拖动手势起效的View--Clear
        tapView = UIView(frame: CGRect(x: bounds.size.width/2-24/2, y: 0, width: 24, height: bounds.size.height-60))
        tapView.backgroundColor = .clear
        addSubview(tapView)
        
        //添加拖动手势
        let tap = UIPanGestureRecognizer.init(target: self, action: #selector(clickTuoDongTap(gestrue:)))
        self.tapView.addGestureRecognizer(tap)
        
        progressLabel = UILabel(frame: CGRect(x: 0, y: bounds.size.height-22-22, width: bounds.size.width, height: 22))
        progressLabel.textAlignment = .center
        progressLabel.textColor = .black
        progressLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        addSubview(progressLabel)
        
        titleLabel = UILabel(frame: CGRect(x: 0, y: bounds.size.height-22, width: bounds.size.width, height: 22))
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        addSubview(titleLabel)
    }
    
    //更新进度条当前的值
    func updateProgressValue(progressValue: Float){
        currentProgressValue = progressValue
        
        progressLabel.text = NSString(format: "%.0f", currentProgressValue) as String + unitValue
        
        let progressView_height = (Float(bounds.size.height)-60.0) * (currentProgressValue-minimumProgressValue)/(maxProgressValue-minimumProgressValue)
        progressView.frame = CGRect(x: bounds.size.width/2-24/2, y: bounds.size.height-60-CGFloat(progressView_height), width: 24, height: CGFloat(progressView_height))
    }

    //拖动手势
    @objc func clickTuoDongTap(gestrue: UIPanGestureRecognizer){
        /*
         //方式一：获取手势本身的移动位置
        if gestrue.state == .began{
            print("开始拖动==============")
        }else if gestrue.state == .changed{
            //持续拖动手势中
            if let panView = gestrue.view{
                //1.获取手势移动的x和y值随时间变化的总平移量
                //计算现在的拖动的位置，只计算平移拖动
                //以手势按下去的位置为原点，当前时间相对于原点的位置:
                let translation = gestrue.translation(in: panView)
                print("移动位置:\(translation)")
                //2.这里只需要计算Y轴的相对位置
                if (translation.y < 0){
                    //向上拖动:
                }else{
                    //想下拖动:
                }
                //3.计算变化的值
                let changePositionY = translation.y
                let changePogress = totalProgressValue*(Float(translation.y)/(Float(bounds.size.height)-60))
                var currentProgress = currentProgressValue - changePogress
                if currentProgress <= 0 {
                    currentProgress = 0.0
                }
                if currentProgress >= totalProgressValue{
                    currentProgress = totalProgressValue
                }
                DispatchQueue.main.async {
                    self.updateProgressValue(progressValue: currentProgress)
                }
            }
        }else if gestrue.state == .ended{
            print("结束拖动==============")
        }*/
        //方式二：获取手指在当前视图中的位置
        if gestrue.state == .began{
            //print("开始拖动==============")
        }else if gestrue.state == .changed{
            //持续拖动手势中
            //1.获取手指在tapView中的位置
            let locationInTapView = gestrue.location(in: self.tapView)
            //print("手指在 tapView 中的位置: \(locationInTapView)")
            //2.直接获取Y值，并将当前的进度条的值设置为手指位置:
            var changePositionY = locationInTapView.y
            if changePositionY <= 0{
                changePositionY = 0
            }
            if changePositionY >= bounds.size.height-60{
                changePositionY = bounds.size.height-60
            }
            let currentProgress =  maxProgressValue - (maxProgressValue-minimumProgressValue)*(Float(changePositionY)/(Float(bounds.size.height)-60))
            DispatchQueue.main.async {
                self.updateProgressValue(progressValue: currentProgress)
            }
        }else if gestrue.state == .ended{
            //print("结束拖动==============")
            //在这里触发回调
            endTapgestureWithValue?(currentProgressValue)
        }
        
    }
    
    
    
    
}
