
import Foundation


//[UInt8]->["0X00", "OX00", "OX00"]
func convertDecimalToHexadecimal(decimalBytes: [UInt8]) -> [String]{
    var byteArrStr = [String]()
    for vlaue1 in decimalBytes{
        let decimalNumber = vlaue1 // 要转换的十进制数字
        let hexadecimalNumber = String(format:"0X%X", decimalNumber) // 将十进制数字转换为十六进制
        byteArrStr.append(hexadecimalNumber)
    }
    return byteArrStr
}

//[UInt8]->"ZhangYe"
func bytesToStr(bytes: [UInt8]) -> String {
    let str = String(bytes: bytes, encoding: .utf8) ?? ""
    return str
}
//Data转String
func dataToStr(data: Data) -> String {
    let str = String(data:data, encoding:.utf8) ?? ""
    return str
}

//[UInt8]->["0X00", "OX00", "OX00"]
func convertDecimalToHexadecimal16(decimalBytes: [Int16]) -> [String]{
    var byteArrStr = [String]()
    for vlaue1 in decimalBytes{
        let decimalNumber = vlaue1 // 要转换的十进制数字
        let hexadecimalNumber = String(format:"0X%X", decimalNumber) // 将十进制数字转换为十六进制
        byteArrStr.append(hexadecimalNumber)
    }
    return byteArrStr
}

