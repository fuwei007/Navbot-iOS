
import Foundation
import UIKit

extension String{
    func getTextWidth(string:String,font:CGFloat,height:CGFloat, lineSpace:CGFloat) ->CGFloat{
        let font = UIFont.systemFont(ofSize: font)
        let size = CGSize(width: CGFloat(MAXFLOAT), height: height)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpace
        let attributes = [NSAttributedString.Key.font:font, NSAttributedString.Key.paragraphStyle:paragraphStyle.copy()]
        let text = string as NSString
        let rect = text.boundingRect(with: size, options:.usesLineFragmentOrigin, attributes: attributes, context:nil)
        return rect.size.width
    }
    
    //Have "\n"
    func getTextHeight(string: String, fontSize: CGFloat, width: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: fontSize)
        let rect = string.boundingRect(with: CGSize(width: width, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        //如果存在换行符，手动添加一行的高度
        var nowHeight = ceil(rect.height)
        let array = string.components(separatedBy: "\n")
        if array.count >= 2{
            let number = array.count - 1
            let oneLineHeight = getTextHeight(string: "AA", fontSize: fontSize, width: width)
            nowHeight = oneLineHeight*CGFloat(number) + nowHeight
        }
        return nowHeight
    }
    
}
