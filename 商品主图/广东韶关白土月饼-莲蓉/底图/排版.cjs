const sharp=require('/Users/rayleighshaw/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const path=require('path');
const dir=path.resolve(__dirname,'..');
const copy=[['韶关白土月饼','莲蓉口味 · 一盒4枚'],['莲蓉馅，切开看','饼皮厚薄，看得清楚'],['柴火烤制','白土月饼非遗技艺'],['一盒四枚，独立包装','125g×4枚 · 净含量500g'],['带一盒家乡味','随盒附礼袋、餐具']];
(async()=>{
const tiles=[];
for(let i=1;i<=6;i++){
 let img=sharp(path.join(__dirname,`主图${i}-底图.png`)).resize(1254,1254,{fit:'contain',background:'#FFFFFF'});
 if(i===6){
 const {data,info}=await img.removeAlpha().raw().toBuffer({resolveWithObject:true});
 for(let p=0;p<data.length;p+=info.channels){
 const r=data[p],g=data[p+1],b=data[p+2];
 if(Math.min(r,g,b)>=245 && Math.max(r,g,b)-Math.min(r,g,b)<=8) data[p]=data[p+1]=data[p+2]=255;
 }
 img=sharp(data,{raw:{width:info.width,height:info.height,channels:info.channels}});
 }
 if(i<=5){
 const color=i<=3?'#FFF8E8':'#3B291D';
 const title=copy[i-1][0],sub=copy[i-1][1];
 const size=i===4?99:112;
 const svg=`<svg width="1254" height="1254" xmlns="http://www.w3.org/2000/svg"><text x="80" y="165" fill="${color}" font-family="Songti SC" font-weight="900" font-size="${size}">${title}</text><text x="84" y="255" fill="${color}" font-family="Hiragino Sans GB" font-size="53">${sub}</text></svg>`;
 img=img.composite([{input:Buffer.from(svg)}]);
 }
 const out=path.join(dir,`广东韶关白土月饼-莲蓉主图${i}.png`);
 await img.png().toFile(out);
 tiles.push({input:await sharp(out).resize(375,375).toBuffer(),left:((i-1)%3)*395,top:Math.floor((i-1)/3)*395});
}
await sharp({create:{width:1165,height:770,channels:3,background:'#ede7df'}}).composite(tiles).png().toFile(path.join(dir,'六张主图预览.png'));
})();
