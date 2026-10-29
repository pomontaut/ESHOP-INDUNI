/* Note de marché PowerPoint (GC / BAT) — générée côté navigateur, en un clic, à partir du
 * modèle INDUNI (public/templates/modele_induni.pptx) et des données déjà chargées par
 * l'écran « Indicateurs de marché » (aucune donnée inventée, aucun prix fournisseur).
 * Dépend de JSZip (public/jszip.min.js). Voir CLAUDE.md > « Note de marché PowerPoint ».
 *   NoteMarchePptx.generate(JSZip, templateArrayBuffer, data, entity) -> Promise<Blob>
 *   data = { kbob, diesel, brent, eurchf, canplast, acier, images:{ferraille,zinc} (ArrayBuffer) } */
(function(root){
'use strict';
var BLUE='0039A6', LIGHT='E7ECF4', MID='8AB1DD', PALE='CBDAEC', GREY='656565', DARK='1B2A41', RED='B91C1C', GREEN='176B28', WHITE='FFFFFF';
var X0=1055687, CW=10080625, Y0=1450000, Y1=6020000;
var ENTITIES={
  GC:{label:'Génie civil (GC)', short:'GC'},
  BAT:{label:'Bâtiment (BAT)', short:'BAT'}
};
var KBOB_SOURCE='KBOB, indices des prix à la production (base déc. 2025 = 100)';
// Produits finis (KBOB) par entité, dans l'ordre demandé.
var PRODUCTS={
  GC:[['Béton frais (béton prêt à l\'emploi)','Béton frais'],['Carrelets de coffrage','Carrelets de coffrage'],['Tuyaux et tubes en plastique','Tuyaux et tubes plastique'],['Non-tissés (sans habillement)','Non-tissés (géotextiles)']],
  BAT:[['Ciment','Ciment'],['Béton frais (béton prêt à l\'emploi)','Béton frais'],['Planches de coffrage','Planches de coffrage'],['Bitume d\'étanchéité','Bitume d\'étanchéité'],['Tuyaux et tubes en plastique','Tuyaux et tubes plastique'],['Matériau isolant en laine de verre ou de roche','Matériau isolant']]
};
var MONTHS=['janv.','févr.','mars','avr.','mai','juin','juil.','août','sept.','oct.','nov.','déc.'];

function esc(s){return String(s==null?'':s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');}
function fmt(n,dec){ if(n==null||isNaN(n)) return 'n/d'; return Number(n).toLocaleString('de-CH',{minimumFractionDigits:dec,maximumFractionDigits:dec}); }
function fmtPct(p){ return p==null?'n/d':(p>=0?'+':'')+p.toFixed(1).replace('.',',')+' %'; }
function monthLabel(ym){ var p=String(ym).split('-'); return MONTHS[parseInt(p[1],10)-1]+' '+p[0]; }
function dateFr(iso){ var p=String(iso).split('-'); return p[2]+'.'+p[1]+'.'+p[0]; }

// ── Séries / variations ────────────────────────────────────────────────────
function lastIdx(v){ var i=v.length-1; while(i>=0&&v[i]==null) i--; return i; }
function change(values,back){
  var l=lastIdx(values); if(l<0) return null;
  var r=l-back; while(r>=0&&values[r]==null) r--;
  if(r<0||!values[r]) return null;
  return {last:values[l],ref:values[r],pct:(values[l]-values[r])/values[r]*100};
}
function tail(arr,n){ return n>0?arr.slice(-n):arr; }

// ── Spécification du contenu (pure : données -> sections/cartes/tableaux) ──
function card(o){ return o; }
function kbobCard(kbob,name,label){
  var v=(kbob.series||{})[name]; if(!v) return card({title:label,source:'KBOB (base déc. 2025 = 100)',value:'n/d',deltas:[],missing:true});
  var l=lastIdx(v);
  return card({title:label,source:'KBOB (base déc. 2025 = 100)',sub:'relevé '+(l>=0?monthLabel(kbob.dates[l]):'n/d'),
    value:l>=0?fmt(v[l],1):'n/d',unit:'indice',
    deltas:[['1 mois',change(v,1)],['3 mois',change(v,3)],['12 mois',change(v,12)]],
    chart:{labels:tail(kbob.dates,36).map(function(d){return d.slice(2).replace('-','/');}),values:tail(v,36),dec:1}, trend3:change(v,3)});
}
function weeklyCard(title,source,vals,dates,dec,unit,suffixDelta,tailN){
  var l=lastIdx(vals);
  return card({title:title,source:source,sub:l>=0?'semaine du '+dateFr(dates[l]):'',value:l>=0?fmt(vals[l],dec):'n/d',unit:unit,
    deltas:[['1 mois',change(vals,4)],['3 mois',change(vals,13)],['12 mois',change(vals,52)]],
    chart:{labels:tail(dates,tailN||52).map(function(d){return d.slice(8)+'/'+d.slice(5,7);}),values:tail(vals,tailN||52),dec:dec},trend3:change(vals,13)});
}

function buildSpec(entity,d){
  var ent=ENTITIES[entity], kbob=d.kbob||{dates:[],series:{}}, spec={entity:entity,label:ent.label,sections:[]};
  var recos=[];
  function reco(name,ch,up,down,flat){
    if(!ch) return;
    var t=ch.pct>3?['Hausse',RED,up]:ch.pct<-3?['Baisse',GREEN,down]:['Stable',GREY,flat];
    recos.push({name:name,trend:t[0]+' ('+fmtPct(ch.pct)+' / 3 mois)',color:t[1],text:t[2]});
  }
  var UP='Anticiper : sécuriser les prix et les quantités, envisager un achat avec stock.',
      DOWN='Acheter au fil des besoins, ne pas anticiper.',
      FLAT='Achat au besoin, surveillance courante.';

  // 1 — Énergie / matières premières (identique GC et BAT)
  var brent=d.brent||{dates:[],values:[]};
  var cBrent=weeklyCard('Pétrole (Brent)','Brent Crude Oil, clôtures hebdomadaires',brent.values,brent.dates,1,'USD/baril');
  var cGaz=kbobCard(kbob,'Gaz (artisanat, industries, services)','Gaz'), cElec=kbobCard(kbob,'Electricité (artisanat, industries, services)','Électricité');
  reco('Pétrole (Brent)',cBrent.trend3,UP+' Répercussion possible sur diesel, bitume et plastiques.',DOWN,FLAT);
  reco('Gaz',cGaz.trend3,UP,DOWN,FLAT); reco('Électricité',cElec.trend3,UP,DOWN,FLAT);
  var s1={title:'1. Énergie – matières premières',slides:[
    {kind:'cards',title:'Énergie : pétrole, gaz, électricité',cards:[cBrent,cGaz,cElec],note:'Pétrole : prix en USD/baril (variation sur 4, 13 et 52 semaines). Gaz et électricité : indices KBOB (variation sur 1, 3 et 12 mois). Hausse en rouge, baisse en vert (point de vue achat).'},
    {kind:'images',title:'Matières premières : ferraille et zinc',images:[
      {key:'ferraille',caption:'Ferraille CFR Turquie (Platts), USD/tonne',source:'Source : Platts (capture)'},
      {key:'zinc',caption:'Zinc (LME), USD/tonne',source:'Source : LME (capture mise à jour le 28.10.2026, cours au 27.10.2026)'}],
     note:'Captures de cours fournies et intégrées dans l\'e-shop : pas de série chiffrée exploitable pour calculer des variations.'}]};
  spec.sections.push(s1);

  // 2 — Taux de change, carburant, armature, Canplast
  var eur=d.eurchf||{dates:[],values:[]};
  var cEur=weeklyCard('Taux de change CHF/EUR','EUR/CHF spot, clôtures hebdomadaires',eur.values,eur.dates,3,'CHF pour 1 EUR');
  var diesel=d.diesel||[], dl=diesel.length?diesel[diesel.length-1]:null;
  var dv=diesel.map(function(x){return x.price;}), dd=diesel.map(function(x){return x.weekStart;});
  var cDiesel=weeklyCard('Diesel – indice ASTAG','ASTAG, prix moyen hebdomadaire du diesel',dv,dd,2,'CHF/litre',null,26);
  if(dl) cDiesel.extra='Surcharge nationale ASTAG : '+fmt(dl.surchargePct,2)+' %';
  cDiesel.deltas=[['1 sem.',change(dv,1)],['4 sem.',change(dv,4)],['12 sem.',change(dv,12)]]; cDiesel.trend3=change(dv,12);
  reco('Taux de change CHF/EUR',cEur.trend3,'Franc plus faible face à l\'euro : les achats importés renchérissent, anticiper les commandes en euros.','Franc plus fort face à l\'euro : conditions favorables aux achats importés, négocier la répercussion.',FLAT);
  reco('Diesel (ASTAG)',cDiesel.trend3,'Surcharge carburant probable : vérifier les frais de transport avant commande.',DOWN,FLAT);
  var ac=d.acier||{dates:[],values:[]}, al=lastIdx(ac.values), rplp=ac.rplpPct!=null?ac.rplpPct:4.3;
  var cAcier=card({title:'Acier d\'armature (Suisse)',source:'Source : Aurélien (relevés Achats)',sub:al>=0?'relevé du '+dateFr(ac.dates[al]):'',
    value:al>=0?fmt(ac.values[al],0):'n/d',unit:'CHF/tonne + RPLP (≈ '+fmt(rplp,1)+' % en moyenne)',
    deltas:[['relevé préc.',change(ac.values,1)],['1er relevé',change(ac.values,ac.values.length-1)]],
    chart:{labels:ac.dates.map(function(x){return x.slice(8)+'/'+x.slice(5,7);}),values:ac.values.slice(),dec:0,dots:true},trend3:null});
  // tendance armature : relevé le plus proche d'il y a ~90 jours
  if(al>0){ var t0=new Date(ac.dates[al]).getTime()-90*864e5, bi=0; ac.dates.forEach(function(x,i){ if(Math.abs(new Date(x).getTime()-t0)<Math.abs(new Date(ac.dates[bi]).getTime()-t0)) bi=i; });
    if(bi<al) reco('Acier d\'armature',{pct:(ac.values[al]-ac.values[bi])/ac.values[bi]*100},UP,DOWN,FLAT); }
  var s2={title:'2. Taux de change et indicateurs locaux',slides:[
    {kind:'cards',title:'Taux de change et carburant',cards:[cEur,cDiesel],note:'Variations sur 4, 13 et 52 semaines (CHF/EUR) ; 1, 4 et 12 semaines (ASTAG).'},
    {kind:'armature',title:'Prix de l\'acier d\'armature',card:cAcier,
     rows:ac.dates.map(function(x,i){return [dateFr(x),fmt(ac.values[i],0)+' CHF/to + RPLP'];}).reverse(),note:'Prix hors RPLP ; la RPLP s\'ajoute (≈ '+fmt(rplp,1)+' % en moyenne). Source : Aurélien.'}]};
  {
    var cp=d.canplast||[], groups={};
    cp.forEach(function(r){ (groups[r.codes]=groups[r.codes]||{codes:r.codes,label:r.label,rows:[]}).rows.push(r); });
    var rows=Object.keys(groups).map(function(k){
      var g=groups[k]; g.rows.sort(function(a,b){return a.effectiveDate.localeCompare(b.effectiveDate);});
      var last=g.rows[g.rows.length-1], prev=g.rows.length>1?g.rows[g.rows.length-2]:null;
      return {label:g.label,codes:g.codes,date:last.effectiveDate,pct:last.surchargePct,delta:prev?last.surchargePct-prev.surchargePct:null};
    });
    rows.forEach(function(r){ if(r.delta!=null&&r.delta>0) recos.push({name:'Canplast : '+r.label,trend:'Hausse (+'+fmt(r.delta,1)+' pt)',color:RED,text:'Surrenchérissement en hausse : contrôler le supplément facturé sur les commandes.'}); });
    // courbes : PVC canalisation/drainage (A1-A3), PE canalisation (D1…), PP canalisation/drainage (F5) ; le reste en tableau
    var CURVES=[['A1, A2, A3','Tuyaux de drainage PVC'],['D1, D3, D4, D8','Tuyaux de canalisation PE'],['F5','Tuyaux de canalisation PP']];
    var curveCards=[], curveCodes={};
    CURVES.forEach(function(cv){ var g=groups[cv[0]]; if(!g) return; curveCodes[cv[0]]=1;
      var rr=g.rows, l=rr[rr.length-1], p=rr.length>1?rr[rr.length-2]:null;
      curveCards.push({title:cv[1],source:'Avis Canplast ('+g.codes+')',sub:'au '+dateFr(l.effectiveDate),value:fmt(l.surchargePct,1)+' %',unit:'de surrenchérissement',
        deltas:[],extra:p?'Écart vs avis précédent : '+(l.surchargePct-p.surchargePct>=0?'+':'')+fmt(l.surchargePct-p.surchargePct,1)+' pt':'',
        chart:{labels:rr.map(function(x){return x.effectiveDate.slice(8)+'/'+x.effectiveDate.slice(5,7)+'/'+x.effectiveDate.slice(2,4);}),values:rr.map(function(x){return x.surchargePct;}),dec:0,dots:true},trend3:null}); });
    if(curveCards.length) s2.slides.push({kind:'cards',title:'Évolution de l\'indice Canplast',cards:curveCards,note:'Surrenchérissement Canplast en % du prix, à chaque date d\'effet des avis. Source : avis Canplast saisis dans l\'e-shop.'});
    rows=rows.filter(function(r){return !curveCodes[r.codes];});
    s2.slides.push({kind:'canplast',title:'Suivi des surrenchérissements Canplast',rows:rows,note:'Dernier surrenchérissement connu par famille d\'articles (en % du prix), avec l\'écart en points par rapport à l\'avis précédent. Source : avis Canplast saisis dans l\'e-shop.'});
  }
  spec.sections.push(s2);

  // 3 — Produits finis (KBOB)
  var pc=PRODUCTS[entity].map(function(p){ var c=kbobCard(kbob,p[0],p[1]); reco(p[1],c.trend3,UP,DOWN,FLAT); return c; });
  spec.sections.push({title:'3. Produits finis',slides:[{kind:'cards',title:'Produits finis : indices KBOB',cards:pc,note:'Indices KBOB des prix à la production (base déc. 2025 = 100) : ils mesurent l\'évolution des prix, pas un prix en CHF. Variations sur 1, 3 et 12 mois.'}]});

  // 4 — Recommandations (règle automatique ±3 % sur 3 mois)
  spec.sections.push({title:'4. Recommandations',slides:[{kind:'reco',title:'Recommandations Achats',rows:recos,note:'Règle automatique : hausse > +3 % sur 3 mois → anticiper ; baisse < −3 % → acheter au besoin ; sinon stable. Aide à la décision à valider par les Achats avant diffusion.'}]});
  return spec;
}

// ── XML (PresentationML) ───────────────────────────────────────────────────
var NS='xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"';
function Slide(){ this.id=10; this.parts=[]; this.images=[]; }
Slide.prototype.nid=function(){return ++this.id;};
function run(t,o){ o=o||{};
  return '<a:r><a:rPr lang="fr-CH" sz="'+Math.round((o.sz||12)*100)+'" b="'+(o.b?1:0)+'" dirty="0"><a:solidFill><a:srgbClr val="'+(o.color||DARK)+'"/></a:solidFill><a:latin typeface="+mn-lt"/></a:rPr><a:t>'+esc(t)+'</a:t></a:r>';
}
function para(runs,o){ o=o||{};
  var bullet=o.bullet?'<a:buFont typeface="Arial"/><a:buChar char="•"/>':'<a:buNone/>';
  var ind=o.bullet?' marL="228600" indent="-228600"':' marL="0" indent="0"';
  return '<a:p><a:pPr algn="'+(o.algn||'l')+'"'+ind+'><a:spcBef><a:spcPts val="'+(o.before||0)+'"/></a:spcBef>'+bullet+'</a:pPr>'+runs+'</a:p>';
}
Slide.prototype.text=function(x,y,w,h,paras,o){ o=o||{};
  this.parts.push('<p:sp><p:nvSpPr><p:cNvPr id="'+this.nid()+'" name="Texte '+this.id+'"/><p:cNvSpPr txBox="1"/><p:nvPr/></p:nvSpPr><p:spPr><a:xfrm><a:off x="'+x+'" y="'+y+'"/><a:ext cx="'+w+'" cy="'+h+'"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:noFill/></p:spPr><p:txBody><a:bodyPr wrap="square" lIns="0" tIns="0" rIns="0" bIns="0" anchor="'+(o.anchor||'t')+'"><a:normAutofit/></a:bodyPr><a:lstStyle/>'+paras.join('')+'</p:txBody></p:sp>');
};
Slide.prototype.rect=function(x,y,w,h,fill,line,round){
  this.parts.push('<p:sp><p:nvSpPr><p:cNvPr id="'+this.nid()+'" name="Forme '+this.id+'"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr><p:spPr><a:xfrm><a:off x="'+x+'" y="'+y+'"/><a:ext cx="'+w+'" cy="'+h+'"/></a:xfrm><a:prstGeom prst="'+(round?'roundRect':'rect')+'"><a:avLst>'+(round?'<a:gd name="adj" fmla="val 3500"/>':'')+'</a:avLst></a:prstGeom>'+(fill?'<a:solidFill><a:srgbClr val="'+fill+'"/></a:solidFill>':'<a:noFill/>')+(line?'<a:ln w="9525"><a:solidFill><a:srgbClr val="'+line+'"/></a:solidFill></a:ln>':'<a:ln><a:noFill/></a:ln>')+'</p:spPr><p:txBody><a:bodyPr/><a:lstStyle/><a:p><a:endParaRPr lang="fr-CH"/></a:p></p:txBody></p:sp>');
};
Slide.prototype.pic=function(bytes,x,y,w,h,descr){
  var n=this.images.length+1; this.images.push(bytes);
  this.parts.push('<p:pic><p:nvPicPr><p:cNvPr id="'+this.nid()+'" name="Image '+this.id+'" descr="'+esc(descr||'')+'"/><p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr><p:nvPr/></p:nvPicPr><p:blipFill><a:blip r:embed="rIdImg'+n+'"/><a:stretch><a:fillRect/></a:stretch></p:blipFill><p:spPr><a:xfrm><a:off x="'+x+'" y="'+y+'"/><a:ext cx="'+w+'" cy="'+h+'"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr></p:pic>');
};
// cells : [{t, b, color, fill, algn, sz}] par ligne ; header = 1re ligne.
Slide.prototype.table=function(x,y,colW,rows,rowH,o){ o=o||{};
  var self=this, W=colW.reduce(function(a,b){return a+b;},0);
  var grid=colW.map(function(w){return '<a:gridCol w="'+w+'"/>';}).join('');
  var trs=rows.map(function(r,ri){
    var head=ri===0&&!o.noHeader;
    return '<a:tr h="'+rowH+'">'+r.map(function(c){
      if(typeof c==='string') c={t:c};
      var fill=head?BLUE:(c.fill||(ri%2?'F5F7FB':WHITE));
      return '<a:tc><a:txBody><a:bodyPr/><a:lstStyle/>'+para(run(c.t,{sz:c.sz||o.sz||11,b:head||c.b,color:head?WHITE:(c.color||DARK)}),{algn:c.algn||'l'})+'</a:txBody><a:tcPr marL="91440" marR="91440" marT="36000" marB="36000" anchor="ctr"><a:lnL w="0"><a:noFill/></a:lnL><a:lnR w="0"><a:noFill/></a:lnR><a:lnT w="0"><a:noFill/></a:lnT><a:lnB w="6350"><a:solidFill><a:srgbClr val="'+PALE+'"/></a:solidFill></a:lnB><a:solidFill><a:srgbClr val="'+fill+'"/></a:solidFill></a:tcPr></a:tc>';
    }).join('')+'</a:tr>';
  }).join('');
  this.parts.push('<p:graphicFrame><p:nvGraphicFramePr><p:cNvPr id="'+this.nid()+'" name="Tableau '+this.id+'"/><p:cNvGraphicFramePr><a:graphicFrameLocks noGrp="1"/></p:cNvGraphicFramePr><p:nvPr/></p:nvGraphicFramePr><p:xfrm><a:off x="'+x+'" y="'+y+'"/><a:ext cx="'+W+'" cy="'+(rowH*rows.length)+'"/></p:xfrm><a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/table"><a:tbl><a:tblPr firstRow="1"/><a:tblGrid>'+grid+'</a:tblGrid>'+trs+'</a:tbl></a:graphicData></a:graphic></p:graphicFrame>');
};
Slide.prototype.xml=function(){
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><p:sld '+NS+'><p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>'+this.parts.join('')+'</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>';
};

// ── Graphiques (canvas -> PNG) ─────────────────────────────────────────────
function lineChartPng(c,W,H){
  var S=2, cv=document.createElement('canvas'); cv.width=W*S; cv.height=H*S;
  var g=cv.getContext('2d'); g.scale(S,S);
  g.fillStyle='#fff'; g.fillRect(0,0,W,H);
  var vals=c.values.filter(function(v){return v!=null;});
  if(!vals.length){ g.fillStyle='#656565'; g.font='13px Arial'; g.fillText('Aucune donnée',12,24); return cv; }
  var min=Math.min.apply(null,vals), max=Math.max.apply(null,vals), span=(max-min)||Math.abs(max)*0.02||1, lo=min-span*0.15, hi=max+span*0.15;
  var pl=46,pr=10,pt=10,pb=22, n=c.values.length;
  var px=function(i){return pl+(n<=1?(W-pl-pr)/2:(W-pl-pr)*i/(n-1));}, py=function(v){return pt+(H-pt-pb)*(1-(v-lo)/(hi-lo));};
  g.font='10px Arial'; g.strokeStyle='#E3E8F0'; g.fillStyle='#656565'; g.lineWidth=1; g.textAlign='right';
  for(var k=0;k<4;k++){ var v=lo+(hi-lo)*k/3, y=py(v); g.beginPath(); g.moveTo(pl,y); g.lineTo(W-pr,y); g.stroke(); g.fillText(fmt(v,c.dec),pl-5,y+3); }
  g.textAlign='center';
  var step=Math.max(1,Math.ceil(n/5));
  for(var i=n-1;i>=0;i-=step){ g.fillText(c.labels[i],Math.min(Math.max(px(i),pl+14),W-pr-14),H-6); }
  var pts=[]; c.values.forEach(function(v,i){ if(v!=null) pts.push([px(i),py(v)]); });
  g.beginPath(); pts.forEach(function(p,i){ i?g.lineTo(p[0],p[1]):g.moveTo(p[0],p[1]); });
  g.strokeStyle='#'+BLUE; g.lineWidth=2; g.lineJoin='round'; g.stroke();
  if(pts.length>1){ g.lineTo(pts[pts.length-1][0],H-pb); g.lineTo(pts[0][0],H-pb); g.closePath(); g.fillStyle='rgba(0,57,166,.08)'; g.fill(); }
  if(c.dots) pts.forEach(function(p){ g.beginPath(); g.arc(p[0],p[1],3,0,7); g.fillStyle='#'+BLUE; g.fill(); });
  var lp=pts[pts.length-1]; g.beginPath(); g.arc(lp[0],lp[1],4,0,7); g.fillStyle='#'+BLUE; g.fill();
  return cv;
}
function canvasPng(cv){ return new Promise(function(res){ cv.toBlob(function(b){ b.arrayBuffer().then(res); },'image/png'); }); }

// ── Mise en page des diapositives ──────────────────────────────────────────
function contentSlide(title,note){
  var s=new Slide();
  s.text(X0,640000,CW-1100000,640000,[para(run(title,{sz:28,color:BLUE}))],{anchor:'t'});
  if(note) s.text(X0,6040000,8400000,300000,[para(run(note,{sz:8,color:GREY}))]);
  s.layout=9; return s;
}
function deltaRuns(deltas){
  var out=[];
  deltas.forEach(function(d,i){ var ch=d[1];
    if(i) out.push(run('  ',{sz:9}));
    out.push(run(d[0]+' ',{sz:9,color:GREY}));
    out.push(run(ch?fmtPct(ch.pct):'n/d',{sz:9,b:1,color:!ch?GREY:ch.pct>0.05?RED:ch.pct<-0.05?GREEN:GREY}));
  });
  return out.join('');
}
async function drawCard(s,c,x,y,w,h){
  s.rect(x,y,w,h,WHITE,PALE,true);
  var horiz=w/h>1.6, pad=110000, tw=horiz?Math.round(w*0.42):w-2*pad, ty=y+pad;
  var paras=[para(run(c.title,{sz:horiz?13:15,b:1,color:BLUE})),para(run(c.source+(c.sub?' · '+c.sub:''),{sz:8,color:GREY}),{before:100}),
    para(run(c.value,{sz:horiz?22:28,b:1,color:DARK})+run('  '+(c.unit||''),{sz:horiz?9:10,color:GREY}),{before:horiz?300:500}),
    para(deltaRuns(c.deltas||[]),{before:300})];
  if(c.extra) paras.push(para(run(c.extra,{sz:9,color:GREY}),{before:200}));
  var th=horiz?h-2*pad:Math.min(h*0.5,1900000);
  s.text(x+pad,ty,tw-(horiz?pad:0),th,paras);
  if(c.chart){
    var cx=horiz?x+tw+pad:x+pad, cy=horiz?y+pad:y+pad+th, cw=horiz?w-tw-2*pad:w-2*pad, ch=horiz?h-2*pad:h-th-2*pad;
    var png=await canvasPng(lineChartPng(c.chart,Math.round(cw/9525),Math.round(ch/9525)));
    s.pic(png,cx,cy,cw,ch,'Évolution : '+c.title);
  }
}
async function cardsSlide(def){
  var s=contentSlide(def.title,def.note), cs=def.cards, n=cs.length, gap=200000, H=Y1-Y0;
  var cols=n<=3?n:2, rows=Math.ceil(n/cols), w=Math.floor((CW-gap*(cols-1))/cols), h=Math.floor((H-gap*(rows-1))/rows);
  for(var i=0;i<n;i++) await drawCard(s,cs[i],X0+(i%cols)*(w+gap),Y0+Math.floor(i/cols)*(h+gap),w,h);
  return s;
}
async function imagesSlide(def,images){
  var s=contentSlide(def.title,def.note), gap=250000, w=Math.floor((CW-gap)/2);
  def.images.forEach(function(im,i){
    var x=X0+i*(w+gap), hh=Math.round(w*0.51);
    s.text(x,Y0,w,330000,[para(run(im.caption,{sz:14,b:1,color:BLUE}))]);
    s.text(x,Y0+330000,w,250000,[para(run(im.source,{sz:9,color:GREY}))]);
    if(images[im.key]) s.pic(images[im.key],x,Y0+650000,w,hh,im.caption);
    else s.text(x,Y0+650000,w,300000,[para(run('Image non disponible',{sz:11,color:GREY}))]);
  });
  return s;
}
async function armatureSlide(def){
  var s=contentSlide(def.title,def.note), w1=5900000, gap=250000;
  await drawCard(s,def.card,X0,Y0,w1,Y1-Y0);
  var rows=[['Date du relevé',{t:'Prix',algn:'r'}]].concat(def.rows.map(function(r){return [r[0],{t:r[1],algn:'r',b:1}];}));
  s.table(X0+w1+gap,Y0,[1500000,2430000],rows,Math.min(380000,Math.floor((Y1-Y0)/rows.length)),{sz:11});
  return s;
}
async function canplastSlide(def){
  var s=contentSlide(def.title,def.note), rows=def.rows.slice(0,11);
  var tr=[['Famille d\'articles',{t:'Date d\'effet',algn:'r'},{t:'Surcharge',algn:'r'},{t:'Écart',algn:'r'}]];
  rows.forEach(function(r){ tr.push([r.label,{t:dateFr(r.date),algn:'r'},{t:fmt(r.pct,1)+' %',algn:'r',b:1},
    {t:r.delta==null?'—':(r.delta>=0?'+':'')+fmt(r.delta,1)+' pt',algn:'r',color:r.delta==null||r.delta===0?GREY:r.delta>0?RED:GREEN,b:1}]); });
  if(def.rows.length>rows.length) tr.push(['… et '+(def.rows.length-rows.length)+' autre(s) famille(s)','','','']);
  if(def.rows.length===0) tr.push(['Aucun avis Canplast enregistré','','','']);
  s.table(X0,Y0,[5300000,1700000,1500000,1580625],tr,Math.min(380000,Math.floor((Y1-Y0)/tr.length)),{sz:11});
  return s;
}
async function recoSlide(def){
  var s=contentSlide(def.title,def.note);
  var tr=[['Indicateur','Tendance','Recommandation']];
  def.rows.forEach(function(r){ tr.push([{t:r.name,b:1},{t:r.trend,color:r.color,b:1},r.text]); });
  if(def.rows.length===0) tr.push(['Données insuffisantes','','']);
  s.table(X0,Y0,[2500000,2300000,5280625],tr,Math.min(400000,Math.floor((Y1-Y0)/tr.length)),{sz:10});
  return s;
}
function coverSlide(spec,dateLabel){
  var s=new Slide(); s.layout=1;
  s.text(5375275,1268413,5400000,1700000,[para(run('Note de marché',{sz:40,color:WHITE})),para(run(spec.label,{sz:28,color:WHITE}),{before:600}),para(run('Achats · '+dateLabel,{sz:16,color:PALE}),{before:900})]);
  return s;
}
function chapterSlide(title,num){
  var s=new Slide(); s.layout=3;
  s.parts.push('<p:sp><p:nvSpPr><p:cNvPr id="'+s.nid()+'" name="Titre"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph type="title"/></p:nvPr></p:nvSpPr><p:spPr><a:xfrm><a:off x="6815988" y="2307266"/><a:ext cx="4320324" cy="2243691"/></a:xfrm></p:spPr><p:txBody><a:bodyPr/><a:lstStyle/><a:p><a:r><a:rPr lang="fr-CH" sz="3200" dirty="0"/><a:t>'+esc(title)+'</a:t></a:r></a:p></p:txBody></p:sp>');
  return s;
}

// ── Assemblage du .pptx à partir du modèle ─────────────────────────────────
async function assemble(JSZip,tplBuf,slides){
  var zip=await JSZip.loadAsync(tplBuf);
  Object.keys(zip.files).forEach(function(n){
    if(/^ppt\/slides\/(_rels\/)?slide\d+\.xml(\.rels)?$/.test(n)||/^ppt\/changesInfos\//.test(n)) zip.remove(n);
  });
  var ct=await zip.file('[Content_Types].xml').async('string');
  ct=ct.replace(/<Override PartName="\/ppt\/slides\/slide\d+\.xml"[^>]*\/>/g,'').replace(/<Override PartName="\/ppt\/changesInfos\/[^"]*"[^>]*\/>/g,'');
  var rels=await zip.file('ppt/_rels/presentation.xml.rels').async('string');
  rels=rels.replace(/<Relationship [^>]*relationships\/slide"[^>]*\/>/g,'').replace(/<Relationship [^>]*changesInfo"[^>]*\/>/g,'');
  var ids='', add='', ovr='', img=0;
  slides.forEach(function(s,i){
    var n=i+1, name='slide'+n+'.xml', imgRels='';
    s.images.forEach(function(b,k){ img++; zip.file('ppt/media/nm_'+img+'.png',b); imgRels+='<Relationship Id="rIdImg'+(k+1)+'" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/nm_'+img+'.png"/>'; });
    zip.file('ppt/slides/'+name,s.xml());
    zip.file('ppt/slides/_rels/'+name+'.rels','<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout'+s.layout+'.xml"/>'+imgRels+'</Relationships>');
    ovr+='<Override PartName="/ppt/slides/'+name+'" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>';
    add+='<Relationship Id="rIdNm'+n+'" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/'+name+'"/>';
    ids+='<p:sldId id="'+(300+n)+'" r:id="rIdNm'+n+'"/>';
  });
  zip.file('[Content_Types].xml',ct.replace('</Types>',ovr+'</Types>'));
  zip.file('ppt/_rels/presentation.xml.rels',rels.replace('</Relationships>',add+'</Relationships>'));
  var pres=await zip.file('ppt/presentation.xml').async('string');
  pres=pres.replace(/<p:sldIdLst>[\s\S]*?<\/p:sldIdLst>/,'<p:sldIdLst>'+ids+'</p:sldIdLst>');
  zip.file('ppt/presentation.xml',pres);
  return zip.generateAsync({type:'blob',mimeType:'application/vnd.openxmlformats-officedocument.presentationml.presentation',compression:'DEFLATE'});
}

async function generate(JSZip,tplBuf,data,entity){
  var spec=buildSpec(entity,data), slides=[];
  var dateLabel=new Date().toLocaleDateString('fr-CH',{month:'long',year:'numeric'});
  slides.push(coverSlide(spec,dateLabel));
  for(var i=0;i<spec.sections.length;i++){
    var sec=spec.sections[i]; slides.push(chapterSlide(sec.title));
    for(var j=0;j<sec.slides.length;j++){
      var d=sec.slides[j], s;
      if(d.kind==='cards') s=await cardsSlide(d);
      else if(d.kind==='images') s=await imagesSlide(d,data.images||{});
      else if(d.kind==='armature') s=await armatureSlide(d);
      else if(d.kind==='canplast') s=await canplastSlide(d);
      else s=await recoSlide(d);
      slides.push(s);
    }
  }
  return assemble(JSZip,tplBuf,slides);
}
root.NoteMarchePptx={generate:generate,buildSpec:buildSpec,ENTITIES:ENTITIES};
})(typeof window!=='undefined'?window:this);
