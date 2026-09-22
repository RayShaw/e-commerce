from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import numpy as np
import shutil, hashlib
import cv2
root=Path(__file__).resolve().parents[2]
out=root/'商品主图/月饼'
specs=[
 ('65444_6613',[(0,550),(45,544),(88,529),(99,551),(83,575),(120,620),(385,630),(680,638),(848,675),(899,631),(917,635),(899,693),(900,1330),(931,1404),(967,1431),(988,1515),(980,1568),(913,1560),(871,1489),(367,1495),(22,1490),(0,1474)]),
 ('65703_6615',[(44,1258),(94,1210),(148,1178),(174,1050),(183,689),(197,528),(190,477),(202,450),(210,422),(221,425),(220,470),(269,477),(525,483),(850,508),(976,514),(985,487),(1007,485),(1007,545),(988,656),(983,1104),(1008,1228),(984,1250),(989,1300),(962,1381),(910,1374),(878,1369),(868,1301),(878,1252),(506,1239),(166,1220),(74,1265)]),
 ('65707_6616',[(0,373),(17,372),(30,410),(30,438),(62,488),(112,462),(366,441),(790,432),(905,408),(938,385),(1012,389),(1034,416),(1032,471),(1055,564),(1056,760),(1063,968),(1080,1004),(1080,1295),(1003,1286),(961,1302),(665,1321),(372,1334),(138,1308),(81,1377),(78,1404),(36,1380),(16,1321),(30,1110),(4,704),(0,676)]),
 ('65712_6617',[(0,1438),(28,1410),(69,1398),(81,1321),(66,1092),(46,831),(60,697),(51,636),(89,633),(282,630),(621,630),(776,609),(843,577),(869,558),(861,587),(842,625),(843,677),(849,1040),(843,1380),(876,1405),(905,1415),(941,1445),(944,1482),(966,1547),(952,1564),(898,1545),(773,1511),(515,1498),(264,1474),(113,1487),(0,1497)])
]
for i,(name,points) in enumerate(specs,2):
 src=root/f'素材/月饼/Weixin Image_202609021{name}_2.jpg'
 raw=Image.open(src).convert('RGB')
 # Photographic corrections only; cake embossing and printing are never regenerated.
 a=np.asarray(raw).astype(np.float32)
 a=(a*np.array([1.20,1.12,1.06])-115)*1.07+121
 a=np.clip(a,0,255).astype('uint8')
 photo=Image.fromarray(a)
 mask=Image.new('L',raw.size); ImageDraw.Draw(mask).polygon(points,fill=255)
 m=np.asarray(mask).copy()
 core=cv2.erode(m,np.ones((55,55),np.uint8))
 outer=cv2.dilate(m,np.ones((35,35),np.uint8))
 gc=np.where(outer==0,cv2.GC_BGD,cv2.GC_PR_BGD).astype('uint8')
 gc[m>0]=cv2.GC_PR_FGD
 gc[core>0]=cv2.GC_FGD
 cv2.grabCut(np.array(raw),gc,None,np.zeros((1,65)),np.zeros((1,65)),5,cv2.GC_INIT_WITH_MASK)
 alpha=np.where((gc==cv2.GC_FGD)|(gc==cv2.GC_PR_FGD),255,0).astype('uint8')
 alpha=cv2.morphologyEx(alpha,cv2.MORPH_CLOSE,np.ones((3,3),np.uint8))
 # Keep translucent film connections rather than cutting holes through the wrapper.
 film=(m>0)&(alpha==0)
 alpha[film]=90
 a[film]=np.clip(a[film].astype(float)*.35+255*.65,0,255).astype('uint8')
 photo=Image.fromarray(a)
 mask=Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(.65))
 box=mask.getbbox(); photo=photo.crop(box); mask=mask.crop(box)
 angle={2:Image.Transpose.ROTATE_270,3:Image.Transpose.ROTATE_270,4:Image.Transpose.ROTATE_90,5:Image.Transpose.ROTATE_180}[i]
 photo=photo.transpose(angle); mask=mask.transpose(angle)
 correction={2:7,3:5,4:-6,5:2}[i]
 photo=photo.rotate(correction,Image.Resampling.BICUBIC,expand=True,fillcolor='white')
 mask=mask.rotate(correction,Image.Resampling.BICUBIC,expand=True,fillcolor=0)
 scale=1080/max(photo.size); size=tuple(round(v*scale) for v in photo.size)
 photo=photo.resize(size,Image.Resampling.LANCZOS); mask=mask.resize(size,Image.Resampling.LANCZOS)
 canvas=Image.new('RGB',(1254,1254),'white'); pos=((1254-size[0])//2,(1254-size[1])//2)
 shadow=Image.new('L',canvas.size)
 shadow.paste(mask,(pos[0],pos[1]+18))
 shadow=shadow.filter(ImageFilter.GaussianBlur(19)).point(lambda v:round(v*.18))
 canvas.paste((65,54,40),(0,0,1254,1254),shadow)
 photo=photo.filter(ImageFilter.UnsharpMask(radius=1.1,percent=65,threshold=3))
 canvas.paste(photo,pos,mask)
 target=out/f'月饼主图{i}.png'; backup=out/'原图备份/AI重绘版-待弃用'/target.name
 if target.exists() and not backup.exists(): shutil.copy2(target,backup)
 canvas.save(target)
 print(i,src.name,canvas.size,hashlib.sha256(src.read_bytes()).hexdigest())
