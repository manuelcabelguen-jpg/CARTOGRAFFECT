# Rapport d'Audit — Micro-Passe 5 : Antagonisme involutif $\mathcal{A}$, appariement Top-3 & confrontation DIMA (CARTOGRAFFECT v3.0.0)

- **Script :** [`python/lexicon_pipeline/04_compute_antagonism.py`](../../python/lexicon_pipeline/04_compute_antagonism.py) *(strictement idempotent, zéro appel réseau)*
- **Suite bloquante :** [`python/lexicon_pipeline/test_lexicon_invariants.py`](../../python/lexicon_pipeline/test_lexicon_invariants.py) *(7 invariants normatifs)*
- **Périmètre Lean 4 :** `Cartograffect/` strictement en lecture seule (`0` fichier modifié)
- **Population appariée (`antagonism_pairs_v3`) :** `550` entrées sources (`8` prototypes canoniques $Z=2$ + `542` `Z_PLUS_ACTIVE` sur $Z \in \{3,4,5\}$) → **`1,568` lignes** (`8` canoniques $Z=2$ + `13` points fixes centraux $Z=3$ + `1,547` paires périphériques `Z_PLUS_ACTIVE`)
- **Couverture strate $Z$ identique (`Z_PLUS_ACTIVE` périphériques, $n = 529$) :** `456` entrées en `same_Z_exact` (`86.2%`) + `73` entrées en `cross_Z_conjugate_fallback` *(cellules conjuguées structurellement vides à ce $Z$ dans DIMA `Z_PLUS_ACTIVE`)*
- **Découplage Option 1A ($w_{|A - A'|} = 0.0$) :** `842` paires `iso_energetic` ($|\Delta A| \le 0.25$) et `705` paires `asymmetric_arousal` ($|\Delta A| > 0.25$) coexistent sans pénalité ; taux de réciprocité Top-3 = `26.4%`
- **Oracle DIMA (`antagonism_audit_conflicts.csv`) :** **`3,284` paires** antonymiques distinctes extraites dans `Z_PLUS_ACTIVE` (`59` impliquant `Entrées antonymes`)

### Empreintes SHA-256 des entrées et sorties

| Artefact | Statut Git | SHA-256 |
| :--- | :--- | :--- |
| `data/processed/lexicon_v3_master.parquet` *(entrée)* | Ignoré Git | `d9214ff7df891c2a5687eb979f1d51b77966fe2a8f765e8dc123104259b156b4` |
| `data/processed/dima_normalized.parquet` *(entrée)* | Ignoré Git | `0ac6a8b34e9f9b0e874cda8fe805760d45076c0b273c1a819e189977f39dfda3` |
| `data/config/canonical_z0_z2_anchors.json` *(entrée)* | Versionné | `5a291d6e8b4553bbf8131276796a1ac85e2a44025c4f4e7c5bfa69caeceb6935` |
| `data/processed/antagonism_pairs_v3.parquet` *(sortie)* | Ignoré Git | `923264e62c3e0c851589c9f22f1ad2e1c511d02155c9a7bb6a5afefb611af9c2` |
| `data/processed/antagonism_pairs_v3.tsv` *(sortie)* | Ignoré Git | `6874c538e54b7d26eeefcad9b1a8d57b9da8c554806853d8e1beaa27e41f0a85` |
| `data/processed/antagonism_audit_conflicts.csv` *(sortie)* | Ignoré Git | `01df102e8566005ad0dfab44de9ee7d8b411f47a28543c8af3aa2fe798913a4f` |

---

## 1. Vérification formelle de l'opérateur géométrique $\mathcal{A}$

| Invariant Lean 4 (`antagonistPoint`) | Portée vérifiée | Résultat | Statut |
| :--- | :--- | :--- | :---: |
| Involutivité exacte rayon $\mathcal{A}(\mathcal{A}(u_X, u_Y, Z)) = (u_X, u_Y, Z)$ | `1,496 / 1,496` | écart max $< 10^{-12}$ | **PASS** |
| Involutivité exacte couronne $\mathcal{A}(\mathcal{A}(X_c, Y_c, Z)) = (X_c, Y_c, Z)$ | `1,496 / 1,496` | `100.00%` exact (entier) | **PASS** |
| Échange controlatéral d'amplitudes $|X| \leftrightarrow |Y|$ (`L1`–`L4`) | `607 / 607` latéraux | `100.00%` exact (rayon & couronne) | **PASS** |
| Conservation de la strate $Z$ et de la norme $L_1$ | `1,496 / 1,496` | `100.00%` exact | **PASS** |
| Points fixes $\mathcal{A}(p) = p \iff$ `centralOperator` | `1,496 / 1,496` | `59` fixes (`6` verrouillés + `53` DIMA), `1,437` mobiles | **PASS** |
| Conjugaison exacte vers les `17` `FunctionalSubsector` | `1,496 / 1,496` | `100.00%` exact | **PASS** |

---

## 2. Synthèse chiffrée des 8 paires conjuguées + centre fixe (`Z_PLUS_ACTIVE`)

| Paire | Sous-secteur $+$ (`Z=3/4/5`) | Sous-secteur $-$ (`Z=3/4/5`) | Paires Top-3 | `same_Z` | `cross_Z` | `iso_energetic` | `asymmetric_arousal` | Méd. $\|\Delta u\|_1$ | Méd. $|\Delta A|$ | Bonus DIMA (`EA` / `ANT`) |
| :---: | :--- | :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :---: |
| `A1` | `axialExpectationPos` (`8/0/3`) | `axialExpectationNeg` (`16/0/12`) | 117 | 117 | 0 | 86 | 31 | `0.000` | `0.141` | `6 / 45` |
| `A2` | `axialControlPos` (`17/0/13`) | `axialControlNeg` (`13/6/0`) | 147 | 90 | 57 | 47 | 100 | `0.000` | `0.320` | `0 / 77` |
| `D1` | `diagonalSynergyPos` (`43/65/0`) | `diagonalSynergyNeg` (`16/12/31`) | 501 | 408 | 93 | 326 | 175 | `0.000` | `0.194` | `8 / 138` |
| `D2` | `diagonalAccommodation` (`12/1/0`) | `diagonalAgenticConfront` (`27/4/0`) | 124 | 124 | 0 | 1 | 123 | `0.000` | `0.540` | `0 / 0` |
| `L1` | `lateralEpistemicMastery` (`1/11/17`) | `lateralAversiveDistress` (`9/12/30`) | 222 | 222 | 0 | 116 | 106 | `0.060` | `0.203` | `0 / 92` |
| `L2` | `lateralApproachSynergy` (`7/9/13`) | `lateralEpistemicClosure` (`21/2/13`) | 186 | 186 | 0 | 150 | 36 | `0.411` | `0.119` | `4 / 36` |
| `L3` | `lateralReceptiveAccomm` (`0/20/0`) | `lateralAgenticConfront` (`7/39/0`) | 198 | 177 | 21 | 101 | 97 | `0.000` | `0.246` | `0 / 15` |
| `L4` | `lateralSecondaryAccomm` (`2/0/4`) | `lateralActiveContest` (`1/12/0`) | 52 | 4 | 48 | 15 | 37 | `0.464` | `0.350` | `0 / 0` |
| `CENTER` | `centralOperator` (`13/0/0`) | `centralOperator` *(point fixe)* | 13 | 13 | 0 | 13 | 0 | `0.000` | `0.000` | `0 / 0` |

> **Note sur les `73` sources en repli `cross_Z_conjugate_fallback` :** `6` cellules `(conjugate_subsector, Z)` ne contiennent aucune entrée `Z_PLUS_ACTIVE` dans DIMA (`A2` `axialControlPos` $Z=5$ : `13`, `axialControlNeg` $Z=4$ : `6` ; `D1` `diagonalSynergyNeg` $Z=5$ : `31` ; `L3` `lateralAgenticConfront` $Z=3$ : `7` ; `L4` `lateralSecondaryAccomm` $Z=5$ : `4`, `lateralActiveContest` $Z=4$ : `12`). Aucune entrée n'est écartée : le moteur sélectionne les Top-3 dans le sous-secteur conjugué sur les strates les plus proches ($|\Delta Z| \in \{1, 2\}$) et marque explicitement `same_Z_match = False`. Au total sur les paires périphériques actives, `18` paires bénéficient du bonus `Entrées antonymes` et `403` du bonus famille `ANTONYMIE`.

---

## 3. Vingt (20) paires antagonistes exemplaires (iso-énergétiques & asymétriques en $A$)

| # | Source (`lemme`, `classe`, $Z$) | Cible (`lemme`, `classe`, $Z$) | Paire | Rang | $(u_X, u_Y) \to (u'_X, u'_Y)$ | $A \to A'$ | $|\Delta A|$ | Régime $A$ | Bonus DIMA | Contexte |
| ---: | :--- | :--- | :---: | :---: | :--- | :---: | ---: | :--- | :---: | :--- |
| 1 | `colère` (`PrimaryCrownPrototype.colere`, Z=2) | `calme` (`PrimaryCrownPrototype.calme`, Z=2) | `D2` | #1 | `(-0.50,+0.50)` → `(+0.50,-0.50)` | `1.000` → `1.000` | `0.000` | `iso_energetic` | `—` | Z=2 canonique (D2, Rew− ↔ Pun−) |
| 2 | `désir` (`PrimaryCrownPrototype.desir`, Z=2) | `dégoût` (`PrimaryCrownPrototype.degout`, Z=2) | `D1` | #1 | `(+0.50,+0.50)` → `(-0.50,-0.50)` | `1.000` → `1.000` | `0.000` | `iso_energetic` | `—` | Z=2 canonique (D1, Rew+ ↔ Pun+) |
| 3 | `colère` (`Colère`, Z=3) | `calme` (`Apaiser`, Z=3) | `D2` | #1 | `(-0.50,+0.50)` → `(+0.50,-0.50)` | `0.686` → `0.401` | `0.285` | `asymmetric_arousal` | `—` | Asymétrique en A (D2, Z=3 : colère haut A ↔ calme bas A) |
| 4 | `angoisse` (`Inquiéter`, Z=4) | `sérénité` (`Rassurer`, Z=4) | `L2` | #1 | `(-0.77,-0.23)` → `(+0.45,+0.55)` | `0.841` → `0.179` | `0.661` | `asymmetric_arousal` | `ANT` | Asymétrique en A + ANT (L2, Z=4 : angoisse haut A ↔ sérénité bas A) |
| 5 | `angoisse` (`Inquiéter`, Z=4) | `tranquillité` (`Rassurer`, Z=4) | `L2` | #3 | `(-0.77,-0.23)` → `(+0.45,+0.55)` | `0.841` → `0.246` | `0.595` | `asymmetric_arousal` | `ANT` | Asymétrique en A + ANT (L2, Z=4 : angoisse haut A ↔ tranquillité bas A) |
| 6 | `énergie` (`Energie`, Z=5) | `avachissement` (`Apathie`, Z=5) | `L1` | #1 | `(+0.75,+0.25)` → `(-0.42,-0.58)` | `0.771` → `0.150` | `0.621` | `asymmetric_arousal` | `ANT` | Asymétrique en A + ANT (L1, Z=5 : énergie haut A ↔ avachissement bas A) |
| 7 | `apathie` (`Apathie`, Z=5) | `fougue` (`Energie`, Z=5) | `L1` | #1 | `(-0.43,-0.57)` → `(+0.55,+0.45)` | `0.316` → `0.830` | `0.514` | `asymmetric_arousal` | `ANT` | Asymétrique en A + ANT (L1, Z=5 : apathie bas A ↔ fougue haut A) |
| 8 | `exaltation` (`Bon moral`, Z=5) | `agoraphobe` (`Peur phobie`, Z=5) | `L2` | #1 | `(+0.36,+0.64)` → `(-0.74,-0.26)` | `0.931` → `0.210` | `0.721` | `asymmetric_arousal` | `—` | Asymétrique en A (L2, Z=5 : exaltation haut A ↔ agoraphobe bas A) |
| 9 | `rage` (`Colère`, Z=3) | `apaisement` (`Apaiser`, Z=3) | `D2` | #3 | `(-0.50,+0.50)` → `(+0.50,-0.50)` | `0.769` → `0.291` | `0.477` | `asymmetric_arousal` | `—` | Asymétrique en A (D2, Z=3 : rage haut A ↔ apaisement bas A) |
| 10 | `gratitude` (`Gratitude`, Z=4) | `rancœur` (`Ressentiment`, Z=4) | `L3` | #1 | `(+0.80,-0.20)` → `(-0.45,+0.55)` | `0.523` → `0.798` | `0.275` | `asymmetric_arousal` | `ANT` | Asymétrique en A + ANT (L3, Z=4 : gratitude ↔ rancœur) |
| 11 | `désamour` (`Amour désamour`, Z=4) | `amour` (`Amour`, Z=4) | `D1` | #2 | `(-0.50,-0.50)` → `(+0.50,+0.50)` | `0.318` → `0.723` | `0.405` | `asymmetric_arousal` | `EA+ANT` | Asymétrique en A + EA/ANT (D1, Z=4 : désamour ↔ amour) |
| 12 | `repos` (`Détendre`, Z=3) | `dépit` (`Décevoir`, Z=3) | `L4` | #1 | `(+0.36,-0.64)` → `(-0.87,+0.13)` | `0.321` → `0.667` | `0.345` | `asymmetric_arousal` | `—` | Asymétrique en A (L4, Z=3 : repos bas A ↔ dépit modéré) |
| 13 | `fierté` (`Orgueil`, Z=4) | `honte` (`Honte`, Z=4) | `L1` | #1 | `(+0.68,+0.32)` → `(-0.45,-0.55)` | `0.698` → `0.730` | `0.033` | `iso_energetic` | `ANT` | Iso-énergétique + ANT (L1, Z=4 : fierté ↔ honte) |
| 14 | `joie` (`Réjouir`, Z=3) | `tristesse` (`Attrister`, Z=3) | `A2` | #3 | `(+0.00,+1.00)` → `(+0.00,-1.00)` | `0.800` → `0.605` | `0.196` | `iso_energetic` | `ANT` | Iso-énergétique + ANT (A2, Z=3 : joie ↔ tristesse) |
| 15 | `confiance` (`Confiance`, Z=5) | `défiance` (`Défiance`, Z=5) | `A1` | #1 | `(+1.00,+0.00)` → `(-1.00,+0.00)` | `0.619` → `0.730` | `0.111` | `iso_energetic` | `EA+ANT` | Iso-énergétique + EA/ANT (A1, Z=5 : confiance ↔ défiance) |
| 16 | `optimisme` (`Confiance_Sentiment de sécurité`, Z=5) | `pessimisme` (`Défiance_Sentiment d'insécurité`, Z=5) | `L2` | #1 | `(+0.45,+0.55)` → `(-0.80,-0.20)` | `0.635` → `0.562` | `0.073` | `iso_energetic` | `EA+ANT` | Iso-énergétique + EA/ANT (L2, Z=5 : optimisme ↔ pessimisme) |
| 17 | `sympathie` (`Plaire_A`, Z=3) | `antipathie` (`Déplaire_A`, Z=3) | `D1` | #1 | `(+0.50,+0.50)` → `(-0.50,-0.50)` | `0.574` → `0.621` | `0.047` | `iso_energetic` | `EA+ANT` | Iso-énergétique + EA/ANT (D1, Z=3 : sympathie ↔ antipathie) |
| 18 | `goût` (`Goût`, Z=4) | `aversion` (`Aversion`, Z=4) | `D1` | #3 | `(+0.50,+0.50)` → `(-0.50,-0.50)` | `0.670` → `0.724` | `0.053` | `iso_energetic` | `ANT` | Iso-énergétique + ANT (D1, Z=4 : goût ↔ aversion) |
| 19 | `espoir` (`Espoir`, Z=5) | `épuisement` (`Mauvais moral`, Z=5) | `L1` | #1 | `(+0.82,+0.18)` → `(-0.34,-0.66)` | `0.678` → `0.697` | `0.019` | `iso_energetic` | `—` | Iso-énergétique (L1, Z=5 : espoir ↔ épuisement) |
| 20 | `terreur` (`Inquiéter Effrayer`, Z=3) | `plaisir` (`Jouissance`, Z=3) | `L2` | #1 | `(-0.88,-0.12)` → `(+0.45,+0.55)` | `0.940` → `0.834` | `0.106` | `iso_energetic` | `—` | Iso-énergétique (L2, Z=3 : terreur haut A ↔ plaisir haut A) |

---

## 4. Audit croisé DIMA vs CARTOGRAFFECT : typologie des divergences (`antagonism_audit_conflicts.csv`)

### 4.1 Répartition globale des 5 catégories analytiques

| Catégorie | Toutes paires DIMA (`Z_PLUS_ACTIVE`) | Part (%) | Paires `Entrées antonymes` | Part `EA` (%) | Interprétation géométrique & cognitive |
| :--- | ---: | ---: | ---: | ---: | :--- |
| `CONGRUENT_EXACT` | 498 | `15.2%` | 9 | `15.3%` | Même strate $Z$ et sous-secteurs conjugués exacts sous $\mathcal{A}$ |
| `CONGRUENT_CROSS_Z` | 623 | `19.0%` | 3 | `5.1%` | Sous-secteurs conjugués exacts sous $\mathcal{A}$, mais strates $Z$ différentes (ex. $Z=3$ réactif opposé à $Z=5$ dispositionnel) |
| `CENTRAL_VS_CONTRALATERAL` | 150 | `4.6%` | 1 | `1.7%` | DIMA oppose par symétrie centrale simple $(-X, -Y)$ sur latéraux sans permuter $|X| \leftrightarrow |Y|$ |
| `INTRA_SECTOR_OR_AROUSAL_CONTRAST` | 131 | `4.0%` | 8 | `13.6%` | Opposition lexicale d'intensité ou de mode dans un même quadrant ou macro-secteur d'axe dominant |
| `OTHER_FUNCTIONAL_DIVERGENCE` | 1,882 | `57.3%` | 38 | `64.4%` | Divergence structurale entre antonymie linguistique de surface et antagonisme fonctionnel en inférence active |
| **Total** | **3,284** | **`100.0%`** | **59** | **`100.0%`** | Congruents totaux (`EXACT + CROSS_Z`) : **`34.1%`** (`20.3%` sur `EA`) |

### 4.2 Macro-paires de classes DIMA par catégorie

#### `CONGRUENT_EXACT` (498 paires)

| Famille `ANTONYMIE` | Pôle A (`classe`, `subsector_id`, $Z$) | Pôle B (`classe`, `subsector_id`, $Z$) | Paires | Dont `EA` | Exemples |
| :--- | :--- | :--- | ---: | ---: | :--- |
| `Energie-Apathie` | `Apathie` (`lateralAversiveDistress`, Z=5) | `Energie` (`lateralEpistemicMastery`, Z=5) | 135 | 0 | `apathique`↔`dynamique`, `apathique`↔`exubérant` |
| `Goût-Aversion` | `Aversion` (`diagonalSynergyNeg`, Z=4) | `Goût` (`diagonalSynergyPos`, Z=4) | 132 | 0 | `hostile`↔`amateur`, `hostile`↔`amoureux` |
| `Plaire-Déplaire` | `Déplaire_A` (`diagonalSynergyNeg`, Z=3) | `Plaire_A` (`diagonalSynergyPos`, Z=3) | 54 | 1 | `antipathie`↔`attirance`, `antipathie`↔`attraction` |
| `Réjouir-Attrister` | `Attrister` (`axialControlNeg`, Z=3) | `Réjouir` (`axialControlPos`, Z=3) | 54 | 0 | `inconsolable`↔`joyeux`, `inconsolable`↔`jubilant` |
| `Confiance / Croyance & Défiance / Doute` | `Confiance` (`axialExpectationPos`, Z=5) | `Doute` (`axialExpectationNeg`, Z=5) | 27 | 0 | `confiant`↔`circonspect`, `confiant`↔`dubitatif` |
| `Confiance / Croyance & Défiance / Doute` | `Confiance_Sentiment de sécurité` (`lateralApproachSynergy`, Z=5) | `Défiance_Sentiment d'insécurité` (`lateralEpistemicClosure`, Z=5) | 24 | 2 | `optimiste`↔`pessimiste`, `optimiste`↔`soupçonneux` |
| `Amour / Affection-Haine / Désamour` | `Amour` (`diagonalSynergyPos`, Z=4) | `Amour désamour` (`diagonalSynergyNeg`, Z=4) | 18 | 1 | `amoureux`↔`désamour`, `fou`↔`désamour` |
| `Gratitude-Ressentiment` | `Gratitude` (`lateralReceptiveAccomm`, Z=4) | `Ressentiment` (`lateralAgenticConfront`, Z=4) | 18 | 0 | `reconnaissant`↔`acrimonieux`, `reconnaissant`↔`vindicatif` |
| `Orgueil / Honte / Pudeur` | `Honte` (`lateralAversiveDistress`, Z=4) | `Orgueil` (`lateralEpistemicMastery`, Z=4) | 14 | 0 | `honteux`↔`autosatisfait`, `honteux`↔`fier` |
| `Confiance / Croyance & Défiance / Doute` | `Confiance` (`axialExpectationPos`, Z=5) | `Défiance` (`axialExpectationNeg`, Z=5) | 9 | 3 | `confiant`↔`méfiant`, `confiant`↔`défiance` |
| `Rassurer-Inquiéter & Effrayer` | `Inquiéter` (`lateralEpistemicClosure`, Z=4) | `Rassurer` (`lateralApproachSynergy`, Z=4) | 7 | 0 | `angoisse`↔`insouciant`, `angoisse`↔`insoucieux` |
| `Amour / Affection-Haine / Désamour` | `Affection` (`diagonalSynergyPos`, Z=4) | `Amour désamour` (`diagonalSynergyNeg`, Z=4) | 5 | 1 | `affection`↔`désamour`, `amour`↔`désamour` |
| `Amour / Affection-Haine / Désamour || Goût-Aversion` | `Amour désamour` (`diagonalSynergyNeg`, Z=4) | `Goût` (`diagonalSynergyPos`, Z=4) | 1 | 1 | `désamour`↔`amour` |

#### `CONGRUENT_CROSS_Z` (623 paires)

| Famille `ANTONYMIE` | Pôle A (`classe`, `subsector_id`, $Z$) | Pôle B (`classe`, `subsector_id`, $Z$) | Paires | Dont `EA` | Exemples |
| :--- | :--- | :--- | ---: | ---: | :--- |
| `Désir / impatience & Absence de désir` | `Absence de désir` (`diagonalSynergyNeg`, Z=5) | `Désir` (`diagonalSynergyPos`, Z=3) | 459 | 3 | `désabusé`↔`ardent`, `désabusé`↔`avide` |
| `Désir / impatience & Absence de désir` | `Absence de désir` (`diagonalSynergyNeg`, Z=5) | `Désir impatience` (`diagonalSynergyPos`, Z=3) | 68 | 0 | `désabusé`↔`impatient`, `désabusé`↔`pressé` |
| `Rassurer-Inquiéter & Effrayer` | `Inquiéter Effrayer` (`lateralEpistemicClosure`, Z=3) | `Rassurer` (`lateralApproachSynergy`, Z=4) | 42 | 0 | `affres`↔`insouciant`, `affres`↔`insoucieux` |
| `Rassurer-Inquiéter & Effrayer` | `Inquiéter` (`lateralEpistemicClosure`, Z=3) | `Rassurer` (`lateralApproachSynergy`, Z=4) | 28 | 0 | `anxieux`↔`insouciant`, `anxieux`↔`insoucieux` |
| `Humeurs bonne-mauvaise-songeuse` | `Humeur bonne` (`axialControlPos`, Z=5) | `Humeur songeuse` (`axialControlNeg`, Z=4) | 26 | 0 | `allègre`↔`mélancolique`, `allègre`↔`mélancolie` |

#### `CENTRAL_VS_CONTRALATERAL` (150 paires)

| Famille `ANTONYMIE` | Pôle A (`classe`, `subsector_id`, $Z$) | Pôle B (`classe`, `subsector_id`, $Z$) | Paires | Dont `EA` | Exemples |
| :--- | :--- | :--- | ---: | ---: | :--- |
| `Bon moral-Mauvais moral` | `Bon moral` (`lateralApproachSynergy`, Z=5) | `Mauvais moral` (`lateralAversiveDistress`, Z=5) | 108 | 0 | `ivre`↔`dépressif`, `ivre`↔`abattement` |
| `Jouissance-Souffrance` | `Jouissance` (`lateralApproachSynergy`, Z=3) | `Souffrance` (`lateralAversiveDistress`, Z=3) | 21 | 1 | `délectation`↔`douleur`, `délectation`↔`déplaisir` |
| `Estime / Respect & Mésestime / Irrespect` | `Estime respect` (`lateralReceptiveAccomm`, Z=4) | `Mésestime` (`lateralActiveContest`, Z=4) | 12 | 0 | `respectueux`↔`dépréciation`, `respectueux`↔`dévalorisation` |
| `Admiration-Mépris` | `Admiration` (`lateralReceptiveAccomm`, Z=4) | `Mépris` (`lateralActiveContest`, Z=4) | 6 | 0 | `admiratif`↔`dédaigneux`, `admiratif`↔`dédain` |
| `Désinhiber-Inhiber / Embarrasser` | `Désinhiber` (`lateralEpistemicMastery`, Z=3) | `Inhiber` (`lateralEpistemicClosure`, Z=3) | 3 | 0 | `sans-gêne`↔`blocage`, `sans-gêne`↔`complexe` |

#### `INTRA_SECTOR_OR_AROUSAL_CONTRAST` (131 paires)

| Famille `ANTONYMIE` | Pôle A (`classe`, `subsector_id`, $Z$) | Pôle B (`classe`, `subsector_id`, $Z$) | Paires | Dont `EA` | Exemples |
| :--- | :--- | :--- | ---: | ---: | :--- |
| `Combler-Décevoir` | `Combler Bonheur` (`axialControlPos`, Z=3) | `Décevoir` (`lateralAgenticConfront`, Z=3) | 77 | 8 | `bienheureux`↔`amer`, `bienheureux`↔`insatisfait` |
| `Humeurs bonne-mauvaise-songeuse` | `Humeur mauvaise` (`lateralAversiveDistress`, Z=5) | `Humeur songeuse` (`lateralSecondaryAccomm`, Z=5) | 32 | 0 | `bougon`↔`méditatif`, `bougon`↔`pensif` |
| `Humeurs bonne-mauvaise-songeuse` | `Humeur mauvaise` (`lateralAversiveDistress`, Z=5) | `Humeur songeuse` (`axialControlNeg`, Z=4) | 16 | 0 | `bougon`↔`mélancolique`, `bougon`↔`mélancolie` |
| `Détendre-Importuner` | `Détendre` (`lateralSecondaryAccomm`, Z=3) | `Importuner` (`axialControlNeg`, Z=3) | 6 | 0 | `décontraction`↔`las`, `décontraction`↔`fatigue` |

#### `OTHER_FUNCTIONAL_DIVERGENCE` (1,882 paires)

| Famille `ANTONYMIE` | Pôle A (`classe`, `subsector_id`, $Z$) | Pôle B (`classe`, `subsector_id`, $Z$) | Paires | Dont `EA` | Exemples |
| :--- | :--- | :--- | ---: | ---: | :--- |
| `Amitié-Inimitié` | `Amitié` (`diagonalSynergyPos`, Z=4) | `Inimitié` (`lateralAgenticConfront`, Z=4) | 957 | 21 | `ami`↔`américanophobe`, `ami`↔`anglophobe` |
| `Curiosité-Désintérêt` | `Curiosité` (`axialExpectationPos`, Z=3) | `Désintérêt` (`diagonalSynergyNeg`, Z=5) | 112 | 4 | `attentif`↔`froid`, `attentif`↔`impassible` |
| `Humeurs bonne-mauvaise-songeuse` | `Humeur bonne` (`axialControlPos`, Z=5) | `Humeur mauvaise` (`lateralAversiveDistress`, Z=5) | 104 | 0 | `allègre`↔`bougon`, `allègre`↔`grincheux` |
| `Apaiser-Troubler` | `Apaiser` (`diagonalAccommodation`, Z=3) | `Troubler` (`lateralEpistemicClosure`, Z=3) | 77 | 0 | `calme`↔`éperdu`, `calme`↔`affolement` |
| `Amour / Affection-Haine / Désamour` | `Amour` (`diagonalSynergyPos`, Z=4) | `Haine de qq` (`diagonalAgenticConfront`, Z=4) | 72 | 0 | `amoureux`↔`aversion`, `amoureux`↔`détestation` |
| `Amitié-Inimitié` | `Amitié préférence` (`lateralEpistemicMastery`, Z=4) | `Inimitié` (`lateralAgenticConfront`, Z=4) | 66 | 0 | `prédilection`↔`américanophobe`, `prédilection`↔`anglophobe` |
| `Apaiser-Troubler` | `Apaiser` (`diagonalAccommodation`, Z=3) | `Troubler` (`axialExpectationNeg`, Z=3) | 55 | 0 | `calme`↔`perplexe`, `calme`↔`agitation` |
| `Humeurs bonne-mauvaise-songeuse` | `Humeur bonne` (`axialControlPos`, Z=5) | `Humeur songeuse` (`lateralSecondaryAccomm`, Z=5) | 52 | 0 | `allègre`↔`méditatif`, `allègre`↔`pensif` |
| `Rassurer-Inquiéter & Effrayer` | `Inquiéter` (`axialExpectationNeg`, Z=3) | `Rassurer` (`lateralApproachSynergy`, Z=4) | 42 | 2 | `inquiet`↔`insouciant`, `inquiet`↔`insoucieux` |
| `Confiance / Croyance & Défiance / Doute` | `Confiance_Sentiment de sécurité` (`lateralApproachSynergy`, Z=5) | `Doute` (`axialExpectationNeg`, Z=5) | 36 | 0 | `optimiste`↔`circonspect`, `optimiste`↔`dubitatif` |
| `Apaiser-Troubler` | `Apaiser` (`diagonalAccommodation`, Z=3) | `Troubler` (`centralOperator`, Z=3) | 33 | 0 | `calme`↔`dépaysement`, `calme`↔`saisissement` |
| `Combler-Décevoir` | `Combler Bonheur` (`axialControlPos`, Z=3) | `Décevoir` (`lateralAversiveDistress`, Z=3) | 33 | 0 | `bienheureux`↔`déception`, `bienheureux`↔`désappointement` |
| `Combler-Décevoir` | `Combler Bonheur` (`axialControlPos`, Z=3) | `Décevoir Malheur` (`lateralAversiveDistress`, Z=3) | 33 | 7 | `bienheureux`↔`malheureux`, `bienheureux`↔`mal-être` |
| `Résignation-Colère` | `Colère` (`diagonalAgenticConfront`, Z=3) | `Résignation` (`lateralAversiveDistress`, Z=4) | 22 | 0 | `enragé`↔`résignation`, `fumasse`↔`résignation` |
| `Résignation-Colère` | `Colère` (`diagonalAgenticConfront`, Z=3) | `Résignation` (`lateralAversiveDistress`, Z=5) | 22 | 0 | `enragé`↔`fatalisme`, `fumasse`↔`fatalisme` |
| `Résignation-Colère` | `Colère` (`diagonalAgenticConfront`, Z=3) | `Résignation` (`lateralReceptiveAccomm`, Z=4) | 22 | 0 | `enragé`↔`acceptation`, `fumasse`↔`acceptation` |
| `Amour / Affection-Haine / Désamour` | `Affection` (`diagonalSynergyPos`, Z=4) | `Haine de qq` (`diagonalAgenticConfront`, Z=4) | 20 | 0 | `affection`↔`aversion`, `affection`↔`détestation` |
| `Confiance / Croyance & Défiance / Doute` | `Confiance` (`axialExpectationPos`, Z=5) | `Défiance_Sentiment d'insécurité` (`lateralEpistemicClosure`, Z=5) | 18 | 0 | `confiant`↔`pessimiste`, `confiant`↔`soupçonneux` |
| `Confiance / Croyance & Défiance / Doute` | `Confiance_Sentiment de sécurité` (`lateralApproachSynergy`, Z=5) | `Défiance` (`axialExpectationNeg`, Z=5) | 12 | 0 | `optimiste`↔`méfiant`, `optimiste`↔`défiance` |
| `Combler-Décevoir` | `Combler Bonheur` (`axialControlPos`, Z=3) | `Décevoir` (`diagonalAgenticConfront`, Z=3) | 11 | 0 | `bienheureux`↔`contrariété`, `béat`↔`contrariété` |
| `Combler-Décevoir` | `Combler Bonheur` (`axialControlPos`, Z=3) | `Décevoir` (`lateralActiveContest`, Z=3) | 11 | 0 | `bienheureux`↔`dépit`, `béat`↔`dépit` |
| `Détendre-Importuner` | `Détendre` (`lateralSecondaryAccomm`, Z=3) | `Importuner` (`diagonalAgenticConfront`, Z=3) | 8 | 0 | `décontraction`↔`crispation`, `décontraction`↔`nervosité` |
| `Désinhiber-Inhiber / Embarrasser` | `Désinhiber` (`lateralEpistemicMastery`, Z=3) | `Embarrasser` (`diagonalSynergyNeg`, Z=3) | 7 | 1 | `sans-gêne`↔`confus`, `sans-gêne`↔`déconfit` |
| `Admiration-Mépris` | `Admiration` (`lateralApproachSynergy`, Z=4) | `Mépris` (`lateralActiveContest`, Z=4) | 6 | 0 | `extatique`↔`dédaigneux`, `extatique`↔`dédain` |
| `Espoir & Crainte / Désespérer de` | `Crainte` (`axialExpectationNeg`, Z=3) | `Espoir` (`lateralEpistemicMastery`, Z=5) | 6 | 0 | `craintif`↔`espoir`, `craintif`↔`espérance` |
| `Estime / Respect & Mésestime / Irrespect` | `Estime` (`lateralEpistemicMastery`, Z=4) | `Mésestime` (`lateralActiveContest`, Z=4) | 6 | 1 | `considération`↔`dépréciation`, `considération`↔`dévalorisation` |
| `Rassurer-Inquiéter & Effrayer` | `Inquiéter` (`axialExpectationNeg`, Z=3) | `Rassurer` (`diagonalAccommodation`, Z=3) | 6 | 0 | `inquiet`↔`soulagement`, `soucieux`↔`soulagement` |
| `Rassurer-Inquiéter & Effrayer` | `Inquiéter` (`axialExpectationNeg`, Z=3) | `Rassurer` (`diagonalAccommodation`, Z=4) | 6 | 0 | `inquiet`↔`quiétude`, `soucieux`↔`quiétude` |
| `Rassurer-Inquiéter & Effrayer` | `Inquiéter Effrayer` (`lateralEpistemicClosure`, Z=3) | `Rassurer` (`diagonalAccommodation`, Z=3) | 6 | 0 | `affres`↔`soulagement`, `détresse`↔`soulagement` |
| `Rassurer-Inquiéter & Effrayer` | `Inquiéter Effrayer` (`lateralEpistemicClosure`, Z=3) | `Rassurer` (`diagonalAccommodation`, Z=4) | 6 | 0 | `affres`↔`quiétude`, `détresse`↔`quiétude` |
| `Rassurer-Inquiéter & Effrayer` | `Inquiéter` (`lateralEpistemicClosure`, Z=3) | `Rassurer` (`diagonalAccommodation`, Z=3) | 4 | 0 | `anxieux`↔`soulagement`, `anxiété`↔`soulagement` |
| `Rassurer-Inquiéter & Effrayer` | `Inquiéter` (`lateralEpistemicClosure`, Z=3) | `Rassurer` (`diagonalAccommodation`, Z=4) | 4 | 0 | `anxieux`↔`quiétude`, `anxiété`↔`quiétude` |
| `Admiration-Mépris` | `Admiration` (`diagonalSynergyPos`, Z=4) | `Mépris` (`lateralActiveContest`, Z=4) | 3 | 0 | `fervent`↔`dédaigneux`, `fervent`↔`dédain` |
| `Curiosité-Désintérêt || Rassurer-Inquiéter & Effrayer` | `Désintérêt` (`diagonalSynergyNeg`, Z=5) | `Inquiéter` (`axialExpectationNeg`, Z=3) | 1 | 1 | `insouciance`↔`souci` |
| `None || Plaire-Déplaire` | `Compassion` (`lateralReceptiveAccomm`, Z=4) | `Déplaire_A` (`diagonalSynergyNeg`, Z=3) | 1 | 1 | `sympathie`↔`antipathie` |
| `Rassurer-Inquiéter & Effrayer` | `Inquiéter` (`lateralEpistemicClosure`, Z=4) | `Rassurer` (`diagonalAccommodation`, Z=3) | 1 | 0 | `angoisse`↔`soulagement` |
| `Rassurer-Inquiéter & Effrayer` | `Inquiéter` (`lateralEpistemicClosure`, Z=4) | `Rassurer` (`diagonalAccommodation`, Z=4) | 1 | 0 | `angoisse`↔`quiétude` |

### 4.3 Lecture épistémologique et clinique des divergences

1. **`CONGRUENT_EXACT` & `CONGRUENT_CROSS_Z` (congruence géométrique directe) :** Les oppositions lexicales symétriques en profondeur temporelle (`Energie`↔`Apathie` en L1, `Goût`↔`Aversion` en D1, `Plaire_A`↔`Déplaire_A` en D1, `Réjouir`↔`Attrister` en A2, `Confiance`↔`Défiance`/`Doute` en A1, `Gratitude`↔`Ressentiment` en L3, `Orgueil`↔`Honte` en L1) s'alignent exactement sur $\mathcal{A}$. Le régime `CONGRUENT_CROSS_Z` révèle que DIMA mélange parfois des strates temporelles distinctes dans une même famille antonymique : par exemple `Désir` ($Z=3$ réactif) y est opposé à `Absence de désir` ($Z=5$ dispositionnel), et `Inquiéter Effrayer` ($Z=3$) à `Rassurer` ($Z=4$).
2. **`CENTRAL_VS_CONTRALATERAL` (signature spécifique de l'échange $|X| \leftrightarrow |Y|$) :** Sur les positions latérales (`Bon moral`↔`Mauvais moral`, `Jouissance`↔`Souffrance`, `Admiration`↔`Mépris`, `Estime respect`↔`Mésestime`, `Désinhiber`↔`Inhiber`), le langage courant associe les contraires par inversion hédonique/centrale $(-X, -Y)$, alors que la dynamique prédictive impose de permuter la voie dominante ($|Y| > |X| \leftrightarrow |X| > |Y|$) afin d'équilibrer le biais d'allocation attentionnelle $(\pi_A, \pi_C)$ (`antagonistPoint_off_axis`).
3. **`INTRA_SECTOR_OR_AROUSAL_CONTRAST` :** Regroupe les contrastes lexicaux internes à un même domaine fonctionnel (`Humeur mauvaise` vs `Humeur songeuse` en $Y < 0$, ou `Combler Bonheur` vs `Décevoir` dans le macro-secteur `sectorControlPos` à $Y > |X|$ où la valence s'inverse par le signe de $X$ sans changer la dominance pragmatique).
4. **`OTHER_FUNCTIONAL_DIVERGENCE` (ex. `Résignation` vs `Colère` dans DIMA 2) :** En sémantique lexicale de surface, DIMA 2 regroupe sous `Résignation-Colère` la soumission résignée et la révolte colérique comme deux attitudes pragmatiques opposées face à l'adversité. En inférence active (Option 1A), la `Colère` occupe le quadrant d'affrontement agentique `Q2` $(-X, +Y)$ (non-révisabilité épistémique mais maintien d'un contrôle instrumental élevé), dont l'antagoniste régulateur exact est `diagonalAccommodation` `Q4` $(+X, -Y)$ (`Calme`, `Apaisement`). À l'inverse, la `Résignation` (`fatalisme`, `résignation`) relève de `Q3` `lateralAversiveDistress` $(-X, -Y)$ (faible contrôle perçu avec basse activation $A$), dont l'antagoniste est `lateralEpistemicMastery` `Q1` $(+X, +Y)$ (`Espoir`, `Fierté`, `Énergie`). De même, `Amitié` (`diagonalSynergyPos` `Q1`) est opposé par DIMA à `Inimitié` (`lateralAgenticConfront` `Q2`) et `Amour` (`Q1`) à `Haine de qq` (`Q2`) : DIMA privilégie l'axe relationnel positif/agressif (`Q1`↔`Q2`), alors que $\mathcal{A}$ inverse simultanément Attente et Contrôle (`Q1`↔`Q3` et `Q2`↔`Q4`).
