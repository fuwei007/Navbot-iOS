

import UIKit
import SwiftyGif

var nowCenterAndSelectedItem = 2

class FaceItemsContentView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    var selectedFaceSuccessBlock:(([String: Any])->())?
    
    lazy var currentFaceImageIconView = {
        let view = UIView(frame: CGRect(x: 60, y: 24, width: self.bounds.size.width-60*2, height: (self.bounds.size.width-60*2)/312*153))
        view.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
        view.layer.cornerRadius = 48
        view.layer.masksToBounds = true
        view.addSubview(self.currentFaceImageIcon)
        return view
    }()
    lazy var currentFaceImageIcon = {
        let gifImageView = UIImageView()
        gifImageView.frame = CGRect(x: 24, y: 24, width: self.bounds.size.width-60*2-24*2, height: (self.bounds.size.width-60*2)/360*212-24*2)
        gifImageView.contentMode = .scaleAspectFit
        //gifImageView.startAnimatingGif()
        //gifImageView.stopAnimatingGif()
        //gifImageView.isAnimatingGif() // Bool
        return gifImageView
    }()
    
    lazy var sendButton = {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: bounds.size.width/2-85/2, y: self.bounds.size.height-80-5-35, width: 85, height: 35)
        button.backgroundColor = COLORFROMRGB(r: 0, 122, 255, alpha: 1)
        button.layer.cornerRadius = 17.5
        button.setTitle("Send", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.addTarget(self, action: #selector(clickSendButton), for: .touchUpInside)
        return button
    }()
    
    lazy var selectFaceItemCollectionView = {
        let flow_layout = UICollectionViewFlowLayout()
        flow_layout.scrollDirection = .horizontal
        flow_layout.minimumLineSpacing = 0
       
        let collectionView = UICollectionView(frame: CGRect(x: 30, y: self.bounds.size.height-80, width: self.bounds.size.width-30*2, height: 80), collectionViewLayout: flow_layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .fast // 更像 pickerView 滚动
        collectionView.backgroundColor = .clear
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "FaceItemsCell", bundle: .main), forCellWithReuseIdentifier: "FaceItemsCellID")
        
        return collectionView
        
    }()

    var allModels = [[String: Any]]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initUI(){
        
        backgroundColor = UIColor(red: 240/255, green: 242/255, blue: 245/255, alpha: 1)
        layer.cornerRadius = 24
            
        addSubview(currentFaceImageIconView)
        addSubview(sendButton)
        addSubview(selectFaceItemCollectionView)
        
        /*
         allModels = [
             ["name":"","image_name":"","index":0],
             ["name":"","image_name":"","index":1],
             ["name":"Angry","image_name":"Angry.gif","index":2],
             ["name":"Bored","image_name":"Bored.gif","index":3],
             ["name":"Cray","image_name":"Cray.gif","index":4],
             ["name":"Dizzy","image_name":"Dizzy.gif","index":5],
             ["name":"Happy","image_name":"Happy.gif","index":6],
             ["name":"Infatuate","image_name":"Infatuate.gif","index":7],
             ["name":"Pained","image_name":"Pained.gif","index":8],
             ["name":"Relaxed","image_name":"Relaxed.gif","index":9],
             ["name":"Sad","image_name":"Sad.gif","index":10],
             ["name":"Standby-Blink","image_name":"Standby-Blink.gif","index":11],
             ["name":"Standby-Doze","image_name":"Standby-Doze.gif","index":12],
             ["name":"Standby-Look","image_name":"Standby-Look.gif","index":13],
             ["name":"","image_name":"","index":14],
             ["name":"","image_name":"","index":15],
         ]
         */
        
        //这里根据从设备获取到的文件名字，对应给出表情的文件名
        let current_all_emoji_files = GetExpressionBluetoothManager.shared.current_Emoji_files
        var new_all_emoji_files = [String]()
        for i in 0..<current_all_emoji_files.count{
            let file_name = current_all_emoji_files[i].components(separatedBy: ".")[0]
            new_all_emoji_files.append(file_name)
        }
        //先添加左边两个空文件数据:
        allModels = [[String: Any]]()
        allModels.append(["name":"","image_name":"","index":0])
        allModels.append(["name":"","image_name":"","index":1])
        //添加表情数据：
        for i in 0..<new_all_emoji_files.count{
            let name = new_all_emoji_files[i]
            let image_name = "\(new_all_emoji_files[i]).gif"
            let file_dict: [String : Any] = ["name": name, "image_name": image_name, "index": i + 2]
            allModels.append(file_dict)
        }
        //最后添加左边两个空文件数据:
        allModels.append(["name":"","image_name":"","index":new_all_emoji_files.count+2])
        allModels.append(["name":"","image_name":"","index":new_all_emoji_files.count+3])
        
        //刷新页面
        self.selectFaceItemCollectionView.reloadData()
        
        //默认显示中间：
        nowCenterAndSelectedItem = Int(round(Double(allModels.count/2)))
        showZhiDingItemWith(index: nowCenterAndSelectedItem)
    }
    
    func showZhiDingItemWith(index: Int){
        if (index >= allModels.count){
            return
        }
        //滚动到最新的位置
        var offset_numer = 0
        if index >= 2{
            offset_numer = index - 2
        }
        let item_width = floor((self.bounds.size.width - 30*2) / 5)
        selectFaceItemCollectionView.setContentOffset(CGPoint(x: item_width*CGFloat(offset_numer), y: 0), animated: true)
        //展示指定的动画
        if (index < allModels.count){
            let image_name = allModels[index]["image_name"] as? String ?? ""
            showZhiDingGIFImage(imageName: image_name)
        }
    }
    func showZhiDingGIFImage(imageName: String){
        //print("显示指定的GIF图片：\(imageName)")
        if imageName.count == 0{
            currentFaceImageIcon.stopAnimatingGif() // 停止动画
            currentFaceImageIcon.clear()            // 清除 GIF 缓存和帧动画
            currentFaceImageIcon.image = nil        // 清除当前图像（可选）
            return
        }
        if let showGif = try? UIImage(gifName: imageName) {
            currentFaceImageIcon.setGifImage(showGif, loopCount: -1)
            currentFaceImageIcon.startAnimatingGif()
        } else {
            currentFaceImageIcon.stopAnimatingGif() // 停止动画
            currentFaceImageIcon.clear()            // 清除 GIF 缓存和帧动画
            currentFaceImageIcon.image = nil        // 清除当前图像（可选）
        }
    }
    //MARK: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allModels.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FaceItemsCellID", for: indexPath) as! FaceItemsCell
        cell.modelDict = allModels[indexPath.row]
        cell.initUI()
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                           sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = floor((self.bounds.size.width - 30*2) / 5)
        return CGSize(width: width, height: 80)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //print("选中了第 \(indexPath.row) 个 item")
    }
    //MARK: ScrollViewDelegate
    //1.滚动中
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //print("滚动视图为：\(scrollView.contentOffset.x)")
        handleDoningScrollView(offset_x: scrollView.contentOffset.x)
    }
    //处理滚动过程中的逻辑：
    func handleDoningScrollView(offset_x: CGFloat){
        //1.模拟PageSize效果:
        let item_width = floor((self.bounds.size.width - 30*2) / 5)
        //四舍五入
        var number = Int(round(offset_x / item_width))
        //print("当前选中第几个：\(number)")
        //2.判断是否需要更新nowCenterAndSelectedItem
        if (nowCenterAndSelectedItem != number + 2){
            //3.更新Cell的展示
            nowCenterAndSelectedItem = number + 2
            selectFaceItemCollectionView.reloadData()
            //4.切换动画展示
            showZhiDingItemWith(index: nowCenterAndSelectedItem)
            //5.触发回调--点击Send按钮才去触发
            //selectedFaceSuccessBlock?(allModels[nowCenterAndSelectedItem])
        }
    }
    //2.滚动结束
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        //print("松开手指：\(scrollView.contentOffset.x)")
        if decelerate{
            //1.当有减速过程，此时还没有停止
        }else{
            //2.当没有减速过程，此时已经停止
            handleEndScrollView(offset_x: scrollView.contentOffset.x)
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //print("结束滚动：\(scrollView.contentOffset.x)")
        handleEndScrollView(offset_x: scrollView.contentOffset.x)
    }
    //处理滚动结束后的逻辑：
    func handleEndScrollView(offset_x: CGFloat){
        //模拟PageSize效果:
        let item_width = floor((self.bounds.size.width - 30*2) / 5)
        var number = Int(offset_x / item_width)
        let remainder = offset_x.truncatingRemainder(dividingBy: item_width)
        if remainder >= item_width/2{
            number += 1
        }
        //print("当前选中第几个：\(number)")
        
        //模拟PageSize操作
        selectFaceItemCollectionView.setContentOffset(CGPoint(x: item_width*CGFloat(number), y: 0), animated: true)
        selectFaceItemCollectionView.reloadData()
    }
    
    @objc func clickSendButton(){
        selectedFaceSuccessBlock?(allModels[nowCenterAndSelectedItem])
    }
}
