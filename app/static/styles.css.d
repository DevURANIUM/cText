:root{
  --bg:#070b16;
  --panel: rgba(255,255,255,0.06);
  --panel2: rgba(255,255,255,0.03);
  --border: rgba(255,255,255,0.12);

  --text:#e8efff;
  --muted: rgba(232,239,255,0.60);

  --blue:#6aa8ff;
  --purple:#7c3aed;

  --radius:18px;
  --radius-sm:12px;
  --shadow: 0 18px 55px rgba(0,0,0,.55);
}

*{ box-sizing:border-box; }

/* ===== Persian font (Vazir) ===== */
@font-face{
  font-family: "Vazir";
  src:
    url("/static/fonts/Vazir-Medium.woff2") format("woff2"),
    url("/static/fonts/Vazir-Medium.woff") format("woff");
  font-weight: normal;
  font-style: normal;
  font-display: swap;
}

html,body{
  height:100%;
  margin:0;
  background: var(--bg);
  color: var(--text);
  font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial;
}

/* background blobs */
.bg-blobs{
  position:fixed;
  inset:0;
  pointer-events:none;
  background:
    radial-gradient(900px 450px at 18% 0%, rgba(106,168,255,.20), transparent 62%),
    radial-gradient(900px 500px at 92% 0%, rgba(124,58,237,.22), transparent 60%),
    radial-gradient(700px 520px at 50% 92%, rgba(106,168,255,.10), transparent 70%);
}

.page{
  max-width: 1100px;
  margin: 54px auto 0;
  padding: 0 22px 40px;
  position: relative;
}

/* header */
.header{
  text-align:center;
  margin-bottom: 14px;
}
.title{
  font-size: 54px;
  font-weight: 800;
  letter-spacing: -1px;
  color: #aebcff;
  text-shadow: 0 10px 40px rgba(0,0,0,.55);
}
.subtitle{
  margin-top: 6px;
  font-size: 14px;
  color: rgba(232,239,255,0.75);
}

.rule{
  height:1px;
  width: 78%;
  margin: 18px auto 34px;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,.18), transparent);
}

/* cards */
.card{
  background: linear-gradient(180deg, var(--panel), var(--panel2));
  border: 1px solid var(--border);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  backdrop-filter: blur(14px);
}

.card-xl{
  width: 880px;
  margin: 0 auto 26px;
  padding: 22px;
}

.card-md{
  width: 880px;
  margin: 0 auto 18px;
  padding: 22px;
}

.form{ width: 100%; }

.field{
  padding: 10px;
  border-radius: var(--radius);
  background: rgba(0,0,0,0.10);
  border: 1px solid rgba(255,255,255,0.06);
}

.textarea{
  width:100%;
  min-height: 300px;
  resize: vertical;
  border-radius: var(--radius-sm);
  border: 1px solid rgba(255,255,255,0.10);
  background: rgba(0,0,0,0.28);
  color: var(--text);
  padding: 18px 18px;
  outline: none;
  font-size: 14px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono","Vazir", monospace;
  transition: border .18s, box-shadow .18s;
}
.textarea::placeholder{ color: rgba(232,239,255,0.28); }
.textarea:focus{
  border-color: rgba(106,168,255,0.55);
  box-shadow: 0 0 0 3px rgba(106,168,255,0.12);
}

/* bottom row */
.bottom-row{
  display:flex;
  align-items:center;
  justify-content:space-between;
  gap: 16px;
  padding: 14px 10px 0;
}

.expire{
  display:flex;
  flex-direction:column;
  gap: 8px;
}
.expire-label{
  display:flex;
  gap: 8px;
  align-items:center;
  font-size: 13px;
  color: rgba(232,239,255,0.75);
}

/* select + centered arrow */
.select{
  width: 120px;
  padding: 8px 10px;
  border-radius: 10px;
  border: 1px solid rgba(255,255,255,0.14);
  background-color: rgba(0,0,0,0.26);
  color: var(--text);
  outline:none;

  appearance:none;
  -webkit-appearance:none;
  -moz-appearance:none;

  background-image:
    linear-gradient(45deg, transparent 50%, #cbd5f5 50%),
    linear-gradient(135deg, #cbd5f5 50%, transparent 50%);
  background-position:
    calc(100% - 18px) 50%,
    calc(100% - 12px) 50%;
  background-size: 6px 6px;
  background-repeat: no-repeat;
  padding-right: 36px;
}
.select:focus{
  border-color: rgba(106,168,255,0.55);
}

/* dropdown options white + black text */
select option, select optgroup{
  background: #ffffff;
  color: #000000;
}

/* button */
.btn{
  padding: 12px 22px;
  border-radius: 12px;
  border: 0;
  color: #f4f2ff;
  font-weight: 800;
  cursor: pointer;
  background: linear-gradient(135deg, rgba(124,58,237,1), rgba(124,58,237,0.75));
  box-shadow: 0 14px 36px rgba(124,58,237,0.35);
  transition: transform .12s ease, box-shadow .12s ease, filter .12s ease;
}
.btn:hover{
  transform: translateY(-1px);
  box-shadow: 0 16px 44px rgba(124,58,237,0.50);
  filter: brightness(1.05);
}

.below-row{
  padding: 12px 10px 6px;
}

.link{
  color: var(--blue);
  text-decoration: none;
  font-weight: 600;
}
.link:hover{ text-decoration: underline; }

.footer{
  text-align:center;
  margin-top: 34px;
  color: rgba(232,239,255,0.28);
  font-size: 12px;
}
.footer-strong{
  color: rgba(232,239,255,0.55);
}

/* created page */
.center{ text-align:center; }

.check{
  width: 58px;
  height: 58px;
  border-radius: 999px;
  margin: 4px auto 12px;
  display:flex;
  align-items:center;
  justify-content:center;
  background: rgba(34,197,94,0.18);
  border: 1px solid rgba(34,197,94,0.35);
  color: #73ffb1;
  font-size: 30px;
}

.h1{ font-size: 22px; font-weight: 800; }
.muted{ color: var(--muted); margin-top: 6px; }

.section-title{
  font-weight: 800;
  color: rgba(200,190,255,0.85);
  margin-bottom: 12px;
}

.copybox{
  display:flex;
  align-items:center;
  gap: 10px;
  padding: 10px;
  border-radius: 12px;
  border: 1px solid rgba(255,255,255,0.14);
  background: rgba(0,0,0,0.24);
}

.copyinput{
  flex:1;
  border:0;
  outline:none;
  background: transparent;
  color: var(--text);
  font-family: ui-monospace, monospace;
  font-size: 14px;
}

.iconbtn{
  width: 44px;
  height: 40px;
  border-radius: 12px;
  border: 1px solid rgba(255,255,255,0.14);
  background: rgba(255,255,255,0.06);
  color: var(--text);
  cursor:pointer;
  transition: transform .12s ease, background .12s ease;
}
.iconbtn:hover{
  transform: scale(1.05);
  background: rgba(255,255,255,0.10);
}

.hint{
  margin-top: 10px;
  color: rgba(232,239,255,0.60);
  font-size: 13px;
}

.actions{
  display:flex;
  justify-content: space-between;
  margin-top: 14px;
}

.topbar{
  display:flex;
  align-items:center;
  justify-content: space-between;
}
.toplinks{
  display:flex;
  align-items:center;
  gap: 8px;
  color: rgba(232,239,255,0.55);
  font-size: 13px;
}
.dot{ opacity:.35; margin: 0 6px; }

.inline-form{ display:inline; }

.pre{
  margin-top: 12px;
  padding: 18px;
  border-radius: 12px;
  border: 1px solid rgba(255,255,255,0.12);
  background: rgba(0,0,0,0.30);
  overflow:auto;
  white-space: pre-wrap;
  word-break: break-word;
  font-family: ui-monospace, monospace;
  font-size: 14px;
}

/* error rtl */
.error{
  margin-top: 10px;
  color: #ffb4b4;
  padding: 10px 12px;
  border-radius: 12px;
  border: 1px solid rgba(255,180,180,0.25);
  background: rgba(255,180,180,0.08);

}

/* success */
.success{
  margin-bottom: 12px;
  padding: 10px 12px;
  border-radius: 12px;
  border: 1px solid rgba(125,255,178,0.28);
  background: rgba(125,255,178,0.10);
  color: #7dffb2;
  font-weight: 700;
}

/* ===== Delete button ===== */
.relative{ position: relative; }

.top-actions{
  position: absolute;
  top: 14px;
  right: 16px;
}

.delete-btn{
  background: rgba(239,68,68,0.12);
  border: 1px solid rgba(239,68,68,0.45);
  color: #ff9b9b;
  padding: 6px 14px;
  border-radius: 999px;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  transition: background .15s, transform .12s, box-shadow .12s;
}
.delete-btn:hover{
  background: rgba(239,68,68,0.22);
  transform: translateY(-1px);
  box-shadow: 0 6px 18px rgba(239,68,68,0.25);
}
.delete-btn.small{
  padding: 4px 10px;
  font-size: 12px;
}

/* responsive */
@media (max-width: 980px){
  .card-xl,.card-md{ width: 100%; }
  .rule{ width: 92%; }
  .title{ font-size: 44px; }
}


/* ===== 404 / Not Found ===== */

.notfound-card{
  direction: rtl;
  text-align: right;
  padding: 32px 26px;
}

.notfound-icon{
  font-size: 44px;
  margin-bottom: 12px;
  text-align: center;
  opacity: 0.9;
}

.notfound-title{
  text-align: center;
  margin-bottom: 6px;
}

.notfound-text{
  text-align: center;
  font-size: 14px;
  line-height: 1.9;
}

.notfound-actions{
  margin-top: 18px;
  text-align: center;
}

.notfound-link{
  font-size: 14px;
  font-weight: 700;
}

.success{
  animation: fadeIn .25s ease-out;
}

@keyframes fadeIn{
  from{
    opacity:0;
    transform: translateY(-6px);
  }
  to{
    opacity:1;
    transform: translateY(0);
  }
}


/* controls group (expires + password) */
.left-controls{
  display:flex;
  gap: 18px;
  align-items:flex-end;
  flex-wrap: wrap;
}

.pass{
  display:flex;
  flex-direction:column;
  gap: 8px;
}

.pass-input{
  width: 200px;
  padding: 8px 10px;
  border-radius: 10px;
  border: 1px solid rgba(255,255,255,0.14);
  background: rgba(0,0,0,0.26);
  color: var(--text);
  outline: none;
}
.pass-input::placeholder{
  color: rgba(232,239,255,0.35);
}
.pass-input:focus{
  border-color: rgba(106,168,255,0.55);
  box-shadow: 0 0 0 3px rgba(106,168,255,0.12);
}

.pass-input.wide{
  width: min(420px, 90%);
}

/* locked view */
.lockbox{
  margin-top: 14px;
  padding: 18px;
  border-radius: 14px;
  border: 1px solid rgba(255,255,255,0.12);
  background: rgba(0,0,0,0.18);
  text-align: center;
}
.lock-title{
  font-weight: 800;
  font-size: 16px;
  color: rgba(232,239,255,0.9);
}

.unlock-form{
  display:flex;
  gap: 12px;
  justify-content: center;
  align-items: center;
  flex-wrap: wrap;
  margin-top: 14px;
}

/* ===== Locked paste layout fix (addon) ===== */


.lock-hint{
  margin-top: 8px;
  color: rgba(232,239,255,0.65);
  font-size: 13px;
  text-align: center;
  line-height: 1.8;
}

/* stack input then button vertically */
.unlock-form-vertical{
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  margin-top: 14px;
}

.unlock-form-vertical .pass-input.wide{
  width: min(520px, 92%);
}

.unlock-form-vertical .btn{
  min-width: 140px;
}

/* ===== Fix password input size (locked view) ===== */

.unlock-form-vertical .pass-input.wide{
  width: 100%;
  max-width: 420px;
  height: 44px;

  padding: 0 14px;
  font-size: 14px;
  line-height: 44px;

  border-radius: 12px;
  box-sizing: border-box;
}
