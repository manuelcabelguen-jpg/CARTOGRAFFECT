"""
09_build_diamond_complete_viewer.py
================================================================================
Génère le visualiseur 3D interactif complet du Diamant Taillé sur Mesure
du Cartograffect (303 positions et 2 780 unigrammes NRC-VAD / DIMA / FANCat),
intégrant :
  1. La Rose Complète des 8 Symétries Géométriques (Axiale, Diagonale,
     Controlatérale Directe Td(Y,X), Controlatérale Inversée Ti(-Y,-X),
     Opposé Central Intra-Dominante (-X,-Y), Miroir de Dominante,
     Opposés Latéraux Orthogonaux Ox/Oy, Homologue Vertical +Z <-> -Z,
     Contrepoids Croisé Trans-Hémisphérique et Filière Inter-Couches ΔZ).
  2. Le Moteur Prédictif & la Matrice de l'Interface Attentionnelle
     (9 Couplages (A,C), 3 Interfaces C/A/P, 4 Opérations Inférentielles,
     6 Régimes Énergétiques, Polarité Lexicographique, 17 Sous-Secteurs,
     Potentiel de Lyapunov V_L).
  3. Les Clusters Lexicaux Harmonieusement Équilibrés (2 780 unigrammes).

Sorties :
  - CARTOGRAFFECT_Diamond_303_Complet.html
  - Artifact utilisateur dans <appDataDir>/brain/<conversation_id>/diamond_303_complet.html
================================================================================
"""

import json
import os
import pandas as pd

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
HTML_OUT = os.path.join(SCRIPT_DIR, "CARTOGRAFFECT_Diamond_303_Complet.html")
ARTIFACT_DIR = os.path.join(SCRIPT_DIR, "output_diamond_303")
ARTIFACT_OUT = os.path.join(ARTIFACT_DIR, "diamond_303_complet.html")


def safe_str(val):
    if pd.isna(val):
        return "-"
    return str(val)


def build_viewer():
    os.chdir(SCRIPT_DIR)
    os.makedirs(ARTIFACT_DIR, exist_ok=True)
    print("=" * 78)
    print(" GÉNÉRATION DU VISUALISEUR 3D DU DIAMANT TAILLÉ SUR MESURE (303 PÔLES)")
    print("=" * 78)

    df_lex = pd.read_csv("CARTOGRAFFECT_Diamant_303_Lexique_Complet.tsv", sep="\t")
    df_stats = pd.read_csv("CARTOGRAFFECT_Diamant_303_Stats_Synthese.tsv", sep="\t")

    words_by_pole = {}
    seen_terms_in_diamond = set()
    for r in df_lex.itertuples():
        pid = int(r.id_303_ancre)
        t_str = str(r.terme_fr).strip()
        seen_terms_in_diamond.add(t_str.lower())
        if pid not in words_by_pole:
            words_by_pole[pid] = []
        words_by_pole[pid].append([
            t_str,
            round(float(r.valence), 2),
            round(float(r.arousal), 2),
            round(float(r.dominance), 2),
            str(r.source_lexicale) + "+CNRS/Lexique/GLAWI",
            safe_str(getattr(r, "triade_statut_z_minus", "-")),
            str(r.categorie_semantique),
            round(float(getattr(r, "score_calcul_semantique", 0.0)), 3),
        ])

    # Intégration des nouvelles entrées Open-Data CNRS / Lexique 3.83 / GLAWI (Strates 1 à 6)
    homologue_by_176 = {}
    for p in df_stats.itertuples():
        pid = int(p.id_303)
        if pid <= 176 and int(p.homologue_id_303) > 176:
            homologue_by_176[pid] = int(p.homologue_id_303)

    open_3d_path = "CARTOGRAFFECT_OpenData_CNRS_Lexique_GLAWI_3D.tsv"
    if os.path.exists(open_3d_path):
        df_open = pd.read_csv(open_3d_path, sep="\t", encoding="utf-8")
        # Ajoute tous les termes de nomenclature ouverte française (DIMA/CNRS/GLAWI/Lexique) non encore présents
        df_open_ext = df_open[df_open["source_nomenclature"].isin([
            "LEXIQUE383_MORPHALOU_OPEN_FR",
            "DIMA_AXIOLOGIE_OUVERTE_FR",
        ])]
        for r in df_open_ext.itertuples():
            t_str = str(r.lemme_fr).strip()
            if t_str.lower() in seen_terms_in_diamond:
                continue
            seen_terms_in_diamond.add(t_str.lower())
            base_176 = int(r.id176)
            # Strates 4, 5, 6 (Éthique, Axiologique, Politique) projetées sur l'hémisphère axiologique Z_MINUS si homologue disponible
            if int(r.stratum_rank) >= 4 and base_176 in homologue_by_176:
                target_pid = homologue_by_176[base_176]
                triade_st = "VALEUR_CENTRALE" if float(r.valence) >= 0 else "DERIVE_EXCES"
            else:
                target_pid = base_176
                triade_st = f"S{int(r.stratum_rank)}_{r.pos_cnrs_lexique}"
            if target_pid not in words_by_pole:
                words_by_pole[target_pid] = []
            words_by_pole[target_pid].append([
                t_str,
                round(float(r.valence), 2),
                round(float(r.arousal_energy), 2),
                round(float(r.coping_power), 2),
                str(r.open_data_badge),
                triade_st,
                f"S{int(r.stratum_rank)} • {r.glawi_domaine_cnrs} ({r.domaine_semantique})",
                round(float(r.Ratio_Z) / 2.75, 3),
            ])

    # Ordonnancement qualitatif des mots par pôle :
    # Pour les 40 triades de Z=-6, placer en tête les VALEURS CENTRALES, puis les DÉFAUTS D-, puis les EXCÈS D+
    for pid in words_by_pole:
        p_row = df_stats[df_stats["id_303"] == pid]
        is_triad = len(p_row) > 0 and int(p_row.iloc[0]["Z_signe"]) == -6
        if is_triad:
            def sort_key_word(item):
                st = item[5]
                if st == "VALEUR_CENTRALE":
                    return (0, -float(item[7]))
                elif st == "DERIVE_DEFAUT":
                    return (1, -float(item[7]))
                elif st == "DERIVE_EXCES":
                    return (2, -float(item[7]))
                return (3, -float(item[7]))
            words_by_pole[pid].sort(key=sort_key_word)
        else:
            words_by_pole[pid].sort(key=lambda item: -float(item[7]))

    poles_data = []
    for p in df_stats.itertuples():
        pid = int(p.id_303)
        poles_data.append({
            "id": pid,
            "lbl": str(p.label_fr),
            "hemi": str(p.hemisphere),
            "x": int(p.X),
            "y": int(p.Y),
            "z": int(p.Z_signe),
            "h": int(p.h_diamant_3d),
            "r": int(p.rayon_L1),
            "type": str(p.type_geom),
            "grp": str(p.groupe_geom),
            "n": int(p.effectif_termes),
            "v_mean": round(float(p.valence_moyenne), 2),
            "a_mean": round(float(p.arousal_moyen), 2),
            "d_mean": round(float(p.dominance_moyenne), 2),
            "score_sem": round(float(getattr(p, "score_semantique_moyen", 0.0)), 3),
            # Rose des 8 symétries
            "c_lbl": safe_str(p.contrepoids_label),
            "c_id": int(p.contrepoids_id_303),
            "c_type": safe_str(getattr(p, "type_antagonisme", "-")),
            "ic_lbl": safe_str(getattr(p, "oppose_central_label", "-")),
            "ic_id": int(getattr(p, "oppose_central_id_303", -1)),
            "md_lbl": safe_str(getattr(p, "miroir_dominant_label", "-")),
            "md_id": int(getattr(p, "miroir_dominant_id_303", -1)),
            "ox_lbl": safe_str(getattr(p, "oppose_lateral_X_label", "-")),
            "ox_id": int(getattr(p, "oppose_lateral_X_id_303", -1)),
            "oy_lbl": safe_str(getattr(p, "oppose_lateral_Y_label", "-")),
            "oy_id": int(getattr(p, "oppose_lateral_Y_id_303", -1)),
            "h_lbl": safe_str(p.homologue_label),
            "h_id": int(p.homologue_id_303),
            "h_z": int(p.homologue_Z_signe),
            "az_lbl": safe_str(getattr(p, "contrepoids_croise_label", "-")),
            "az_id": int(getattr(p, "contrepoids_croise_id_303", -1)),
            "trans_loi": safe_str(getattr(p, "loi_transmutation_verticale", "-")),
            "fz_in_lbl": safe_str(getattr(p, "filiere_inf_label", "-")),
            "fz_in_id": int(getattr(p, "filiere_inf_id_303", -1)),
            "fz_out_lbl": safe_str(getattr(p, "filiere_sup_label", "-")),
            "fz_out_id": int(getattr(p, "filiere_sup_id_303", -1)),
            # Triades Z=-6
            "def": safe_str(p.deficit_D_moins),
            "exc": safe_str(p.exces_D_plus),
            "fam": safe_str(p.famille_thematique),
            # Moteur prédictif & Matrice attentionnelle
            "ac": safe_str(getattr(p, "moteur_couplage_AC", "-")),
            "if_dom": safe_str(getattr(p, "moteur_interface_dominante", "-")),
            "op_inf": safe_str(getattr(p, "moteur_operation_inferentielle", "-")),
            "st_nom": safe_str(getattr(p, "couche_z_nom", "-")),
            "st_obj": safe_str(getattr(p, "couche_z_objet_inference", "-")),
            "st_role": safe_str(getattr(p, "strate_role_fonctionnel", "-")),
            "reg_en": safe_str(getattr(p, "matrice_regime_energetique", "-")),
            "pol_lex": safe_str(getattr(p, "matrice_polarite_hedonique", "-")),
            "prof_act": safe_str(getattr(p, "matrice_activation", "-")),
            "ssect17": safe_str(getattr(p, "taxonomie_sous_secteur_17", "-")),
            "lyap": int(getattr(p, "noyau_potentiel_lyapunov", 0)),
            "w": words_by_pole.get(pid, []),
        })

    json_data = json.dumps(poles_data, ensure_ascii=False)

    html_content = f"""<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>Diamant Taillé sur Mesure du Cartograffect — 303 Pôles, Rose des 8 Symétries & Moteur Prédictif</title>
<style>
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  body {{
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    background: #090c10;
    color: #e6edf3;
    overflow: hidden;
    height: 100vh;
    width: 100vw;
  }}
  #canvas-container {{
    position: absolute;
    top: 0; left: 0; right: 0; bottom: 0;
    z-index: 1;
  }}
  #top-bar {{
    position: absolute;
    top: 10px; left: 14px; right: 14px;
    z-index: 10;
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    align-items: center;
    background: rgba(13, 17, 23, 0.92);
    backdrop-filter: blur(12px);
    border: 1px solid #30363d;
    border-radius: 12px;
    padding: 8px 14px;
    box-shadow: 0 4px 20px rgba(0,0,0,0.6);
  }}
  .title-group h1 {{
    font-size: 14px;
    font-weight: 700;
    letter-spacing: 0.4px;
    color: #58a6ff;
  }}
  .title-group p {{
    font-size: 10.5px;
    color: #8b949e;
  }}
  .controls-group {{
    display: flex;
    flex-wrap: wrap;
    gap: 5px;
    align-items: center;
    margin-left: auto;
  }}
  .btn {{
    background: #21262d;
    color: #c9d1d9;
    border: 1px solid #30363d;
    border-radius: 6px;
    padding: 4px 9px;
    font-size: 11px;
    cursor: pointer;
    transition: all 0.15s ease;
  }}
  .btn:hover {{
    background: #30363d;
    border-color: #8b949e;
  }}
  .btn.active {{
    background: #1f6feb;
    color: #ffffff;
    border-color: #58a6ff;
  }}
  select.filter-select {{
    background: #0d1117;
    color: #e6edf3;
    border: 1px solid #30363d;
    border-radius: 6px;
    padding: 4px 7px;
    font-size: 11px;
    cursor: pointer;
  }}
  select.filter-select:focus {{
    outline: none;
    border-color: #58a6ff;
  }}
  .search-box {{
    position: relative;
    width: 190px;
  }}
  .search-box input {{
    width: 100%;
    background: #0d1117;
    border: 1px solid #30363d;
    color: #e6edf3;
    padding: 4px 9px;
    border-radius: 6px;
    font-size: 11px;
  }}
  .search-box input:focus {{
    outline: none;
    border-color: #58a6ff;
  }}
  #drawer {{
    position: absolute;
    top: 72px; right: 14px; bottom: 14px;
    width: 430px;
    z-index: 10;
    background: rgba(13, 17, 23, 0.95);
    backdrop-filter: blur(14px);
    border: 1px solid #30363d;
    border-radius: 12px;
    display: flex;
    flex-direction: column;
    padding: 14px;
    box-shadow: -4px 0 24px rgba(0,0,0,0.65);
    overflow: hidden;
  }}
  #drawer h2 {{
    font-size: 16px;
    font-weight: 700;
    color: #f0f6fc;
    display: flex;
    align-items: center;
    justify-content: space-between;
  }}
  .badge {{
    font-size: 9.5px;
    padding: 2px 7px;
    border-radius: 10px;
    text-transform: uppercase;
    font-weight: 700;
    letter-spacing: 0.5px;
  }}
  .badge-affect {{ background: #238636; color: #fff; }}
  .badge-valeur {{ background: #8957e5; color: #fff; }}
  .badge-equateur {{ background: #f0883e; color: #fff; }}
  .meta-grid {{
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 6px;
    margin: 9px 0;
    padding: 8px;
    background: #161b22;
    border-radius: 8px;
    font-size: 10.5px;
    border: 1px solid #21262d;
  }}
  .meta-item b {{ color: #8b949e; font-weight: 500; display: block; font-size: 9.5px; }}
  .meta-item span {{ color: #e6edf3; font-weight: 600; font-family: monospace; }}
  .tabs-bar {{
    display: flex;
    gap: 4px;
    border-bottom: 1px solid #30363d;
    padding-bottom: 6px;
    margin-bottom: 8px;
  }}
  .tab-btn {{
    flex: 1;
    background: #161b22;
    color: #8b949e;
    border: 1px solid #21262d;
    border-radius: 6px;
    padding: 5px 6px;
    font-size: 10.5px;
    font-weight: 600;
    cursor: pointer;
    text-align: center;
  }}
  .tab-btn.active {{
    background: #1f6feb;
    color: #fff;
    border-color: #58a6ff;
  }}
  .tab-panel {{
    display: none;
    flex: 1;
    overflow-y: auto;
    padding-right: 4px;
  }}
  .tab-panel.active {{
    display: block;
  }}
  .tab-panel::-webkit-scrollbar {{ width: 5px; }}
  .tab-panel::-webkit-scrollbar-thumb {{ background: #30363d; border-radius: 3px; }}
  .section-title {{
    font-size: 10px;
    font-weight: 700;
    text-transform: uppercase;
    color: #8b949e;
    margin: 8px 0 5px 0;
    letter-spacing: 0.5px;
  }}
  .relation-box {{
    background: #161b22;
    border: 1px solid #21262d;
    border-radius: 7px;
    padding: 6px 9px;
    font-size: 10.5px;
    margin-bottom: 6px;
    line-height: 1.4;
  }}
  .relation-box.gold {{ border-left: 3px solid #ffd700; }}
  .relation-box.orange {{ border-left: 3px solid #ff7b72; }}
  .relation-box.violet {{ border-left: 3px solid #d2a8ff; }}
  .relation-box.blue {{ border-left: 3px solid #58a6ff; }}
  .relation-box.cyan {{ border-left: 3px solid #39c5cf; }}
  .relation-box.magenta {{ border-left: 3px solid #ff55ff; }}
  .relation-box.green {{ border-left: 3px solid #2ea043; }}
  .relation-box b {{ color: #8b949e; }}
  .jump-link {{
    color: #58a6ff;
    font-weight: 600;
    cursor: pointer;
    text-decoration: underline;
    text-decoration-color: rgba(88,166,255,0.4);
  }}
  .jump-link:hover {{ color: #79c0ff; }}
  .engine-card {{
    background: #161b22;
    border: 1px solid #21262d;
    border-radius: 7px;
    padding: 7px 9px;
    font-size: 10.5px;
    margin-bottom: 6px;
  }}
  .engine-card b {{ color: #79c0ff; display: block; margin-bottom: 2px; font-size: 10px; text-transform: uppercase; }}
  .engine-card span {{ color: #e6edf3; font-family: monospace; font-size: 10.5px; }}
  .word-pill {{
    display: inline-flex;
    align-items: center;
    gap: 5px;
    background: #21262d;
    border: 1px solid #30363d;
    border-radius: 12px;
    padding: 3px 8px;
    font-size: 10.5px;
    margin: 2px 2px 3px 0;
    color: #c9d1d9;
  }}
  .word-pill .src {{
    font-size: 8.5px;
    color: #8b949e;
    background: #161b22;
    padding: 1px 4px;
    border-radius: 4px;
  }}
  .word-pill.derive-defaut {{ border-left: 3px solid #f85149; }}
  .word-pill.derive-exces {{ border-left: 3px solid #da3633; }}
  .word-pill.valeur-centrale {{ border-left: 3px solid #2ea043; }}
  #legend {{
    position: absolute;
    bottom: 14px; left: 14px;
    z-index: 10;
    background: rgba(13, 17, 23, 0.9);
    backdrop-filter: blur(10px);
    border: 1px solid #30363d;
    border-radius: 10px;
    padding: 7px 12px;
    font-size: 10.5px;
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    max-width: calc(100vw - 470px);
    box-shadow: 0 4px 16px rgba(0,0,0,0.5);
  }}
  .leg-item {{ display: flex; align-items: center; gap: 5px; }}
  .leg-dot {{ width: 9px; height: 9px; border-radius: 50%; }}
</style>
<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/OrbitControls.js"></script>
</head>
<body>

<div id="canvas-container"></div>

<div id="top-bar">
  <div class="title-group">
    <h1>DIAMANT TAILLÉ SUR MESURE — CARTOGRAFFECT 303</h1>
    <p>Rose des 8 Symétries • Moteur Prédictif (A,C,P) • Matrice Attentionnelle • 2 780 Unigrammes Déduits</p>
  </div>
  <div class="controls-group">
    <button class="btn active" id="btn-all" onclick="filterHemi('ALL')">Tous (303)</button>
    <button class="btn" id="btn-zplus" onclick="filterHemi('ZPLUS')">Z+ Affectif (176)</button>
    <button class="btn" id="btn-zminus" onclick="filterHemi('ZMINUS')">Z- Valeurs (127)</button>
    <select class="filter-select" id="sel-strate" onchange="applyCombinedFilters()">
      <option value="ALL">Toutes Strates Z (-7..+7)</option>
      <option value="0">Z = 0 (Veille)</option>
      <option value="1">Z = +1 (Micro-expressions)</option>
      <option value="2">Z = +2 (Tempéraments)</option>
      <option value="3">Z = +3 (Humeurs)</option>
      <option value="4">Z = +4 (Sentiments)</option>
      <option value="5">Z = +5 (Émotions)</option>
      <option value="6">Z = +6 (Ressentis)</option>
      <option value="7">Z = +7 (Équateur / Passions)</option>
      <option value="-6">Z = -6 / W=1 (Principes adj.)</option>
      <option value="-5">Z = -5 / W=2 (Forces d'appui)</option>
      <option value="-4">Z = -4 / W=3 (Engagements)</option>
      <option value="-3">Z = -3 / W=4 (Modes d'intégr.)</option>
      <option value="-2">Z = -2 / W=5 (Forces card.)</option>
      <option value="-1">Z = -1 / W=6 (Orientations)</option>
      <option value="-7">Z = -7 / W=7 (Éveil)</option>
    </select>
    <select class="filter-select" id="sel-regime" onchange="applyCombinedFilters()">
      <option value="ALL">Tous Régimes Moteur</option>
      <option value="Synergie_Positive">Synergie + (A+, C+)</option>
      <option value="Synergie_Negative">Synergie - (A-, C-)</option>
      <option value="Compensation_Ergotrope">Ergotrope (A-, C+)</option>
      <option value="Relachement_Trophotrope">Trophotrope (A+, C-)</option>
      <option value="Mobilisation_Pure">Mobilisation Pure (A0, C+)</option>
      <option value="Repos_Basal">Repos Basal (0, 0)</option>
    </select>
    <button class="btn active" id="btn-rose" onclick="toggleRose()">Rose 8 Axes</button>
    <button class="btn active" id="btn-pillars" onclick="togglePillars()">Piliers Z+↔Z-</button>
    <button class="btn" id="btn-cords" onclick="toggleCords()">144 Contrepoids</button>
    <button class="btn" id="btn-triads" onclick="toggleTriads()">Triades Z=-6</button>
    <div class="search-box">
      <input type="text" id="search-input" placeholder="Chercher pôle ou mot..." oninput="applyCombinedFilters()">
    </div>
  </div>
</div>

<div id="drawer">
  <div style="display:flex; justify-content:space-between; align-items:center;">
    <h2 id="d-label">Sélectionnez un pôle</h2>
    <span class="badge" id="d-badge">-</span>
  </div>
  <p id="d-sub" style="font-size: 10.5px; color:#8b949e; margin-top:2px;">Cliquez sur une sphère 3D du Diamant</p>

  <div class="meta-grid">
    <div class="meta-item"><b>Coord. (X, Y, Z)</b><span id="d-coord">-</span></div>
    <div class="meta-item"><b>Hauteur 3D / L1</b><span id="d-h">-</span></div>
    <div class="meta-item"><b>Secteur / Groupe</b><span id="d-grp">-</span></div>
    <div class="meta-item"><b>Effectif Déduit</b><span id="d-n">-</span></div>
    <div class="meta-item"><b>VAD Moyen</b><span id="d-vad">-</span></div>
    <div class="meta-item"><b>Lyapunov V_L</b><span id="d-lyap">-</span></div>
  </div>

  <div class="tabs-bar">
    <button class="tab-btn active" id="tab-btn-rose" onclick="switchTab('rose')">Rose des 8 Symétries</button>
    <button class="tab-btn" id="tab-btn-engine" onclick="switchTab('engine')">Moteur & Matrice</button>
    <button class="tab-btn" id="tab-btn-words" onclick="switchTab('words')">Lexique (<span id="tab-w-count">0</span>)</button>
  </div>

  <!-- ONGLET 1 : ROSE DES 8 SYMÉTRIES -->
  <div class="tab-panel active" id="tab-rose">
    <div class="relation-box gold">
      <b>1. Antagoniste Régulateur Formel A(P) :</b> <span class="jump-link" id="d-cont" onclick="selectById(this.dataset.id)">-</span><br>
      <span id="d-cont-type" style="color:#d29922; font-size:9.5px; font-family:monospace;">-</span>
    </div>
    <div class="relation-box orange">
      <b>2. Opposé Central Intra-Dominante Ic(-X, -Y, Z) :</b> <span class="jump-link" id="d-ic" onclick="selectById(this.dataset.id)">-</span>
    </div>
    <div class="relation-box violet">
      <b>3. Miroir Diagonal de Dominante M_dom(|Y|, |X|) :</b> <span class="jump-link" id="d-md" onclick="selectById(this.dataset.id)">-</span>
    </div>
    <div class="relation-box blue">
      <b>4a. Miroir Latéral Orthogonal X (-X, Y, Z) :</b> <span class="jump-link" id="d-ox" onclick="selectById(this.dataset.id)">-</span><br>
      <b>4b. Miroir Latéral Orthogonal Y (X, -Y, Z) :</b> <span class="jump-link" id="d-oy" onclick="selectById(this.dataset.id)">-</span>
    </div>
    <div class="relation-box cyan">
      <b>5. Homologue Vertical (+Z ↔ -Z) :</b> <span class="jump-link" id="d-hom" onclick="selectById(this.dataset.id)">-</span><br>
      <span id="d-trans-loi" style="color:#39c5cf; font-size:9.5px; font-family:monospace;">-</span>
    </div>
    <div class="relation-box magenta">
      <b>6. Contrepoids Croisé Trans-Hémisphérique A_Z(P) :</b> <span class="jump-link" id="d-az" onclick="selectById(this.dataset.id)">-</span>
    </div>
    <div class="relation-box green">
      <b>7. Filière Hiérarchique Inter-Couches (ΔZ) :</b><br>
      • Dissipation (|Z|-1) : <span class="jump-link" id="d-fzin" onclick="selectById(this.dataset.id)">-</span><br>
      • Approfondissement (|Z|+1) : <span class="jump-link" id="d-fzout" onclick="selectById(this.dataset.id)">-</span>
    </div>
    <div class="relation-box green" id="box-triad" style="display:none;">
      <b>8. Triade Aristotélicienne (Z = -6 / W = 1) :</b><br>
      <span id="d-triad" style="color:#e6edf3; font-size:10px;">-</span>
    </div>
  </div>

  <!-- ONGLET 2 : MOTEUR PRÉDICTIF & MATRICE ATTENTIONNELLE -->
  <div class="tab-panel" id="tab-engine">
    <div class="engine-card">
      <b>Couplage Topologique (A, C) — Interface Attentionnelle</b>
      <span id="d-ac">-</span>
    </div>
    <div class="engine-card">
      <b>Interface Dominante & Opération Inférentielle</b>
      <span id="d-if-op">-</span>
    </div>
    <div class="engine-card">
      <b>Strate Z — Objet d'Inférence & Rôle Fonctionnel</b>
      <span id="d-strate-info">-</span>
    </div>
    <div class="engine-card">
      <b>Régime Énergétique & Profil d'Activation</b>
      <span id="d-regime-prof">-</span>
    </div>
    <div class="engine-card">
      <b>Polarité Lexicographique (Primauté de X)</b>
      <span id="d-pol-lex">-</span>
    </div>
    <div class="engine-card">
      <b>Sous-Secteur de la Matrice (Partition en 17 Régions)</b>
      <span id="d-ssect17">-</span>
    </div>
  </div>

  <!-- ONGLET 3 : CORTÈGE LEXICAL -->
  <div class="tab-panel" id="tab-words">
    <div class="section-title" id="d-words-title">Cortège Lexical Déduit (0)</div>
    <div id="d-words"></div>
  </div>
</div>

<div id="legend">
  <div class="leg-item"><div class="leg-dot" style="background:#ffaa33;"></div>Joie / Volonté (+Y)</div>
  <div class="leg-item"><div class="leg-dot" style="background:#4488ff;"></div>Tristesse / Tempérance (-Y)</div>
  <div class="leg-item"><div class="leg-dot" style="background:#9966ff;"></div>Peur / Prudence (-X)</div>
  <div class="leg-item"><div class="leg-dot" style="background:#ff4466;"></div>Courage / Audace (+X)</div>
  <div class="leg-item"><div class="leg-dot" style="background:#ff3333;"></div>Colère / Équité (-X,+Y)</div>
  <div class="leg-item"><div class="leg-dot" style="background:#33ccaa;"></div>Calme / Clémence (+X,-Y)</div>
  <div class="leg-item"><div class="leg-dot" style="background:#ff77aa;"></div>Désir / Aspiration (+X,+Y)</div>
  <div class="leg-item"><div class="leg-dot" style="background:#88aa33;"></div>Dégoût / Intégrité (-X,-Y)</div>
</div>

<script>
const rawData = {json_data};

const GROUP_COLORS = {{
  'JOIE': 0xffaa33, 'VOLONTÉ': 0xffaa33,
  'TRISTESSE': 0x4488ff, 'TEMPÉRANCE': 0x4488ff,
  'PEUR': 0x9966ff, 'PRUDENCE': 0x9966ff,
  'COURAGE': 0xff4466, 'AUDACE': 0xff4466,
  'COLERE': 0xff3333, 'COLÈRE': 0xff3333, 'ÉQUITÉ': 0xff3333,
  'CALME': 0x33ccaa, 'CLÉMENCE': 0x33ccaa,
  'DESIR': 0xff77aa, 'DÉSIR': 0xff77aa, 'ASPIRATION': 0xff77aa,
  'DEGOUT': 0x88aa33, 'DÉGOÛT': 0x88aa33, 'INTÉGRITÉ': 0x88aa33,
  'OPERATEUR_CENTRAL': 0xffffff
}};

const container = document.getElementById('canvas-container');
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x090c10);
scene.fog = new THREE.FogExp2(0x090c10, 0.014);

const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);
camera.position.set(22, 16, 28);

const renderer = new THREE.WebGLRenderer({{ antialias: true }});
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(window.devicePixelRatio);
container.appendChild(renderer.domElement);

const controls = new THREE.OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.dampingFactor = 0.05;
controls.maxDistance = 120;
controls.minDistance = 3;

scene.add(new THREE.AmbientLight(0xffffff, 0.78));
const dirLight1 = new THREE.DirectionalLight(0xffffff, 0.9);
dirLight1.position.set(20, 30, 20);
scene.add(dirLight1);
const dirLight2 = new THREE.DirectionalLight(0x58a6ff, 0.5);
dirLight2.position.set(-20, -30, -20);
scene.add(dirLight2);

const nodesGroup = new THREE.Group();
scene.add(nodesGroup);
const pillarsGroup = new THREE.Group();
scene.add(pillarsGroup);
const cordsGroup = new THREE.Group();
scene.add(cordsGroup);
const triadsGroup = new THREE.Group();
scene.add(triadsGroup);
const activeOverlayGroup = new THREE.Group();
scene.add(activeOverlayGroup);

let showRose = true;
let currentHemiFilter = 'ALL';

// Axe central
const axisMat = new THREE.LineDashedMaterial({{ color: 0x484f58, dashSize: 0.5, gapSize: 0.3 }});
const axisGeo = new THREE.BufferGeometry().setFromPoints([
  new THREE.Vector3(0, -7 * 1.5, 0),
  new THREE.Vector3(0, 7 * 1.5, 0)
]);
const axisLine = new THREE.Line(axisGeo, axisMat);
axisLine.computeLineDistances();
scene.add(axisLine);

// Anneau équatorial Z=7
const eqMat = new THREE.LineBasicMaterial({{ color: 0xf0883e, transparent: true, opacity: 0.4 }});
const eqPoints = [];
rawData.filter(p => p.z === 7).sort((a,b) => Math.atan2(a.y, a.x) - Math.atan2(b.y, b.x)).forEach(p => {{
  eqPoints.push(new THREE.Vector3(p.x * 0.85, 0, p.y * 0.85));
}});
if (eqPoints.length > 0) {{
  eqPoints.push(eqPoints[0].clone());
  const eqGeo = new THREE.BufferGeometry().setFromPoints(eqPoints);
  scene.add(new THREE.Line(eqGeo, eqMat));
}}

const nodeMeshes = [];
const nodeMapById = new Map();
const nodeMapByLabel = new Map();

rawData.forEach(p => {{
  const px = p.x * 0.85;
  const py = p.h * 1.5;
  const pz = p.y * 0.85;

  // Rayon harmonieux proportionnel à log2(1 + effectif)
  const radius = 0.36 + 0.14 * Math.log2(1 + p.n);
  const colorHex = GROUP_COLORS[p.grp] || 0xffffff;

  const geo = new THREE.SphereGeometry(radius, 20, 20);
  const mat = new THREE.MeshStandardMaterial({{
    color: colorHex,
    roughness: 0.25,
    metalness: 0.3,
    emissive: colorHex,
    emissiveIntensity: p.z === 0 || p.z === -7 || p.r === 0 ? 0.35 : 0.08
  }});

  const mesh = new THREE.Mesh(geo, mat);
  mesh.position.set(px, py, pz);
  mesh.userData = p;
  nodesGroup.add(mesh);
  nodeMeshes.push(mesh);

  nodeMapById.set(p.id, mesh);
  nodeMapByLabel.set(p.lbl.toLowerCase(), mesh);
}});

// 127 piliers verticaux (+Z <-> -Z)
const pillarMat = new THREE.LineBasicMaterial({{ color: 0x39c5cf, transparent: true, opacity: 0.24 }});
rawData.forEach(p => {{
  if (p.z >= 0 && p.z < 7 && p.h_id > 0 && nodeMapById.has(p.h_id)) {{
    const m1 = nodeMapById.get(p.id);
    const m2 = nodeMapById.get(p.h_id);
    if (m1 && m2) {{
      const geo = new THREE.BufferGeometry().setFromPoints([m1.position, m2.position]);
      pillarsGroup.add(new THREE.Line(geo, pillarMat));
    }}
  }}
}});

// 144 cordes d'antagonistes régulateurs
const cordMat = new THREE.LineDashedMaterial({{ color: 0xd29922, dashSize: 0.4, gapSize: 0.3, transparent: true, opacity: 0.22 }});
const seenCords = new Set();
rawData.forEach(p => {{
  if (p.c_id > 0 && nodeMapById.has(p.c_id)) {{
    const key = [Math.min(p.id, p.c_id), Math.max(p.id, p.c_id)].join('-');
    if (!seenCords.has(key)) {{
      seenCords.add(key);
      const m1 = nodeMapById.get(p.id);
      const m2 = nodeMapById.get(p.c_id);
      if (m1 && m2) {{
        const geo = new THREE.BufferGeometry().setFromPoints([m1.position, m2.position]);
        const line = new THREE.Line(geo, cordMat);
        line.computeLineDistances();
        cordsGroup.add(line);
      }}
    }}
  }}
}});
cordsGroup.visible = false;

// 8 triades aristotéliciennes Z=-6
const triadMat = new THREE.LineBasicMaterial({{ color: 0x2ea043, transparent: true, opacity: 0.65 }});
rawData.forEach(p => {{
  if (p.z === -6 && p.def !== '-' && p.exc !== '-') {{
    const mDef = nodeMapByLabel.get(p.def.toLowerCase());
    const mExc = nodeMapByLabel.get(p.exc.toLowerCase());
    const mVal = nodeMapById.get(p.id);
    if (mVal && mDef && mExc) {{
      const geo = new THREE.BufferGeometry().setFromPoints([
        mDef.position, mVal.position, mExc.position, mDef.position
      ]);
      triadsGroup.add(new THREE.Line(geo, triadMat));
    }}
  }}
}});
triadsGroup.visible = false;

const raycaster = new THREE.Raycaster();
const mouse = new THREE.Vector2();
let selectedMesh = null;

window.addEventListener('click', onPointerClick);
function onPointerClick(e) {{
  if (e.clientX > window.innerWidth - 450 && e.clientY > 65) return;
  if (e.clientY < 65) return;

  mouse.x = (e.clientX / window.innerWidth) * 2 - 1;
  mouse.y = -(e.clientY / window.innerHeight) * 2 + 1;
  raycaster.setFromCamera(mouse, camera);

  const intersects = raycaster.intersectObjects(nodeMeshes.filter(m => m.visible));
  if (intersects.length > 0) {{
    selectNode(intersects[0].object);
  }}
}}

function setLink(elId, label, targetId) {{
  const el = document.getElementById(elId);
  el.innerText = label && label !== '-' ? label : 'Point central (invariant)';
  el.dataset.id = targetId || -1;
}}

function addSymmetryLine(posA, targetId, colorHex, dashed = false) {{
  if (!targetId || targetId <= 0 || !nodeMapById.has(targetId)) return;
  const targetMesh = nodeMapById.get(targetId);
  if (!targetMesh || targetMesh.position.equals(posA)) return;
  const geo = new THREE.BufferGeometry().setFromPoints([posA, targetMesh.position]);
  let line;
  if (dashed) {{
    const mat = new THREE.LineDashedMaterial({{ color: colorHex, dashSize: 0.35, gapSize: 0.2 }});
    line = new THREE.Line(geo, mat);
    line.computeLineDistances();
  }} else {{
    const mat = new THREE.LineBasicMaterial({{ color: colorHex, linewidth: 2 }});
    line = new THREE.Line(geo, mat);
  }}
  activeOverlayGroup.add(line);
}}

function selectNode(mesh) {{
  if (!mesh) return;
  selectedMesh = mesh;
  const p = mesh.userData;

  document.getElementById('d-label').innerText = p.lbl;
  const badge = document.getElementById('d-badge');
  if (p.z === 7) {{
    badge.className = 'badge badge-equateur';
    badge.innerText = 'Équateur Z=+7';
  }} else if (p.z >= 0) {{
    badge.className = 'badge badge-affect';
    badge.innerText = `Affect Z=+${{p.z}}`;
  }} else {{
    badge.className = 'badge badge-valeur';
    badge.innerText = `Valeur Z=${{p.z}}`;
  }}

  document.getElementById('d-sub').innerText = `${{p.st_nom}} • ${{p.type}} • Sous-secteur : ${{p.ssect17}}`;
  document.getElementById('d-coord').innerText = `(${{p.x}}, ${{p.y}}, ${{p.z >= 0 ? '+' + p.z : p.z}})`;
  document.getElementById('d-h').innerText = `h=${{p.h >= 0 ? '+' + p.h : p.h}} | L1=${{p.r}}`;
  document.getElementById('d-grp').innerText = p.grp;
  document.getElementById('d-n').innerText = `${{p.n}} unigrammes`;
  document.getElementById('d-vad').innerText = `${{p.v_mean}} / ${{p.a_mean}} / ${{p.d_mean}}`;
  document.getElementById('d-lyap').innerText = `V_L = ${{p.lyap}} (S=${{p.score_sem}})`;

  // Onglet 1 : Rose des 8 symétries
  setLink('d-cont', p.c_lbl, p.c_id);
  document.getElementById('d-cont-type').innerText = `Opérateur : ${{p.c_type}}`;
  setLink('d-ic', p.ic_lbl, p.ic_id);
  setLink('d-md', p.md_lbl, p.md_id);
  setLink('d-ox', p.ox_lbl, p.ox_id);
  setLink('d-oy', p.oy_lbl, p.oy_id);
  setLink('d-hom', `${{p.h_lbl}} (Z=${{p.h_z >= 0 ? '+' + p.h_z : p.h_z}})`, p.h_id);
  document.getElementById('d-trans-loi').innerText = `Loi : ${{p.trans_loi}}`;
  setLink('d-az', p.az_lbl, p.az_id);
  setLink('d-fzin', p.fz_in_lbl, p.fz_in_id);
  setLink('d-fzout', p.fz_out_lbl, p.fz_out_id);

  const boxTriad = document.getElementById('box-triad');
  if (p.z === -6 && (p.def !== '-' || p.exc !== '-')) {{
    boxTriad.style.display = 'block';
    document.getElementById('d-triad').innerHTML = `
      <b style="color:#f85149;">Défaut (D-) :</b> ${{p.def}} &nbsp;|&nbsp;
      <b style="color:#58a6ff;">Valeur (V) :</b> ${{p.lbl}} &nbsp;|&nbsp;
      <b style="color:#da3633;">Excès (D+) :</b> ${{p.exc}}<br>
      <b style="color:#8b949e;">Famille :</b> ${{p.fam}}
    `;
  }} else {{
    boxTriad.style.display = 'none';
  }}

  // Onglet 2 : Moteur prédictif & Matrice attentionnelle
  document.getElementById('d-ac').innerText = p.ac;
  document.getElementById('d-if-op').innerText = `${{p.if_dom}}\n→ ${{p.op_inf}}`;
  document.getElementById('d-strate-info').innerText = `${{p.st_nom}} : ${{p.st_obj}}\n→ ${{p.st_role}}`;
  document.getElementById('d-regime-prof').innerText = `${{p.reg_en}}\n→ Profil : ${{p.prof_act}}`;
  document.getElementById('d-pol-lex').innerText = p.pol_lex;
  document.getElementById('d-ssect17').innerText = p.ssect17;

  // Onglet 3 : Cortège lexical
  document.getElementById('tab-w-count').innerText = p.n;
  document.getElementById('d-words-title').innerText = `Cortège Lexical Déduit (${{p.n}} termes)`;
  const wContainer = document.getElementById('d-words');
  wContainer.innerHTML = '';
  p.w.forEach(w => {{
    const pill = document.createElement('div');
    pill.className = 'word-pill';
    let triadeTag = '';
    if (w[5] === 'DERIVE_DEFAUT') {{
      pill.classList.add('derive-defaut');
      triadeTag = '<span style="background:rgba(248,81,73,0.2); color:#f85149; padding:1px 4px; border-radius:3px; font-size:8px; font-weight:bold; margin-left:4px;">DÉFAUT D-</span>';
    }} else if (w[5] === 'DERIVE_EXCES') {{
      pill.classList.add('derive-exces');
      triadeTag = '<span style="background:rgba(218,54,51,0.2); color:#da3633; padding:1px 4px; border-radius:3px; font-size:8px; font-weight:bold; margin-left:4px;">EXCÈS D+</span>';
    }} else if (w[5] === 'VALEUR_CENTRALE') {{
      pill.classList.add('valeur-centrale');
      triadeTag = '<span style="background:rgba(46,160,67,0.2); color:#3fb950; padding:1px 4px; border-radius:3px; font-size:8px; font-weight:bold; margin-left:4px;">VERTU V</span>';
    }}

    pill.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <b>${{w[0]}}</b>
        ${{triadeTag}}
      </div>
      <span class="src">${{w[4]}}</span>
      <span style="color:#8b949e; font-size:9px;">V:${{w[1]}} A:${{w[2]}} D:${{w[3]}}</span>
    `;
    wContainer.appendChild(pill);
  }});

  drawActiveRose(mesh);
}}

function drawActiveRose(mesh) {{
  activeOverlayGroup.clear();
  if (!mesh) return;
  const p = mesh.userData;

  const haloGeo = new THREE.SphereGeometry(mesh.geometry.parameters.radius * 1.48, 16, 16);
  const haloMat = new THREE.MeshBasicMaterial({{ color: 0xffffff, wireframe: true, transparent: true, opacity: 0.7 }});
  const halo = new THREE.Mesh(haloGeo, haloMat);
  halo.position.copy(mesh.position);
  activeOverlayGroup.add(halo);

  if (!showRose) return;

  // 1. Antagoniste Régulateur Formel A(P) (Or vif)
  addSymmetryLine(mesh.position, p.c_id, 0xffd700, false);
  // 2. Opposé Central Intra-Dominante Ic (Orange corail)
  addSymmetryLine(mesh.position, p.ic_id, 0xff7b72, true);
  // 3. Miroir de Dominante M_dom (Violet)
  addSymmetryLine(mesh.position, p.md_id, 0xd2a8ff, true);
  // 4. Miroirs Latéraux Orthogonaux Ox et Oy (Bleu acier)
  addSymmetryLine(mesh.position, p.ox_id, 0x58a6ff, true);
  addSymmetryLine(mesh.position, p.oy_id, 0x58a6ff, true);
  // 5. Homologue Vertical +Z <-> -Z (Cyan vif)
  addSymmetryLine(mesh.position, p.h_id, 0x00ffff, false);
  // 6. Contrepoids Croisé Trans-Hémisphérique A_Z (Magenta)
  addSymmetryLine(mesh.position, p.az_id, 0xff55ff, true);
  // 7. Filière Hiérarchique Inter-Couches ΔZ (Émeraude)
  addSymmetryLine(mesh.position, p.fz_in_id, 0x2ea043, false);
  addSymmetryLine(mesh.position, p.fz_out_id, 0x2ea043, false);
}}

function selectById(idStr) {{
  const id = parseInt(idStr, 10);
  if (id > 0 && nodeMapById.has(id)) {{
    selectNode(nodeMapById.get(id));
  }}
}}

function switchTab(tabName) {{
  ['rose', 'engine', 'words'].forEach(t => {{
    document.getElementById('tab-btn-' + t).classList.toggle('active', t === tabName);
    document.getElementById('tab-' + t).classList.toggle('active', t === tabName);
  }});
}}

function filterHemi(type) {{
  currentHemiFilter = type;
  document.getElementById('btn-all').classList.toggle('active', type === 'ALL');
  document.getElementById('btn-zplus').classList.toggle('active', type === 'ZPLUS');
  document.getElementById('btn-zminus').classList.toggle('active', type === 'ZMINUS');
  applyCombinedFilters();
}}

function applyCombinedFilters() {{
  const strateVal = document.getElementById('sel-strate').value;
  const regimeVal = document.getElementById('sel-regime').value;
  const q = document.getElementById('search-input').value.trim().toLowerCase();

  nodeMeshes.forEach(m => {{
    const p = m.userData;
    let vis = true;
    if (currentHemiFilter === 'ZPLUS' && p.z < 0) vis = false;
    if (currentHemiFilter === 'ZMINUS' && p.z >= 0) vis = false;
    if (strateVal !== 'ALL' && p.z !== parseInt(strateVal, 10)) vis = false;
    if (regimeVal !== 'ALL' && !p.reg_en.includes(regimeVal)) vis = false;
    if (q) {{
      const matchLabel = p.lbl.toLowerCase().includes(q);
      const matchWord = p.w.some(w => w[0].toLowerCase().includes(q));
      if (!matchLabel && !matchWord) vis = false;
    }}
    m.visible = vis;
  }});
}}

function toggleRose() {{
  showRose = !showRose;
  document.getElementById('btn-rose').classList.toggle('active', showRose);
  if (selectedMesh) drawActiveRose(selectedMesh);
}}

function togglePillars() {{
  pillarsGroup.visible = !pillarsGroup.visible;
  document.getElementById('btn-pillars').classList.toggle('active', pillarsGroup.visible);
}}

function toggleCords() {{
  cordsGroup.visible = !cordsGroup.visible;
  document.getElementById('btn-cords').classList.toggle('active', cordsGroup.visible);
}}

function toggleTriads() {{
  triadsGroup.visible = !triadsGroup.visible;
  document.getElementById('btn-triads').classList.toggle('active', triadsGroup.visible);
}}

window.addEventListener('resize', () => {{
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
}});

function animate() {{
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
}}
animate();

if (nodeMapByLabel.has('éveil')) {{
  selectNode(nodeMapByLabel.get('éveil'));
}}
</script>
</body>
</html>
"""

    with open(HTML_OUT, "w", encoding="utf-8") as f:
        f.write(html_content)
    print(f"Généré {HTML_OUT} ({len(html_content)} octets)")

    with open(ARTIFACT_OUT, "w", encoding="utf-8") as f:
        f.write(html_content)
    print(f"Généré artifact utilisateur {ARTIFACT_OUT}")


if __name__ == "__main__":
    build_viewer()
