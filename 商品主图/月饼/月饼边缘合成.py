"""Keep source-photo cake and every printed label; use generated pixels only at perimeter."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageChops
import numpy as np
root=Path(__file__).resolve().parent
# Inner tray polygons include all embossing, emblems, labels and curved small print.
polys={
 2:[(330,258),(500,210),(745,210),(897,270),(958,400),(991,815),(936,925),(360,982),(285,889),(251,422)],
 3:[(380,298),(561,314),(800,316),(945,350),(1000,526),(1000,951),(924,1042),(435,1054),(332,991),(310,473)],
 4:[(349,295),(500,235),(755,237),(909,305),(963,458),(949,906),(879,996),(355,988),(250,886),(266,433)],
 5:[(376,344),(522,275),(790,280),(960,365),(1019,542),(1000,938),(918,1018),(396,1030),(307,899),(310,485)]
}
for i,points in polys.items():
 source=Image.open(root/f'原图备份/旋转提亮版/月饼主图{i}.png').convert('RGB')
 base=Image.open(root/f'边缘修复素材/月饼主图{i}-边缘.png').convert('RGB').resize(source.size)
 protected=Image.new('L',source.size); ImageDraw.Draw(protected).polygon(points,fill=255)
 # Feather only outside the protected region: its pixels stay exactly equal to source.
 transition=protected.filter(ImageFilter.MaxFilter(15 if i==3 else 41)).filter(ImageFilter.GaussianBlur(4 if i==3 else 10))
 mask=ImageChops.lighter(protected,transition)
 base.paste(source,(0,0),mask)
 a=np.array(base); b=np.array(source); p=np.array(protected)==255
 assert np.array_equal(a[p],b[p]),'Protected product pixels changed'
 base.save(root/f'月饼主图{i}.png')
 print(i,'protected pixels identical:',p.sum(),'size:',base.size)
