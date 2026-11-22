// Renders docs/store/feature-graphic-1024x500.png (Play Store requirement).
// Run: node docs/store/make-feature-graphic.js   (needs Playwright)
const {chromium}=require('playwright');
const html=`<html><head><link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Anek+Tamil:wdth,wght@75..125,400..800&display=block"></head>
<body style="margin:0;width:1024px;height:500px;background:#5A62D6;font-family:'Anek Tamil',sans-serif;color:#fff;display:flex;align-items:center;overflow:hidden">
<div style="padding-left:80px;flex:1">
 <div style="font-size:76px;font-weight:800;line-height:1">Shop Manager</div>
 <div style="font-size:30px;margin-top:18px;opacity:.92;max-width:560px;line-height:1.25">Repairs, second-hand phones, bills and stock — for mobile shops.</div>
 <div style="margin-top:26px;display:inline-block;background:#2DD4A7;color:#06372B;font-weight:700;font-size:24px;padding:8px 18px;border-radius:12px">English · தமிழ் · हिन्दी</div>
</div>
<svg width="300" height="300" viewBox="20 18 70 70" style="margin-right:70px"><rect x="38" y="25" width="32" height="58" rx="7" fill="none" stroke="#fff" stroke-width="5"/><rect x="48" y="31" width="12" height="3" rx="1.5" fill="#fff"/><path d="M58 58 h16 a3 3 0 0 1 3 3 v9 a3 3 0 0 1 -3 3 h-16 l-7 -7.5 z" fill="#2DD4A7"/><circle cx="57.5" cy="65.5" r="2" fill="#5A62D6"/></svg>
</body></html>`;
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:1024,height:500}});
await p.setContent(html);await p.waitForLoadState('networkidle');await p.evaluate(()=>document.fonts.ready);
await p.screenshot({path:__dirname+'/feature-graphic-1024x500.png'});await b.close();})();
