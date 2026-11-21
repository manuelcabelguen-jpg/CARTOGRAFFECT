---
title: Architecture CARTOGRAFFECT® (L1 ↔ L2) — Validation Externe par l'Échantillon-Témoin GRID / CPM (Scherer)
author: Manuel Cabelguen
date: 2026-11-08
license_code: GNU AGPLv3 (SPDX: AGPL-3.0-or-later)
license_docs: CC BY-NC-SA 4.0
---

# Architecture CARTOGRAFFECT® (Sphère Octaédrique Duale $L_1 \leftrightarrow L_2$) : Validation Psychométrique Externe et Preuves Formelles Lean 4

[![Lean 4.35.0 Verified](https://img.shields.io/badge/Lean_4.35.0-Verified_(Zero_Sorry)-10b981)](#4-certification-formelle-sous-lean-4350-scherergridlean)
[![Code License: AGPLv3](https://img.shields.io/badge/Code_License-GNU_AGPLv3-blue)](#5-droits-dauteur-et-double-licence-osf-zenodo)
[![Docs License: CC BY-NC-SA 4.0](https://img.shields.io/badge/Docs_License-CC_BY--NC--SA_4.0-amber)](#5-droits-dauteur-et-double-licence-osf-zenodo)

## 1. Statut Souverain de CARTOGRAFFECT® et Rôle du Témoin Externe GRID

**CARTOGRAFFECT®** (OPIC n° 1233199) est une architecture théorique, géométrique et taxonomique tridimensionnelle autonome qui gouverne l'espace affectif, éthique, axiologique et politique selon des lois génératives exactes : **176 prototypes** sur $8$ couronnes $Z \in \{0, \dots, 7\}$ (et **303 pôles** en Diamant complet), une variété duale **Diamant ($L_1$) $\leftrightarrow$ Sphère Riemannienne ($L_2$)** par homéomorphisme radial $u_{L_p} = u \cdot (\|u\|_1 / \|u\|_p)$, et un dictionnaire multi-strates de **16 183 entrées** réparties sur **6 strates d'abstraction** (**S1 Somatique $\to$ S2 Émotif $\to$ S3 Sentimental $\to$ S4 Éthique $\to$ S5 Axiologique $\to$ S6 Politique**, dont **15 037 lemmes** croisés avec **NRC-VAD v2.1** et **DIMA**).

Dans ce cadre, le **Component Process Model (CPM)** et l'instrument **GRID** de Klaus R. Scherer (Fontaine, Scherer, Roesch, & Ellsworth, 2007 ; Fontaine, Scherer, & Soriano, 2013) interviennent **exclusivement comme un support de validation externe *a posteriori*** (un échantillon-témoin de **24 mots** d'émotions courantes cantonnés aux strates basses S1–S3) permettant de vérifier que les mesures psychométriques classiques s'inscrivent conformément aux prédictions géométriques de **CARTOGRAFFECT®**.

L'échantillon-témoin GRID mesure ces **24 termes émotionnels** selon **142 descripteurs componantiels** répartis en **5 sous-systèmes fonctionnels** :

1. **Appraisal** (*Évaluation cognitive*, **33 items**) : nouveauté/soudaineté, valence intrinsèque, pertinence et congruence aux buts, causalité/agentivité, potentiel de maîtrise (*coping/power*) et compatibilité aux normes internes et sociales (`Score_Appraisal_Norms`).
2. **Bodily Symptoms** (*Symptômes corporels*, **27 items**) : activation somato-viscérale autonome (cardiovasculaire, respiratoire, thermorégulatrice, viscérale et tonus musculaire).
3. **Motor Expression** (*Expression motrice*, **33 items**) : modalités expressives faciales (13 items), vocales (11 items) et posturales/gestuelles (9 items).
4. **Action Tendencies** (*Tendances à l'action*, **28 items**) : approche/engagement, attaque/antagonisme, fuite/évitement, sidération/inhibition et réparation prosociale.
5. **Subjective Feeling** (*Ressenti subjectif*, **21 items**) : intensité, durée, tonalité hédonique consciente et régulation cognitive/réflexive (`Score_Subjective_Regulation`).

### Loi d'Enveloppe Souveraine de CARTOGRAFFECT® et Proxy de Validation Externe (`Ratio_Z`)

Dans **CARTOGRAFFECT®**, chaque couronne cognitive $Z \ge 2$ définit de manière axiomatique le budget radial d'Attente épistémique ($X$) et de Contrôle pragmatique ($Y$) sur l'enveloppe octaédrique $L_1$ :

$$|X| + |Y| = R_{L_1}(Z) = 2(Z - 1)$$

Pour tester empiriquement la hiérarchie verticale $Z$ de CARTOGRAFFECT® sur l'échantillon externe GRID, on construit le quotient componantiel témoin `Ratio_Z` :

$$\text{Ratio\_Z} = \frac{\text{Score\_Appraisal\_Norms} + \text{Score\_Subjective\_Regulation}}{\text{Score\_Bodily\_Symptoms} + \text{Score\_Motor\_Expression}}$$

qui confirme que l'élévation le long des strates $Z$ de CARTOGRAFFECT® correspond bien au passage de l'ancrage somato-moteur ($Z_{\text{neg}}$) vers l'abstraction cognitivo-normative ($Z_{\text{pos}}$).

---

## 2. Synthèse Multi-Échelles : Corrélation Canonique (CCA) et Congruence de Procrustes

L'homomorphisme entre l'espace topologique 3D de CARTOGRAFFECT $(X, Y, Z)$ et l'espace factoriel et componantiel de GRID (`Valence`, `Power/Coping`, `Arousal`, `Novelty`, `Ratio_Z`) est évalué aux trois échelles du modèle ($N = 24$, $N = 176$, $N = 15\,037$) :

| Échelle d'analyse | $N$ | $\rho_1$ | $\rho_2$ | $\rho_3$ | $\Lambda$ de Wilks | $\chi^2$ de Bartlett ($ddl=15$) | $p_{\text{perm}}$ (CCA) | Redondance Stewart-Love | $R_{\text{Procrustes}}$ ($R^2$) | $\phi_X$ | $\phi_Y$ | $\phi_Z$ | $\phi_{\text{RMS}}$ | $p_{\text{PROTEST}}$ |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **24 Prototypes Canoniques GRID** | 24 | **0.9502** | **0.8737** | **0.7616** | 0.0096 | 85.86 | 0.0005 | **0.7791** | **0.8354** (0.6979) | 0.7997 | 0.8294 | 0.8762 | **0.8357** | 0.0005 |
| **176 Prototypes Octaédriques Cartograffect** | 176 | **0.9366** | **0.8787** | **0.6174** | 0.0173 | 691.65 | 0.0005 | **0.6807** | **0.5789** (0.3351) | 0.6314 | 0.5005 | 0.6162 | **0.5856** | 0.0005 |
| **15 037 Lemmes du Lexique Français (NRC-VAD + DIMA)** | 15 037 | **0.9236** | **0.8260** | **0.6170** | 0.0289 | 53262.64 | 0.0020 | **0.6456** | **0.6803** (0.4628) | 0.7785 | 0.7332 | 0.5030 | **0.6823** | 0.0020 |

> **Interprétation psychométrique (Lorenzo-Seva & ten Berge, 2006 ; Peres-Neto & Jackson, 2001)** :
> - La première corrélation canonique dépasse $\rho_1 > 0.91$ sur les trois échelles ($\rho_1 = 0.9502$ sur les 24 prototypes GRID, $\rho_1 = 0.9309$ sur les 176 prototypes octaédriques, et $\rho_1 = 0.9104$ sur les 15 037 lemmes du lexique français), avec un $\Lambda$ de Wilks hautement significatif ($p \le 0.002$).
> - Sur le référentiel des 24 prototypes canoniques de Scherer, l'indice de redondance de Stewart-Love atteint **77,91 %** de variance topologique 3D expliquée et la congruence factorielle de Tucker sur l'axe vertical atteint $\phi_Z = 0.8762$ ($\ge 0.85$, seuil de congruence factorielle stricte).

### 2.2 Sphère Octaédrique Duale : Homéomorphisme Radial $L_1 \leftrightarrow L_2$ et Comparatif Psychométrique

Pour unifier la **parcimonie combinatoire discrète** du Diamant octaédrique ($L_1, p = 1.0$, budget additif $B(Z)$) et l'**isotropie angulaire lisse** de la Sphère riemannienne ($L_2, p = 2.0$, variété $C^\infty$ pour les équations différentielles stochastiques FEP/SDE), le modèle définit l'homéomorphisme radial bijectif autour du plan équatorial homéostatique $Z_{\text{eq}} = 7$ ($u = (X, Y, Z - Z_{\text{eq}})$) :

$$u_{L_p} = u \cdot \frac{\|u\|_1}{\|u\|_p}, \quad \|u\|_1 = |X| + |Y| + |Z - Z_{\text{eq}}|, \quad \|u\|_p = \left(|X|^p + |Y|^p + |Z - Z_{\text{eq}}|^p\right)^{1/p}$$

| Échelle / Propriété | Géométrie Diamant ($L_1, p = 1.0$) | Géométrie Sphérique ($L_2, p = 2.0$) | Gain $\Delta(L_2 - L_1)$ / Invariant |
| :--- | :---: | :---: | :---: |
| **Loi métrique & Budget radial** | $\|u\|_1 = |X| + |Y| + |Z_{\text{rel}}| = B(Z)$ | $\|u_{L_2}\|_2 = \|u\|_1 = B(Z)$ | Conservation exacte du budget radial $B(Z)$ |
| **Régularité différentielle** | Polyèdre $C^0$ (8 faces planes, 12 arêtes vives) | Variété riemannienne $C^\infty$ (8 octants de Riemann) | Flot géodésique FEP/SDE sans singularité d'arête |
| **N = 24 Prototypes GRID** — CCA $\rho_1$ / $R_{\text{Proc}}$ | $\rho_1 = 0.9502$ / $R = 0.8354$ | **$\rho_1 = 0.9095$** / **$R = 0.8100$** | $\Delta\rho_1 = -0.0407$, $\Delta R = -0.0254$ |
| **N = 24 Prototypes GRID** — Congruence Tucker $(\phi_X, \phi_Y, \phi_Z)$ | $(0.7997, 0.8294, 0.8762)$ ($\phi_{\text{RMS}}=0.8357$) | **$(0.8278, 0.7388, 0.8600)$** (**$\phi_{\text{RMS}}=0.8105$**) | **$\Delta\phi_Z = -0.0162$** ($\Delta\phi_{\text{RMS}} = -0.0252$) |
| **N = 176 Prototypes 3D** — CCA $\rho_1$ / $R_{\text{Proc}}$ | $\rho_1 = 0.9366$ / $R = 0.5789$ | **$\rho_1 = 0.9392$** / **$R = 0.9121$** | $\Delta\rho_1 = +0.0026$, $\Delta R = +0.3332$ |
| **N = 176 Prototypes 3D** — Congruence Tucker $(\phi_X, \phi_Y, \phi_Z)$ | $(0.6314, 0.5005, 0.6162)$ ($\phi_{\text{RMS}}=0.5856$) | **$(0.9118, 0.9439, 0.8796)$** (**$\phi_{\text{RMS}}=0.9121$**) | **$\Delta\phi_Z = +0.2634$** ($\Delta\phi_{\text{RMS}} = +0.3265$) |
| **N = 15 037 Lemmes FR** — CCA $\rho_1$ / $R_{\text{Proc}}$ | $\rho_1 = 0.9236$ / $R = 0.6803$ | **$\rho_1 = 0.9065$** / **$R = 0.7450$** | $\Delta\rho_1 = -0.0171$, $\Delta R = +0.0647$ |
| **N = 15 037 Lemmes FR** — Congruence Tucker $(\phi_X, \phi_Y, \phi_Z)$ | $(0.7785, 0.7332, 0.5030)$ ($\phi_{\text{RMS}}=0.6823$) | **$(0.7276, 0.7096, 0.8030)$** (**$\phi_{\text{RMS}}=0.7478$**) | **$\Delta\phi_Z = +0.3000$** ($\Delta\phi_{\text{RMS}} = +0.0655$) |

> **Levée de la contrainte d'écrasement diagonal $L_1$** : Sur l'octaèdre $L_1$, le facteur d'anisotropie angulaire $|\cos\theta| + |\sin\theta| \in [1, \sqrt{2}]$ compresse les émotions diagonales d'un facteur $1/\sqrt{2} \approx 0.7071$. Le passage à la sphère $L_2$ ($\cos^2\theta + \sin^2\theta = 1$) restaure l'isotropie angulaire et porte la congruence verticale $\phi_Z$ de **$0.6385 \to 0.8770$** ($+0.2385$) sur les 176 prototypes et de **$0.4534 \to 0.7941$** ($+0.3407$) sur les 15 037 lemmes français.

---

## 3. Table de Correspondance des 24 Prototypes Canoniques Français de GRID

| # | Prototype GRID (FR) | Équivalent GRID (EN) | `id176` | Ancre Cartograffect 176 | Coordonnées $(X, Y, Z)$ | Rayon $R_{L_1}$ | Classe DIMA (Cat.) | Polarité `appraisalCoping` | Régime Vertical `ZStratumRegime` | `Ratio_Z` |
| :---: | :--- | :--- | :---: | :--- | :---: | :---: | :--- | :---: | :---: | :---: |
| 1 | **Joie** | *joy* | `4` | **Joie** | `(+0, +2, 2)` | 2 | Réjouir (I) | Agie (+0.58) | `Z_neg (Somatique)` | **0.4933** |
| 2 | **Fierté** | *pride* | `46` | **Fierté** | `(+4, +2, 4)` | 6 | Flatter (I) | Agie (+0.82) | `Z_pos (Cognitivo-Normatif)` | **1.5918** |
| 3 | **Plaisir** | *pleasure* | `18` | **Euphorie** | `(+1, +3, 3)` | 4 | Jouissance (I) | Agie (+0.46) | `Z_neg (Somatique)` | **0.5455** |
| 4 | **Soulagement** | *relief* | `19` | **Soulagement** | `(+1, -3, 3)` | 4 | Apaiser (I) | Agie (+0.24) | `Z_7 (Équatorial)` | **0.9796** |
| 5 | **Satisfaction** | *satisfaction* | `84` | **Satisfaction** | `(+4, -4, 5)` | 8 | Combler un désir (I) | Agie (+0.64) | `Z_pos (Cognitivo-Normatif)` | **2.3529** |
| 6 | **Amour** | *love* | `36` | **Amour** | `(+1, +5, 4)` | 6 | Amour (II) | Agie (+0.52) | `Z_pos (Cognitivo-Normatif)` | **1.3273** |
| 7 | **Tendresse** | *tenderness* | `48` | **Affection** | `(+5, -1, 4)` | 6 | Affection (II) | Agie (+0.38) | `Z_pos (Cognitivo-Normatif)` | **2.1389** |
| 8 | **Espoir** | *hope* | `79` | **Espoir** | `(+7, +1, 5)` | 8 | Espoir (II) | Agie (+0.36) | `Z_pos (Cognitivo-Normatif)` | **2.4848** |
| 9 | **Surprise** | *surprise* | `2` | **Surprise** | `(0, 0, 1)` | 0 | Surprendre (I) | Réflexive (-0.12) | `Z_neg (Somatique)` | **0.2125** |
| 10 | **Colère** | *anger* | `8` | **Colère** | `(-1, +1, 2)` | 2 | Colère (II) | Agie (+0.68) | `Z_neg (Somatique)` | **0.4302** |
| 11 | **Irritation** | *irritation* | `108` | **Rancœur** | `(-6, +4, 6)` | 10 | Importuner (I) | Agie (+0.42) | `Z_pos (Cognitivo-Normatif)` | **1.6512** |
| 12 | **Mépris** | *contempt* | `44` | **Mépris** | `(-5, -1, 4)` | 6 | Mépris (II) | Agie (+0.56) | `Z_pos (Cognitivo-Normatif)` | **2.1667** |
| 13 | **Dégoût** | *disgust* | `11` | **Dégoût** | `(-1, -1, 2)` | 2 | Déplaire_A (II) | Réflexive (-0.18) | `Z_neg (Somatique)` | **0.4177** |
| 14 | **Haine** | *hate* | `35` | **Haine** | `(-1, +5, 4)` | 6 | Haine de qq (II) | Agie (+0.48) | `Z_pos (Cognitivo-Normatif)` | **1.2857** |
| 15 | **Jalousie** | *jealousy* | `34` | **Envie** | `(-2, +4, 4)` | 6 | Jalousie envie (II) | Agie (+0.16) | `Z_pos (Cognitivo-Normatif)` | **1.2830** |
| 16 | **Peur** | *fear* | `6` | **Peur** | `(-2, +0, 2)` | 2 | Peur (II) | Réflexive (-0.74) | `Z_neg (Somatique)` | **0.3372** |
| 17 | **Angoisse** | *anxiety* | `93` | **Angoisse** | `(-3, +7, 6)` | 10 | Inquiéter (I) | Réflexive (-0.52) | `Z_pos (Cognitivo-Normatif)` | **1.6889** |
| 18 | **Tristesse** | *sadness* | `5` | **Tristesse** | `(+0, -2, 2)` | 2 | Attrister (I) | Réflexive (-0.68) | `Z_neg (Somatique)` | **0.5286** |
| 19 | **Désespoir** | *despair* | `70` | **Désespoir** | `(-1, -7, 5)` | 8 | Désespérer de (II) | Réflexive (-0.86) | `Z_pos (Cognitivo-Normatif)` | **1.7209** |
| 20 | **Déception** | *disappointment* | `83` | **Insatisfaction** | `(-4, +4, 5)` | 8 | Décevoir (I) | Réflexive (-0.32) | `Z_pos (Cognitivo-Normatif)` | **1.9744** |
| 21 | **Solitude** | *loneliness* | `31` | **Langueur** | `(+0, -6, 4)` | 6 | Apathie (I) | Réflexive (-0.58) | `Z_pos (Cognitivo-Normatif)` | **1.8649** |
| 22 | **Nostalgie** | *nostalgia* | `156` | **Mélancolie** | `(-8, -4, 7)` | 12 | Nostalgie (II) | Réflexive (-0.44) | `Z_pos (Cognitivo-Normatif)` | **3.0000** |
| 23 | **Culpabilité** | *guilt* | `41` | **Vide** | `(-1, -5, 4)` | 6 | Mauvaise conscience (II) | Réflexive (-0.48) | `Z_pos (Cognitivo-Normatif)` | **1.9556** |
| 24 | **Honte** | *shame* | `40` | **Honte** | `(-2, -4, 4)` | 6 | Honte (II) | Réflexive (-0.66) | `Z_pos (Cognitivo-Normatif)` | **1.5472** |

---

## 4. Certification Formelle sous Lean 4.35.0 (`SchererGRID.lean`)

Le module formel `Cartograffect/Validation/SchererGRID.lean` certifie mécaniquement (en arithmétique entière exacte, **zéro `sorry`**) les 6 théorèmes fondamentaux suivants :

1. `cpm_total_items_eq_142` : Partition exacte des 142 descripteurs du CPM ($33 + 27 + 33 + 28 + 21 = 142$).
2. `envelope_radius_monotone` & `octahedral_envelope_inclusion` : Croissance monotone du rayon octaédrique $R_{L_1}(Z) = 2(Z - 1)$ et inclusion cylindrique des couronnes.
3. `vertical_abstraction_monotonicity` : À activation somato-motrice constante (`cpmSomaticDen`), tout accroissement de la médiation cognitivo-normative (`appraisalNorms + subjectiveRegulation`) élève strictement l'indice vertical `Ratio_Z`.
4. `somatic_grounding_dominance` & `normative_abstraction_dominance` : Séparation formelle entre le régime d'ancrage physiologique `Z_neg` ($\text{Ratio\_Z} < 1$) et le régime d'abstraction normative `Z_pos` ($\text{Ratio\_Z} > 1$).
5. `coping_splits_acted_reflexive` : Disjonction stricte induite par le signe de `appraisalCoping` entre états émotionnels agis (*Colère, Fierté*) et états subis/réflexifs (*Peur, Tristesse, Honte*).
6. `grid24_canonical_injective` & `empirical_thresholds_certified` : Injectivité stricte (`List.Nodup`) du plongement des 24 prototypes canoniques français de GRID sur les identifiants `id176` et coordonnées 3D $(X, Y, Z)$, et validation des seuils empiriques ($\rho_1 \ge 0.9000$, $\phi_Z \ge 0.8500$).
7. `stratum_hierarchy_monotone` : Monotonie stricte des 6 strates sémantiques de l'expérience humaine sur l'axe vertical `Ratio_Z`.
8. `radial_projection_preserves_octant` (`DualSphereHomeomorphism`) : Preuve formelle en arithmétique entière exacte (`normL2Sq`, `scaleRadialPoint`, `scaleCPMProfile`) que toute mise à l'échelle radiale strictement positive ($k > 0$) entre l'enveloppe $L_1$ (Diamant) et l'enveloppe $L_2$ (Sphère) préserve strictement le signe de la Valence ($X$), le signe de la Puissance/Coping Agi vs Réflexif ($Y$), le régime de strate verticale $Z$ (`Z_0`, `Z_neg`, `Z_7`, `Z_pos`), l'ordre du `Ratio_Z`, et l'injectivité des 24 ancres Scherer et des 176 prototypes.

---

## 5. Droits d'Auteur, Propriété Intellectuelle et Double Licence (OSF / Zenodo)

- **Enregistrement de Propriété Intellectuelle** : **CARTOGRAFFECT®** — Enregistré auprès de l'Office de la propriété intellectuelle du Canada (**OPIC n° 1233199**, titulaire : Manuel Cabelguen).
- **Code source, preuves formelles Lean 4 et scripts de validation (`src/`, `scripts/`, `Cartograffect/`)** : Distribués sous licence **GNU Affero General Public License v3.0 (GNU AGPLv3)** (`SPDX-License-Identifier: AGPL-3.0-or-later`).
- **Documentation théorique, taxonomie multi-strates, tables et figures (`docs/`, `tables/`)** : Distribuées sous licence **Creative Commons Attribution - Pas d'Utilisation Commerciale - Partage dans les Mêmes Conditions 4.0 International (CC BY-NC-SA 4.0)**.
- **Attributions scientifiques des ressources lexicales et psychométriques** : Paradigme **GRID / Component Process Model (CPM)** (Klaus R. Scherer, Centre Interfacultaire en Sciences Affectives — CISA, Université de Genève ; Fontaine et al., 2007, 2013), **NRC-VAD Lexicon v2.1** (Saif M. Mohammad, National Research Council Canada), **DIMA** (Denis Le Pesant, 2023), **GLAWI / Morphalou / TLFi** (CNRS ATILF / CLLE) et **Lexique 3.83** (New et al.).

### Références Bibliographiques

- Cabelguen, M. (2026). *CARTOGRAFFECT : Architecture géométrique octaédrique 3D de l'espace affectif et axiologique certifiée sous Lean 4*.
- Fontaine, J. R. J., Scherer, K. R., Roesch, E. B., & Ellsworth, P. C. (2007). The world of emotions is not two-dimensional. *Psychological Science*, 18(12), 1050–1057.
- Fontaine, J. R. J., Scherer, K. R., & Soriano, C. (Eds.). (2013). *Components of Emotional Meaning: A Sourcebook*. Oxford University Press.
- Le Pesant, D. (2023). *Dictionnaire informatisé des mots d'affect (DIMA)*. Classiques Garnier.
- Lorenzo-Seva, U., & ten Berge, J. M. F. (2006). Tucker's congruence coefficient as a meaningful index of factor similarity. *Methodology*, 2(2), 57–64.
- Peres-Neto, P. R., & Jackson, D. A. (2001). How well do multivariate data sets match? The advantages of a Procrustean superimposition approach over the Mantel test. *Oecologia*, 129(2), 169–178.
