import AppKit
import CoreText
import ImageIO
import UniformTypeIdentifiers

// Run with: swift -module-cache-path /private/tmp/yinghong-swift-cache 排版.swift 商品目录 原始包装实拍
let out = URL(fileURLWithPath:CommandLine.arguments[1], isDirectory:true)
let source = URL(fileURLWithPath:CommandLine.arguments[2])
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
let actual = read(source)
// Copy original photographed labels rather than regenerate or transcribe tiny packaging text.
let rawBag = actual.cropping(to:CGRect(x:601,y:221,width:69,height:114))!
let rawTin = actual.cropping(to:CGRect(x:190,y:361,width:46,height:79))!
func roundedLabel(_ raw:CGImage) -> CGImage {
 let c=canvas(raw.width,raw.height)
 c.addPath(CGPath(roundedRect:CGRect(x:0,y:0,width:raw.width,height:raw.height),cornerWidth:2,cornerHeight:2,transform:nil))
 c.clip()
 c.draw(raw,in:CGRect(x:0,y:0,width:raw.width,height:raw.height))
 return c.makeImage()!
}
let bagLabel = roundedLabel(rawBag)
let tinLabel = roundedLabel(rawTin)
// Coordinates in source bottom-image pixels: top-left, top-right, bottom-right, bottom-left.
struct Label { let isBag:Bool; let points:[[CGFloat]] }
let labels:[Int:[Label]] = [
 1:[Label(isBag:true,points:[[952,502],[1062,502],[1062,675],[952,675]]),
    Label(isBag:false,points:[[282,706],[357,706],[357,826],[282,826]]),
    Label(isBag:false,points:[[591,795],[668,795],[668,924],[591,924]])],
 2:[Label(isBag:true,points:[[554,420],[626,413],[635,541],[563,548]]),
    Label(isBag:false,points:[[524,893],[585,887],[596,981],[531,987]]),
    Label(isBag:false,points:[[934,784],[987,801],[954,881],[899,866]])],
 4:[Label(isBag:false,points:[[499,596],[580,600],[582,738],[499,735]]),
    Label(isBag:false,points:[[872,723],[973,735],[975,893],[872,879]])],
 5:[Label(isBag:true,points:[[957,623],[1064,623],[1064,792],[957,792]]),
    Label(isBag:false,points:[[285,807],[356,807],[356,922],[285,922]]),
    Label(isBag:false,points:[[561,807],[634,807],[634,922],[561,922]])]
]
func solve(_ rows:[[Double]]) -> [Double] {
 var a=rows
 for j in 0..<8 {
  let pivot=(j..<8).max {abs(a[$0][j]) < abs(a[$1][j])}!
  a.swapAt(j,pivot)
  let v=a[j][j]
  precondition(abs(v)>1e-10)
  for k in j...8 {a[j][k] /= v}
  for i in 0..<8 where i != j {
   let t=a[i][j]
   for k in j...8 {a[i][k] -= t*a[j][k]}
  }
 }
 return a.map{$0[8]}
}
func restoreLabels(_ bg:CGImage,_ n:Int) -> CGImage {
 let target=canvas();target.draw(bg,in:CGRect(x:0,y:0,width:W,height:H))
 let dest=target.data!.bindMemory(to:UInt8.self,capacity:W*H*4)
 for label in labels[n] ?? [] {
  let raw=label.isBag ? bagLabel : tinLabel
  let sw=raw.width,sh=raw.height
  let srcContext=canvas(sw,sh);srcContext.draw(raw,in:CGRect(x:0,y:0,width:sw,height:sh))
  let src=srcContext.data!.bindMemory(to:UInt8.self,capacity:sw*sh*4)
  let uv=[[0.0,0.0],[Double(sw-1),0],[Double(sw-1),Double(sh-1)],[0,Double(sh-1)]]
  var rows=[[Double]]()
  for i in 0..<4 {
   let x=Double(label.points[i][0]),y=Double(label.points[i][1]),u=uv[i][0],v=uv[i][1]
   rows.append([x,y,1,0,0,0,-u*x,-u*y,u])
   rows.append([0,0,0,x,y,1,-v*x,-v*y,v])
  }
  let m=solve(rows)
  let minX=Int(label.points.map{$0[0]}.min()!.rounded(.down)),maxX=Int(label.points.map{$0[0]}.max()!.rounded(.up))
  let minY=Int(label.points.map{$0[1]}.min()!.rounded(.down)),maxY=Int(label.points.map{$0[1]}.max()!.rounded(.up))
  for y in minY...maxY {for x in minX...maxX {
   let dx=Double(x),dy=Double(y),den=m[6]*dx+m[7]*dy+1
   let u=(m[0]*dx+m[1]*dy+m[2])/den,v=(m[3]*dx+m[4]*dy+m[5])/den
   if u<0 || v<0 || u>=Double(sw-1) || v>=Double(sh-1) {continue}
   let xx=Int(u),yy=Int(v),fx=u-Double(xx),fy=v-Double(yy)
   let idx=[(yy*sw+xx)*4,(yy*sw+xx+1)*4,((yy+1)*sw+xx)*4,((yy+1)*sw+xx+1)*4]
   let wt=[(1-fx)*(1-fy),fx*(1-fy),(1-fx)*fy,fx*fy]
   var rgba=[Double](repeating:0,count:4)
   for c in 0..<4 {for k in 0..<4 {rgba[c] += Double(src[idx[k]+c])*wt[k]}}
   let alpha=rgba[3]/255;let p=(y*W+x)*4
   for c in 0..<3 {dest[p+c]=UInt8(max(0,min(255,rgba[c]+Double(dest[p+c])*(1-alpha))))}
   dest[p+3]=255
  }}
 }
 return target.makeImage()!
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
func pureWhiteBackground(_ context:CGContext) {
 // Background-only flood fill. It cannot pass through dark/colored tea pixels.
 let p=context.data!.bindMemory(to:UInt8.self,capacity:W*H*4)
 var seen=[Bool](repeating:false,count:W*H)
 var queue=[Int]();queue.reserveCapacity(W*H)
 func add(_ x:Int,_ y:Int) {
  guard x>=0 && x<W && y>=0 && y<H else{return}
  let k=y*W+x
  if seen[k] {return};seen[k]=true
  let i=k*4;let r=Int(p[i]),g=Int(p[i+1]),b=Int(p[i+2])
  if min(r,g,b)>=235 && max(r,g,b)-min(r,g,b)<=12 {queue.append(k)}
 }
 for x in 0..<W {add(x,0);add(x,H-1)}
 for y in 0..<H {add(0,y);add(W-1,y)}
 var head=0
 while head<queue.count {
  let k=queue[head];head+=1;let i=k*4
  p[i]=255;p[i+1]=255;p[i+2]=255;p[i+3]=255
  add(k%W-1,k/W);add(k%W+1,k/W);add(k%W,k/W-1);add(k%W,k/W+1)
 }
 print("White background normalized:",queue.count,"pixels")
}
for n in [3,4,6] {
 let original=read(out.appendingPathComponent("底图/\(name)主图\(n)底图.png"))
 precondition(original.width==W && original.height==H)
 let corrected=restoreLabels(original,n)
 let c=canvas()
 c.interpolationQuality = .high
 c.setFillColor(color(n==6 ? 0xFFFFFF : 0xF3EBDD));c.fill(CGRect(x:0,y:0,width:W,height:H))
 let scale:CGFloat=n==6 ? 0.88 : 1
 let inset=CGFloat(W)*(1-scale)/2
 c.draw(corrected,in:CGRect(x:inset,y:inset,width:CGFloat(W)*scale,height:CGFloat(H)*scale))
 switch n {
 case 1:
  line(c,"英德红茶·英红九号",78,72,100,"PingFangSC-Semibold",0x604238)
  line(c,"浓香型｜双罐配礼袋",80,211,46,"PingFangSC-Medium",0x23565B)
 case 2:
  line(c,"一袋两罐",78,68,104,"PingFangSC-Semibold",0x604238)
  line(c,"双铁罐装，配同款礼袋",81,212,46,"PingFangSC-Medium",0x23565B)
 case 3:
  line(c,"干茶近一点看",78,68,96,"PingFangSC-Semibold",0xF3EBDD)
  line(c,"卷曲茶条，深浅自然",80,204,44,"PingFangSC-Medium",0xF3EBDD)
 case 4:
  line(c,"一罐常喝，一罐收好",78,72,88,"PingFangSC-Semibold",0x604238)
  line(c,"英红九号，家里慢慢喝",80,205,44,"PingFangSC-Medium",0x23565B)
 case 5:
  line(c,"拜访亲友，带份茶",164,73,92,"STSongti-SC-Bold",0x604238)
  line(c,"礼袋配好了，拎上就走",165,216,44,"PingFangSC-Medium",0x23565B)
 default:pureWhiteBackground(c)
 }
 let u=out.appendingPathComponent("\(name)主图\(n).png")
 save(c.makeImage()!,u)
 print(u.lastPathComponent)
}
// A review sheet is separate from the six upload images.
let thumb=376, gap=22, sheetW=thumb*3+gap*4, sheetH=thumb*2+gap*3
let sheet=canvas(sheetW,sheetH)
sheet.setFillColor(color(0xE9E5DE));sheet.fill(CGRect(x:0,y:0,width:sheetW,height:sheetH))
for n in 1...6 {
 let im=read(out.appendingPathComponent("\(name)主图\(n).png"))
 let x=gap+((n-1)%3)*(thumb+gap),y=sheetH-gap-thumb-((n-1)/3)*(thumb+gap)
 sheet.interpolationQuality = .high
 sheet.draw(im,in:CGRect(x:x,y:y,width:thumb,height:thumb))
}
save(sheet.makeImage()!,out.appendingPathComponent("六张主图预览.png"))
let review=canvas(1020,520)
review.setFillColor(color(0xE9E5DE));review.fill(CGRect(x:0,y:0,width:1020,height:520))
for n in 1...6 {
 let im=read(out.appendingPathComponent("\(name)主图\(n).png"))
 review.interpolationQuality = .high
 review.draw(im,in:CGRect(x:10+(n-1)*170,y:350,width:160,height:160))
}
for n in 1...3 {
 let im=read(out.appendingPathComponent("\(name)主图\(n).png"))
 review.draw(im,in:CGRect(x:20+(n-1)*340,y:20,width:300,height:300))
}
save(review.makeImage()!,out.appendingPathComponent("制作文件/缩略图检查.png"))
