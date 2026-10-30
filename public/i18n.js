/* Traduction de l'interface de l'e-shop (FR par défaut → ES / IT / PT / EN).
 *
 * Aucune réécriture de catalogue.html : les textes affichés (nœuds texte +
 * placeholder/title/alt) sont traduits au vol, y compris ceux construits
 * dynamiquement, par un MutationObserver. Le français reste la langue source :
 * choisir 🇫🇷 restitue les textes d'origine.
 *
 * Dictionnaire : /i18n_dict.js (window.I18N_ROWS). Trois niveaux :
 *   E = texte entier (exact), F = fragments (dans une phrase construite),
 *   P = motifs avec capture ($1…) pour les phrases à valeurs variables.
 *
 * Restent en français, volontairement : noms d'articles / catalogues, bons de
 * commande PDF et e-mails fournisseurs, textarea / champs saisis, pages /admin.
 */
(function(){
  var LANGS=[
    {c:'fr',n:'Français'},{c:'es',n:'Español'},{c:'it',n:'Italiano'},
    {c:'pt',n:'Português'},{c:'en',n:'English'}
  ];
  var IDX={fr:0,en:1,es:2,it:3,pt:4}; // colonne dans I18N_ROWS (0 = français)
  var lang='fr';
  try{var s=localStorage.getItem('eshopLang'); if(IDX[s]!==undefined) lang=s;}catch(e){}

  var SKIP={SCRIPT:1,STYLE:1,TEXTAREA:1,NOSCRIPT:1,CODE:1,PRE:1};
  var ATTRS=['placeholder','title','alt','aria-label'];
  var nodeMap=new WeakMap(), attrMap=new WeakMap();
  var cache={}, tables={};
  var busy=false, observer=null, pending=new Set(), raf=0;

  function esc(s){return s.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');}
  function norm(s){return s.replace(/\s+/g,' ').trim();}

  function build(l){
    if(tables[l]) return tables[l];
    var ix=IDX[l], rows=window.I18N_ROWS||{};
    var E=new Map(), F=[], P=[];
    (rows.E||[]).forEach(function(r){ if(r[ix]) E.set(norm(r[0]),r[ix]); });
    (rows.F||[]).forEach(function(r){ if(r[ix]) F.push([r[0],r[ix]]); });
    (rows.P||[]).forEach(function(r){ if(r[ix]) P.push([new RegExp('^'+r[0]+'$'),r[ix]]); });
    F.sort(function(a,b){return b[0].length-a[0].length;});
    var fmap=new Map(F), fre=null;
    if(F.length){
      fre=new RegExp(F.map(function(r){
        var k=r[0], pre=/^[\p{L}\p{N}]/u.test(k)?'(?<![\\p{L}\\p{N}])':'',
            post=/[\p{L}\p{N}]$/u.test(k)?'(?![\\p{L}\\p{N}])':'';
        return pre+esc(k)+post;
      }).join('|'),'gu');
    }
    return tables[l]={E:E,P:P,fmap:fmap,fre:fre};
  }

  // Traduit un texte français ; renvoie le texte inchangé s'il n'y a rien à faire.
  function tr(txt,l){
    l=l||lang;
    if(l==='fr'||!txt) return txt;
    var m=txt.match(/^(\s*)([\s\S]*?)(\s*)$/), core=m[2];
    if(!core||!/[A-Za-zÀ-ÿ]/.test(core)) return txt;
    var key=norm(core), ck=l+'\u0001'+key, hit=cache[ck];
    if(hit===undefined){
      var T=build(l), out=T.E.get(key);
      if(out===undefined){
        for(var i=0;i<T.P.length&&out===undefined;i++){
          var mm=key.match(T.P[i][0]);
          if(mm) out=T.P[i][1].replace(/\$(\d)/g,function(_,n){return mm[n]===undefined?'':tr(mm[n],l);});
        }
      }
      if(out===undefined&&key.indexOf(' · ')>0){ // listes « Béton · Mortiers · … »
        var parts=key.split(' · '), tp=parts.map(function(x){return tr(x,l);});
        if(tp.join(' · ')!==key) out=tp.join(' · ');
      }
      if(out===undefined&&T.fre){
        var ch=false;
        out=key.replace(T.fre,function(f){ch=true;return T.fmap.get(f);});
        if(!ch) out=key;
      }
      hit=cache[ck]=out;
    }
    return hit===key?txt:m[1]+hit+m[3];
  }

  function doText(n){
    var rec=nodeMap.get(n), cur=n.data, orig;
    if(rec&&cur===rec.t) orig=rec.o; else orig=cur; // texte relu par l'appli = nouvel original
    var t=tr(orig);
    if(t===orig){ if(rec) nodeMap.delete(n); if(cur!==orig) n.data=orig; return; }
    nodeMap.set(n,{o:orig,t:t});
    if(cur!==t) n.data=t;
  }

  function doAttrs(el){
    var rec=attrMap.get(el)||{}, used=false;
    ATTRS.forEach(function(a){
      if(!el.hasAttribute(a)) return;
      var cur=el.getAttribute(a), r=rec[a], orig=(r&&cur===r.t)?r.o:cur, t=tr(orig);
      if(t===orig){ if(r){delete rec[a]; if(cur!==orig) el.setAttribute(a,orig);} return; }
      rec[a]={o:orig,t:t}; used=true;
      if(cur!==t) el.setAttribute(a,t);
    });
    if(used) attrMap.set(el,rec); else attrMap.delete(el);
  }

  function walk(root){
    if(root.nodeType===3){ if(!skipParent(root.parentNode)) doText(root); return; }
    if(root.nodeType!==1||root.closest&&root.closest('[translate="no"]')) return;
    doAttrs(root);
    if(SKIP[root.tagName]) return;
    var w=document.createTreeWalker(root,NodeFilter.SHOW_ELEMENT|NodeFilter.SHOW_TEXT,{
      acceptNode:function(n){
        if(n.nodeType===1){
          if(n.getAttribute('translate')==='no') return NodeFilter.FILTER_REJECT;
          if(SKIP[n.tagName]){ doAttrs(n); return NodeFilter.FILTER_REJECT; } // placeholder d'un textarea
        }
        return NodeFilter.FILTER_ACCEPT;
      }});
    var n; while((n=w.nextNode())){ if(n.nodeType===3) doText(n); else doAttrs(n); }
  }
  function skipParent(p){
    return !p||SKIP[p.tagName]||(p.closest&&p.closest('[translate="no"]'));
  }

  function flush(){
    raf=0; if(!pending.size) return;
    var list=Array.from(pending); pending.clear();
    busy=true;
    try{ list.forEach(function(n){ if(n.isConnected) walk(n); }); }
    finally{ busy=false; if(observer) observer.takeRecords(); }
  }
  function schedule(n){ pending.add(n); if(!raf) raf=requestAnimationFrame(flush); }

  function startObserver(){
    if(observer) return;
    observer=new MutationObserver(function(recs){
      if(busy||lang==='fr') return;
      recs.forEach(function(r){
        if(r.type==='childList') r.addedNodes.forEach(function(n){schedule(n);});
        else if(r.type==='characterData') schedule(r.target);
        else if(r.type==='attributes') schedule(r.target);
      });
    });
    observer.observe(document.body,{childList:true,subtree:true,characterData:true,
      attributes:true,attributeFilter:ATTRS});
  }

  function applyAll(){
    busy=true;
    try{ walk(document.body); }finally{ busy=false; if(observer) observer.takeRecords(); }
    document.documentElement.lang=lang;
  }

  // Messages natifs (alert / confirm / prompt)
  ['alert','confirm','prompt'].forEach(function(k){
    var o=window[k]; if(!o) return;
    window[k]=function(m){ var a=Array.prototype.slice.call(arguments);
      if(typeof m==='string') a[0]=tr(m);
      if(k==='prompt'&&typeof a[1]==='string') a[1]=a[1];
      return o.apply(window,a); };
  });

  function paintSwitch(){
    var box=document.getElementById('langSwitch'); if(!box) return;
    box.querySelectorAll('button').forEach(function(b){
      var on=b.dataset.lang===lang;
      b.setAttribute('aria-pressed',on?'true':'false');
      b.style.opacity=on?'1':'.55';
      b.style.outline=on?'2px solid #f1642a':'2px solid transparent';
    });
  }

  function setLang(l){
    if(IDX[l]===undefined||l===lang&&document.documentElement.lang===l) return;
    lang=l;
    try{localStorage.setItem('eshopLang',l);}catch(e){}
    applyAll(); paintSwitch();
  }

  function mountSwitch(){
    if(document.getElementById('langSwitch')) return;
    var box=document.createElement('div');
    box.id='langSwitch'; box.setAttribute('translate','no');
    box.style.cssText='display:flex;gap:4px;align-items:center;margin-left:14px;flex-shrink:0;background:rgba(255,255,255,.92);border-radius:10px;padding:3px 6px';
    LANGS.forEach(function(L){
      var b=document.createElement('button');
      b.type='button'; b.dataset.lang=L.c; b.title=L.n; b.setAttribute('aria-label',L.n);
      b.style.cssText='border:0;background:none;padding:2px;border-radius:4px;cursor:pointer;line-height:0';
      var img=document.createElement('img');
      img.src='/flags/'+L.c+'.svg'; img.alt=''; img.width=26; img.height=18;
      img.style.cssText='border-radius:3px;box-shadow:0 0 0 1px #0003;display:block;object-fit:cover';
      b.appendChild(img);
      b.addEventListener('click',function(){setLang(L.c);});
      box.appendChild(b);
    });
    var row=document.querySelector('.topbarSearchRow');
    if(row) row.appendChild(box); else document.body.appendChild(box);
    paintSwitch();
  }

  window.EshopI18n={t:tr,setLang:setLang,get lang(){return lang;}};

  function init(){
    mountSwitch(); startObserver();
    if(lang!=='fr') applyAll(); else document.documentElement.lang='fr';
  }
  if(document.readyState==='loading') document.addEventListener('DOMContentLoaded',init); else init();
})();
