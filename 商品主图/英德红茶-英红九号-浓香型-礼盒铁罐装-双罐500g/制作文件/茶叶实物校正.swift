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

let src=URL(fileURLWithPath:CommandLine.arguments[2])
let real=read(src.appendingPathComponent("英红九号散装茶叶袋内俯拍.jpg"))
for n in 7...8 {
 let c=canvas();c.interpolationQuality = .high
 c.setFillColor(color(n==7 ? 0xF3EBDD:0x292826));c.fill(CGRect(x:0,y:0,width:W,height:H))
 let crop=n==7 ? CGRect(x:20,y:700,width:1040,height:780):CGRect(x:215,y:910,width:670,height:498)
 let im=real.cropping(to:crop)!
 let photoH=CGFloat(W)*CGFloat(im.height)/CGFloat(im.width)
 c.draw(im,in:CGRect(x:0,y:0,width:CGFloat(W),height:photoH))
 save(c.makeImage()!,out.appendingPathComponent("底图/\(name)主图\(n)底图.png"))
 if n==7 {
  line(c,"英红九号·袋内实拍",78,55,98,"PingFangSC-Semibold",0x604238)
  line(c,"茶条原貌，按实物展示",80,194,44,"PingFangSC-Medium",0x23565B)
 }else{
  line(c,"原片放大，看清茶条",78,55,96,"PingFangSC-Semibold",0xF3EBDD)
  line(c,"长短有别，粗细不一",80,194,44,"PingFangSC-Medium",0xF3EBDD)
 }
 save(c.makeImage()!,out.appendingPathComponent("\(name)主图\(n).png"))
}
let original=read(out.appendingPathComponent("原图备份/茶叶实物校正前/底图/\(name)主图4底图.png"))
let edited=read(URL(fileURLWithPath:CommandLine.arguments[3]))
let c=canvas();c.draw(original,in:CGRect(x:0,y:0,width:W,height:H))
let box=CGRect(x:132,y:1017,width:274,height:143)
c.draw(edited.cropping(to:box)!,in:CGRect(x:132,y:94,width:274,height:143))
save(c.makeImage()!,out.appendingPathComponent("底图/\(name)主图4底图.png"))
let sheet=canvas(1230,615);sheet.setFillColor(color(0xE9E5DE));sheet.fill(CGRect(x:0,y:0,width:1230,height:615))
for n in 7...8 {sheet.draw(read(out.appendingPathComponent("\(name)主图\(n).png")),in:CGRect(x:15+(n-7)*607,y:15,width:585,height:585))}
save(sheet.makeImage()!,out.appendingPathComponent("新增茶叶主图预览.png"))
