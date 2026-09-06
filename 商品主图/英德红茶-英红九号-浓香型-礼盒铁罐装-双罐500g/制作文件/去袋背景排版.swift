import AppKit
import CoreText
import ImageIO
import UniformTypeIdentifiers

// Run with: swift -module-cache-path /private/tmp/yinghong-swift-cache 排版.swift 商品目录 原始包装实拍
let out = URL(fileURLWithPath:CommandLine.arguments[1], isDirectory:true)
let name = "英德红茶-英红九号-浓香型-礼盒铁罐装-双罐500g"
let W = 1254
let H = 1254
let space = CGColorSpace(name:CGColorSpace.sRGB)!
func read(_ u:URL) -> CGImage {
 let source = CGImageSourceCreateWithURL(u as CFURL,nil)!
 return CGImageSourceCreateImageAtIndex(source,0,nil)!
}
func canvas(_ w:Int = W,_ h:Int = H) -> CGContext {
 CGContext(data:nil,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:space,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
}
func color(_ hex:UInt32) -> CGColor {
 CGColor(colorSpace:space, components:[CGFloat((hex>>16)&255)/255,CGFloat((hex>>8)&255)/255,CGFloat(hex&255)/255,1])!
}
func save(_ im:CGImage,_ u:URL) {
 let d = CGImageDestinationCreateWithURL(u as CFURL,UTType.png.identifier as CFString,1,nil)!
 CGImageDestinationAddImage(d,im,nil)
 precondition(CGImageDestinationFinalize(d))
}
func line(_ c:CGContext,_ text:String,_ x:CGFloat,_ top:CGFloat,_ size:CGFloat,_ font:String,_ hex:UInt32) {
 let f=CTFontCreateWithName(font as CFString,size,nil)
 let attr:NSAttributedString = NSAttributedString(string:text,attributes:[
  NSAttributedString.Key(kCTFontAttributeName as String):f,
  NSAttributedString.Key(kCTForegroundColorAttributeName as String):color(hex),
  NSAttributedString.Key(kCTKernAttributeName as String):1.0])
 let l=CTLineCreateWithAttributedString(attr)
 let width=CTLineGetTypographicBounds(l,nil,nil,nil)
 precondition(x+width <= CGFloat(W)-68,"Text overflows: \(text)")
 c.textMatrix = .identity
 c.textPosition=CGPoint(x:x,y:CGFloat(H)-top-CTFontGetAscent(f))
 CTLineDraw(l,c)
}

for n in 7...8 {
 let im=read(out.appendingPathComponent("底图/\(name)主图\(n)底图.png"))
 let c=canvas();c.interpolationQuality = .high
 c.draw(im,in:CGRect(x:0,y:0,width:W,height:H))
 if n==7 {
  line(c,"英红九号·干茶展示",78,64,86,"PingFangSC-Semibold",0x604238)
  line(c,"自然条形，深浅交错",80,197,44,"PingFangSC-Medium",0x23565B)
 } else {
  line(c,"茶条近看，细节清楚",78,64,96,"PingFangSC-Semibold",0xF3EBDD)
  line(c,"长短有别，粗细不一",80,201,44,"PingFangSC-Medium",0xF3EBDD)
 }
 save(c.makeImage()!,out.appendingPathComponent("\(name)主图\(n).png"))
}
let sheet=canvas(1230,615)
sheet.setFillColor(color(0xE9E5DE));sheet.fill(CGRect(x:0,y:0,width:1230,height:615))
for n in 7...8 {
 let im=read(out.appendingPathComponent("\(name)主图\(n).png"))
 sheet.interpolationQuality = .high
 sheet.draw(im,in:CGRect(x:15+(n-7)*607,y:15,width:585,height:585))
}
save(sheet.makeImage()!,out.appendingPathComponent("新增茶叶主图预览.png"))
let check=canvas(640,490)
check.setFillColor(color(0xE9E5DE));check.fill(CGRect(x:0,y:0,width:640,height:490))
for n in 7...8 {
 let im=read(out.appendingPathComponent("\(name)主图\(n).png"))
 check.interpolationQuality = .high
 check.draw(im,in:CGRect(x:10+(n-7)*320,y:10,width:300,height:300))
 check.draw(im,in:CGRect(x:10+(n-7)*320,y:320,width:160,height:160))
}
save(check.makeImage()!,out.appendingPathComponent("制作文件/新增茶叶图缩略检查.png"))
