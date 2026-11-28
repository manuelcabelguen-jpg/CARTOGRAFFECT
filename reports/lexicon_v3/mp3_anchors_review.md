# Rapport de Revue Clinique — Micro-Passe 3 (FINALISÉE MP3b) : Ancrage des 109 classes DIMA vers $Z \in \{3, 4, 5\}$ et les 17 `FunctionalSubsector` (CARTOGRAFFECT v3.0.0)

- **Script :** [`python/lexicon_pipeline/03a_build_class_anchors_draft.py`](../../python/lexicon_pipeline/03a_build_class_anchors_draft.py) *(idempotent, zéro appel réseau)*
- **Statut de revue clinique :** `APPROVED` (`clinical_review_status: APPROVED`)
- **Périmètre Lean 4 :** `Cartograffect/` strictement en lecture seule (`0` fichier modifié)
- **Référentiel figé :** [`data/config/canonical_z0_z2_anchors.json`](../../data/config/canonical_z0_z2_anchors.json) (`SHA-256`: `5a291d6e8b4553bbf8131276796a1ac85e2a44025c4f4e7c5bfa69caeceb6935`)
- **Table d'ancrage approuvée :** [`data/config/dima_class_to_subsector_109.yaml`](../../data/config/dima_class_to_subsector_109.yaml) (`SHA-256`: `8273f6be72978a05cb3037b98776cee9164fc9768848827b5a887d5b7c6e25a4`)
- **Couverture DIMA :** `109` classes = `76` `active_z_plus` + `16` `satellite_only_z_plus` (`92` classes $Z_+$ couvrant `1,494` entrées = `549` `Z_PLUS_ACTIVE` + `945` `Z_PLUS_SATELLITE`, après reclassement des 4 métatermes `affect`, `affectivité`, `sentiment`, `émotion` de `Troubler` vers `NON_LEXICAL_DISCARD`/`META_CLASSIFIER`) + `17` `reserve_or_discard_only`
- **Règles `subclass_overrides` :** `8` classes hétérogènes découpées / `52` règles structurées par `SOUS-CLASSE`

### Empreintes SHA-256 des entrées lues en lecture seule

| Source | SHA-256 |
| :--- | :--- |
| `Cartograffect/CoreAffect.lean` | `6d76ad7677d9330bf6ca539ef85568e25c2561eff58e45fd3431e04d2dfdd8a6` |
| `Cartograffect/AffectiveMatrix.lean` | `9f0cac2742c6adc66d9191f329a2f5a7b4a46b5d81bf45a9d1d18eae3dfdb6cc` |
| `Cartograffect/AffectiveTaxonomy.lean` | `dfc9d28f7caf2e912f1a96db4601746f729012c1aa26bd2eea10933d76b11559` |
| `Cartograffect/OperantFactorization.lean` | `804ef00a77d120b0611b263764fcb5d467437814a8c23f31b3a24180d896f536` |
| `data/processed/dima_classes_summary.csv` | `8f20bc1b4616c73f00c510d5955ab0c4c905064e2df0179d6392ded0784a90be` |
| `data/processed/dima_z_plus_psychometrics.parquet` | `726b09a0b5b099084dc947c3da889bb499e2dad555c8a79317a029cbaf629453` |

---

## 1. Spécification figée du noyau Lean 4 v3.0.0

### 1.1 Les 11 états canoniques verrouillés sur $Z \in \{0, 1, 2\}$ et la bijection Rolls bornée à $Z = 2$

| Identifiant Lean 4 | Libellé | Coordonnée `(X, Y, Z)` | Géométrie | Sous-secteur | Valence | Antagoniste | Bijection Rolls ($Z=2$ uniquement) | Note |
| :--- | :--- | :---: | :---: | :--- | :---: | :--- | :--- | :--- |
| `CentralOperator.pointDeVeille` | Point de Veille | `(0, 0, 0)` | `central` | `centralOperator` | `neutral` | `pointDeVeille` | — | Centre basal |
| `CentralOperator.surprise` | Surprise | `(0, 0, 1)` | `central` | `centralOperator` | `neutral` | `surprise` | — | Rupture ascendante |
| `CentralOperator.anticipation` | Anticipation | `(0, 0, 2)` | `central` | `centralOperator` | `neutral` | `anticipation` | — | Suspension descendante R5 |
| `PrimaryCrownPrototype.joie` | Joie | `(0, 2, 2)` | `axial` | `axialControlPos` | `positive` | `tristesse` | — | — |
| `PrimaryCrownPrototype.tristesse` | Tristesse | `(0, -2, 2)` | `axial` | `axialControlNeg` | `negative` | `joie` | — | Instabilité axiale P2 (`χ > 0`) |
| `PrimaryCrownPrototype.peur` | Peur | `(-2, 0, 2)` | `axial` | `axialExpectationNeg` | `negative` | `courage` | — | Instabilité axiale P2 (`χ > 0`) |
| `PrimaryCrownPrototype.courage` | Courage | `(2, 0, 2)` | `axial` | `axialExpectationPos` | `positive` | `peur` | — | — |
| `PrimaryCrownPrototype.desir` | Désir | `(1, 1, 2)` | `diagonal` | `diagonalSynergyPos` | `positive` | `degout` | `Rew+` (S+) | — |
| `PrimaryCrownPrototype.degout` | Dégoût | `(-1, -1, 2)` | `diagonal` | `diagonalSynergyNeg` | `negative` | `desir` | `Pun+` (S−) | — |
| `PrimaryCrownPrototype.colere` | Colère | `(-1, 1, 2)` | `diagonal` | `diagonalAgenticConfront` | `negative` | `calme` | `Rew−` (¬S+) | — |
| `PrimaryCrownPrototype.calme` | Calme | `(1, -1, 2)` | `diagonal` | `diagonalAccommodation` | `positive` | `colere` | `Pun−` (¬S−) | — |

### 1.2 Les 3 opérateurs centraux de la taxonomie structurée ($Z \in \{3, 4, 5\}$)

| Constructeur Lean 4 | Libellé | Coordonnée | Rayon $R(Z)$ | Rôle |
| :--- | :--- | :---: | :---: | :--- |
| `CentralOperator.emoi` | **Émoi** | `(0, 0, 3)` | `4` | Z = 3 : Opérateur central des émotions réactives |
| `CentralOperator.reserve` | **Réserve** | `(0, 0, 4)` | `6` | Z = 4 : Opérateur central des sentiments réflexifs |
| `CentralOperator.recul` | **Recul** | `(0, 0, 5)` | `8` | Z = 5 : Opérateur central des orientations durables et humeurs |

### 1.3 Les 17 `FunctionalSubsector` (8 paires conjuguées + centre fixe) et vecteurs $L_1$

| Paire | Constructeur Lean 4 | Conjugué | $(u_X, u_Y)$ | $\|u\|_1$ | Valence | Repères Tableau 1b ($Z=3/4/5$) | Classes $Z_+$ |
| :---: | :--- | :--- | :---: | :---: | :---: | :--- | ---: |
| `CENTER` | `centralOperator` | `centralOperator` | `(+0.00, +0.00)` | `0.0` | `neutral` | Z3: Émoi (0, 0, 3)/Émoi (0, 0, 3) · Z4: Réserve (0, 0, 4)/Réserve (0, 0, 4) · Z5: Recul (0, 0, 5)/Recul (0, 0, 5) | 2 |
| `A2` | `axialControlPos` | `axialControlNeg` | `(+0.00, +1.00)` | `1.0` | `positive` | Z3: Allégresse/Contentement · Z4: Euphorie/Bien-être · Z5: Jubilation/Épanouissement | 4 |
| `A2` | `axialControlNeg` | `axialControlPos` | `(+0.00, -1.00)` | `1.0` | `negative` | Z3: Chagrin/Mélancolie · Z4: Affliction/Lassitude · Z5: Désolation/Abattement | 6 |
| `A1` | `axialExpectationPos` | `axialExpectationNeg` | `(+1.00, +0.00)` | `1.0` | `positive` | Z3: Audace/Curiosité · Z4: Détermination/Confiance · Z5: Conviction/Lucidité | 5 |
| `A1` | `axialExpectationNeg` | `axialExpectationPos` | `(-1.00, +0.00)` | `1.0` | `negative` | Z3: Frayeur/Inquiétude · Z4: Effroi/Méfiance · Z5: Épouvante/Insécurité | 7 |
| `D1` | `diagonalSynergyPos` | `diagonalSynergyNeg` | `(+0.50, +0.50)` | `1.0` | `positive` | Z3: Enthousiasme/Attrait · Z4: Passion/Affection · Z5: Amour/Attachement | 8 |
| `D1` | `diagonalSynergyNeg` | `diagonalSynergyPos` | `(-0.50, -0.50)` | `1.0` | `negative` | Z3: Révulsion/Malaise · Z4: Aversion/Écœurement · Z5: Répulsion/Rejet durable | 6 |
| `D2` | `diagonalAgenticConfront` | `diagonalAccommodation` | `(-0.50, +0.50)` | `1.0` | `negative` | Z3: Exaspération/Agacement · Z4: Rage/Contrariété · Z5: Haine/Rancœur | 3 |
| `D2` | `diagonalAccommodation` | `diagonalAgenticConfront` | `(+0.50, -0.50)` | `1.0` | `positive` | Z3: Délivrance/Apaisement · Z4: Soulagement/Quiétude · Z5: Sagesse apaisée/Paix intérieure | 3 |
| `L2` | `lateralApproachSynergy` | `lateralEpistemicClosure` | `(+0.25, +0.75)` | `1.0` | `positive` | Z3: Assurance/Plaisir paisible · Z4: Exaltation/Sérénité · Z5: Plénitude/Sécurité | 3 |
| `L3` | `lateralAgenticConfront` | `lateralReceptiveAccomm` | `(-0.25, +0.75)` | `1.0` | `negative` | Z3: Frustration/Opposition · Z4: Hostilité/Ressentiment · Z5: Révolte/Amertume | 2 |
| `L4` | `lateralSecondaryAccomm` | `lateralActiveContest` | `(+0.25, -0.75)` | `1.0` | `positive` | Z3: Répit vif/Relâchement · Z4: Détachement/Lâcher-prise · Z5: Recul serein/Abandon confiant | 2 |
| `L1` | `lateralAversiveDistress` | `lateralEpistemicMastery` | `(-0.25, -0.75)` | `1.0` | `negative` | Z3: Déception vive/Découragement · Z4: Honte/Résignation · Z5: Désespoir/Apathie | 14 |
| `L1` | `lateralEpistemicMastery` | `lateralAversiveDistress` | `(+0.75, +0.25)` | `1.0` | `positive` | Z3: Élan/Satisfaction · Z4: Fierté/Estime · Z5: Optimisme actif/Espoir | 9 |
| `L3` | `lateralReceptiveAccomm` | `lateralAgenticConfront` | `(+0.75, -0.25)` | `1.0` | `positive` | Z3: Résilience vive/Acceptation · Z4: Endurance active/Patience · Z5: Stoïcisme/Consentement lucide | 6 |
| `L4` | `lateralActiveContest` | `lateralSecondaryAccomm` | `(-0.75, +0.25)` | `1.0` | `negative` | Z3: Contestation/Dépit · Z4: Indignation/Mépris froid · Z5: Défiance combative/Cynisme | 5 |
| `L2` | `lateralEpistemicClosure` | `lateralApproachSynergy` | `(-0.75, -0.25)` | `1.0` | `negative` | Z3: Alarme/Anxiété · Z4: Angoisse/Appréhension diffuse · Z5: Terreur/Tourment | 7 |

---

## 2. Table complète des 92 classes $Z_+$ regroupées par `FunctionalSubsector`

### `centralOperator` (`CENTER` · `u = (+0.00, +0.00)` · 2 classes)

| Classe DIMA | Cat. | Portée | $Z$ | `ACT` / `SAT` | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Exemples de lemmes (3–5) | Drapeaux |
| :--- | :---: | :--- | :---: | :---: | ---: | ---: | ---: | :--- | :--- |
| `Surprendre` | I | `ACT` | 3 | 10/17 | `-0.04` | `+0.37` | `-0.10` | `interdit`, `pantelant`, `pantois`, `stupéfait`, `abasourdissement` | `link:surprise_z1` `SPLIT` `z6_z7_effraction_candidate` |
| `Troubler` | I | `ACT` | 3 | 15/27 | `-0.54` | `+0.51` | `-0.08` | `perplexe`, `éperdu`, `affolement`, `agitation`, `confusion` | `link:emoi_z3` `OVR:14` `z6_z7_effraction_candidate` |

### `axialControlPos` (`A2` · `u = (+0.00, +1.00)` · 4 classes)

| Classe DIMA | Cat. | Portée | $Z$ | `ACT` / `SAT` | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Exemples de lemmes (3–5) | Drapeaux |
| :--- | :---: | :--- | :---: | :---: | ---: | ---: | ---: | :--- | :--- |
| `Amuser` | I | `SAT_ONLY` | 3 | 0/2 | `+0.77` | `+0.41` | `+0.04` | `ne pas s'embêter`, `ne pas s'ennuyer` | — |
| `Combler Bonheur` | I | `ACT` | 3 | 11/17 | `+0.80` | `+0.10` | `-0.00` | `bienheureux`, `béat`, `content`, `heureux`, `satisfait` | `SPLIT` `z7_transcendental_candidate` |
| `Réjouir` | I | `ACT` | 3 | 6/13 | `+0.92` | `+0.68` | `+0.07` | `joyeux`, `jubilant`, `exultation`, `joie`, `jubilation` | `SPLIT` |
| `Humeur bonne` | I | `ACT` | 5 | 13/3 | `+0.80` | `+0.42` | `-0.13` | `allègre`, `badin`, `enjoué`, `euphorique`, `folâtre` | — |

### `axialControlNeg` (`A2` · `u = (+0.00, -1.00)` · 6 classes)

| Classe DIMA | Cat. | Portée | $Z$ | `ACT` / `SAT` | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Exemples de lemmes (3–5) | Drapeaux |
| :--- | :---: | :--- | :---: | :---: | ---: | ---: | ---: | :--- | :--- |
| `Attrister` | I | `ACT` | 3 | 9/10 | `-0.71` | `-0.25` | `-0.19` | `inconsolable`, `inconsolé`, `triste`, `éploré`, `affliction` | `SPLIT` |
| `Ennuyer` | I | `ACT` | 3 | 1/2 | `-0.53` | `-0.26` | `-0.19` | `ennui` | `SPLIT` |
| `Déplorer` | II | `ACT` | 4 | 1/2 | `-0.59` | `+0.22` | `-0.12` | `regret` | — |
| `Nostalgie` | II | `ACT` | 4 | 3/3 | `-0.28` | `-0.14` | `-0.27` | `nostalgique`, `nostalgie`, `regret` | `SPLIT` |
| `Regretter qq` | II | `SAT_ONLY` | 4 | 0/2 | `-0.41` | `-0.07` | `-0.12` | `en deuil`, `ennuyer` | — |
| `Regretter qqc ou qq` | II | `SAT_ONLY` | 4 | 0/2 | `-0.72` | `+0.24` | `-0.19` | `pleurer`, `regretter` | — |

### `axialExpectationPos` (`A1` · `u = (+1.00, +0.00)` · 5 classes)

| Classe DIMA | Cat. | Portée | $Z$ | `ACT` / `SAT` | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Exemples de lemmes (3–5) | Drapeaux |
| :--- | :---: | :--- | :---: | :---: | ---: | ---: | ---: | :--- | :--- |
| `Surprendre Bonne surprise` | I | `SAT_ONLY` | 3 | 0/2 | `+0.72` | `+0.77` | `-0.10` | `agréablement surpris`, `épatement` | `link:surprise_z1` |
| `Curiosité` | II | `ACT` | 3 | 8/8 | `+0.16` | `+0.27` | `-0.16` | `attentif`, `curieux`, `sensible`, `soucieux`, `curiosité` | `SPLIT` |
| `Confiance` | II | `ACT` | 5 | 3/18 | `+0.66` | `-0.27` | `+0.12` | `confiant`, `confiance`, `foi` | `SPLIT` `z7_transcendental_candidate` |
| `Croyance` | II | `ACT` | 5 | 1/1 | `+0.05` | `-0.32` | `-0.04` | `croyance` | `SPLIT` `zm:move_to_z_minus_reserve` |
| `Croyance relig` | II | `ACT` | 5 | 1/4 | `+0.67` | `-0.56` | `+0.15` | `foi` | `SPLIT` `zm:move_to_z_minus_reserve` `z7_transcendental_candidate` |

### `axialExpectationNeg` (`A1` · `u = (-1.00, +0.00)` · 7 classes)

| Classe DIMA | Cat. | Portée | $Z$ | `ACT` / `SAT` | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Exemples de lemmes (3–5) | Drapeaux |
| :--- | :---: | :--- | :---: | :---: | ---: | ---: | ---: | :--- | :--- |
| `Surprendre Mauvaise surprise` | I | `SAT_ONLY` | 3 | 0/1 | `-0.67` | `+0.47` | `+0.01` | `désagréablement surpris` | `link:surprise_z1` |
| `Crainte` | II | `ACT` | 3 | 3/3 | `-0.55` | `+0.18` | `-0.07` | `craintif`, `appréhension`, `crainte` | `SPLIT` |
| `Peur` | II | `ACT` | 3 | 2/64 | `-0.64` | `+0.48` | `-0.08` | `apeurement`, `peur` | — |
| `Doute` | II | `ACT` | 5 | 9/3 | `-0.25` | `-0.07` | `-0.03` | `circonspect`, `dubitatif`, `prudent`, `réservé`, `sceptique` | `SPLIT` |
| `Défiance` | II | `ACT` | 5 | 3/3 | `-0.81` | `+0.00` | `-0.07` | `méfiant`, `défiance`, `méfiance` | `SPLIT` |
| `Incrédulité` | II | `ACT` | 5 | 2/0 | `-0.42` | `+0.34` | `-0.24` | `incrédule`, `incrédulité` | `SPLIT` `zm:move_to_z_minus_reserve` |
| `Incrédulité relig` | II | `ACT` | 5 | 2/0 | `-0.57` | `-0.09` | `-0.06` | `incroyant`, `incroyance` | `SPLIT` `zm:move_to_z_minus_reserve` |

### `diagonalSynergyPos` (`D1` · `u = (+0.50, +0.50)` · 8 classes)

| Classe DIMA | Cat. | Portée | $Z$ | `ACT` / `SAT` | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Exemples de lemmes (3–5) | Drapeaux |
| :--- | :---: | :--- | :---: | :---: | ---: | ---: | ---: | :--- | :--- |
| `Désir` | II | `ACT` | 3 | 27/19 | `+0.08` | `+0.47` | `+0.08` | `ardent`, `avide`, `compulsif`, `désireux`, `frénétique` | `SPLIT` |
| `Désir impatience` | II | `ACT` | 3 | 4/10 | `-0.39` | `+0.52` | `-0.01` | `impatient`, `pressé`, `hâte`, `impatience` | `SPLIT` |
| `Intéresser_A` | II | `ACT` | 3 | 6/4 | `+0.58` | `+0.47` | `+0.07` | `enthousiaste`, `passionné`, `enthousiasme`, `intérêt`, `passion` | `SPLIT` |
| `Plaire_A` | II | `ACT` | 3 | 6/4 | `+0.64` | `+0.47` | `+0.01` | `attirance`, `attraction`, `attrait`, `envoûtement`, `excitation` | — |
| `Affection` | II | `ACT` | 4 | 5/17 | `+0.59` | `-0.04` | `-0.24` | `affection`, `amour`, `attachement`, `attendrissement`, `tendresse` | `SPLIT` |
| `Amitié` | II | `ACT` | 4 | 29/25 | `+0.63` | `-0.04` | `-0.06` | `ami`, `américanophile`, `anglophile`, `bienveillant`, `complaisant` | `SPLIT` |
| `Amour` | II | `ACT` | 4 | 18/53 | `+0.30` | `+0.23` | `-0.09` | `amoureux`, `fou`, `épris`, `amour`, `amour-passion` | `SPLIT` `z6_z7_transcendence_candidate` |
| `Goût` | II | `ACT` | 4 | 12/33 | `+0.26` | `+0.17` | `-0.06` | `amateur`, `amoureux`, `enclin`, `jaloux`, `épris` | `SPLIT` |

### `diagonalSynergyNeg` (`D1` · `u = (-0.50, -0.50)` · 6 classes)

| Classe DIMA | Cat. | Portée | $Z$ | `ACT` / `SAT` | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Exemples de lemmes (3–5) | Drapeaux |
| :--- | :---: | :--- | :---: | :---: | ---: | ---: | ---: | :--- | :--- |
| `Embarrasser` | I | `ACT` | 3 | 7/2 | `-0.59` | `+0.14` | `-0.26` | `confus`, `déconfit`, `penaud`, `confusion`, `embarras` | `SPLIT` |
| `Déplaire_A` | II | `ACT` | 3 | 9/6 | `-0.71` | `+0.40` | `-0.02` | `antipathie`, `dégoût`, `haut-le-cœur`, `horreur`, `nausée` | `SPLIT` |
| `Amour désamour` | II | `ACT` | 4 | 1/2 | `-0.67` | `-0.57` | `-0.27` | `désamour` | `SPLIT` |
| `Aversion` | II | `ACT` | 4 | 11/16 | `-0.65` | `+0.46` | `+0.09` | `hostile`, `rebelle`, `réfractaire`, `rétif`, `aversion` | `SPLIT` |
| `Absence de désir` | II | `ACT` | 5 | 17/22 | `-0.40` | `-0.30` | `-0.13` | `désabusé`, `désenchanté`, `détaché`, `las`, `repu` | `SPLIT` |
| `Désintérêt` | II | `ACT` | 5 | 14/38 | `-0.31` | `-0.44` | `-0.23` | `froid`, `impassible`, `indifférent`, `insensible`, `insouciant` | `SPLIT` |

### `diagonalAgenticConfront` (`D2` · `u = (-0.50, +0.50)` · 3 classes)

| Classe DIMA | Cat. | Portée | $Z$ | `ACT` / `SAT` | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Exemples de lemmes (3–5) | Drapeaux |
| :--- | :---: | :--- | :---: | :---: | ---: | ---: | ---: | :--- | :--- |
| `Importuner` | I | `ACT` | 3 | 7/18 | `-0.58` | `+0.23` | `-0.08` | `las`, `crispation`, `fatigue`, `lassitude`, `nervosité` | `OVR:5` |
| `Colère` | II | `ACT` | 3 | 22/44 | `-0.65` | `+0.67` | `+0.23` | `enragé`, `fumasse`, `furibond`, `furieux`, `hargneux` | `SPLIT` |
| `Haine de qq` | II | `ACT` | 4 | 4/28 | `-0.77` | `+0.40` | `+0.12` | `aversion`, `détestation`, `exécration`, `haine` | `SPLIT` |

### `diagonalAccommodation` (`D2` · `u = (+0.50, -0.50)` · 3 classes)

| Classe DIMA | Cat. | Portée | $Z$ | `ACT` / `SAT` | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Exemples de lemmes (3–5) | Drapeaux |
| :--- | :---: | :--- | :---: | :---: | ---: | ---: | ---: | :--- | :--- |
| `Apaiser` | I | `ACT` | 3 | 11/7 | `+0.42` | `-0.68` | `-0.24` | `calme`, `impassible`, `imperturbable`, `inébranlable`, `paisible` | `SPLIT` |
| `Rassurer` | I | `ACT` | 3 | 9/5 | `+0.58` | `-0.63` | `-0.29` | `insouciant`, `insoucieux`, `serein`, `tranquille`, `insouciance` | `OVR:5` |
| `Bonne conscience` | II | `SAT_ONLY` | 4 | 0/11 | `+0.57` | `-0.65` | `-0.09` | `en paix avec sa conscience`, `en paix avec soi-même`, `en règle avec sa conscience`, `bonne conscience`, `avoir bonne conscience` | `SPLIT` |

### `lateralApproachSynergy` (`L2` · `u = (+0.25, +0.75)` · 3 classes)

| Classe DIMA | Cat. | Portée | $Z$ | `ACT` / `SAT` | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Exemples de lemmes (3–5) | Drapeaux |
| :--- | :---: | :--- | :---: | :---: | ---: | ---: | ---: | :--- | :--- |
| `Jouissance` | I | `ACT` | 3 | 7/5 | `+0.83` | `+0.31` | `-0.09` | `délectation`, `jouissance`, `orgasme`, `plaisir`, `réconfort` | `SPLIT` |
| `Bon moral` | I | `ACT` | 5 | 9/9 | `+0.12` | `+0.67` | `+0.03` | `ivre`, `enivrement`, `exaltation`, `excitation`, `griserie` | `SPLIT` |
| `Confiance_Sentiment de sécurité` | II | `ACT` | 5 | 4/6 | `+0.68` | `-0.04` | `+0.15` | `optimiste`, `sûr`, `assurance`, `optimisme` | `SPLIT` |

### `lateralAgenticConfront` (`L3` · `u = (-0.25, +0.75)` · 2 classes)

| Classe DIMA | Cat. | Portée | $Z$ | `ACT` / `SAT` | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Exemples de lemmes (3–5) | Drapeaux |
| :--- | :---: | :--- | :---: | :---: | ---: | ---: | ---: | :--- | :--- |
| `Inimitié` | II | `ACT` | 4 | 33/14 | `-0.73` | `+0.37` | `+0.28` | `américanophobe`, `anglophobe`, `anticlérical`, `antisémite`, `ennemi` | `SPLIT` |
| `Ressentiment` | II | `ACT` | 4 | 6/17 | `-0.71` | `+0.41` | `+0.10` | `acrimonieux`, `vindicatif`, `aigreur`, `rancune`, `rancœur` | `SPLIT` |

### `lateralSecondaryAccomm` (`L4` · `u = (+0.25, -0.75)` · 2 classes)

| Classe DIMA | Cat. | Portée | $Z$ | `ACT` / `SAT` | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Exemples de lemmes (3–5) | Drapeaux |
| :--- | :---: | :--- | :---: | :---: | ---: | ---: | ---: | :--- | :--- |
| `Détendre` | I | `ACT` | 3 | 2/1 | `+0.70` | `-0.54` | `-0.50` | `décontraction`, `repos` | — |
| `Humeur songeuse` | I | `ACT` | 5 | 6/0 | `-0.03` | `-0.52` | `-0.15` | `méditatif`, `mélancolique`, `pensif`, `rêveur`, `songeur` | `link:recul_z5` `OVR:5` |

### `lateralAversiveDistress` (`L1` · `u = (-0.25, -0.75)` · 14 classes)

| Classe DIMA | Cat. | Portée | $Z$ | `ACT` / `SAT` | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Exemples de lemmes (3–5) | Drapeaux |
| :--- | :---: | :--- | :---: | :---: | ---: | ---: | ---: | :--- | :--- |
| `Décevoir` | I | `ACT` | 3 | 12/11 | `-0.71` | `+0.09` | `-0.12` | `amer`, `insatisfait`, `mécontent`, `amertume`, `contrariété` | `OVR:9` |
| `Décevoir Malheur` | I | `ACT` | 3 | 3/16 | `-0.77` | `+0.17` | `-0.06` | `malheureux`, `mal-être`, `malheur` | `SPLIT` |
| `Souffrance` | I | `ACT` | 3 | 3/21 | `-0.71` | `+0.10` | `-0.10` | `douleur`, `déplaisir`, `souffrance` | `SPLIT` |
| `Doute de soi` | II | `SAT_ONLY` | 4 | 0/1 | `-0.21` | `-0.30` | `-0.36` | `douter de soi` | — |
| `Honte` | II | `ACT` | 4 | 2/17 | `-0.78` | `+0.26` | `-0.25` | `honteux`, `honte` | — |
| `Honte de soi` | II | `SAT_ONLY` | 4 | 0/3 | `-0.80` | `+0.15` | `-0.14` | `pas content de soi`, `pas fier de soi`, `avoir honte de soi` | — |
| `Manque de confiance en soi` | II | `SAT_ONLY` | 4 | 0/2 | `-0.81` | `+0.29` | `-0.01` | `manque de confiance en soi`, `manquer de confiance en soi` | — |
| `Mauvaise conscience` | II | `ACT` | 4 | 9/19 | `-0.35` | `+0.08` | `-0.16` | `contrit`, `repentant`, `résipiscent`, `contrition`, `regret` | `SPLIT` `zm:keep_z_plus` |
| `Mésestime de soi` | II | `SAT_ONLY` | 4 | 0/1 | `-0.17` | `-0.07` | `-0.43` | `se sous-estimer` | — |
| `Apathie` | I | `ACT` | 5 | 9/16 | `-0.62` | `-0.47` | `-0.21` | `apathique`, `morne`, `prostré`, `alanguissement`, `apathie` | `SPLIT` |
| `Humeur mauvaise` | I | `ACT` | 5 | 8/11 | `-0.60` | `+0.17` | `-0.01` | `bougon`, `grincheux`, `grognon`, `maussade`, `morose` | `SPLIT` |
| `Mauvais moral` | I | `ACT` | 5 | 12/15 | `-0.72` | `+0.07` | `-0.13` | `dépressif`, `abattement`, `accablement`, `anéantissement`, `atterrement` | `SPLIT` `z6_z7_effraction_candidate` |
| `Désespérer de` | II | `SAT_ONLY` | 5 | 0/7 | `-0.77` | `+0.59` | `-0.17` | `abandonner tout espoir`, `abandonner toute espérance`, `désespérer`, `perdre espoir`, `perdre l'espoir` | — |
| `Résignation` | II | `ACT` | 5 | 3/7 | `-0.21` | `-0.08` | `+0.13` | `acceptation`, `fatalisme`, `résignation` | `OVR:3` |

### `lateralEpistemicMastery` (`L1` · `u = (+0.75, +0.25)` · 9 classes)

| Classe DIMA | Cat. | Portée | $Z$ | `ACT` / `SAT` | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Exemples de lemmes (3–5) | Drapeaux |
| :--- | :---: | :--- | :---: | :---: | ---: | ---: | ---: | :--- | :--- |
| `Désinhiber` | I | `ACT` | 3 | 1/10 | `-0.45` | `+0.43` | `-0.03` | `sans-gêne` | `SPLIT` |
| `Amitié préférence` | II | `ACT` | 4 | 2/2 | `+0.46` | `+0.03` | `+0.11` | `prédilection`, `préférence` | — |
| `Apprécier` | II | `SAT_ONLY` | 4 | 0/1 | `+0.77` | `-0.16` | `+0.09` | `apprécier` | — |
| `Confiance en soi` | II | `SAT_ONLY` | 4 | 0/3 | `+0.62` | `+0.33` | `+0.23` | `confiance en soi`, `avoir confiance en soi`, `croire en soi` | — |
| `Estime` | II | `ACT` | 4 | 2/6 | `+0.33` | `-0.24` | `+0.13` | `considération`, `estime` | — |
| `Orgueil` | II | `ACT` | 4 | 7/27 | `+0.27` | `+0.25` | `+0.25` | `autosatisfait`, `fier`, `orgueilleux`, `amour-propre`, `autosatisfaction` | `SPLIT` |
| `Orgueil surestimation de soi` | II | `SAT_ONLY` | 4 | 0/13 | `-0.57` | `+0.62` | `+0.46` | `surestimation de soi`, `avoir la grosse tête`, `avoir les chevilles qui enflent`, `croire que c'est arrivé`, `ne pas moucher du coude` | `SPLIT` |
| `Energie` | I | `ACT` | 5 | 15/3 | `+0.61` | `+0.63` | `+0.17` | `dynamique`, `exubérant`, `fougueux`, `fringant`, `pétulant` | `SPLIT` |
| `Espoir` | II | `ACT` | 5 | 2/7 | `+0.62` | `+0.11` | `+0.06` | `espoir`, `espérance` | — |

### `lateralReceptiveAccomm` (`L3` · `u = (+0.75, -0.25)` · 6 classes)

| Classe DIMA | Cat. | Portée | $Z$ | `ACT` / `SAT` | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Exemples de lemmes (3–5) | Drapeaux |
| :--- | :---: | :--- | :---: | :---: | ---: | ---: | ---: | :--- | :--- |
| `Plaire_B` | II | `SAT_ONLY` | 3 | 0/2 | `-0.44` | `+0.22` | `-0.08` | `subjugation`, `être sous le charme` | `SPLIT` |
| `Admiration` | II | `ACT` | 4 | 5/13 | `+0.66` | `+0.39` | `+0.07` | `admiratif`, `extatique`, `fervent`, `admiration`, `extase` | `OVR:3` `z7_transcendental_candidate` |
| `Compassion` | II | `ACT` | 4 | 10/7 | `+0.21` | `-0.29` | `-0.26` | `compatissant`, `miséricordieux`, `apitoiement`, `attendrissement`, `commisération` | `SPLIT` |
| `Estime respect` | II | `ACT` | 4 | 4/7 | `+0.65` | `-0.18` | `+0.08` | `respectueux`, `crainte`, `respect`, `vénération` | `SPLIT` `zm:keep_z_plus` |
| `Gratitude` | II | `ACT` | 4 | 3/5 | `+0.82` | `-0.18` | `-0.14` | `reconnaissant`, `gratitude`, `reconnaissance` | `SPLIT` `zm:keep_z_plus` |
| `Pudeur` | II | `ACT` | 4 | 1/0 | `+0.56` | `-0.52` | `-0.20` | `pudeur` | `SPLIT` `zm:move_to_z_minus_reserve` |

### `lateralActiveContest` (`L4` · `u = (-0.75, +0.25)` · 5 classes)

| Classe DIMA | Cat. | Portée | $Z$ | `ACT` / `SAT` | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Exemples de lemmes (3–5) | Drapeaux |
| :--- | :---: | :--- | :---: | :---: | ---: | ---: | ---: | :--- | :--- |
| `Blesser` | I | `SAT_ONLY` | 3 | 0/3 | `-0.71` | `+0.54` | `-0.05` | `prendre ombrage`, `se formaliser`, `se sentir agressé` | `SPLIT` |
| `Jalousie envie` | II | `ACT` | 4 | 4/4 | `-0.61` | `+0.46` | `+0.02` | `envieux`, `jaloux`, `envie`, `jalousie` | `SPLIT` |
| `Jalousie sexuelle` | II | `ACT` | 4 | 2/0 | `-0.58` | `+0.47` | `+0.04` | `jaloux`, `jalousie` | — |
| `Mépris` | II | `ACT` | 4 | 3/8 | `-0.70` | `+0.04` | `-0.02` | `dédaigneux`, `dédain`, `mépris` | — |
| `Mésestime` | II | `ACT` | 4 | 3/11 | `-0.70` | `-0.36` | `-0.13` | `dépréciation`, `dévalorisation`, `sous-estimation` | `SPLIT` |

### `lateralEpistemicClosure` (`L2` · `u = (-0.75, -0.25)` · 7 classes)

| Classe DIMA | Cat. | Portée | $Z$ | `ACT` / `SAT` | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Exemples de lemmes (3–5) | Drapeaux |
| :--- | :---: | :--- | :---: | :---: | ---: | ---: | ---: | :--- | :--- |
| `Inhiber` | I | `ACT` | 3 | 3/0 | `-0.59` | `+0.10` | `+0.06` | `blocage`, `complexe`, `inhibition` | `SPLIT` |
| `Inquiéter` | I | `ACT` | 3 | 11/22 | `-0.61` | `+0.56` | `-0.07` | `anxieux`, `inquiet`, `soucieux`, `angoisse`, `anxiété` | `OVR:8` |
| `Inquiéter Effrayer` | I | `ACT` | 3 | 6/9 | `-0.74` | `+0.64` | `-0.05` | `affres`, `détresse`, `effroi`, `frayeur`, `terreur` | `SPLIT` `z6_z7_effraction_candidate` |
| `Peur panique` | II | `ACT` | 3 | 1/2 | `-0.88` | `+0.88` | `+0.08` | `panique` | `z6_z7_effraction_candidate` |
| `Mauvaise conscience scrupule` | II | `ACT` | 4 | 1/2 | `-0.33` | `-0.57` | `-0.20` | `scrupule` | `zm:keep_z_plus` |
| `Défiance_Sentiment d'insécurité` | II | `ACT` | 5 | 6/8 | `-0.70` | `+0.26` | `-0.04` | `pessimiste`, `soupçonneux`, `suspicieux`, `pessimisme`, `soupçon` | `SPLIT` |
| `Peur phobie` | II | `ACT` | 5 | 7/0 | `-0.80` | `+0.16` | `-0.11` | `agoraphobe`, `claustrophobe`, `zoophobe`, `agoraphobie`, `claustrophobie` | `SPLIT` |

---

## 3. Matrice de vérification des jalons du Tableau 1b v3.0.0

- **Jalons Tableau 1b vérifiés dans `Z_PLUS_ACTIVE` :** `78` (`66` `EXACT_MATCH` dont `16` résolus via `subclass_overrides`, `12` `SPLIT_FLAGGED` résiduels pour découpage ultérieur, `0` `ADJACENT_RAY`).
- **Note sur `Z_PLUS_SATELLITE` :** `sentiment de sécurité` (`Confiance_Sentiment de sécurité`, $V=+0.67, A=-0.28, D=+0.23$) et `sentiment d'insécurité` (`Défiance_Sentiment d'insécurité`, $V=-0.81, A=+0.29, D=-0.01$) sont présents en `Z_PLUS_SATELLITE` (locutions multi-mots) et alignés sur leurs classes respectives.
- **Note sur les jalons absents de DIMA `ExpAffect` :** `courage`, `plénitude`, `émerveillement` sont conservés dans `data/config/fr_en_bridge_overrides.csv` comme ancres théoriques hors DIMA v35.

| Jalon (`lemme_norm`) | $Z_{\text{T1b}}$ | Sous-secteur Tableau 1b | Classe DIMA | `SOUS-CLASSE` | Sous-secteur assigné | $Z_{\text{eff}}$ | Override | $\|\Delta u\|_1$ | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Statut |
| :--- | :---: | :--- | :--- | :--- | :--- | :---: | :---: | :---: | ---: | ---: | ---: | :--- |
| `peur` | 2 | `axialExpectationNeg` | `Peur` | `peur` | `axialExpectationNeg` | 3 | — | `0.00` | `-0.42` | `+0.27` | `-0.08` | `EXACT_MATCH` |
| `joie` | 2 | `axialControlPos` | `Réjouir` | `joie` | `axialControlPos` | 3 | — | `0.00` | `+0.86` | `+0.50` | `+0.11` | `EXACT_MATCH` |
| `tristesse` | 2 | `axialControlNeg` | `Attrister` | `tristesse` | `axialControlNeg` | 3 | — | `0.00` | `-0.64` | `+0.06` | `-0.26` | `EXACT_MATCH` |
| `désir` | 2 | `diagonalSynergyPos` | `Désir` | `désirer` | `diagonalSynergyPos` | 3 | — | `0.00` | `+0.79` | `+0.38` | `-0.06` | `EXACT_MATCH` |
| `dégoût` | 2 | `diagonalSynergyNeg` | `Déplaire_A` | `dégoût` | `diagonalSynergyNeg` | 3 | — | `0.00` | `-0.90` | `+0.55` | `-0.03` | `EXACT_MATCH` |
| `colère` | 2 | `diagonalAgenticConfront` | `Colère` | `colère` | `diagonalAgenticConfront` | 3 | — | `0.00` | `-0.48` | `+0.24` | `+0.40` | `EXACT_MATCH` |
| `calme` | 2 | `diagonalAccommodation` | `Apaiser` | `calmer` | `diagonalAccommodation` | 3 | — | `0.00` | `+0.57` | `-0.39` | `-0.48` | `EXACT_MATCH` |
| `curiosité` | 3 | `axialExpectationPos` | `Curiosité` | `curieux` | `axialExpectationPos` | 3 | — | `0.00` | `+0.50` | `+0.51` | `-0.24` | `EXACT_MATCH` |
| `frayeur` | 3 | `axialExpectationNeg` | `Inquiéter Effrayer` | `effrayer` | `lateralEpistemicClosure` | 3 | — | `0.50` | `-0.65` | `+0.63` | `-0.29` | `SPLIT_FLAGGED` |
| `inquiétude` | 3 | `axialExpectationNeg` | `Inquiéter` | `inquiéter` | `axialExpectationNeg` | 3 | `OVR` | `0.00` | `-0.51` | `+0.55` | `-0.22` | `EXACT_MATCH` |
| `confiance` | 4 | `axialExpectationPos` | `Confiance` | `confiance` | `axialExpectationPos` | 5 | — | `0.00` | `+0.78` | `+0.09` | `+0.09` | `EXACT_MATCH` |
| `effroi` | 4 | `axialExpectationNeg` | `Inquiéter Effrayer` | `effroi` | `lateralEpistemicClosure` | 3 | — | `0.50` | `-0.69` | `+0.58` | `-0.02` | `SPLIT_FLAGGED` |
| `méfiance` | 4 | `axialExpectationNeg` | `Défiance` | `défiance` | `axialExpectationNeg` | 5 | — | `0.00` | `-0.88` | `+0.34` | `-0.10` | `EXACT_MATCH` |
| `épouvante` | 5 | `axialExpectationNeg` | `Inquiéter Effrayer` | `épouvanter` | `lateralEpistemicClosure` | 3 | — | `0.50` | `-0.69` | `+0.58` | `-0.02` | `SPLIT_FLAGGED` |
| `allégresse` | 3 | `axialControlPos` | `Humeur bonne` | `allégresse` | `axialControlPos` | 5 | — | `0.00` | `+0.48` | `+0.71` | `+0.00` | `EXACT_MATCH` |
| `contentement` | 3 | `axialControlPos` | `Combler Bonheur` | `contentement` | `axialControlPos` | 3 | — | `0.00` | `+0.75` | `+0.22` | `+0.15` | `EXACT_MATCH` |
| `chagrin` | 3 | `axialControlNeg` | `Attrister` | `chagrin` | `axialControlNeg` | 3 | — | `0.00` | `-0.69` | `-0.21` | `+0.19` | `EXACT_MATCH` |
| `mélancolie` | 3 | `axialControlNeg` | `Humeur songeuse` | `mélancolie` | `axialControlNeg` | 4 | `OVR` | `0.00` | `-0.62` | `-0.48` | `-0.23` | `EXACT_MATCH` |
| `euphorie` | 4 | `axialControlPos` | `Humeur bonne` | `euphorie` | `axialControlPos` | 5 | — | `0.00` | `+0.54` | `+0.91` | `+0.02` | `EXACT_MATCH` |
| `bien-être` | 4 | `axialControlPos` | `Combler Bonheur` | `bien-être` | `axialControlPos` | 3 | — | `0.00` | `+0.73` | `-0.10` | `-0.11` | `EXACT_MATCH` |
| `affliction` | 4 | `axialControlNeg` | `Attrister` | `affliger` | `axialControlNeg` | 3 | — | `0.00` | `-0.41` | `+0.27` | `-0.07` | `EXACT_MATCH` |
| `lassitude` | 4 | `axialControlNeg` | `Importuner` | `lasser` | `axialControlNeg` | 3 | `OVR` | `0.00` | `-0.56` | `-0.28` | `-0.20` | `EXACT_MATCH` |
| `jubilation` | 5 | `axialControlPos` | `Réjouir` | `jubiler` | `axialControlPos` | 3 | — | `0.00` | `+1.00` | `+1.00` | `+0.09` | `EXACT_MATCH` |
| `épanouissement` | 5 | `axialControlPos` | `Combler Bonheur` | `épanouissement` | `axialControlPos` | 3 | — | `0.00` | `+0.67` | `+0.06` | `+0.03` | `EXACT_MATCH` |
| `désolation` | 5 | `axialControlNeg` | `Attrister` | `désoler` | `axialControlNeg` | 3 | — | `0.00` | `-0.85` | `-0.04` | `-0.11` | `EXACT_MATCH` |
| `abattement` | 5 | `axialControlNeg` | `Mauvais moral` | `abattre` | `lateralAversiveDistress` | 5 | — | `0.50` | `-1.00` | `-0.92` | `-0.33` | `SPLIT_FLAGGED` |
| `enthousiasme` | 3 | `diagonalSynergyPos` | `Intéresser_A` | `enthousiasme` | `diagonalSynergyPos` | 3 | — | `0.00` | `+0.64` | `+0.51` | `+0.21` | `EXACT_MATCH` |
| `attrait` | 3 | `diagonalSynergyPos` | `Plaire_A` | `atttait` | `diagonalSynergyPos` | 3 | — | `0.00` | `+0.33` | `+0.20` | `-0.05` | `EXACT_MATCH` |
| `révulsion` | 3 | `diagonalSynergyNeg` | `Déplaire_A` | `révulsion` | `diagonalSynergyNeg` | 3 | — | `0.00` | `-0.79` | `+0.53` | `-0.02` | `EXACT_MATCH` |
| `malaise` | 3 | `diagonalSynergyNeg` | `Embarrasser` | `mal à l'aise` | `diagonalSynergyNeg` | 3 | — | `0.00` | `-0.70` | `+0.20` | `-0.24` | `EXACT_MATCH` |
| `passion` | 4 | `diagonalSynergyPos` | `Amour` | `passion amoureuse` | `diagonalSynergyPos` | 4 | — | `0.00` | `+0.76` | `+0.37` | `+0.09` | `EXACT_MATCH` |
| `affection` | 4 | `diagonalSynergyPos` | `Affection` | `affection` | `diagonalSynergyPos` | 4 | — | `0.00` | `+0.80` | `+0.12` | `+0.01` | `EXACT_MATCH` |
| `aversion` | 4 | `diagonalSynergyNeg` | `Aversion` | `aversion` | `diagonalSynergyNeg` | 4 | — | `0.00` | `-0.85` | `+0.33` | `+0.26` | `EXACT_MATCH` |
| `écœurement` | 4 | `diagonalSynergyNeg` | `Déplaire_A` | `écoeurement` | `diagonalSynergyNeg` | 3 | — | `0.00` | `-0.90` | `+0.55` | `-0.03` | `EXACT_MATCH` |
| `amour` | 5 | `diagonalSynergyPos` | `Amour` | `aimer` | `diagonalSynergyPos` | 4 | — | `0.00` | `+0.40` | `+0.32` | `-0.16` | `EXACT_MATCH` |
| `attachement` | 5 | `diagonalSynergyPos` | `Affection` | `attachement` | `diagonalSynergyPos` | 4 | — | `0.00` | `+0.14` | `-0.31` | `-0.08` | `EXACT_MATCH` |
| `répulsion` | 5 | `diagonalSynergyNeg` | `Déplaire_A` | `répulsion` | `diagonalSynergyNeg` | 3 | — | `0.00` | `-0.51` | `+0.35` | `-0.10` | `EXACT_MATCH` |
| `rejet` | 5 | `diagonalSynergyNeg` | `Aversion` | `rejet` | `diagonalSynergyNeg` | 4 | — | `0.00` | `-0.84` | `+0.41` | `-0.03` | `EXACT_MATCH` |
| `exaspération` | 3 | `diagonalAgenticConfront` | `Colère` | `exaspération` | `diagonalAgenticConfront` | 3 | — | `0.00` | `-0.57` | `+0.67` | `+0.11` | `EXACT_MATCH` |
| `agacement` | 3 | `diagonalAgenticConfront` | `Colère` | `agacement` | `diagonalAgenticConfront` | 3 | — | `0.00` | `-0.67` | `+0.44` | `-0.06` | `EXACT_MATCH` |
| `apaisement` | 3 | `diagonalAccommodation` | `Apaiser` | `apaiser` | `diagonalAccommodation` | 3 | — | `0.00` | `-0.67` | `-0.63` | `-0.32` | `EXACT_MATCH` |
| `rage` | 4 | `diagonalAgenticConfront` | `Colère` | `rage` | `diagonalAgenticConfront` | 3 | — | `0.00` | `-0.37` | `+0.43` | `+0.45` | `EXACT_MATCH` |
| `contrariété` | 4 | `diagonalAgenticConfront` | `Décevoir` | `contrarier` | `diagonalAgenticConfront` | 3 | `OVR` | `0.00` | `-0.67` | `+0.44` | `-0.06` | `EXACT_MATCH` |
| `soulagement` | 4 | `diagonalAccommodation` | `Rassurer` | `soulager` | `diagonalAccommodation` | 3 | `OVR` | `0.00` | `+0.69` | `-0.44` | `-0.27` | `EXACT_MATCH` |
| `quiétude` | 4 | `diagonalAccommodation` | `Rassurer` | `quiétude` | `diagonalAccommodation` | 4 | `OVR` | `0.00` | `+0.68` | `-0.73` | `-0.32` | `EXACT_MATCH` |
| `haine` | 5 | `diagonalAgenticConfront` | `Haine de qq` | `haine` | `diagonalAgenticConfront` | 4 | — | `0.00` | `-0.76` | `+0.40` | `+0.15` | `EXACT_MATCH` |
| `rancœur` | 5 | `diagonalAgenticConfront` | `Ressentiment` | `rancune` | `lateralAgenticConfront` | 4 | — | `0.50` | `-0.67` | `+0.49` | `+0.21` | `SPLIT_FLAGGED` |
| `satisfaction` | 3 | `lateralEpistemicMastery` | `Combler Bonheur` | `satisfaction` | `axialControlPos` | 3 | — | `1.50` | `+0.88` | `+0.27` | `-0.04` | `SPLIT_FLAGGED` |
| `déception` | 3 | `lateralAversiveDistress` | `Décevoir` | `décevoir` | `lateralAversiveDistress` | 3 | `OVR` | `0.00` | `-0.77` | `-0.02` | `-0.04` | `EXACT_MATCH` |
| `découragement` | 3 | `lateralAversiveDistress` | `Mauvais moral` | `découragement` | `lateralAversiveDistress` | 5 | — | `0.00` | `-0.78` | `-0.36` | `-0.23` | `EXACT_MATCH` |
| `fierté` | 4 | `lateralEpistemicMastery` | `Orgueil` | `fierté` | `lateralEpistemicMastery` | 4 | — | `0.00` | `+0.46` | `+0.27` | `+0.34` | `EXACT_MATCH` |
| `estime` | 4 | `lateralEpistemicMastery` | `Estime` | `estime` | `lateralEpistemicMastery` | 4 | — | `0.00` | `+0.49` | `-0.24` | `+0.08` | `EXACT_MATCH` |
| `honte` | 4 | `lateralAversiveDistress` | `Honte` | `honte` | `lateralAversiveDistress` | 4 | — | `0.00` | `-0.88` | `+0.34` | `-0.27` | `EXACT_MATCH` |
| `résignation` | 4 | `lateralAversiveDistress` | `Résignation` | `résignation` | `lateralAversiveDistress` | 4 | `OVR` | `0.00` | `-0.71` | `-0.22` | `-0.10` | `EXACT_MATCH` |
| `optimisme` | 5 | `lateralEpistemicMastery` | `Confiance_Sentiment de sécurité` | `optimisme` | `lateralApproachSynergy` | 5 | — | `1.00` | `+0.90` | `+0.13` | `+0.16` | `SPLIT_FLAGGED` |
| `espoir` | 5 | `lateralEpistemicMastery` | `Espoir` | `espoir` | `lateralEpistemicMastery` | 5 | — | `0.00` | `+0.65` | `+0.22` | `+0.06` | `EXACT_MATCH` |
| `désespoir` | 5 | `lateralAversiveDistress` | `Mauvais moral` | `désespérer` | `lateralAversiveDistress` | 5 | — | `0.00` | `-0.77` | `+0.59` | `-0.17` | `EXACT_MATCH` |
| `apathie` | 5 | `lateralAversiveDistress` | `Apathie` | `apathie` | `lateralAversiveDistress` | 5 | — | `0.00` | `-0.63` | `-0.58` | `-0.28` | `EXACT_MATCH` |
| `assurance` | 3 | `lateralApproachSynergy` | `Confiance_Sentiment de sécurité` | `assurance` | `lateralApproachSynergy` | 5 | — | `0.00` | `+0.35` | `-0.12` | `+0.16` | `EXACT_MATCH` |
| `plaisir` | 3 | `lateralApproachSynergy` | `Jouissance` | `plaisir` | `lateralApproachSynergy` | 3 | — | `0.00` | `+0.78` | `+0.57` | `-0.03` | `EXACT_MATCH` |
| `anxiété` | 3 | `lateralEpistemicClosure` | `Inquiéter` | `anxiété` | `lateralEpistemicClosure` | 3 | `OVR` | `0.00` | `-0.67` | `+0.26` | `-0.05` | `EXACT_MATCH` |
| `exaltation` | 4 | `lateralApproachSynergy` | `Bon moral` | `exalter` | `lateralApproachSynergy` | 5 | — | `0.00` | `+0.19` | `+0.78` | `+0.16` | `EXACT_MATCH` |
| `sérénité` | 4 | `lateralApproachSynergy` | `Rassurer` | `sérénité` | `lateralApproachSynergy` | 4 | `OVR` | `0.00` | `+0.80` | `-0.88` | `-0.19` | `EXACT_MATCH` |
| `angoisse` | 4 | `lateralEpistemicClosure` | `Inquiéter` | `angoisser` | `lateralEpistemicClosure` | 4 | `OVR` | `0.00` | `-0.69` | `+0.58` | `-0.17` | `EXACT_MATCH` |
| `appréhension` | 4 | `lateralEpistemicClosure` | `Crainte` | `appréhender` | `axialExpectationNeg` | 3 | — | `0.50` | `-0.23` | `+0.44` | `-0.03` | `SPLIT_FLAGGED` |
| `terreur` | 5 | `lateralEpistemicClosure` | `Inquiéter Effrayer` | `terroriser` | `lateralEpistemicClosure` | 3 | — | `0.00` | `-0.86` | `+0.80` | `+0.10` | `EXACT_MATCH` |
| `frustration` | 3 | `lateralAgenticConfront` | `Décevoir` | `frustrer` | `lateralAgenticConfront` | 3 | `OVR` | `0.00` | `-0.88` | `+0.46` | `-0.09` | `EXACT_MATCH` |
| `acceptation` | 3 | `lateralReceptiveAccomm` | `Résignation` | `acceptation` | `lateralReceptiveAccomm` | 4 | `OVR` | `0.00` | `+0.67` | `-0.43` | `+0.14` | `EXACT_MATCH` |
| `hostilité` | 4 | `lateralAgenticConfront` | `Inimitié` | `hostilité` | `lateralAgenticConfront` | 4 | — | `0.00` | `-0.76` | `+0.55` | `+0.14` | `EXACT_MATCH` |
| `ressentiment` | 4 | `lateralAgenticConfront` | `Ressentiment` | `ressentiment` | `lateralAgenticConfront` | 4 | — | `0.00` | `-0.67` | `+0.49` | `+0.21` | `EXACT_MATCH` |
| `révolte` | 5 | `lateralAgenticConfront` | `Colère` | `révolte` | `diagonalAgenticConfront` | 3 | — | `0.50` | `-0.31` | `+0.76` | `+0.29` | `SPLIT_FLAGGED` |
| `amertume` | 5 | `lateralAgenticConfront` | `Décevoir` | `amertume` | `lateralAgenticConfront` | 3 | `OVR` | `0.00` | `-0.77` | `+0.27` | `-0.14` | `EXACT_MATCH` |
| `dépit` | 3 | `lateralActiveContest` | `Décevoir` | `dépiter` | `lateralActiveContest` | 3 | `OVR` | `0.00` | `-0.84` | `+0.20` | `-0.05` | `EXACT_MATCH` |
| `indignation` | 4 | `lateralActiveContest` | `Colère` | `indignation` | `diagonalAgenticConfront` | 3 | — | `0.50` | `-0.65` | `+0.56` | `+0.06` | `SPLIT_FLAGGED` |
| `mépris` | 4 | `lateralActiveContest` | `Mépris` | `mépriser` | `lateralActiveContest` | 4 | — | `0.00` | `-0.59` | `+0.27` | `-0.01` | `EXACT_MATCH` |
| `détachement` | 4 | `lateralSecondaryAccomm` | `Absence de désir` | `détachement` | `diagonalSynergyNeg` | 5 | — | `1.00` | `-0.51` | `+0.40` | `+0.04` | `SPLIT_FLAGGED` |
| `défiance` | 5 | `lateralActiveContest` | `Défiance` | `défiance` | `axialExpectationNeg` | 5 | — | `0.50` | `-0.88` | `+0.34` | `-0.10` | `SPLIT_FLAGGED` |
| `émoi` | 3 | `centralOperator` | `Troubler` | `émouvoir` | `centralOperator` | 3 | `OVR` | `0.00` | `-0.60` | `+0.78` | `+0.03` | `EXACT_MATCH` |

---

## 4. Audit explicite des 4 verrous normatifs Option 1A (`0` violation)

- **Statut global de vérification programmatique :** **`PASS` (0 violation — classes + 52 règles `subclass_overrides`)**

### 4.1 Verrou 1A-a : États aversifs à faible contrôle instrumental perçu ($Y \le 0$)

| Classe | Sous-secteur | $Z$ | $u_X$ | $u_Y$ | Contrôle |
| :--- | :--- | :---: | :---: | :---: | :---: |
| `Peur panique` | `lateralEpistemicClosure` | 3 | `-0.75` | `-0.25` | PASS (`Y <= 0`) |
| `Peur phobie` | `lateralEpistemicClosure` | 5 | `-0.75` | `-0.25` | PASS (`Y <= 0`) |
| `Désespérer de` | `lateralAversiveDistress` | 5 | `-0.25` | `-0.75` | PASS (`Y <= 0`) |
| `Honte` | `lateralAversiveDistress` | 4 | `-0.25` | `-0.75` | PASS (`Y <= 0`) |
| `Honte de soi` | `lateralAversiveDistress` | 4 | `-0.25` | `-0.75` | PASS (`Y <= 0`) |
| `Souffrance` | `lateralAversiveDistress` | 3 | `-0.25` | `-0.75` | PASS (`Y <= 0`) |
| `Attrister` | `axialControlNeg` | 3 | `+0.00` | `-1.00` | PASS (`Y <= 0`) |
| `Décevoir Malheur` | `lateralAversiveDistress` | 3 | `-0.25` | `-0.75` | PASS (`Y <= 0`) |
| `Aversion` | `diagonalSynergyNeg` | 4 | `-0.50` | `-0.50` | PASS (`Y <= 0`) |
| `Déplaire_A` | `diagonalSynergyNeg` | 3 | `-0.50` | `-0.50` | PASS (`Y <= 0`) |
| `Mauvais moral` | `lateralAversiveDistress` | 5 | `-0.25` | `-0.75` | PASS (`Y <= 0`) |
| `Apathie` | `lateralAversiveDistress` | 5 | `-0.25` | `-0.75` | PASS (`Y <= 0`) |
| `Désintérêt` | `diagonalSynergyNeg` | 5 | `-0.50` | `-0.50` | PASS (`Y <= 0`) |
| `Absence de désir` | `diagonalSynergyNeg` | 5 | `-0.50` | `-0.50` | PASS (`Y <= 0`) |

### 4.2 Verrou 1A-b : Quadrant Q2 ($-X, +Y$) strictement réservé à l'affrontement agentique

| Classe | Sous-secteur Q2 | $Z$ | $u_X$ | $u_Y$ | Note de découpage |
| :--- | :--- | :---: | :---: | :---: | :--- |
| `Blesser` | `lateralActiveContest` | 3 | `-0.75` | `+0.25` | Oui (`SPLIT` signalé) |
| `Importuner` | `diagonalAgenticConfront` | 3 | `-0.50` | `+0.50` | Oui (`SPLIT` signalé) |
| `Colère` | `diagonalAgenticConfront` | 3 | `-0.50` | `+0.50` | Oui (`SPLIT` signalé) |
| `Haine de qq` | `diagonalAgenticConfront` | 4 | `-0.50` | `+0.50` | Oui (`SPLIT` signalé) |
| `Inimitié` | `lateralAgenticConfront` | 4 | `-0.25` | `+0.75` | Oui (`SPLIT` signalé) |
| `Jalousie envie` | `lateralActiveContest` | 4 | `-0.75` | `+0.25` | Oui (`SPLIT` signalé) |
| `Jalousie sexuelle` | `lateralActiveContest` | 4 | `-0.75` | `+0.25` | Non |
| `Mépris` | `lateralActiveContest` | 4 | `-0.75` | `+0.25` | Non |
| `Mésestime` | `lateralActiveContest` | 4 | `-0.75` | `+0.25` | Oui (`SPLIT` signalé) |
| `Ressentiment` | `lateralAgenticConfront` | 4 | `-0.25` | `+0.75` | Oui (`SPLIT` signalé) |

- **Overrides Q2 autorisés (affrontement/frustration active) :** `Décevoir[amertume]->lateralAgenticConfront`, `Décevoir[contrarier]->diagonalAgenticConfront`, `Décevoir[dépiter]->lateralActiveContest`, `Décevoir[frustrer]->lateralAgenticConfront`, `Décevoir[insatisfaisant]->lateralAgenticConfront`, `Décevoir[mécontenter]->lateralAgenticConfront`, `Importuner[crisper]->diagonalAgenticConfront`, `Importuner[tendre]->diagonalAgenticConfront`, `Importuner[énerver]->diagonalAgenticConfront`.

### 4.3 Verrou 1A-c : Q4 ($+X, -Y$) accommodation secondaire vs sécurité/bonheur en $Y \ge 0$

- **Classes assignées en Q4 (`+X, -Y`, accommodation face à une limite objective d'action) :** `Apaiser` (`diagonalAccommodation`), `Détendre` (`lateralSecondaryAccomm`), `Humeur songeuse` (`lateralSecondaryAccomm`), `Rassurer` (`diagonalAccommodation`), `Admiration` (`lateralReceptiveAccomm`), `Bonne conscience` (`diagonalAccommodation`), `Compassion` (`lateralReceptiveAccomm`), `Estime respect` (`lateralReceptiveAccomm`), `Gratitude` (`lateralReceptiveAccomm`), `Plaire_B` (`lateralReceptiveAccomm`), `Pudeur` (`lateralReceptiveAccomm`).
- **Splits encodés pour Verrou 1A-c :** `Rassurer` (`sérénité`, `tranquilliser`, `insouciance` -> Q1 `lateralApproachSynergy`, $Y > 0$) et `Résignation` (`acceptation` -> Q4 `lateralReceptiveAccomm`, $X > 0, Y < 0$).

| Classe sécurité / bonheur | Sous-secteur | $Z$ | $u_X$ | $u_Y$ | Contrôle |
| :--- | :--- | :---: | :---: | :---: | :---: |
| `Confiance_Sentiment de sécurité` | `lateralApproachSynergy` | 5 | `+0.25` | `+0.75` | PASS (`Y >= 0`) |
| `Combler Bonheur` | `axialControlPos` | 3 | `+0.00` | `+1.00` | PASS (`Y >= 0`) |
| `Bon moral` | `lateralApproachSynergy` | 5 | `+0.25` | `+0.75` | PASS (`Y >= 0`) |
| `Humeur bonne` | `axialControlPos` | 5 | `+0.00` | `+1.00` | PASS (`Y >= 0`) |
| `Réjouir` | `axialControlPos` | 3 | `+0.00` | `+1.00` | PASS (`Y >= 0`) |
| `Jouissance` | `lateralApproachSynergy` | 3 | `+0.25` | `+0.75` | PASS (`Y >= 0`) |

### 4.4 Verrou 1A-d : Classes de surprise et lien `central_operator_link: surprise_z1`

| Classe | Portée | $Z$ | Sous-secteur | `central_operator_link` | Contrôle |
| :--- | :--- | :---: | :--- | :--- | :---: |
| `Surprendre` | `active_z_plus` | 3 | `centralOperator` | `surprise_z1` | PASS |
| `Surprendre Bonne surprise` | `satellite_only_z_plus` | 3 | `axialExpectationPos` | `surprise_z1` | PASS |
| `Surprendre Mauvaise surprise` | `satellite_only_z_plus` | 3 | `axialExpectationNeg` | `surprise_z1` | PASS |
| `Sans surprise` | `reserve_or_discard_only` | — | `—` | `surprise_z1` | PASS |

### 4.5 Règles structurées `subclass_overrides` approuvées (`8` classes / `52` règles)

| Classe | `SOUS-CLASSE` | `subsector_id` | Paire | $Z$ | $Z_{\text{alt}}$ | $(u_X, u_Y)$ | Justification clinique |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| `Décevoir` | `amertume` | `lateralAgenticConfront` | `L3` | 3 | — | `(-0.25, +0.75)` | Amertume / rancœur agentique (L3, Q2, Tableau 1b Amertume). |
| `Décevoir` | `contrarier` | `diagonalAgenticConfront` | `D2` | 3 | — | `(-0.50, +0.50)` | Contrariété / blocage contrariant agentique (D2, Q2, Tableau 1b). |
| `Décevoir` | `décevoir` | `lateralAversiveDistress` | `L1` | 3 | — | `(-0.25, -0.75)` | Perte subie / attente déçue (L1, Q3, Tableau 1b Déception vive Z=3). |
| `Décevoir` | `dépiter` | `lateralActiveContest` | `L4` | 3 | — | `(-0.75, +0.25)` | Dépit / contestation dépitée (L4, Q2, Tableau 1b Dépit Z=3). |
| `Décevoir` | `désappointer` | `lateralAversiveDistress` | `L1` | 3 | — | `(-0.25, -0.75)` | Désappointement subi à faible contrôle (L1, Q3). |
| `Décevoir` | `désillusionner` | `lateralAversiveDistress` | `L1` | 3 | — | `(-0.25, -0.75)` | Désillusion subie (L1, Q3). |
| `Décevoir` | `frustrer` | `lateralAgenticConfront` | `L3` | 3 | — | `(-0.25, +0.75)` | Frustration avec maintien d'agentivité (L3, Q2, Tableau 1b Frustration Z=3). |
| `Décevoir` | `insatisfaisant` | `lateralAgenticConfront` | `L3` | 3 | — | `(-0.25, +0.75)` | Insatisfaction frustrative active (L3, Q2). |
| `Décevoir` | `mécontenter` | `lateralAgenticConfront` | `L3` | 3 | — | `(-0.25, +0.75)` | Mécontentement actif (L3, Q2). |
| `Humeur songeuse` | `méditatif` | `lateralSecondaryAccomm` | `L4` | 5 | — | `(+0.25, -0.75)` | Disposition méditative sereine en Q4 dom. -Y (L4, Z=5). |
| `Humeur songeuse` | `mélancolie` | `axialControlNeg` | `A2` | 4 | — | `(+0.00, -1.00)` | Mélancolie dysphorique à faible contrôle (A2, Axe -Y, Z=4, Tableau 1b A2). |
| `Humeur songeuse` | `pensif` | `lateralSecondaryAccomm` | `L4` | 5 | — | `(+0.25, -0.75)` | Disposition pensive apaisée en Q4 dom. -Y (L4, Z=5). |
| `Humeur songeuse` | `rêveur` | `lateralSecondaryAccomm` | `L4` | 5 | — | `(+0.25, -0.75)` | Rêverie détachée en Q4 dom. -Y (L4, Z=5). |
| `Humeur songeuse` | `songeur` | `lateralSecondaryAccomm` | `L4` | 5 | — | `(+0.25, -0.75)` | Humeur songeuse contemplative en Q4 dom. -Y (L4, Z=5). |
| `Importuner` | `crisper` | `diagonalAgenticConfront` | `D2` | 3 | — | `(-0.50, +0.50)` | Crispation réactive irritée (D2, Q2, Z=3). |
| `Importuner` | `fatiguer` | `axialControlNeg` | `A2` | 3 | — | `(+0.00, -1.00)` | Fatigue et baisse de contrôle instrumental sans affrontement Q2 (A2, Axe -Y, Z=3). |
| `Importuner` | `lasser` | `axialControlNeg` | `A2` | 3 | — | `(+0.00, -1.00)` | Lassitude à bas contrôle (A2, Axe -Y, Z=3, Tableau 1b Lassitude). |
| `Importuner` | `tendre` | `diagonalAgenticConfront` | `D2` | 3 | — | `(-0.50, +0.50)` | Tension réactive active (D2, Q2, Z=3). |
| `Importuner` | `énerver` | `diagonalAgenticConfront` | `D2` | 3 | — | `(-0.50, +0.50)` | Énervement / nervosité en affrontement agentique actif (D2, Q2, Z=3, Verrou 1A-b). |
| `Inquiéter` | `angoisser` | `lateralEpistemicClosure` | `L2` | 4 | 3 | `(-0.75, -0.25)` | Angoisse avec fermeture épistémique marquée (L2, Q3 dom. -X, Tableau 1b Angoisse Z=4/3). |
| `Inquiéter` | `anxiété` | `lateralEpistemicClosure` | `L2` | 3 | 4 | `(-0.75, -0.25)` | Anxiété diffuse à faible contrôle (L2, Q3 dom. -X, Tableau 1b Anxiété Z=3/4). |
| `Inquiéter` | `inquiéter` | `axialExpectationNeg` | `A1` | 3 | — | `(-1.00, +0.00)` | Inquiétude situationnelle centrée sur l'attente négative (A1, Axe -X, Tableau 1b Z=3). |
| `Inquiéter` | `oppresser` | `lateralEpistemicClosure` | `L2` | 3 | 4 | `(-0.75, -0.25)` | Oppression anxieuse somatique/épistémique (L2, Q3 dom. -X, Z=3/4). |
| `Inquiéter` | `préoccuper` | `axialExpectationNeg` | `A1` | 3 | — | `(-1.00, +0.00)` | Préoccupation épistémique ciblée sur l'attente (A1, Axe -X, Z=3). |
| `Inquiéter` | `souci` | `axialExpectationNeg` | `A1` | 3 | — | `(-1.00, +0.00)` | Souci immédiat sur l'attente négative (A1, Axe -X, Z=3). |
| `Inquiéter` | `trac` | `lateralEpistemicClosure` | `L2` | 3 | 4 | `(-0.75, -0.25)` | Trac / appréhension anxieuse situationnelle (L2, Q3 dom. -X, Z=3/4). |
| `Inquiéter` | `tracasser` | `axialExpectationNeg` | `A1` | 3 | — | `(-1.00, +0.00)` | Tracas focalisé sur une issue incertaine (A1, Axe -X, Z=3). |
| `Rassurer` | `insouciance` | `lateralApproachSynergy` | `L2` | 4 | — | `(+0.25, +0.75)` | Insouciance apaisée hors menace active (L2, Q1 dom. +Y, Z=4). |
| `Rassurer` | `quiétude` | `diagonalAccommodation` | `D2` | 4 | 3 | `(+0.50, -0.50)` | Quiétude apaisée en accommodation secondaire (D2, Q4, Z=4/3). |
| `Rassurer` | `soulager` | `diagonalAccommodation` | `D2` | 3 | 4 | `(+0.50, -0.50)` | Soulagement post-alerte face à une contrainte levée (D2, Q4, Z=3/4). |
| `Rassurer` | `sérénité` | `lateralApproachSynergy` | `L2` | 4 | — | `(+0.25, +0.75)` | Sérénité stable à bas arousal hors contrainte d'incontrôlabilité (L2, Q1 dom. +Y, Z=4, Verrou 1A-c). |
| `Rassurer` | `tranquilliser` | `lateralApproachSynergy` | `L2` | 4 | — | `(+0.25, +0.75)` | Tranquillité sûre à bas arousal (L2, Q1 dom. +Y, Z=4, Verrou 1A-c). |
| `Troubler` | `affoler` | `lateralEpistemicClosure` | `L2` | 3 | — | `(-0.75, -0.25)` | Affolement à faible contrôle et fermeture épistémique (L2, Q3 dom. -X, Z=3). |
| `Troubler` | `agitation` | `axialExpectationNeg` | `A1` | 3 | — | `(-1.00, +0.00)` | Agitation inquiète sur l'axe -X (A1, Z=3). |
| `Troubler` | `confusion` | `axialExpectationNeg` | `A1` | 3 | — | `(-1.00, +0.00)` | Confusion cognitive sur l'attente négative (A1, Axe -X, Z=3). |
| `Troubler` | `dépayser` | `centralOperator` | `CENTER` | 3 | — | `(+0.00, +0.00)` | Dépaysement / suspens de repères sur l'axe central Z=3. |
| `Troubler` | `désarroi` | `lateralEpistemicClosure` | `L2` | 3 | — | `(-0.75, -0.25)` | Désarroi sidérant en Q3 dom. -X (L2, Z=3, hors Y+). |
| `Troubler` | `effarer` | `lateralEpistemicClosure` | `L2` | 3 | — | `(-0.75, -0.25)` | Effarement à fermeture épistémique (L2, Q3 dom. -X, Z=3). |
| `Troubler` | `hébéter` | `lateralEpistemicClosure` | `L2` | 3 | — | `(-0.75, -0.25)` | Hébétude sous charge choc (L2, Q3 dom. -X, Z=3). |
| `Troubler` | `perplexité` | `axialExpectationNeg` | `A1` | 3 | — | `(-1.00, +0.00)` | Perplexité dubitative sur l'axe -X (A1, Z=3). |
| `Troubler` | `saisir` | `centralOperator` | `CENTER` | 3 | — | `(+0.00, +0.00)` | Saisissement suspensif pré-valencé sur l'axe central Z=3. |
| `Troubler` | `troubler` | `axialExpectationNeg` | `A1` | 3 | — | `(-1.00, +0.00)` | Trouble épistémique négatif sur l'axe -X (A1, Z=3). |
| `Troubler` | `vertige` | `lateralEpistemicClosure` | `L2` | 3 | — | `(-0.75, -0.25)` | Vertige psychique / perte de repères en Q3 dom. -X (L2, Z=3, hors Y+). |
| `Troubler` | `égarer` | `lateralEpistemicClosure` | `L2` | 3 | — | `(-0.75, -0.25)` | Égarement confusionnel en Q3 dom. -X (L2, Z=3). |
| `Troubler` | `émouvoir` | `centralOperator` | `CENTER` | 3 | — | `(+0.00, +0.00)` | Opérateur central Émoi (0, 0, 3) ; émoi conservé après exclusion des 4 métatermes. |
| `Troubler` | `éperdu` | `lateralEpistemicClosure` | `L2` | 3 | — | `(-0.75, -0.25)` | Éperdu / submersion aversive en Q3 dom. -X (L2, Z=3). |
| `Admiration` | `admiration` | `lateralReceptiveAccomm` | `L3` | 4 | — | `(+0.75, -0.25)` | Admiration réceptive canonique (L3, Q4, Z=4, Article §7.1). |
| `Admiration` | `extase` | `lateralApproachSynergy` | `L2` | 4 | — | `(+0.25, +0.75)` | Extase / exaltation positive en Q1 dom. +Y (L2, Z=4). |
| `Admiration` | `ferveur` | `diagonalSynergyPos` | `D1` | 4 | — | `(+0.50, +0.50)` | Ferveur enthousiaste / passionnelle en Q1 diagonale (D1, Z=4). |
| `Résignation` | `acceptation` | `lateralReceptiveAccomm` | `L3` | 4 | — | `(+0.75, -0.25)` | Accommodation réceptive acceptée face à une limite objective (L3, Q4, Verrou 1A-c). |
| `Résignation` | `fatalisme` | `lateralAversiveDistress` | `L1` | 5 | 4 | `(-0.25, -0.75)` | Disposition fataliste durable à faible contrôle (L1, Q3, Z=5/4). |
| `Résignation` | `résignation` | `lateralAversiveDistress` | `L1` | 4 | 5 | `(-0.25, -0.75)` | Résignation subie à faible contrôle (L1, Q3, Tableau 1b Z=4/5). |

### 4.6 Synthèse des notes de découpage par `SOUS-CLASSE` (`69` classes)

| Classe | Sous-secteur par défaut | `subclass_overrides` | Note de découpage / sous-classes critiques |
| :--- | :--- | :---: | :--- |
| `Apaiser` | `diagonalAccommodation` | — | Découpage recommandé par SOUS-CLASSE : 'ataraxie', 'imperturbable', 'inébranlable' -> lateralReceptiveAccomm (Z=5, stoïcisme/consentement lucide) ; 'impassible' -> lateralSecondaryAccomm ; le cœur 'apaiser'/'calmer'/'zen'/'placidité' reste en diagonalAccommodation (Calme -> Apaisement Z=3). |
| `Apathie` | `lateralAversiveDistress` | — | Découpage optionnel : 'prostration'/'avachissement' peuvent basculer vers axialControlNeg (Abattement Z=5) ; 'spleen'/'vague à l'âme' voisinent la mélancolie (axialControlNeg). |
| `Attrister` | `axialControlNeg` | — | Granularité temporelle par SOUS-CLASSE : 'chagrin'/'peiner' (Z=3), 'affliger'/'affliction' (Z=4), 'désoler'/'désolation'/'inconsolable' (Z=5) le long du même axe -Y (axialControlNeg). |
| `Blesser` | `lateralActiveContest` | — | Classe uniquement satellite en Z+ ('prendre ombrage', 'se formaliser', 'se sentir agressé' ; 50 entrées en réserve -Z CausAffect). Si lue comme blessure subie/vulnérabilité passive plutôt que susceptibilité défensive/vexation active, basculer vers lateralAversiveDistress (Q3). |
| `Bon moral` | `lateralApproachSynergy` | — | Découpage recommandé par SOUS-CLASSE : 'ivre', 'ivresse', 'enivrement', 'surexcitation' présentent des valeurs V_harm négatives artefactuelles (gloses EN 'intoxication' / hyper-arousal) à isoler de 'tonus'/'exalter'. |
| `Combler Bonheur` | `axialControlPos` | — | Découpage par SOUS-CLASSE : 'satisfaction'/'contentement' -> lateralEpistemicMastery (Tableau 1b L1 Z=3) ; 'bien-être'/'bonheur' s'étendent en Z=4 et 'épanouissement' en Z=5 sur axialControlPos. |
| `Décevoir` | `lateralAversiveDistress` | 9 | Découpage encodé dans `subclass_overrides` (MP3b) : {décevoir, désappointer, désillusionner} -> lateralAversiveDistress (L1, Z=3) ; {contrarier} -> diagonalAgenticConfront (D2, Q2, Z=3) ; {frustrer, amertume, insatisfaisant, mécontenter} -> lateralAgenticConfront (L3, Q2, Z=3) ; {dépiter} -> lateralActiveContest (L4, Q2, Z=3). |
| `Décevoir Malheur` | `lateralAversiveDistress` | — | Extension verticale possible : 'mal-être' et 'sentiment d'abandon' relèvent souvent de Z=4/Z=5 sur lateralAversiveDistress / axialControlNeg. |
| `Désinhiber` | `lateralEpistemicMastery` | — | DÉCOUPAGE IMPÉRATIF actif vs satellites : l'unique entrée Z_PLUS_ACTIVE est 'sans-gêne' (V=-0.45, A=+0.43, connotation morale/comportementale péjorative, proche de Q2/CaractAffect), tandis que les 10 satellites ('à l'aise', 'décontracté', 'libéré', 'relax', V_all=+0.49) relèvent de lateralApproachSynergy / lateralSecondaryAccomm. |
| `Embarrasser` | `diagonalSynergyNeg` | — | Découpage recommandé par SOUS-CLASSE : 'embarras'/'gêne'/'penaud'/'déconfit' voisinent lateralAversiveDistress (voisin Z=3 de la Honte en Z=4) ; 'confusion' -> lateralEpistemicClosure. |
| `Energie` | `lateralEpistemicMastery` | — | Sous-classes à forte mobilisation instrumentale ('dynamisme', 'énergie', 'entrain', 'exubérance') voisinent lateralApproachSynergy (Q1 dom. +Y). |
| `Ennuyer` | `axialControlNeg` | — | L'ennui réactionnel immédiat siège en Z=3 (axialControlNeg) ; sa forme chronique ('trouver le temps long') prolonge vers lateralAversiveDistress / Absence de désir (Z=5). |
| `Humeur mauvaise` | `lateralAversiveDistress` | — | DÉCOUPAGE IMPÉRATIF par SOUS-CLASSE : classe hétérogène mêlant irritabilité active (Q2) et morosité (Q3/-Y). 'bougon', 'grincheux', 'grognon', 'humeur massacrante' (D_orth=+0.24) -> Q2 lateralActiveContest ; 'humeur chagrine' -> axialControlNeg ; 'morose'/'morosité'/'sinistrose' restent en lateralAversiveDistress (Q3). |
| `Humeur songeuse` | `lateralSecondaryAccomm` | 5 | Découpage encodé dans `subclass_overrides` (MP3b) : {méditatif, pensif, rêveur, songeur} -> lateralSecondaryAccomm (L4, Q4 dom. -Y, Z=5) ; {mélancolie} -> axialControlNeg (A2, Axe -Y, Z=4 ; Tableau 1b A2). |
| `Importuner` | `diagonalAgenticConfront` | 5 | Découpage encodé dans `subclass_overrides` (MP3b) : {énerver, crisper, tendre} -> diagonalAgenticConfront (D2, Q2, Z=3) ; {fatiguer, lasser} -> axialControlNeg (A2, Axe -Y, Z=3 ; Tableau 1b A2). |
| `Inhiber` | `lateralEpistemicClosure` | — | Découpage optionnel : 'complexe' (V=-0.81) relève plutôt de Z=4 (lateralAversiveDistress, voisin de Honte/Mésestime de soi). |
| `Inquiéter` | `lateralEpistemicClosure` | 8 | Découpage encodé dans `subclass_overrides` (MP3b) : {inquiéter, préoccuper, souci, tracasser} -> axialExpectationNeg (A1, Axe -X, Z=3) ; {angoisser, anxiété, oppresser, trac} -> lateralEpistemicClosure (L2, Q3 dom. -X, Z=3/4). |
| `Inquiéter Effrayer` | `lateralEpistemicClosure` | — | Découpage par SOUS-CLASSE : 'frayeur'/'effroi'/'épouvante' -> axialExpectationNeg (Tableau 1b A1) ; 'détresse' -> lateralAversiveDistress (Q3 dom. -Y) ; 'terreur' -> lateralEpistemicClosure (Tableau 1b L2). |
| `Jouissance` | `lateralApproachSynergy` | — | Découpage optionnel : 'réconfort' (A=-0.54) relève de diagonalAccommodation (Q4, apaisement post-stress). |
| `Mauvais moral` | `lateralAversiveDistress` | — | Découpage recommandé par SOUS-CLASSE : 'abattement'/'accablement' (V=-1.00, A=-0.92) -> axialControlNeg (Tableau 1b A2 Z=5) ; 'consternation'/'anéantissement'/'atterrement' -> lateralEpistemicClosure ; 'désespoir'/'désespérance'/'dépression'/'découragement' restent en lateralAversiveDistress (Tableau 1b L1 Z=5). |
| `Rassurer` | `diagonalAccommodation` | 5 | Découpage encodé dans `subclass_overrides` (MP3b, Verrou 1A-c) : {soulager, quiétude} -> diagonalAccommodation (D2, Q4, Z=3/4) ; {sérénité, tranquilliser, insouciance} -> lateralApproachSynergy (L2, Q1 dom. +Y, A bas, Z=4). |
| `Réjouir` | `axialControlPos` | — | Découpage par SOUS-CLASSE : 'joie mauvaise' (sat: 'schadenfreude', V<0 en NRC) constitue une sous-classe sociale hostile hors axe +Y ; 'jubiler'/'jubilation' s'étend vers Z=5 sur axialControlPos (Tableau 1b A2). |
| `Sans surprise` | `reserve` | — | Classe 100 % CausAffect en réserve -Z (1 entrée : 'sans surprise') ; lien documentaire à Surprise Z=1. |
| `Souffrance` | `lateralAversiveDistress` | — | Extension verticale possible : la douleur immédiate siège en Z=3, tandis que 'souffrance morale'/'martyre' prolongent vers Z=4/Z=5 sur lateralAversiveDistress. |
| `Surprendre` | `centralOperator` | — | DÉCOUPAGE IMPÉRATIF par SOUS-CLASSE (Verrou 1A-d) : classe bipolaire centrée sur la rupture de veille Z=1 se déployant en Z=3 vers : (a) ouverture/étonnement positif ('étonnement', 'ébahissement', 'abasourdissement') -> axialExpectationPos ; (b) choc/effraction sidérante ('sidération', 'stupéfaction', 'ahurissement', 'pantelant', 'interdit') -> lateralEpistemicClosure. |
| `Troubler` | `centralOperator` | 14 | Découpage encodé dans `subclass_overrides` (MP3b) après exclusion des 4 métatermes (affect, affectivité, sentiment, émotion -> NON_LEXICAL_DISCARD/META_CLASSIFIER) : {affoler, désarroi, effarer, hébéter, vertige, égarer, éperdu} -> lateralEpistemicClosure (L2, Q3 dom. -X, Z=3) ; {confusion, perplexité, troubler, agitation} -> axialExpectationNeg (A1, Axe -X, Z=3) ; {émouvoir (émoi), saisir, dépayser} -> centralOperator (Z=3). |
| `Absence de désir` | `diagonalSynergyNeg` | — | DÉCOUPAGE IMPÉRATIF par SOUS-CLASSE : 'détachement' -> lateralSecondaryAccomm (Tableau 1b L4 Z=4) ; 'lassitude'/'fatigue' -> axialControlNeg (Tableau 1b A2) ; 'démotivation'/'démobilisation'/'désabusement'/'désenchantement' -> lateralAversiveDistress (Q3) ; 'rassasiement'/'satiété'/'repu' (V>+0.20) -> satiété apaisée hors Q3 (Q4/Q1) ; 'dégoût'/'indigestion'/'saturation' restent en diagonalSynergyNeg (antonyme exact de Désir). |
| `Admiration` | `lateralReceptiveAccomm` | 3 | Découpage encodé dans `subclass_overrides` (MP3b) : {admiration} -> lateralReceptiveAccomm (L3, Q4, Z=4) ; {extase} -> lateralApproachSynergy (L2, Q1, Z=4) ; {ferveur} -> diagonalSynergyPos (D1, Q1, Z=4). |
| `Affection` | `diagonalSynergyPos` | — | Sous-classes 'tendresse'/'attendrissement' (D_orth=-0.50) voisinent lateralReceptiveAccomm ou axialControlPos. |
| `Amitié` | `diagonalSynergyPos` | — | Découpage recommandé par SOUS-CLASSE : les termes en '-philie'/'-phile' (américanophile, francophilie, philanthropie, etc.) relèvent d'attitudes durables (Z=5 lateralEpistemicMastery) ; 'harmonie'/'concorde'/'entente' voisinent lateralApproachSynergy. |
| `Amour` | `diagonalSynergyPos` | — | Découpage recommandé par SOUS-CLASSE : 'faible', 'faiblesse', 'fou', 'béguin' tirent artificiellement la moyenne V_harm vers +0.30 (gloses EN polysémiques) ; le cœur ('amour', 'passion', 'flamme', 'amour-passion', V>+0.70) couvre Z=4 (Passion) et Z=5 (Amour) dans Tableau 1b D1. |
| `Amour désamour` | `diagonalSynergyNeg` | — | Le satellite 'se détacher' touche lateralSecondaryAccomm. |
| `Aversion` | `diagonalSynergyNeg` | — | DÉCOUPAGE IMPÉRATIF par SOUS-CLASSE : 'aversion', 'répugnance', 'rejet', 'détestation', 'exécration' relèvent de diagonalSynergyNeg (Tableau 1b D1 Z=4 Aversion, Verrou 1A-a) ; 'haine', 'hostile', 'hostilité', 'rebelle', 'réfractaire', 'rétif' (D_orth>0) doivent basculer en Q2 (diagonalAgenticConfront / lateralAgenticConfront). |
| `Bonne conscience` | `diagonalAccommodation` | — | Classe 100 % Z_PLUS_SATELLITE (11 entrées ; déjà exclue de Z_PLUS_ACTIVE en MP1c) à valence positive et basse activation (V=+0.57, A=-0.65) ; statut axiologique frontalier avec -Z. |
| `Colère` | `diagonalAgenticConfront` | — | Découpage hiérarchique par SOUS-CLASSE : 'agacement'/'exaspération'/'colère' en Z=3 (diagonalAgenticConfront) ; 'rage'/'fureur'/'courroux' en Z=4 ; 'indignation' -> lateralActiveContest (Z=4) ; 'révolte' -> lateralAgenticConfront (Z=5). |
| `Compassion` | `lateralReceptiveAccomm` | — | Découpage par SOUS-CLASSE : 'compassion', 'empathie', 'attendrissement', 'sympathie' (V>+0.45) en lateralReceptiveAccomm ; 'pitié', 'apitoiement', 'commisération' (V<-0.33) penchent vers axialControlNeg. |
| `Confiance` | `axialExpectationPos` | — | Note d'échelle : 'confiance' figure à Z=4 dans Tableau 1b A1 (et Conviction/Lucidité à Z=5) ; ancrée par défaut en Z=5 comme disposition épistémique générale. |
| `Confiance_Sentiment de sécurité` | `lateralApproachSynergy` | — | Découpage par SOUS-CLASSE : 'optimisme'/'optimiste' -> lateralEpistemicMastery (Tableau 1b L1 Z=5) ; 'assurance'/'sûr'/'sentiment de sécurité' restent en lateralApproachSynergy (Tableau 1b L2 Z=5, Verrou 1A-c). |
| `Crainte` | `axialExpectationNeg` | — | Découpage optionnel : 'appréhender'/'appréhension' penche vers lateralEpistemicClosure (Tableau 1b L2 Z=4). |
| `Croyance` | `axialExpectationPos` | — | Classe mono-entrée active ('croyance') à très faible charge affective (V=+0.05, A=-0.32). |
| `Croyance relig` | `axialExpectationPos` | — | Classe mono-entrée active ('foi') ; forte composante culturelle/religieuse. |
| `Curiosité` | `axialExpectationPos` | — | DÉCOUPAGE IMPÉRATIF par SOUS-CLASSE : 'souci'/'soucieux' (V<-0.51, doublons d'Inquiéter) doivent être rattachés à axialExpectationNeg ; 'engouement' -> diagonalSynergyPos ; 'curieux'/'curiosité'/'attentif' restent en axialExpectationPos (Tableau 1b A1 Z=3). |
| `Doute` | `axialExpectationNeg` | — | DÉCOUPAGE IMPÉRATIF par SOUS-CLASSE : 'circonspection'/'circonspect'/'prudent'/'réservé' (V_harm>=+0.10, suspension réflexive sans dysphorie) relèvent de centralOperator (Réserve Z=4 / Recul Z=5) ; 'doute'/'incertitude'/'scepticisme'/'dubitatif' (V=-0.41 à -0.87) restent en axialExpectationNeg. |
| `Défiance` | `axialExpectationNeg` | — | Découpage par SOUS-CLASSE : 'défiance' (versant combatif) -> lateralActiveContest (Tableau 1b L4 Z=5) ; 'méfiance'/'méfiant' (versant replié) -> axialExpectationNeg (Z=4 Méfiance) ou lateralEpistemicClosure. |
| `Défiance_Sentiment d'insécurité` | `lateralEpistemicClosure` | — | Découpage par SOUS-CLASSE : 'se sentir en insécurité' -> axialExpectationNeg (Tableau 1b A1 Z=5 Insécurité) ; 'pessimisme'/'pessimiste' -> lateralAversiveDistress (Article §8.1 Pessimisme (-2,-6,5)) ; 'suspicion'/'soupçon' -> lateralEpistemicClosure. |
| `Déplaire_A` | `diagonalSynergyNeg` | — | Découpage optionnel : 'horreur' -> lateralEpistemicClosure (Q3 dom. -X). |
| `Désintérêt` | `diagonalSynergyNeg` | — | DÉCOUPAGE IMPÉRATIF par SOUS-CLASSE : 'insouciance'/'insouciant'/'insoucieux' (V=+0.51, doublons Rassurer) -> Q4 lateralSecondaryAccomm ; 'impassibilité'/'impassible' -> lateralSecondaryAccomm ; 'indifférence'/'insensibilité' -> lateralAversiveDistress / diagonalSynergyNeg. |
| `Désir` | `diagonalSynergyPos` | — | Découpage recommandé par SOUS-CLASSE : le noyau actif inclut des états de manque/excès ('avide', 'avidité', 'compulsion', 'convoitise', 'faim', 'fureur', V<0) qui abaissent V_harm à +0.08 alors que 'désir'/'aspiration'/'motivation' sont franchement positifs (V>+0.40). |
| `Désir impatience` | `diagonalSynergyPos` | — | Tension frustrative d'attente (V_harm=-0.39, A=+0.52) : frontière entre Désir bloqué (diagonalSynergyPos) et frustration active en Q2 (diagonalAgenticConfront / lateralAgenticConfront). |
| `Estime respect` | `lateralReceptiveAccomm` | — | Découpage optionnel : 'respect'/'respectueux' égalitaire voisine lateralEpistemicMastery, tandis que 'vénération' et 'crainte révérentielle' relèvent pleinement de la déférence réceptive (Q4 dom. +X). Arbitrage frontière -Z à confirmer. |
| `Goût` | `diagonalSynergyPos` | — | Outlier à isoler : 'jaloux' (V=-0.65, emploi 'jaloux de ses prérogatives') est à écarter de cette classe positive. |
| `Gratitude` | `lateralReceptiveAccomm` | — | Arbitrage frontière -Z : sentiment relationnel prosocial conservé en Z=4 par défaut. |
| `Haine de qq` | `diagonalAgenticConfront` | — | Découpage par SOUS-CLASSE : 'aversion' chevauche Aversion (Q3 diagonalSynergyNeg) ; 'haine' est également repérée en Z=5 dans Tableau 1b D2. |
| `Incrédulité` | `axialExpectationNeg` | — | Classe épistémique (2 entrées actives : 'incrédule', 'incrédulité') candidate à la réserve -Z. |
| `Incrédulité relig` | `axialExpectationNeg` | — | Classe épistémique religieuse (2 entrées actives : 'incroyance', 'incroyant') candidate à la réserve -Z. |
| `Inimitié` | `lateralAgenticConfront` | — | Découpage recommandé par SOUS-CLASSE : les attitudes idéologiques/discriminatoires durables ('antisémitisme', 'racisme', 'xénophobie', 'homophobie', 'misanthropie', '-phobe') relèvent de Z=5 ou de la réserve -Z, tandis que 'hostilité'/'inimitié'/'fâcherie'/'discorde' restent en Z=4 lateralAgenticConfront (Tableau 1b L3). |
| `Intéresser_A` | `diagonalSynergyPos` | — | DÉCOUPAGE IMPÉRATIF : 'préoccupation' (V=-0.25, D=-0.13) est un outlier aversif à rattacher à Inquiéter / axialExpectationNeg ; 'intérêt' voisine Curiosité (axialExpectationPos) ; 'enthousiasme'/'passion' sont exactement en diagonalSynergyPos (Tableau 1b D1). |
| `Irrespect` | `reserve` | — | 8/8 entrées ComportAffect en réserve -Z (si projetée ultérieurement : affinité Q2 lateralActiveContest). |
| `Jalousie envie` | `lateralActiveContest` | — | Découpage optionnel : le versant 'envie' impuissante/dépressive (sans revendication active) voisine lateralAversiveDistress (Q3). |
| `Mauvaise conscience` | `lateralAversiveDistress` | — | Arbitrage frontière -Z : les sous-classes religieuses/expiatoires ('résipiscence', 'pénitence', 'repentance') sont les plus proches de la norme morale (-Z), tandis que 'remords'/'regret'/'contrition' relèvent pleinement de la culpabilité réflexive en Z=4. |
| `Mésestime` | `lateralActiveContest` | — | Classe à D_orth=-0.13 : si lue comme dépréciation froide sans affrontement actif, basculer vers lateralEpistemicClosure (Y < 0) ; maintenue en lateralActiveContest par symétrie avec Mépris/Irrespect. |
| `Nostalgie` | `axialControlNeg` | — | Tonalité douce-amère : le regret du passé révolu ('mal du pays', V=-0.28, D=-0.27) siège en axialControlNeg (impuissance sur le révolu), avec un versant apaisé voisinant lateralSecondaryAccomm. |
| `Orgueil` | `lateralEpistemicMastery` | — | Découpage par SOUS-CLASSE : 'fierté', 'amour-propre', 'contentement de soi' (V>+0.45, D=+0.34) -> jalon exact Tableau 1b L1 Z=4 (Fierté) ; 'autosatisfaction'/'autosatisfait' (glose EN 'smug', V=-0.60) et 'vanité' reflètent un jugement moral d'autrui (candidats CaractAffect/-Z). |
| `Orgueil surestimation de soi` | `lateralEpistemicMastery` | — | Classe 100 % Z_PLUS_SATELLITE (13 locutions familières ; 12 CaractAffect déjà en -Z). Le V_harm=-0.57 mesuré sur 'overconfidence'/'arrogant' reflète la réprobation sociale de l'observateur, non une détresse vécue ; forte affinité avec -Z si épurée des locutions familières. |
| `Peur phobie` | `lateralEpistemicClosure` | — | Ancrée en Z=5 comme disposition phobique durable (agoraphobie, claustrophobie, zoophobie) ; peut se lire en Z=4 sur une phobie centrée sur un objet relationnel spécifique. |
| `Plaire_B` | `lateralReceptiveAccomm` | — | Classe 100 % Z_PLUS_SATELLITE (2 entrées : 'subjugation', 'être sous le charme') ; la glose EN 'subjugation' (V=-0.44) tire artificiellement vers le négatif alors que le sens français est l'enchantement réceptif (si lu comme attirance active -> diagonalSynergyPos). |
| `Pudeur` | `lateralReceptiveAccomm` | — | Arbitrage clinique MP3b : norme/vertu morale de retenue ('modesty') basculée vers la réserve axiologique -Z. |
| `Ressentiment` | `lateralAgenticConfront` | — | Note d'échelle : 'rancœur' figure aussi en Tableau 1b D2 Z=5 (diagonalAgenticConfront). |
| `Résignation` | `lateralAversiveDistress` | 3 | Découpage encodé dans `subclass_overrides` (MP3b, Verrou 1A-c) : {acceptation} -> lateralReceptiveAccomm (L3, Q4, Z=4) ; {résignation, fatalisme} -> lateralAversiveDistress (L1, Q3, Z=4/5). |

---

## 5. Tableau d'arbitrage clinique des 24 entrées frontières `z_minus_value_candidate == True` (9 classes)

Arbitrage clinique définitif sur les 24 entrées restantes dans `Z_PLUS_ACTIVE` (9 classes axiologiques/épistémiques) : **5 classes (`7` entrées) basculées vers `-Z` (`move_to_z_minus_reserve`)** (`Croyance` : 1, `Croyance relig` : 1, `Incrédulité` : 2, `Incrédulité relig` : 2, `Pudeur` : 1) et **4 classes (`17` entrées) maintenues en $Z_+$, $Z = 4$ (`keep_z_plus`)** (`Estime respect` : 4, `Gratitude` : 3, `Mauvaise conscience` : 9, `Mauvaise conscience scrupule` : 1).

| # | Classe DIMA | `lemme_norm` | POS | `sous_classe` | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\perp}$ | Sous-secteur ($Z$) | Arbitrage proposé |
| ---: | :--- | :--- | :---: | :--- | ---: | ---: | ---: | :--- | :--- |
| 1 | `Croyance` | `croyance` | `NOM` | `croyance relig` | `+0.05` | `-0.32` | `-0.04` | `axialExpectationPos` ($Z=5$) | **`move_to_z_minus_reserve`** |
| 2 | `Croyance relig` | `foi` | `NOM` | `foi` | `+0.67` | `-0.56` | `+0.15` | `axialExpectationPos` ($Z=5$) | **`move_to_z_minus_reserve`** |
| 3 | `Estime respect` | `crainte` | `NOM` | `crainte révérentielle` | `+0.29` | `-0.31` | `-0.10` | `lateralReceptiveAccomm` ($Z=4$) | **`keep_z_plus`** |
| 4 | `Estime respect` | `respect` | `NOM` | `respect` | `+0.93` | `-0.49` | `+0.12` | `lateralReceptiveAccomm` ($Z=4$) | **`keep_z_plus`** |
| 5 | `Estime respect` | `respectueux` | `ADJ` | `respect` | `+0.90` | `-0.23` | `+0.16` | `lateralReceptiveAccomm` ($Z=4$) | **`keep_z_plus`** |
| 6 | `Estime respect` | `vénération` | `NOM` | `vénération` | `+0.49` | `+0.30` | `+0.13` | `lateralReceptiveAccomm` ($Z=4$) | **`keep_z_plus`** |
| 7 | `Gratitude` | `gratitude` | `NOM` | `gratitude` | `+0.77` | `-0.12` | `-0.10` | `lateralReceptiveAccomm` ($Z=4$) | **`keep_z_plus`** |
| 8 | `Gratitude` | `reconnaissance` | `NOM` | `reconnaissance` | `+0.77` | `-0.12` | `-0.10` | `lateralReceptiveAccomm` ($Z=4$) | **`keep_z_plus`** |
| 9 | `Gratitude` | `reconnaissant` | `ADJ` | `reconnaissance` | `+0.92` | `-0.29` | `-0.22` | `lateralReceptiveAccomm` ($Z=4$) | **`keep_z_plus`** |
| 10 | `Incrédulité` | `incrédule` | `ADJ` | `incrédulité` | `-0.43` | `+0.02` | `-0.24` | `axialExpectationNeg` ($Z=5$) | **`move_to_z_minus_reserve`** |
| 11 | `Incrédulité` | `incrédulité` | `NOM` | `incrédulité` | `-0.42` | `+0.67` | `-0.24` | `axialExpectationNeg` ($Z=5$) | **`move_to_z_minus_reserve`** |
| 12 | `Incrédulité relig` | `incroyance` | `NOM` | `incroyance relig` | `-0.62` | `-0.18` | `-0.03` | `axialExpectationNeg` ($Z=5$) | **`move_to_z_minus_reserve`** |
| 13 | `Incrédulité relig` | `incroyant` | `ADJ` | `incroyance relig` | `-0.52` | `+0.00` | `-0.09` | `axialExpectationNeg` ($Z=5$) | **`move_to_z_minus_reserve`** |
| 14 | `Mauvaise conscience` | `contrit` | `ADJ` | `contrition` | `-0.31` | `-0.27` | `+0.02` | `lateralAversiveDistress` ($Z=4$) | **`keep_z_plus`** |
| 15 | `Mauvaise conscience` | `contrition` | `NOM` | `contrition` | `-0.31` | `+0.17` | `+0.00` | `lateralAversiveDistress` ($Z=4$) | **`keep_z_plus`** |
| 16 | `Mauvaise conscience` | `regret` | `NOM` | `regret` | `-0.59` | `+0.22` | `-0.12` | `lateralAversiveDistress` ($Z=4$) | **`keep_z_plus`** |
| 17 | `Mauvaise conscience` | `remords` | `NOM` | `remords` | `-0.79` | `+0.35` | `+0.03` | `lateralAversiveDistress` ($Z=4$) | **`keep_z_plus`** |
| 18 | `Mauvaise conscience` | `repentance` | `NOM` | `repentir` | `-0.17` | `+0.21` | `-0.24` | `lateralAversiveDistress` ($Z=4$) | **`keep_z_plus`** |
| 19 | `Mauvaise conscience` | `repentant` | `ADJ` | `repentir` | `-0.35` | `+0.00` | `-0.37` | `lateralAversiveDistress` ($Z=4$) | **`keep_z_plus`** |
| 20 | `Mauvaise conscience` | `repentir` | `NOM` | `repentir` | `-0.10` | `-0.16` | `-0.17` | `lateralAversiveDistress` ($Z=4$) | **`keep_z_plus`** |
| 21 | `Mauvaise conscience` | `résipiscence` | `NOM` | `résipiscence` | `-0.17` | `+0.21` | `-0.24` | `lateralAversiveDistress` ($Z=4$) | **`keep_z_plus`** |
| 22 | `Mauvaise conscience` | `résipiscent` | `ADJ` | `résipiscence` | `-0.35` | `+0.00` | `-0.37` | `lateralAversiveDistress` ($Z=4$) | **`keep_z_plus`** |
| 23 | `Mauvaise conscience scrupule` | `scrupule` | `NOM` | `scrupule` | `-0.33` | `-0.57` | `-0.20` | `lateralEpistemicClosure` ($Z=4$) | **`keep_z_plus`** |
| 24 | `Pudeur` | `pudeur` | `NOM` | `pudeur` | `+0.56` | `-0.52` | `-0.20` | `lateralReceptiveAccomm` ($Z=4$) | **`move_to_z_minus_reserve`** |

---

## 6. Traçabilité des 17 classes `reserve_or_discard_only` et marqueurs exploratoires $Z = 6 / Z = 7$

### 6.1 Les 17 classes sans projection $Z_+$ (`reserve_or_discard_only`)

| Classe DIMA | Cat. | `n_entries` | `Z_MINUS_RESERVE` | `NON_LEXICAL_DISCARD` | Famille `ANTONYMIE` | Note |
| :--- | :---: | ---: | ---: | ---: | :--- | :--- |
| `Bon moral Revigorer` | I | 11 | 11 | 0 | Bon moral-Mauvais moral | Classe 100 % CausAffect en réserve -Z (11 entrées) : aucune projection directe en Z+. |
| `Combler un désir` | I | 11 | 11 | 0 | Combler-Décevoir | Classe 100 % CausAffect en réserve -Z (11 entrées) : aucune projection directe en Z+. |
| `Flatter` | I | 11 | 11 | 0 | Flatter-Blesser | Classe 100 % CausAffect/HumAffect en réserve -Z (11 entrées) : aucune projection en Z+. |
| `Sans surprise` | I | 1 | 1 | 0 | Surprise | Aucune entrée Z+ (réserve -Z uniquement) ; signalée avec central_operator_link: surprise_z1 (Verrou 1A-d). |
| `Z Classifieurs` | I | 12 | 0 | 12 | — | Classe métalinguistique classifieur (12 entrées NON_LEXICAL_DISCARD) : aucune projection en Z+. |
| `Confiance_Crédit` | II | 4 | 4 | 0 | Confiance / Croyance & Défiance / Doute | Classe 100 % CausAffect/ObjAffect en réserve -Z (4 entrées) : aucune projection en Z+. |
| `Confiance_Fiabilité` | II | 6 | 6 | 0 | Confiance / Croyance & Défiance / Doute | Classe 100 % ObjAffect en réserve -Z (6 entrées) : aucune projection en Z+. |
| `Défiance_Discrédit` | II | 5 | 5 | 0 | Confiance / Croyance & Défiance / Doute | Classe 100 % CausAffect/ObjAffect en réserve -Z (5 entrées) : aucune projection en Z+. |
| `Défiance_Non fiabilité` | II | 2 | 2 | 0 | Confiance / Croyance & Défiance / Doute | Classe 100 % ObjAffect/HumAffect en réserve -Z (2 entrées) : aucune projection en Z+. |
| `Déplaire_B` | II | 38 | 38 | 0 | Plaire-Déplaire | Classe 100 % ObjAffect en réserve -Z (38 entrées) : aucune projection en Z+. |
| `Intéresser_B` | II | 23 | 23 | 0 | Intéresser-Laisser indifférent | Classe 100 % ObjAffect en réserve -Z (23 entrées) : aucune projection en Z+. |
| `Irrespect` | II | 8 | 8 | 0 | Estime / Respect & Mésestime / Irrespect | Classe 100 % ComportAffect en réserve -Z (8 entrées) : aucune projection en Z+. |
| `Laisser indifférent_A` | II | 1 | 1 | 0 | Intéresser-Laisser indifférent | Classe 100 % ObjAffect en réserve -Z (1 entrée) : aucune projection en Z+. |
| `Laisser indifférent_B` | II | 16 | 16 | 0 | Intéresser-Laisser indifférent | Classe 100 % ObjAffect en réserve -Z (16 entrées) : aucune projection en Z+. |
| `Orgueil impudence` | II | 8 | 8 | 0 | Orgueil / Honte / Pudeur | Classe 100 % ComportAffect en réserve -Z (8 entrées) : aucune projection en Z+. |
| `Sentiment` | II | 3 | 3 | 0 | — | Classe 100 % CaractAffect en réserve -Z (3 entrées) : aucune projection en Z+. |
| `Sentiment classifieur` | II | 3 | 0 | 3 | — | Classe métalinguistique classifieur (3 entrées NON_LEXICAL_DISCARD) : aucune projection en Z+. |

### 6.2 Marqueurs documentaires facultatifs `exploratory_z6_z7_tag` (`10` classes, conservées dans $Z \in \{3, 4, 5\}$)

| Classe DIMA | $Z$ normatif | Sous-secteur | `exploratory_z6_z7_tag` |
| :--- | :---: | :--- | :--- |
| `Combler Bonheur` | 3 | `axialControlPos` | `z7_transcendental_candidate` |
| `Inquiéter Effrayer` | 3 | `lateralEpistemicClosure` | `z6_z7_effraction_candidate` |
| `Mauvais moral` | 5 | `lateralAversiveDistress` | `z6_z7_effraction_candidate` |
| `Surprendre` | 3 | `centralOperator` | `z6_z7_effraction_candidate` |
| `Troubler` | 3 | `centralOperator` | `z6_z7_effraction_candidate` |
| `Admiration` | 4 | `lateralReceptiveAccomm` | `z7_transcendental_candidate` |
| `Amour` | 4 | `diagonalSynergyPos` | `z6_z7_transcendence_candidate` |
| `Confiance` | 5 | `axialExpectationPos` | `z7_transcendental_candidate` |
| `Croyance relig` | 5 | `axialExpectationPos` | `z7_transcendental_candidate` |
| `Peur panique` | 3 | `lateralEpistemicClosure` | `z6_z7_effraction_candidate` |
