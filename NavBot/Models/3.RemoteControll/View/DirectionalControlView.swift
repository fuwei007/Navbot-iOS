

import UIKit

class DirectionalControlView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var tapView: UIView!
    var updateCoordinateSystemPoint: ((CGPoint)->())?
    var endUpdateCoordinateSystemPoint: ((CGPoint)->())?
    
    func initUI(){
        //1.大圈
        let bigCircleView = UIView(frame: CGRect(x: bounds.width/2-120/2, y: bounds.height/2-120/2, width: 120, height: 120))
        bigCircleView.backgroundColor = .clear
        bigCircleView.layer.borderWidth = 2.0
        bigCircleView.layer.borderColor = COLORFROMRGB(r: 0, 122, 255, alpha: 1).cgColor
        bigCircleView.layer.cornerRadius = 60.0
        addSubview(bigCircleView)
        
        //2.拖动滑块
        tapView = UIView(frame: CGRect(x: bounds.width/2-48/2, y: bounds.height/2-48/2, width: 48, height: 48))
        tapView.backgroundColor = COLORFROMRGB(r: 0, 122, 255, alpha: 1)
        tapView.layer.cornerRadius = 24
        addSubview(tapView)
        
        //3.拖动手势
        let tap = UIPanGestureRecognizer.init(target: self, action: #selector(clickTuoDongTap(gestrue:)))
        self.tapView.addGestureRecognizer(tap)
    }
    @objc func clickTuoDongTap(gestrue: UIPanGestureRecognizer){
        if gestrue.state == .began{
            print("开始拖动==============")
        }else if gestrue.state == .changed{
            //持续拖动手势中
            if let panView = gestrue.view{
                //1.获取手势移动的x和y值随时间变化的总平移量
                //计算现在的拖动的位置，只计算平移拖动
                //以手势按下去的位置为原点，当前时间相对于原点的位置:
                let translation = gestrue.translation(in: panView)
                //print("相对上一次位置拖动的距离:\(translation)")

                //2.更新滑块位置
                var newX = tapView.center.x + translation.x
                newX = min(newX, bounds.size.width)
                newX = max(newX, 0.0)
                var newY = tapView.center.y + translation.y
                newY = min(newY, bounds.size.height)
                newY = max(newY, 0.0)
                tapView.center = CGPoint(x: newX, y: newY)
                
                //3.重置 translation，避免累加
                gestrue.setTranslation(.zero, in: self)

                //4.实时输出滑块相对位置:
                //4.1.获取当前移动滑块相对于整个控件的位置：
                //let origin_change_x = tapView.center.x
                //let origin_change_y = tapView.center.y
                //print("origin_change_x:", origin_change_x)
                //print("origin_change_y:", origin_change_y)
                
                //4.2.相对于原点的相对坐标，数学坐标系（X 轴向右，Y 轴向上）
                //那么当前这个位置需要转化一下
                //原点位置为：(60, 60)
                let math_change_x = tapView.center.x - 60
                let math_change_y = 60 - tapView.center.y
                print("math_change_x:", math_change_x)
                print("math_change_y :", math_change_y)
                
                //4.3.触发回调
                let coordinateSystemPoint = CGPoint(x: math_change_x, y: math_change_y)
                self.updateCoordinateSystemPoint?(coordinateSystemPoint)
            }
        }else if gestrue.state == .ended{
            print("结束拖动==============")
            //复原位置：
            tapView.center = self.center
            gestrue.setTranslation(.zero, in: self)
            //print("center__x:", tapView.center.x)
            //print("center__y:", tapView.center.y)
            //4.3.触发回调:(0,0)
            let coordinateSystemPoint = CGPoint(x: 0, y: 0)
            self.endUpdateCoordinateSystemPoint?(coordinateSystemPoint)
        }
    }

}
