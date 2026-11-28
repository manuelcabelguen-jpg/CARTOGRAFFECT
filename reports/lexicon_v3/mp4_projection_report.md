# Rapport d'Audit — Micro-Passe 4 : Projection sur la surface pleine $L_1$ ($|x| + |y| \le 2\lfloor Z \rfloor - 2$) & Injection radiale de $A$ (CARTOGRAFFECT v3.0.0)

- **Script :** [`python/lexicon_pipeline/03_project_surface_v3.py`](../../python/lexicon_pipeline/03_project_surface_v3.py) *(strictement idempotent, zéro appel réseau)*
- **Périmètre Lean 4 :** `Cartograffect/` strictement en lecture seule (`0` fichier modifié)
- **Statut YAML MP3b vérifié au démarrage :** `clinical_review_status == "APPROVED"` (`109` classes, `52` règles `subclass_overrides`)
- **Filtrage clinique MP3b (`move_to_z_minus_reserve`) :** `moved_to_z_minus_in_mp3b = 7` (`Z_PLUS_ACTIVE`) + `5` (`Z_PLUS_SATELLITE`) = `12` entrées exclues sur les 5 classes (`Croyance, Croyance relig, Incrédulité, Incrédulité relig, Pudeur`)
- **Table maître résultante (`lexicon_v3_master`) :** `1,496` lignes = `11` `canonical_lean4` ($Z \in \{0,1,2\}$) + `3` `central_operator_v3` ($Z \in \{3,4,5\}$) + `542` `Z_PLUS_ACTIVE` + `940` `Z_PLUS_SATELLITE` (`1,482` DIMA projetés)
- **Winsorisation robuste de $A_{\text{harm}}$ (périphériques $n = 1,429$) :** $p_{01} = -0.942200$, $p_{99} = +0.936440$, projection linéaire monotone vers $[0.15,\; 1.00]$

### Empreintes SHA-256 des entrées et sorties

| Artefact | Statut Git | SHA-256 |
| :--- | :--- | :--- |
| `data/processed/dima_z_plus_psychometrics.parquet` *(entrée)* | Ignoré Git | `726b09a0b5b099084dc947c3da889bb499e2dad555c8a79317a029cbaf629453` |
| `data/config/dima_class_to_subsector_109.yaml` *(entrée)* | Versionné | `8273f6be72978a05cb3037b98776cee9164fc9768848827b5a887d5b7c6e25a4` |
| `data/config/canonical_z0_z2_anchors.json` *(entrée)* | Versionné | `5a291d6e8b4553bbf8131276796a1ac85e2a44025c4f4e7c5bfa69caeceb6935` |
| `data/processed/lexicon_v3_master.parquet` *(sortie)* | Ignoré Git | `d9214ff7df891c2a5687eb979f1d51b77966fe2a8f765e8dc123104259b156b4` |
| `data/processed/lexicon_v3_master.tsv` *(sortie)* | Ignoré Git | `fdcbb05de9aa3af3d1d2a307c4096df4d7d7a9ed8ef87d85bb4404aa323aee5e` |
| `reports/lexicon_v3/surface_Z3.png` *(sortie 300 dpi)* | Versionnable | `f74e04bc83fb7523a19d359f611da73f10155df7f7a89070c449c3f7bc648dcc` |
| `reports/lexicon_v3/surface_Z4.png` *(sortie 300 dpi)* | Versionnable | `685456ac6f8444f022ab23704418b898eaf4dfeaeaaa375da6b9da38aab6763d` |
| `reports/lexicon_v3/surface_Z5.png` *(sortie 300 dpi)* | Versionnable | `06e248d236ad1363b3f544badc543681e1bf4c7301fc414546968789fb43908f` |

---

## 1. Bilan des effectifs projetés par strate $Z \in \{0..5\}$, par `FunctionalSubsector` (17) et par `ring_A`

### 1.1 Effectifs par strate $Z \in \{0..5\}$

| Strate $Z$ | Rayon $R(Z)$ | `canonical_lean4` | `central_operator_v3` | `Z_PLUS_ACTIVE` | `Z_PLUS_SATELLITE` | Total table maître |
| :---: | :---: | ---: | ---: | ---: | ---: | ---: |
| **0** | `0` | 1 | 0 | 0 | 0 | **1** |
| **1** | `0` | 1 | 0 | 0 | 0 | **1** |
| **2** | `2` | 9 | 0 | 0 | 0 | **9** |
| **3** | `4` | 0 | 1 | 213 | 384 | **598** |
| **4** | `6` | 0 | 1 | 193 | 383 | **577** |
| **5** | `8` | 0 | 1 | 136 | 173 | **310** |
| **Total** | — | **11** | **3** | **542** | **940** | **1496** |

### 1.2 Effectifs par `FunctionalSubsector` (17 sous-secteurs Lean 4)

| Paire | `subsector_id` | $(u_X^{\text{prior}}, u_Y^{\text{prior}})$ | Verrouillés ($Z \le 5$) | `Z_PLUS_ACTIVE` ($Z=3/4/5$) | `Z_PLUS_SATELLITE` | Total DIMA | Total général |
| :---: | :--- | :---: | ---: | :---: | ---: | ---: | ---: |
| `CENTER` | `centralOperator` | `(+0.00, +0.00)` | 6 | 13 (`13/0/0`) | 40 | 53 | **59** |
| `A2` | `axialControlPos` | `(+0.00, +1.00)` | 1 | 30 (`17/0/13`) | 35 | 65 | **66** |
| `A2` | `axialControlNeg` | `(+0.00, -1.00)` | 1 | 19 (`13/6/0`) | 21 | 40 | **41** |
| `A1` | `axialExpectationPos` | `(+1.00, +0.00)` | 1 | 11 (`8/0/3`) | 28 | 39 | **40** |
| `A1` | `axialExpectationNeg` | `(-1.00, +0.00)` | 1 | 28 (`16/0/12`) | 77 | 105 | **106** |
| `D1` | `diagonalSynergyPos` | `(+0.50, +0.50)` | 1 | 108 (`43/65/0`) | 165 | 273 | **274** |
| `D1` | `diagonalSynergyNeg` | `(-0.50, -0.50)` | 1 | 59 (`16/12/31`) | 86 | 145 | **146** |
| `D2` | `diagonalAgenticConfront` | `(-0.50, +0.50)` | 1 | 31 (`27/4/0`) | 90 | 121 | **122** |
| `D2` | `diagonalAccommodation` | `(+0.50, -0.50)` | 1 | 13 (`12/1/0`) | 21 | 34 | **35** |
| `L2` | `lateralApproachSynergy` | `(+0.25, +0.75)` | 0 | 29 (`7/9/13`) | 24 | 53 | **53** |
| `L3` | `lateralAgenticConfront` | `(-0.25, +0.75)` | 0 | 46 (`7/39/0`) | 31 | 77 | **77** |
| `L4` | `lateralSecondaryAccomm` | `(+0.25, -0.75)` | 0 | 6 (`2/0/4`) | 1 | 7 | **7** |
| `L1` | `lateralAversiveDistress` | `(-0.25, -0.75)` | 0 | 51 (`9/12/30`) | 146 | 197 | **197** |
| `L1` | `lateralEpistemicMastery` | `(+0.75, +0.25)` | 0 | 29 (`1/11/17`) | 72 | 101 | **101** |
| `L3` | `lateralReceptiveAccomm` | `(+0.75, -0.25)` | 0 | 20 (`0/20/0`) | 33 | 53 | **53** |
| `L4` | `lateralActiveContest` | `(-0.75, +0.25)` | 0 | 13 (`1/12/0`) | 26 | 39 | **39** |
| `L2` | `lateralEpistemicClosure` | `(-0.75, -0.25)` | 0 | 36 (`21/2/13`) | 44 | 80 | **80** |

### 1.3 Effectifs par anneau iso-activation (`ring_A`) et rattachement des satellites

| Anneau `ring_A` | Plage $A_{\text{norm}}$ | Verrouillés | `Z_PLUS_ACTIVE` | `Z_PLUS_SATELLITE` | Total |
| :--- | :---: | ---: | ---: | ---: | ---: |
| `center_operator` | $A = 0$ (`centralOperator`) | 6 | 13 | 40 | **59** |
| `inner_low` | $A \in (0,\; 0.35]$ | 0 | 55 | 64 | **119** |
| `inner_mod` | $A \in (0.35,\; 0.65]$ | 0 | 174 | 315 | **489** |
| `sub_perimeter` | $A \in (0.65,\; 0.85]$ | 0 | 202 | 362 | **564** |
| `perimeter_high` | $A \in (0.85,\; 1.00]$ | 8 | 98 | 159 | **265** |

- **Priorité `subclass_overrides` :** `102` entrées DIMA résolues via les `52` règles `subclass_overrides` (dont `68` `Z_PLUS_ACTIVE`), et `1380` via les défauts de classe.
- **Rattachement `parent_lemma_id` des `940` satellites `Z_PLUS_SATELLITE` :** `331` par `(classe, sous_classe)`, `553` par `classe`, `54` par `(subsector_id, Z)` *(classes exclusivement satellites)*, `2` par `subsector_id` (`0` satellite orphelin).

---

## 2. Vérification formelle de 100 % des invariants

| Invariant | Portée vérifiée | Résultat | Statut |
| :--- | :--- | :--- | :---: |
| Strate normative $Z \in \{3, 4, 5\}$ (DIMA projetés) | `1,482 / 1,482` | `100.00%` dans `{3, 4, 5}` | **PASS** |
| Identifiants exacts `FunctionalSubsector` (17 Lean 4) | `1,496 / 1,496` | `17 / 17` identifiants exacts, `0` inconnu | **PASS** |
| Inégalité de surface pleine $|x| + |y| \le 2\lfloor Z \rfloor - 2$ | `1,496 / 1,496` | `max(|x|+|y| - R(Z)) = 0.00e+00` | **PASS** |
| Canal autonome périphérique $A_{\text{norm}} \in [0.15,\; 1.00]$ | `1,429 / 1,429` | min=`0.150000`, max=`1.000000` | **PASS** |
| Norme unitaire directionnelle $|u_X| + |u_Y| = 1$ | `1,429 / 1,429` | écart max = `0.00e+00` | **PASS** |
| Garde cône latéral ($\delta = 0.05$ aux axes & diagonales) | `607 / 607` latéraux | `min(|u_minor|) = 0.0500` (`>= 0.05`), `max = 0.4500` (`<= 0.45`) | **PASS** |
| Idempotence exacte `apportionRay(X, Y, Z) == (X, Y)` | `Z in {2,3,4,5}` (`84` pts) | `84 / 84` (`100.00%` exact) | **PASS** |
| Conformité Option 1A (verrous 1A-a/b/c/d, 0 aversif $Y > 0$) | `1,482 / 1,482` | `0` violation | **PASS** |
| Lisibilité PNG sans chevauchement d'étiquettes | `surface_Z{3,4,5}.png` | `0` chevauchement sur `62` jalons | **PASS** |

---

## 3. Audit de séparation radiale en $A$ (médianes & test de Mann-Whitney $U$)

Les deux contrastes évaluent la séparation radiale de l'activation autonome ($A_{\text{norm}}$ et $A_{\text{harm}}$) entre jalons haute activation vs basse activation situés dans un même domaine quadrantique sur les entrées `Z_PLUS_ACTIVE` :

| Contraste | Base | Haute activation (médiane, IQR, $n$) | Basse activation (médiane, IQR, $n$) | $U$ | $p$ (unilatéral `>`) | $p$ (bilatéral) | $r_{\text{rb}}$ |
| :--- | :--- | :--- | :--- | ---: | ---: | ---: | ---: |
| **Q3 ($Y < 0$) : Panique/Angoisse/Terreur/Effroi/Affliction vs Résignation/Apathie/Lassitude/Accablement** | Lemmes uniques (`A_norm`) | `0.8405` (IQR `0.0995`, $n=5$) | `0.3837` (IQR `0.1813`, $n=4$) | `20.0` | `9.7255e-03` | `1.9451e-02` | `+1.0000` |
| Q3 ($Y < 0$) — toutes occurrences actives | Toutes lignes (`A_norm`) | `0.8405` (IQR `0.0995`, $n=5$) | `0.4518` (IQR `0.1361`, $n=5$) | `25.0` | `5.8337e-03` | `1.1667e-02` | `+1.0000` |
| Q3 ($Y < 0$) — échelle brute $A_{\text{harm}}$ | Lemmes uniques (`A_harm`) | `0.5840` (IQR `0.2200`, $n=5$) | `-0.4256` (IQR `0.4008`, $n=4$) | `20.0` | `9.7255e-03` | `1.9451e-02` | `+1.0000` |
| **Q1/Q4 : Euphorie/Exaltation/Passion/Enthousiasme vs Calme/Sérénité/Tranquillité/Quiétude/Repos** | Lemmes uniques (`A_norm`) | `0.8699` (IQR `0.1523`, $n=4$) | `0.2460` (IQR `0.0754`, $n=5$) | `20.0` | `9.7255e-03` | `1.9451e-02` | `+1.0000` |
| Q1/Q4 — toutes occurrences actives | Toutes lignes (`A_norm`) | `0.8089` (IQR `0.1858`, $n=5$) | `0.2837` (IQR `0.1352`, $n=6$) | `30.0` | `3.8430e-03` | `7.6860e-03` | `+1.0000` |
| Q1/Q4 — échelle brute $A_{\text{harm}}$ | Lemmes uniques (`A_harm`) | `0.6490` (IQR `0.3367`, $n=4$) | `-0.7300` (IQR `0.1667`, $n=5$) | `20.0` | `9.7255e-03` | `1.9451e-02` | `+1.0000` |

### Détail des lemmes évalués dans les deux contrastes

| Contraste | Groupe | `lemme_norm` | Classe DIMA | `subsector_id` | $Z$ | $A_{\text{harm}}$ | $A_{\text{norm}}$ | `ring_A` | $(x, y)$ |
| :--- | :--- | :--- | :--- | :--- | :---: | ---: | ---: | :--- | :---: |
| Q3 ($Y < 0$) | Haute activation | `panique` | `Peur panique` | `lateralEpistemicClosure` | 3 | `+0.8760` | `0.9727` | `perimeter_high` | `(-3.41, -0.48)` |
| Q3 ($Y < 0$) | Haute activation | `terreur` | `Inquiéter Effrayer` | `lateralEpistemicClosure` | 3 | `+0.8040` | `0.9401` | `perimeter_high` | `(-3.32, -0.44)` |
| Q3 ($Y < 0$) | Haute activation | `angoisse` | `Inquiéter` | `lateralEpistemicClosure` | 4 | `+0.5840` | `0.8405` | `sub_perimeter` | `(-3.89, -1.15)` |
| Q3 ($Y < 0$) | Haute activation | `effroi` | `Inquiéter Effrayer` | `lateralEpistemicClosure` | 3 | `+0.5840` | `0.8405` | `sub_perimeter` | `(-2.82, -0.54)` |
| Q3 ($Y < 0$) | Haute activation | `affliction` | `Attrister` | `axialControlNeg` | 3 | `+0.2700` | `0.6985` | `sub_perimeter` | `(+0.00, -2.79)` |
| Q3 ($Y < 0$) | Basse activation | `résignation` | `Résignation` | `lateralAversiveDistress` | 4 | `-0.2160` | `0.4786` | `inner_mod` | `(-1.29, -1.58)` |
| Q3 ($Y < 0$) | Basse activation | `lassitude` | `Absence de désir` | `diagonalSynergyNeg` | 5 | `-0.2753` | `0.4518` | `inner_mod` | `(-1.81, -1.81)` |
| Q3 ($Y < 0$) | Basse activation | `lassitude` | `Importuner` | `axialControlNeg` | 3 | `-0.2753` | `0.4518` | `inner_mod` | `(+0.00, -1.81)` |
| Q3 ($Y < 0$) | Basse activation | `apathie` | `Apathie` | `lateralAversiveDistress` | 5 | `-0.5760` | `0.3157` | `inner_low` | `(-1.08, -1.44)` |
| Q3 ($Y < 0$) | Basse activation | `accablement` | `Mauvais moral` | `lateralAversiveDistress` | 5 | `-0.9170` | `0.1614` | `inner_low` | `(-0.58, -0.71)` |
| Q1/Q4 | Haute activation | `euphorie` | `Humeur bonne` | `axialControlPos` | 5 | `+0.9100` | `0.9880` | `perimeter_high` | `(+0.00, +7.90)` |
| Q1/Q4 | Haute activation | `exaltation` | `Bon moral` | `lateralApproachSynergy` | 5 | `+0.7840` | `0.9310` | `perimeter_high` | `(+2.71, +4.74)` |
| Q1/Q4 | Haute activation | `enthousiasme` | `Intéresser_A` | `diagonalSynergyPos` | 3 | `+0.5140` | `0.8089` | `sub_perimeter` | `(+1.62, +1.62)` |
| Q1/Q4 | Haute activation | `passion` | `Amour` | `diagonalSynergyPos` | 4 | `+0.3733` | `0.7452` | `sub_perimeter` | `(+2.24, +2.24)` |
| Q1/Q4 | Haute activation | `passion` | `Intéresser_A` | `diagonalSynergyPos` | 3 | `+0.3733` | `0.7452` | `sub_perimeter` | `(+1.49, +1.49)` |
| Q1/Q4 | Basse activation | `calme` | `Apaiser` | `diagonalAccommodation` | 3 | `-0.3872` | `0.4011` | `inner_mod` | `(+0.80, -0.80)` |
| Q1/Q4 | Basse activation | `calme` | `Apaiser` | `diagonalAccommodation` | 3 | `-0.3872` | `0.4011` | `inner_mod` | `(+0.80, -0.80)` |
| Q1/Q4 | Basse activation | `repos` | `Détendre` | `lateralSecondaryAccomm` | 3 | `-0.5633` | `0.3214` | `inner_low` | `(+0.47, -0.82)` |
| Q1/Q4 | Basse activation | `quiétude` | `Rassurer` | `diagonalAccommodation` | 4 | `-0.7300` | `0.2460` | `inner_low` | `(+0.74, -0.74)` |
| Q1/Q4 | Basse activation | `tranquillité` | `Rassurer` | `lateralApproachSynergy` | 4 | `-0.7300` | `0.2460` | `inner_low` | `(+0.66, +0.81)` |
| Q1/Q4 | Basse activation | `sérénité` | `Rassurer` | `lateralApproachSynergy` | 4 | `-0.8780` | `0.1790` | `inner_low` | `(+0.48, +0.59)` |

---

## 4. Cohérence des coordonnées de 20 jalons clés du Tableau 1b v3.0.0 (17/17 sous-secteurs)

| # | Jalon (`lemme_norm`) | Classe DIMA | `subsector_id` | $Z$ | $(u_X, u_Y)$ | $A_{\text{norm}}$ | `ring_A` | $(x, y)$ | Couronne $(X_c, Y_c)$ | $|x|+|y| / R(Z)$ |
| ---: | :--- | :--- | :--- | :---: | :---: | ---: | :--- | :---: | :---: | :---: |
| 1 | `émoi` | `Troubler` | `centralOperator` | 3 | `(+0.000, +0.000)` | `0.0000` | `center_operator` | `(+0.00, +0.00)` | `(+0, +0)` | `0.00 / 4` |
| 2 | `confiance` | `Confiance` | `axialExpectationPos` | 5 | `(+1.000, +0.000)` | `0.6188` | `inner_mod` | `(+4.95, +0.00)` | `(+8, +0)` | `4.95 / 8` |
| 3 | `inquiétude` | `Inquiéter` | `axialExpectationNeg` | 3 | `(-1.000, +0.000)` | `0.8261` | `sub_perimeter` | `(-3.30, +0.00)` | `(-4, +0)` | `3.30 / 4` |
| 4 | `euphorie` | `Humeur bonne` | `axialControlPos` | 5 | `(+0.000, +1.000)` | `0.9880` | `perimeter_high` | `(+0.00, +7.90)` | `(+0, +8)` | `7.90 / 8` |
| 5 | `chagrin` | `Attrister` | `axialControlNeg` | 3 | `(+0.000, -1.000)` | `0.4818` | `inner_mod` | `(+0.00, -1.93)` | `(+0, -4)` | `1.93 / 4` |
| 6 | `enthousiasme` | `Intéresser_A` | `diagonalSynergyPos` | 3 | `(+0.500, +0.500)` | `0.8089` | `sub_perimeter` | `(+1.62, +1.62)` | `(+2, +2)` | `3.24 / 4` |
| 7 | `aversion` | `Aversion` | `diagonalSynergyNeg` | 4 | `(-0.500, -0.500)` | `0.7238` | `sub_perimeter` | `(-2.17, -2.17)` | `(-3, -3)` | `4.34 / 6` |
| 8 | `rage` | `Colère` | `diagonalAgenticConfront` | 3 | `(-0.500, +0.500)` | `0.7686` | `sub_perimeter` | `(-1.54, +1.54)` | `(-2, +2)` | `3.07 / 4` |
| 9 | `quiétude` | `Rassurer` | `diagonalAccommodation` | 4 | `(+0.500, -0.500)` | `0.2460` | `inner_low` | `(+0.74, -0.74)` | `(+3, -3)` | `1.48 / 6` |
| 10 | `fierté` | `Orgueil` | `lateralEpistemicMastery` | 4 | `(+0.680, +0.320)` | `0.6976` | `sub_perimeter` | `(+2.85, +1.34)` | `(+4, +2)` | `4.19 / 6` |
| 11 | `honte` | `Honte` | `lateralAversiveDistress` | 4 | `(-0.450, -0.550)` | `0.7301` | `sub_perimeter` | `(-1.97, -2.41)` | `(-2, -4)` | `4.38 / 6` |
| 12 | `résignation` | `Résignation` | `lateralAversiveDistress` | 4 | `(-0.450, -0.550)` | `0.4786` | `inner_mod` | `(-1.29, -1.58)` | `(-2, -4)` | `2.87 / 6` |
| 13 | `exaltation` | `Bon moral` | `lateralApproachSynergy` | 5 | `(+0.364, +0.636)` | `0.9310` | `perimeter_high` | `(+2.71, +4.74)` | `(+3, +5)` | `7.45 / 8` |
| 14 | `sérénité` | `Rassurer` | `lateralApproachSynergy` | 4 | `(+0.450, +0.550)` | `0.1790` | `inner_low` | `(+0.48, +0.59)` | `(+2, +4)` | `1.07 / 6` |
| 15 | `angoisse` | `Inquiéter` | `lateralEpistemicClosure` | 4 | `(-0.772, -0.228)` | `0.8405` | `sub_perimeter` | `(-3.89, -1.15)` | `(-5, -1)` | `5.04 / 6` |
| 16 | `terreur` | `Inquiéter Effrayer` | `lateralEpistemicClosure` | 3 | `(-0.882, -0.118)` | `0.9401` | `perimeter_high` | `(-3.32, -0.44)` | `(-3, -1)` | `3.76 / 4` |
| 17 | `hostilité` | `Inimitié` | `lateralAgenticConfront` | 4 | `(-0.450, +0.550)` | `0.8252` | `sub_perimeter` | `(-2.23, +2.72)` | `(-2, +4)` | `4.95 / 6` |
| 18 | `acceptation` | `Résignation` | `lateralReceptiveAccomm` | 4 | `(+0.906, -0.094)` | `0.3836` | `inner_mod` | `(+2.09, -0.22)` | `(+5, -1)` | `2.30 / 6` |
| 19 | `mépris` | `Mépris` | `lateralActiveContest` | 4 | `(-0.854, +0.146)` | `0.6985` | `sub_perimeter` | `(-3.58, +0.61)` | `(-5, +1)` | `4.19 / 6` |
| 20 | `repos` | `Détendre` | `lateralSecondaryAccomm` | 3 | `(+0.365, -0.635)` | `0.3214` | `inner_low` | `(+0.47, -0.82)` | `(+1, -3)` | `1.29 / 4` |

---

## 5. Figures de contrôle générées (300 dpi)

- **`reports/lexicon_v3/surface_Z3.png`** ($Z = 3$, $R = 4$) : `213` entrées `Z_PLUS_ACTIVE`, `384` satellites en fond, `23` jalons annotés (`0` chevauchement), `816,837` octets, SHA-256 `f74e04bc83fb7523...`
- **`reports/lexicon_v3/surface_Z4.png`** ($Z = 4$, $R = 6$) : `193` entrées `Z_PLUS_ACTIVE`, `383` satellites en fond, `21` jalons annotés (`0` chevauchement), `815,833` octets, SHA-256 `685456ac6f8444f0...`
- **`reports/lexicon_v3/surface_Z5.png`** ($Z = 5$, $R = 8$) : `136` entrées `Z_PLUS_ACTIVE`, `173` satellites en fond, `18` jalons annotés (`0` chevauchement), `761,698` octets, SHA-256 `06e248d236ad1363...`
