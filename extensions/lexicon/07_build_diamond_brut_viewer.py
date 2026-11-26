"""
07_build_diamond_brut_viewer.py
Génère la visualisation 3D interactive du « Diamant Brut du Cartograffect » (303 positions : Z+ et Z-) :
- Hémisphère inférieur (Affects, Z in [0..+6], dégradé rouge/ambre) : de la Veille (0,0,0) vers la Suspension
- Plan médian équatorial (Suspension, Z = +7, R_L1 = 12, anneau d'or blanc) : 49 positions
- Hémisphère supérieur (Valeurs/Forces/Engagements, Z- in [-6..-1, -7], dégradé émeraude/cyan/bleu/violet) :
  de Discernement (Z=-6, R_L1=10) jusqu'à l'Éveil (Z=-7, R_L1=0)
"""

import json
import pandas as pd


def build_nodes_ultra_compact():
    df = pd.read_csv("ref_303_diamant_z.tsv", sep="\t", encoding="utf-8")
    rows = []
    for r in df.itertuples():
        rows.append([
            int(r.id_303),
            str(r.label_fr),
            int(r.X),
            int(r.Y),
            int(r.Z_signe),
            int(r.h_diamant_3d),
            str(r.type_geom),
            str(r.groupe_geom),
            int(r.correspondant_id_303),
            int(r.homologue_id_303),
            str(r.deficit_D_moins),
            str(r.exces_D_plus),
            str(r.famille_thematique),
        ])
    return rows


INLINE_TEMPLATE = """<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8" />
  <script src="https://www.gstatic.com/antigravity/web/dev/tailwindcss.min.js"></script>
</head>
<body class="bg-transparent text-[var(--foreground)] antialiased p-2 select-none">
  <div class="bg-[var(--card)] border border-[var(--border)] rounded-xl p-3 shadow-sm flex flex-col gap-2.5">
    <div class="flex flex-wrap items-center justify-between gap-2 border-b border-[var(--border)] pb-2">
      <div class="flex items-center gap-2">
        <span class="px-2 py-0.5 rounded-full text-xs font-semibold bg-[var(--primary)] text-[var(--primary-foreground)]">Diamant Brut 303</span>
        <h2 class="text-sm font-bold text-[var(--foreground)]">CARTOGRAFFECT — Double Pyramide L1 (Z⁺ Affects ↔ Z⁻ Valeurs)</h2>
      </div>
      <div class="flex items-center gap-2 text-xs">
        <select id="stratumSel" class="bg-[var(--content)] text-[var(--foreground)] border border-[var(--border)] rounded-lg px-2 py-1 text-xs focus:outline-none">
          <option value="ALL">Tout le Diamant (303 pôles • h = -7 à +7)</option>
          <option value="Z_MINUS">Hémisphère Axiologique Z⁻ (-7 à -1 • 127 valeurs)</option>
          <option value="EQ">Équateur Suspension Z = +7 (49 pôles • R=12)</option>
          <option value="Z_PLUS">Hémisphère Affectif Z⁺ (0 à +6 • 127 affects)</option>
          <option value="PAIR_6">|Z| = 6 : Z=+6 Identités ↔ Z=-6 Valeurs (R=10)</option>
          <option value="PAIR_5">|Z| = 5 : Z=+5 Dispositions ↔ Z=-5 Forces (R=8)</option>
          <option value="PAIR_4">|Z| = 4 : Z=+4 Sentiments ↔ Z=-4 Engagements (R=6)</option>
          <option value="PAIR_3">|Z| = 3 : Z=+3 Émotions ↔ Z=-3 Intégration (R=4)</option>
          <option value="PAIR_2">|Z| = 2 : Z=+2 Primaires ↔ Z=-2 Cardinales (R=2)</option>
        </select>
        <input id="qInput" type="text" placeholder="Chercher (ex: Juste, Tourment, Éveil...)"
          class="bg-[var(--content)] text-[var(--foreground)] border border-[var(--border)] rounded-lg px-2 py-1 text-xs w-44 focus:outline-none" />
      </div>
    </div>

    <div class="grid grid-cols-12 gap-3 items-stretch">
      <div class="col-span-7 relative rounded-lg overflow-hidden border border-[var(--border)] bg-[var(--content)] h-[365px]">
        <canvas id="diamCanvas" class="w-full h-full block cursor-grab active:cursor-grabbing"></canvas>
        <div class="absolute top-2 left-2.5 pointer-events-none flex flex-col gap-0.5 text-xs">
          <span class="font-semibold text-violet-400">▲ Sommet Z = -7 : ÉVEIL (Valeurs Z⁻)</span>
          <span class="font-semibold text-amber-300">◆ Équateur Z = +7 : SUSPENSION (R=12)</span>
          <span class="font-semibold text-rose-400">▼ Sommet Z = 0 : VEILLE (Affects Z⁺)</span>
        </div>
        <div class="absolute bottom-2 left-2.5 right-2.5 flex items-center justify-between text-xs">
          <label class="inline-flex items-center gap-1.5 bg-[var(--card)]/85 backdrop-blur px-2 py-0.5 rounded border border-[var(--border)] cursor-pointer">
            <input id="showHomolLine" type="checkbox" checked class="rounded" />
            <span>Pilier d'homologie (+Z ↔ -Z)</span>
          </label>
          <button id="resetBtn" class="bg-[var(--card)]/85 backdrop-blur px-2 py-0.5 rounded border border-[var(--border)] hover:opacity-80">
            Réinitialiser vue
          </button>
        </div>
      </div>

      <div class="col-span-5 bg-[var(--content)] border border-[var(--border)] rounded-lg p-3 flex flex-col justify-between h-[365px] text-xs">
        <div>
          <div class="flex items-center justify-between gap-1">
            <span id="nBadge" class="px-2 py-0.5 rounded font-mono bg-[var(--card)] border border-[var(--border)]"></span>
            <span id="nGrp" class="px-2 py-0.5 rounded-full font-semibold"></span>
          </div>
          <h3 id="nTitle" class="text-base font-bold text-[var(--foreground)] mt-1"></h3>
          <p id="nCoords" class="font-mono text-[var(--muted-foreground)] mt-0.5"></p>
        </div>

        <div class="bg-[var(--card)] border border-[var(--border)] rounded-lg p-2.5 space-y-1">
          <div class="text-[var(--muted-foreground)] font-medium">Homologue vertical (X, Y identiques • Z⁺ ↔ Z⁻) :</div>
          <div class="flex items-center justify-between">
            <button id="homBtn" class="font-bold underline text-left hover:opacity-80 text-[var(--foreground)]"></button>
            <span id="homCoords" class="font-mono text-[var(--muted-foreground)]"></span>
          </div>
        </div>

        <div class="bg-[var(--card)] border border-[var(--border)] rounded-lg p-2.5 space-y-1">
          <div id="corrHeader" class="text-[var(--muted-foreground)] font-medium">Correspondant intra-couronne (même Z) :</div>
          <div class="flex items-center justify-between">
            <button id="corrBtn" class="font-bold underline text-left hover:opacity-80 text-[var(--foreground)]"></button>
            <span id="corrCoords" class="font-mono text-[var(--muted-foreground)]"></span>
          </div>
          <div id="symRule" class="text-[var(--muted-foreground)] font-mono"></div>
        </div>

        <div id="triadBox" class="bg-[var(--card)] border border-[var(--border)] rounded-lg p-2.5 space-y-1">
          <div class="text-[var(--muted-foreground)] font-medium">Équilibre axiologique (D⁻ ← V → D⁺) :</div>
          <div id="triadContent" class="font-semibold text-[var(--foreground)]"></div>
        </div>
      </div>
    </div>
  </div>

  <script>
    const RAW = __NODES_JSON__;
    const NODES = RAW.map(r => {
      const z = r[4], h3d = r[5];
      const w = z < 0 ? (z === -7 ? 7 : 7 + z) : (z === 7 ? 0 : null);
      return {
        id: r[0], lbl: r[1], x: r[2], y: r[3], z, w, h3d,
        r: Math.abs(r[2]) + Math.abs(r[3]),
        type: r[6], grp: r[7], corr_id: r[8], hom_id: r[9],
        d_min: r[10], d_max: r[11], fam_th: r[12]
      };
    });
    const nodeById = {};
    NODES.forEach(n => { nodeById[n.id] = n; });

    const H3D_COLORS = {
      "-7": "#ef4444", "-6": "#dc2626", "-5": "#b91c1c", "-4": "#c2410c",
      "-3": "#d97706", "-2": "#ea580c", "-1": "#f59e0b", "0": "#fde047",
      "1": "#10b981", "2": "#06b6d4", "3": "#0ea5e9", "4": "#3b82f6",
      "5": "#6366f1", "6": "#8b5cf6", "7": "#f59e0b"
    };

    let rotYaw = -0.65, rotPitch = 0.22, zoom = 1.02;
    let selectedId = 300;
    let hoveredId = null;
    let activeIds = new Set(NODES.map(n => n.id));

    const canvas = document.getElementById("diamCanvas");
    const ctx = canvas.getContext("2d");

    function resize() {
      const rect = canvas.parentElement.getBoundingClientRect();
      const dpr = window.devicePixelRatio || 1;
      canvas.width = rect.width * dpr;
      canvas.height = rect.height * dpr;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      draw();
    }
    window.addEventListener("resize", resize);

    function project([x, y, h3d], w, h) {
      const zWorld = h3d * 1.45;
      const cosY = Math.cos(rotYaw), sinY = Math.sin(rotYaw);
      const cosP = Math.cos(rotPitch), sinP = Math.sin(rotPitch);
      const x1 = x * cosY - y * sinY;
      const y1 = x * sinY + y * cosY;
      const z2 = zWorld * cosP - y1 * sinP;
      const depth = zWorld * sinP + y1 * cosP;
      const scale = (Math.min(w, h) * 0.029 * zoom) * (45 / (45 - depth * 0.42));
      return { sx: w * 0.5 + x1 * scale, sy: h * 0.5 - z2 * scale, depth };
    }

    let projList = [];

    function draw() {
      const rect = canvas.parentElement.getBoundingClientRect();
      const w = rect.width, h = rect.height;
      ctx.clearRect(0, 0, w, h);

      const isLight = document.documentElement.classList.contains("light");
      const textFill = isLight ? "#0f172a" : "#f8fafc";
      const wireAlpha = isLight ? 0.35 : 0.28;

      const pTop = project([0, 0, 7], w, h), pBot = project([0, 0, -7], w, h);
      ctx.strokeStyle = isLight ? "rgba(71,85,105,0.45)" : "rgba(226,232,240,0.35)";
      ctx.lineWidth = 1.3;
      ctx.beginPath(); ctx.moveTo(pBot.sx, pBot.sy); ctx.lineTo(pTop.sx, pTop.sy); ctx.stroke();

      [[[-13.5, 0, 0], [13.5, 0, 0]], [[0, -13.5, 0], [0, 13.5, 0]]].forEach(([a, b]) => {
        const pa = project(a, w, h), pb = project(b, w, h);
        ctx.beginPath(); ctx.moveTo(pa.sx, pa.sy); ctx.lineTo(pb.sx, pb.sy); ctx.stroke();
      });

      for (let h3d = -5; h3d <= 5; h3d++) {
        const r = 12 - 2 * Math.abs(h3d);
        ctx.strokeStyle = H3D_COLORS[String(h3d)] || "#94a3b8";
        ctx.globalAlpha = h3d === 0 ? 0.85 : wireAlpha;
        ctx.lineWidth = h3d === 0 ? 2.0 : 1.1;
        const corners = [[r, 0, h3d], [0, r, h3d], [-r, 0, h3d], [0, -r, h3d], [r, 0, h3d]];
        ctx.beginPath();
        corners.forEach((pt, idx) => {
          const pr = project(pt, w, h);
          if (idx === 0) ctx.moveTo(pr.sx, pr.sy); else ctx.lineTo(pr.sx, pr.sy);
        });
        ctx.stroke();
      }

      ctx.strokeStyle = isLight ? "rgba(100,116,139,0.30)" : "rgba(148,163,184,0.25)";
      ctx.lineWidth = 1.0;
      [[12, 0], [-12, 0], [0, 12], [0, -12], [6, 6], [-6, -6], [-6, 6], [6, -6]].forEach(([cx, cy], idx) => {
        ctx.globalAlpha = idx < 4 ? 0.45 : 0.22;
        const pLow = project([0, 0, -6], w, h), pMid = project([cx, cy, 0], w, h), pHigh = project([0, 0, 6], w, h);
        ctx.beginPath(); ctx.moveTo(pLow.sx, pLow.sy); ctx.lineTo(pMid.sx, pMid.sy); ctx.lineTo(pHigh.sx, pHigh.sy); ctx.stroke();
      });
      ctx.globalAlpha = 1.0;

      const sel = nodeById[selectedId];
      if (sel && sel.corr_id && sel.corr_id !== sel.id) {
        const corr = nodeById[sel.corr_id];
        if (corr) {
          const pA = project([sel.x, sel.y, sel.h3d], w, h), pB = project([corr.x, corr.y, corr.h3d], w, h);
          ctx.save(); ctx.setLineDash([4, 3]); ctx.strokeStyle = textFill; ctx.lineWidth = 1.6;
          ctx.beginPath(); ctx.moveTo(pA.sx, pA.sy); ctx.lineTo(pB.sx, pB.sy); ctx.stroke(); ctx.restore();
        }
      }

      if (document.getElementById("showHomolLine").checked && sel && sel.hom_id && sel.hom_id !== sel.id) {
        const hom = nodeById[sel.hom_id];
        if (hom) {
          const pA = project([sel.x, sel.y, sel.h3d], w, h), pB = project([hom.x, hom.y, hom.h3d], w, h);
          ctx.save(); ctx.strokeStyle = "#38bdf8"; ctx.lineWidth = 2.2;
          ctx.beginPath(); ctx.moveTo(pA.sx, pA.sy); ctx.lineTo(pB.sx, pB.sy); ctx.stroke(); ctx.restore();
        }
      }

      projList = NODES.map(n => ({ n, ...project([n.x, n.y, n.h3d], w, h) })).sort((a, b) => a.depth - b.depth);
      projList.forEach(item => {
        const { n, sx, sy } = item;
        const isVis = activeIds.has(n.id);
        const isSel = n.id === selectedId;
        const isHom = sel && sel.hom_id === n.id && n.id !== selectedId;
        const isCorr = sel && sel.corr_id === n.id && n.id !== selectedId;
        const isHov = n.id === hoveredId;

        const baseR = n.r === 0 ? 5.2 : (n.type === "Axiale" || n.type === "Diagonale" ? 4.2 : 3.3);
        const rad = isSel ? baseR + 3.5 : (isHom || isCorr || isHov ? baseR + 2.2 : baseR);

        ctx.globalAlpha = isVis ? 1.0 : 0.10;
        ctx.fillStyle = H3D_COLORS[String(n.h3d)] || "#94a3b8";
        ctx.beginPath(); ctx.arc(sx, sy, rad, 0, Math.PI * 2); ctx.fill();

        if (isSel || isHom || isCorr || isHov || n.r === 0) {
          ctx.lineWidth = isSel ? 2.4 : 1.4;
          ctx.strokeStyle = isHom ? "#38bdf8" : textFill;
          ctx.stroke();
        }

        if (isSel || isHom || isCorr || isHov || (isVis && activeIds.size <= 34)) {
          ctx.font = (isSel || isHom) ? "bold 12px sans-serif" : "12px sans-serif";
          ctx.fillStyle = textFill;
          const zTag = n.z > 0 ? `+${n.z}` : `${n.z}`;
          ctx.fillText(`${n.lbl} (Z=${zTag})`, sx + rad + 4, sy + 4);
        }
      });
      ctx.globalAlpha = 1.0;
    }

    function updateInspector() {
      const n = nodeById[selectedId];
      if (!n) return;
      const zTag = n.z > 0 ? `+${n.z}` : `${n.z}`;
      const wInfo = n.w !== null ? ` • W=${n.w}` : "";
      document.getElementById("nBadge").textContent = `#${n.id} • Z=${zTag}${wInfo} • ${n.type}`;

      const grpEl = document.getElementById("nGrp");
      grpEl.textContent = n.grp;
      const col = H3D_COLORS[String(n.h3d)] || "#3b82f6";
      grpEl.style.backgroundColor = col + "28";
      grpEl.style.color = col;

      document.getElementById("nTitle").textContent = n.lbl;
      const xStr = n.x >= 0 ? `+${n.x}` : `${n.x}`, yStr = n.y >= 0 ? `+${n.y}` : `${n.y}`;
      document.getElementById("nCoords").textContent =
        `(X=${xStr}, Y=${yStr}, Z=${zTag}) • R_L1=${n.r} • h_3D=${n.h3d >= 0 ? "+" + n.h3d : n.h3d}`;

      const hom = nodeById[n.hom_id];
      const homBtn = document.getElementById("homBtn"), homCoords = document.getElementById("homCoords");
      if (hom && hom.id !== n.id) {
        const hzTag = hom.z > 0 ? `+${hom.z}` : `${hom.z}`;
        homBtn.textContent = `${hom.lbl} (#${hom.id})`;
        homCoords.textContent = `(X=${xStr}, Y=${yStr}, Z=${hzTag})`;
        homBtn.onclick = () => { selectedId = hom.id; updateInspector(); draw(); };
      } else {
        homBtn.textContent = `${n.lbl} (Équateur auto-dual Z=+7)`;
        homCoords.textContent = `h_3D = 0`;
        homBtn.onclick = null;
      }

      const corr = nodeById[n.corr_id];
      const corrBtn = document.getElementById("corrBtn"), corrCoords = document.getElementById("corrCoords");
      document.getElementById("corrHeader").textContent =
        n.z < 0 ? "Contrepoids axiologique (même Z⁻) :" : "Antagoniste affectif (même Z⁺) :";
      if (corr) {
        const cxStr = corr.x >= 0 ? `+${corr.x}` : `${corr.x}`, cyStr = corr.y >= 0 ? `+${corr.y}` : `${corr.y}`;
        corrBtn.textContent = `${corr.lbl} (#${corr.id})`;
        corrCoords.textContent = `(X*=${cxStr}, Y*=${cyStr}, Z=${zTag})`;
        corrBtn.onclick = () => { selectedId = corr.id; updateInspector(); draw(); };
      }

      const symRule = document.getElementById("symRule");
      if (n.r === 0) symRule.textContent = "Opérateur central sur l'axe (0, 0, Z) [XY = 0]";
      else if (n.type === "Axiale") symRule.textContent = "Inversion centrale axiale (-X, -Y, Z) [XY = 0]";
      else if (n.type === "Diagonale") symRule.textContent = "Inversion centrale diagonale (-X, -Y, Z) [XY ≠ 0, |X| = |Y|]";
      else symRule.textContent = "Involution controlatérale (-sgn(X)|Y|, -sgn(Y)|X|, Z) [XY ≠ 0]";

      const triadContent = document.getElementById("triadContent");
      if (n.d_min !== "-") {
        triadContent.innerHTML = `<span class="text-rose-400">${n.d_min} (D⁻)</span> ← <span class="text-emerald-400 font-bold">${n.lbl} (V)</span> → <span class="text-amber-400">${n.d_max} (D⁺)</span> <span class="text-[var(--muted-foreground)] font-normal">• Famille : ${n.fam_th}</span>`;
      } else if (n.z < 0 && hom) {
        triadContent.textContent = `Strate Z=${zTag} (W=${n.w}) — Orientation choisie issue de la transmutation de « ${hom.lbl} » (Z=+${Math.abs(n.z === -7 ? 0 : n.z)}).`;
      } else if (n.z === 7) {
        triadContent.textContent = `Plan médian de la Suspension (Z=+7 ≡ W=0) : équateur du Diamant entre l'éprouvé et le choisi.`;
      } else if (hom) {
        triadContent.textContent = `Affect de strate Z=+${n.z} — Se transmute en « ${hom.lbl} » (Z=${hom.z}) dans l'hémisphère axiologique.`;
      }
    }

    function applyFilter() {
      const mode = document.getElementById("stratumSel").value;
      const q = document.getElementById("qInput").value.trim().toLowerCase();
      activeIds.clear();
      let firstMatch = null;

      NODES.forEach(n => {
        let keep = true;
        if (mode === "Z_MINUS") keep = n.z < 0;
        else if (mode === "EQ") keep = n.z === 7;
        else if (mode === "Z_PLUS") keep = n.z >= 0 && n.z < 7;
        else if (mode.startsWith("PAIR_")) {
          const k = parseInt(mode.split("_")[1], 10);
          keep = Math.abs(n.z) === k;
        }
        if (!keep) return;

        if (q) {
          const hom = nodeById[n.hom_id], corr = nodeById[n.corr_id];
          const hay = `${n.lbl} ${hom ? hom.lbl : ""} ${corr ? corr.lbl : ""} ${n.d_min} ${n.d_max} ${n.grp}`.toLowerCase();
          if (!hay.includes(q)) return;
          if (n.lbl.toLowerCase().includes(q) && firstMatch === null) firstMatch = n.id;
        }
        activeIds.add(n.id);
        if (firstMatch === null) firstMatch = n.id;
      });

      if (q && firstMatch !== null) selectedId = firstMatch;
      updateInspector();
      draw();
    }

    let dragging = false, sx0 = 0, sy0 = 0, moved = false;
    canvas.addEventListener("mousedown", e => { dragging = true; moved = false; sx0 = e.clientX; sy0 = e.clientY; });
    window.addEventListener("mousemove", e => {
      const rect = canvas.getBoundingClientRect();
      if (dragging) {
        const dx = e.clientX - sx0, dy = e.clientY - sy0;
        if (Math.abs(dx) + Math.abs(dy) > 3) moved = true;
        rotYaw += dx * 0.008;
        rotPitch = Math.max(-1.4, Math.min(1.4, rotPitch + dy * 0.008));
        sx0 = e.clientX; sy0 = e.clientY;
        draw();
        return;
      }
      if (e.target === canvas) {
        const mx = e.clientX - rect.left, my = e.clientY - rect.top;
        let f = null;
        for (let i = projList.length - 1; i >= 0; i--) {
          const it = projList[i];
          if (!activeIds.has(it.n.id)) continue;
          if (Math.hypot(mx - it.sx, my - it.sy) <= 9) { f = it.n.id; break; }
        }
        if (f !== hoveredId) { hoveredId = f; draw(); }
      }
    });
    window.addEventListener("mouseup", e => {
      if (dragging && !moved && e.target === canvas && hoveredId !== null) {
        selectedId = hoveredId; updateInspector(); draw();
      }
      dragging = false;
    });
    canvas.addEventListener("wheel", e => {
      e.preventDefault();
      zoom = Math.max(0.5, Math.min(2.4, zoom * (e.deltaY < 0 ? 1.08 : 0.92)));
      draw();
    }, { passive: false });

    document.getElementById("stratumSel").addEventListener("change", applyFilter);
    document.getElementById("qInput").addEventListener("input", applyFilter);
    document.getElementById("showHomolLine").addEventListener("change", draw);
    document.getElementById("resetBtn").addEventListener("click", () => {
      rotYaw = -0.65; rotPitch = 0.22; zoom = 1.02; draw();
    });

    updateInspector();
    setTimeout(resize, 20);
  </script>
</body>
</html>
"""


def main():
    nodes = build_nodes_ultra_compact()
    html_out = INLINE_TEMPLATE.replace("__NODES_JSON__", json.dumps(nodes, ensure_ascii=False, separators=(",", ":")))
    with open("CARTOGRAFFECT_Diamond_303_Brut.html", "w", encoding="utf-8") as f:
        f.write(html_out)
    print(f"Généré CARTOGRAFFECT_Diamond_303_Brut.html ({len(html_out)} octets, {len(nodes)} pôles)")


if __name__ == "__main__":
    main()
