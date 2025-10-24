
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

func encodeLinear(_ linear: Int16) -> (UInt8, UInt8) {
    if linear < -200 || linear > 200{
        return (0, 0)
    }
    // Int16 -> UInt16，方便拆高低字节
    let value = UInt16(bitPattern: linear)
    // 拆高低字节
    let linear_H = UInt8((value >> 8) & 0xFF)  // 高 8 位
    let linear_L = UInt8(value & 0xFF)         // 低 8 位
    return (linear_H, linear_L)
}
