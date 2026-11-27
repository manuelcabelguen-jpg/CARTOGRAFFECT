# Protocole Pré-enregistré OSF / Stage 1 Registered Report — Étude 1 Critique (CARTOGRAFFECT v3.0 : V2 → V3)

**Titre complet :** *Testing the Geometry of Core Affect: Instrumental Controllability, Autonomous Arousal, Minkowski Capacity Norm ($L_1$ vs $L_2$), Rolls’ $2 \times 2$ Contingencies, and Contralateral Antagonism in a Cross-Linguistic Study ($N \ge 600$)*  
**Type de manuscrit :** Stage 1 Registered Report (pré-enregistrement OSF avant toute collecte humaine)  
**Auteur :** Manuel Cabelguen, Ph. D. (`manuelcabelguen@gmail.com`)  
**Référentiel théorique & formel :** CARTOGRAFFECT `v3.0.0` (`docs/01-Article_Cartograffect.md`, `DECISIONS_V3.md`, `FORMAL_AUDIT_PACK.md`, commit de référence `66d9a0d`)  
**Dépôts & Identifiants :** OSF [`https://osf.io/z89sg`](https://osf.io/z89sg) · GitHub `manuelcabelguen-jpg/CARTOGRAFFECT` · Zenodo Article [`10.5281/zenodo.24022795`](https://doi.org/10.5281/zenodo.24022795) · Zenodo Code [`10.5281/zenodo.23833938`](https://doi.org/10.5281/zenodo.23833938) · CIPO / OPIC `1233199`  
**Licences (séparation physique FAIR4RS / OSI) :** Protocole & textes sous **`CC-BY-4.0`** (`LICENSE-CC-BY-4.0.md`) · Pipeline analytique `protocols/study1_analysis_pipeline.py` sous **`AGPL-3.0-or-later`** (`LICENSE`)  
**Statut épistémique :** **Stage 1 pré-collecte (`V3 = 0` donnée humaine collectée à ce jour)**. Les seules vérifications exécutées avant gel OSF sont des tests de cohérence interne (`synthetic_identifiability_check` dans `extensions/in_silico/results/v3_identifiability_report.json` et `pilot_pipeline_dry_run` dans `protocols/study1_analysis_pipeline.py`), qui ne constituent **aucune validation empirique ni clinique**.

---

## 1. Positionnement dans le Programme Empirique V2 → V3

CARTOGRAFFECT `v3.0.0` repose sur un noyau formel certifié mécaniquement en Lean 4 (**8 modules normatifs, 148 théorèmes substantiels / 169 déclarations exportées, 8 théorèmes piliers, 0 `sorryAx`, 0 `native_decide`**) dont la cohérence déductive interne ne préjuge en rien de sa validité empirique (`V3 = 0`). Le programme empirique V2 → V3 se déploie en **trois études séquentielles à portes bloquantes** :

1. **Étude 1 (présent Stage 1 Registered Report — Porte structurale critique, $N \ge 600$, cohortes FR + EN) :** Soumet à falsification sévère l'architecture statique et géométrique de `v3.0.0` (Option 1A, surface remplie $|x| + |y| \le R(Z)$, exposant libre $p$ sur la frontière de capacité $A = 1$, bijection $2 \times 2$ de Rolls sur $Z = 2$ et loi contralatérale des 8 paires conjuguées du Tableau 1b). **Si l'Étude 1 réfute un postulat architectural central (notamment la norme $L_1$ ou le découplage $Y/A$), le modèle est formellement révisé ou abandonné avant tout passage aux Études 2 et 3.**
2. **Étude 2 (Comportementale & psychophysiologique en laboratoire — post-Étude 1) :** Tâche comportementale orthogonale $2 \times 2$ (Volatilité × Contrôlabilité) couplée à la conductance cutanée (SCR) et à la variabilité de la fréquence cardiaque (HRV) testant l'estimation individuelle des 5 paramètres orthogonalisés $(\rho, p, \gamma_A, \chi, \beta)$ (dont l'identifiabilité préalable sous bruit ordinal réaliste a été vérifiée par `synthetic_identifiability_check` : $\min r = 0{,}926$, $\max |r_{\text{off-diag}}| = 0{,}174 < 0{,}35$), la règle lexicographique P4 (notamment le quadrant risqué $(+X\text{ faible}, -Y\text{ fort})$) et la médiation instrumentale P5 (`Peur → Colère` vs `Peur → Dégoût` contre l'hypothèse rivale `Peur → Tristesse`).
3. **Étude 3 (EMA écologique sur 14 jours — post-Étude 2) :** Séries temporelles intensives en vie quotidienne testant la prédiction P2 (instabilité axiale asymétrique Option 3b restreinte à `Peur` et `Tristesse`, avec normalisation exacte par probabilité marginale d'occupation ; `Joie` et `Courage` relaxant vers `Veille`) et P3 (persistance croissante et moindre révision le long de la profondeur continue $Z \in [0, 5]$).

---

## 2. Hypothèses Sévères et Critères Numériques de Réfutation *a priori*

Aucune clause d'immunisation *ad hoc* n'est admise : **aucun sous-ensemble de stimuli ou de participants ne peut être exclu *post hoc*** au motif de « conditions non concurrentes » ou d'« incompatibilité lexicale ». Chaque test confronte CARTOGRAFFECT `v3.0.0` à des modèles rivaux explicites par **Facteurs de Bayes ($\text{BF}_{10} > 10$ pour corroboration ; $\text{BF}_{01} > 10$ pour réfutation)** et par **comparaison prédictive hors-échantillon (PSIS-LOO-CV et WAIC, seuil $|\Delta\text{ELPD}_{\text{LOO}}| > 2\,\text{SE}$)**.

### 2.1. Test 1A — Validité de construit de $Y$, orthogonalité du canal autonome $A$ et structure radiale du Tableau 1b ($Z = 2..5$)

- **Objet théorique :** Option 1A (`DECISIONS_V3.md` §1) — `Y` mesure **exclusivement la contrôlabilité instrumentale perçue**, découplée du canal autonome d'activation physiologique / mobilisation allostatique `A ≥ 0`, et chaque strate $Z \in \{2, 3, 4, 5\}$ déploie une **surface remplie** $|x| + |y| \le R(Z)$ structurée radialement entre **périmètre** ($A$ élevé, frontière de capacité $A = 1$) et **surface intérieure** ($A$ modéré/bas, $A < 1$).
- **Matériel en aveugle :** Évaluation en aveugle des jalons du **Tableau 1b** ($Z = 2..5$ : les 8 prototypes canoniques + centre `Anticipation` en $Z = 2$, ainsi que les paires Périmètre $A$ haut / Surface intérieure $A$ bas couvrant les **17 sous-secteurs fonctionnels** sur $Z = 3, 4, 5$, présentés en ordre aléatoire sans aucune coordonnée ni étiquette théorique) sur quatre échelles validées indépendantes :
  1. **Orientation épistémique / révisabilité (`X`)** : *« Dans cet état, dans quelle mesure la personne sent-elle pouvoir intégrer ou réviser sa compréhension de la situation face à ce qui arrive ? »* (échelle visuelle analogique continue VAS `-100` à `+100`, ancrée *Totalement bloqué / irrévisable* à *Totalement ouvert / révisable* ; convertie sur `[-1, +1]`).
  2. **Contrôlabilité instrumentale stricte (`Y`)** : *« Dans cet état, dans quelle mesure la personne sent-elle disposer d'une capacité concrète d'agir pour modifier la situation ? »* (VAS `-100` à `+100`, *Aucune prise d'action / limite objective* à *Pleine prise d'action instrumentale*).
  3. **Activation autonome perçue (`A`)** : *« Dans cet état, quelle est l'intensité de la mobilisation physiologique et corporelle (rythme cardiaque, tension musculaire, urgence viscérale) ? »* (VAS `0` à `100`, *Repos corporel minimal* à *Mobilisation maximale*).
  4. **Tonalité hédonique / valence (`V`)** : *« Dans cet état, le vécu est-il globalement désagréable ou agréable ? »* (VAS `-100` à `+100`), permettant en outre un contrôle secondaire de la priorité hédonique P4 sur $(X > 0, Y < 0)$.
- **Prédictions directionnelles ($H_1$) :**
  - **1A-i (Dissociation instrumentale sur $Y$) :** Les états aversifs à faible contrôle perçu (`Angoisse`, `Terreur`, `Honte`, `Désespoir`, `Alarme`, `Aversion`, `Dégoût`, `Frayeur`) obtiennent un score `Y` strictement inférieur aux états d'opposition agentique (`Colère`, `Frustration`, `Hostilité`, `Révolte`, `Exaspération`, `Rage`, `Indignation`), avec $d_z \ge 0{,}50$, IC 95 % excluant `0` et $\text{BF}_{10} > 10$ dans chacune des cohortes FR et EN.
  - **1A-ii (Gradient radial Périmètre vs Intérieur sur $A$) :** Sur $Z \in \{3, 4, 5\}$, les jalons de périmètre ($A$ haut) dépassent significativement leurs homologues de surface intérieure ($A$ bas) sur l'échelle $A$ ($d_z \ge 0{,}40$, $\text{BF}_{10} > 10$) et le modèle **surface remplie 3 canaux** $(X, Y, A)$ surpasse le modèle **anneau plat 2D** sans modulation radiale $A$ ($\Delta\text{ELPD}_{\text{LOO}} > 2\,\text{SE}$).
  - **1A-iii (Orthogonalité de $Y$ et $A$) :** La corrélation empirique globale $|r(Y, A)|$ (au niveau essai et au niveau centroïdes d'items) demeure strictement inférieure au seuil de colinéarité $0{,}70$ (cible $|r| < 0{,}40$), et la représentation 3 canaux $(X, Y, A)$ surpasse le modèle bidimensionnel Valence–Activation de Russell (1980) en LOO-CV / WAIC.
  - **1A-iv (Symétrie sémantique sur $Y-$) :** Les états d'accommodation positive face à une limite objective d'action (`Calme`, `Acceptation`, `Lâcher-prise`, `Patience`, `Stoïcisme`) obtiennent un score `Y` inférieur aux états de maîtrise/sécurité (`Joie`, `Fierté`, `Sécurité`, `Plénitude`, `Sérénité`), tout en conservant une valence nette positive ($V > 0$).
- **Critères explicites de RÉFUTATION de 1A (aucune clause d'échappement) :**
  Le Test 1A est déclaré **RÉFUTÉ** si **l'une quelconque** des conditions suivantes survient :
  1. $d_z(\text{Opposition agentique} - \text{Aversif faible contrôle sur } Y) < 0{,}30$ **OU** IC 95 % incluant `0` **OU** $\text{BF}_{01} > 10$ ;
  2. $d_z(\text{Périmètre} - \text{Intérieur sur } A) < 0{,}20$ **OU** $\text{BF}_{01} > 10$ **OU** victoire de l'anneau plat en LOO-CV ($\Delta\text{ELPD}_{\text{LOO}} < -2\,\text{SE}$) ;
  3. $|r(Y, A)| > 0{,}70$ (au niveau essai ou centroïdes d'items) **OU** victoire du modèle 2D Valence–Activation $(V, A)$ en LOO-CV / WAIC.

---

### 2.2. Test 1B — Estimation bayésienne libre de l'exposant $p$ sur la frontière de capacité ($A = 1$) dans $|X|^p + |Y|^p = R^p$ (Prédiction P1)

- **Objet théorique :** Postulat géométrique heuristique $L_1$ sur la frontière de capacité ($A = 1$, $|X| + |Y| = R(Z)$ ; `docs/01-Article_Cartograffect.md` §5.2 & §8.2 P1).
- **Sauvegarde psychométrique pré-enregistrée contre l'artefact de plafond :** Comme l'a mis en évidence le `pilot_pipeline_dry_run` avant collecte, une échelle ordinale grossière 1–7 provoque une compression asymétrique par troncature plafond aux pôles axiaux (qui biaiserait artificiellement $\hat{p}$ vers le haut). En conséquence, l'Étude 1 recueille $(X, Y)$ sur des **échelles visuelles analogiques continues (VAS `-100` à `+100`, pas `1`)** à ancrages extrêmes gradués, et les analyses de sensibilité incluent un modèle probit ordonné latent afin de neutraliser tout biais de bord.
- **Modèles confrontés sur les mêmes observations frontières ($A$ haut / périmètre, $Z \in \{2, 3, 4, 5\}$) :**
  Exprimé sur le rayon euclidien observable $r_2(\theta_i) = \sqrt{X_i^2 + Y_i^2}$ en fonction de l'angle polaire $\theta_i = \arctan(|Y_i|/|X_i|)$ (garantissant des vraisemblances strictement comparables sur la même variable cible) :
  1. **$M_{L_p}$ (Estimation libre hiérarchique de $p$) :** $r_2(\theta_i) = R / \big(|\cos\theta_i|^p + |\sin\theta_i|^p\big)^{1/p} + \varepsilon_i$, avec prior symétrique faiblement informatif centré à mi-chemin géométrique entre $L_1$ et $L_2$ : $\log p \sim \mathcal{N}(\log\sqrt{2},\, 0{,}45^2)$ tronqué à $p \in [0{,}55, 3{,}20]$.
  2. **$M_{L_1}$ (CARTOGRAFFECT, $p = 1$) :** Budget additif linéaire $|X| + |Y| = R$ (contraction diagonale $r_2(\pi/4) = 0{,}707 R$).
  3. **$M_{L_2}$ (Circomplexe euclidien de Russell, 1980, $p = 2$) :** Rayon constant $X^2 + Y^2 = R^2$ ($r_2(\pi/4) = 1{,}000 R$).
  4. **$M_{\text{free}}$ (Absence de contrainte budgétaire radiale / axes indépendants ou coopératifs) :** $r_2(\theta_i) = b_0 + b_1 \sin(2\theta_i) + \varepsilon_i$ sous $b_1 \ge 0$ (couvrant le cercle $b_1 = 0$ et la boîte indépendante $L_\infty$ à $b_1 > 0$ où $|X|$ et $|Y|$ co-varient librement sans goulot d'étranglement).
- **Critères explicites d'ABANDON de la métrique $L_1$ (aucune clause d'immunisation) :**
  La métrique en losange $L_1$ est **explicitement abandonnée et déclarée RÉFUTÉE** si **l'une quelconque** des conditions suivantes est vérifiée :
  1. La moyenne a posteriori de l'exposant libre satisfait **$\hat{p} \ge 1{,}70$** (ou l'ICr 95 % exclut $1{,}0$ au profit de valeurs $\ge 1{,}70$) ;
  2. Le modèle euclidien $M_{L_2}$ ($p = 2$) ou le modèle sans contrainte budgétaire $M_{\text{free}}$ l'emporte en **LOO-CV / WAIC** ($\text{ELPD}_{L_2} - \text{ELPD}_{L_1} > 2\,\text{SE}$ ou $\text{ELPD}_{\text{free}} - \text{ELPD}_{L_1} > 2\,\text{SE}$) ;
  3. Le Facteur de Bayes favorise un modèle rival avec **$\text{BF}_{01}(L_2 \text{ vs } L_1) > 10$** ou **$\text{BF}_{01}(M_{\text{free}} \text{ vs } L_1) > 10$** ;
  4. La corrélation frontière $\text{Corr}(|X|, |Y| \mid A\text{ haut})$ est positive ou nulle ($\ge 0$).
- **Critère de corroboration de $L_1$ :** $\hat{p} \in [0{,}80, 1{,}35]$ (ICr 95 % excluant $1{,}70$ et $2{,}00$), $\text{BF}_{10}(L_1 \text{ vs } L_2) > 10$, $\text{BF}_{10}(L_1 \text{ vs } M_{\text{free}}) > 10$, et victoire de $M_{L_1}$ en LOO-CV ($\Delta\text{ELPD} > 2\,\text{SE}$) contre les deux rivaux.

---

### 2.3. Test 1C — Bijection $2 \times 2$ de Rolls sur $Z = 2$ et loi contralatérale des 8 paires conjuguées (`A1–D2` & `L1–L4`)

Ce test se compose de **deux volets conjoints**, tous deux requis pour corroboration :

#### Volet 1C-i — Bijection $2 \times 2$ de Rolls bornée strictement à $Z = 2$
- **Protocole en aveugle :** Chaque participant lit 4 séries de scénarios situationnels non lexicalisés (aucun mot d'émotion dans l'énoncé) opérationnalisant les 4 contingences de stimuli de Rolls (2014) :
  - `Rew+` ($S^+$, ajout/acquisition d'une récompense sous prise instrumentale active) $\to$ prédiction **`Désir`** `(+1, +1, 2)` ;
  - `Rew−` ($\overline{S^+}$, retrait/omission frustrative d'une récompense attendue avec prise d'action disponible) $\to$ prédiction **`Colère`** `(-1, +1, 2)` ;
  - `Pun+` ($S^-$, présentation subie d'un stimulus punitif/aversif sous faible contrôle instrumental) $\to$ prédiction **`Dégoût`** `(-1, -1, 2)` ;
  - `Pun−` ($\overline{S^-}$, cessation/omission d'une punition face à une limite objective d'action, rigoureusement dissociée de l'évitement opérant actif skinnerien `R−`) $\to$ prédiction **`Calme`** `(+1, -1, 2)` *(sans aucun qualificatif additionnel)*.
- **Mesures :** Choix forcé parmi les **8 prototypes canoniques de $Z = 2$** (`Désir`, `Colère`, `Dégoût`, `Calme`, `Joie`, `Tristesse`, `Courage`, `Peur`, en ordre aléatoire) + évaluations continues $(X, Y, A, V)$.
- **Modèles rivaux :** (a) Modèle **Valence 1D** (fusionnant `Rew+`/`Pun−` en positif et `Rew−`/`Pun+` en négatif) ; (b) Modèle **Valence–Activation 2D (Russell, 1980)**.
- **Critères de RÉFUTATION de 1C-i :** Réfuté si **l'une quelconque des 4 cellules** échoue à prédire son prototype désigné en 1re position devant son plus proche concurrent ($\text{BF}_{01} > 10$ ou taux inférieur au concurrent), **OU** si le modèle Valence 1D ou Russell 2D surpasse la factorisation Rolls $2 \times 2$ en LOO-CV / WAIC ($\Delta\text{ELPD} > 2\,\text{SE}$).

#### Volet 1C-ii — Loi contralatérale des 8 paires conjuguées (`A1–D2` & `L1–L4`), découplée de $A' = A$
- **Objet théorique :** Théorèmes Lean 4 `contralateral_swaps_amplitudes` (`Cartograffect/AffectiveMatrix.lean:334`) et `contralateral_group_bindings` (`Cartograffect/AffectiveTaxonomy.lean:307`), structurant les 17 sous-secteurs du Tableau 1b en 1 centre fixe + 4 paires axiales/diagonales (`A1, A2, D1, D2`) + **4 paires latérales contralatérales (`L1–L4`)** :
  - **L1 (`Q1 dom. +X ↔ Q3 dom. -Y`) :** ex. *Fierté ↔ Honte*, *Estime ↔ Résignation*, *Optimisme actif ↔ Désespoir* ;
  - **L2 (`Q1 dom. +Y ↔ Q3 dom. -X`) :** ex. *Exaltation ↔ Angoisse*, *Sérénité ↔ Appréhension diffuse*, *Plénitude / Sécurité ↔ Terreur / Tourment* ;
  - **L3 (`Q2 dom. +Y ↔ Q4 dom. +X`) :** ex. *Frustration ↔ Résilience vive*, *Hostilité ↔ Endurance active / Patience*, *Révolte ↔ Stoïcisme* ;
  - **L4 (`Q2 dom. -X ↔ Q4 dom. -Y`) :** ex. *Contestation ↔ Répit vif*, *Indignation ↔ Détachement / Lâcher-prise*, *Défiance combative ↔ Recul serein*.
- **Prédiction géométrique critique sur `L1–L4` :** Pour chaque paire latérale $(s, s')$, les centroïdes empiriques vérifient l'**échange d'axe dominant $|X| \leftrightarrow |Y|$** combiné à l'inversion des deux signes :
  $$(\hat{X}_{s'}, \hat{Y}_{s'}) = \big(-\text{sgn}(\bar{X}_s)\,|\bar{Y}_s|,\; -\text{sgn}(\bar{Y}_s)\,|\bar{X}_s|\big)$$
  ce qui se traduit par une corrélation positive élevée entre $\Delta_{\text{dom}}(s) = |\bar{X}_s| - |\bar{Y}_s|$ et $-\Delta_{\text{dom}}(s')$, **sans exiger $A_{s'} = A_s$** (vérification explicite sur des paires iso-énergétiques comme *Fierté ↔ Honte* autant que sur des paires à activation asymétrique comme *Sérénité ↔ Angoisse* ou *Colère ↔ Calme*).
- **Modèle rival direct :** **Inversion centrale pure** $f_{\text{central}}(x, y) = (-x, -y)$, qui inverse les signes **sans échanger l'axe dominant** (prédisant $\Delta_{\text{dom}}(s') = +\Delta_{\text{dom}}(s)$ au lieu de $-\Delta_{\text{dom}}(s)$).
- **Critères de RÉFUTATION de 1C-ii :** Réfuté si la corrélation d'échange d'axe dominant $\text{Corr}(\Delta_{\text{dom}}(s), -\Delta_{\text{dom}}(s')) \le 0$, **OU** si l'inversion centrale pure $(-x, -y)$ surpasse l'échange contralatéral en LOO-CV / WAIC ($\Delta\text{ELPD}_{\text{central} - \text{contra}} > 2\,\text{SE}$), **OU** si $\text{BF}_{01}(\text{central vs contra}) > 10$.

---

## 3. Plan d'Échantillonnage et Analyse de Puissance Formelle ($N \ge 600$)

### 3.1. Échantillon cible et recrutement bilingue
- **Effectif analysable garanti :** **$N_{\text{analysable}} \ge 600$** participants adultes naïfs (18–70 ans, sans formation préalable au modèle CARTOGRAFFECT), stratifiés en deux cohortes linguistiques indépendantes :
  - **Cohorte FR ($n_{\text{analysable}} \ge 300$) :** francophones natifs (Québec / Canada & France / Europe francophone via Prolific / Bilendi).
  - **Cohorte EN ($n_{\text{analysable}} \ge 300$) :** anglophones natifs (Amérique du Nord & Royaume-Uni via Prolific), permettant un contrôle d'invariance transculturelle et linguistique (traduction/rétro-traduction indépendante par deux traducteurs bilingues certifiés).
- **Sur-recrutement pré-enregistré contre l'attrition QC :** Recrutement cible de **$N_{\text{brut}} = 660$** (330 FR + 330 EN) afin d'absorber jusqu'à ~9 % d'exclusions pré-enregistrées tout en garantissant $N_{\text{analysable}} \ge 600$ ($\ge 300$ par cohorte).

### 3.2. Justification formelle par analyse de puissance fréquentiste et Bayes Factor Design Analysis (BFDA)
Les calculs de puissance reposent sur un seuil conservateur $\alpha = 0{,}01$ (fréquentiste) et sur les seuils bayésiens décisifs $\text{BF}_{10} > 10$ / $\text{BF}_{01} > 10$ (Schönbrodt & Wagenmakers, 2018) :

| Cible statistique | Taille d'effet minimale d'intérêt (SESOI) | Puissance fréquentiste ($n = 300$ / cohorte, $\alpha = 0{,}01$) | Puissance fréquentiste ($N = 600$ poolé, $\alpha = 0{,}01$) | Probabilité BFDA $P(\text{BF}_{10} > 10 \mid H_1)$ ($N = 600$) | Probabilité BFDA $P(\text{BF}_{01} > 10 \mid H_0)$ ($N = 600$) |
|:---|:---|:---:|:---:|:---:|:---:|
| **1A-i : Contraste $Y$** (Agentique vs Aversif faible contrôle) | $d_z = 0{,}30$ | $> 0{,}99$ | $> 0{,}999$ | $> 0{,}999$ | $> 0{,}95$ |
| **1A-ii : Contraste $A$** (Périmètre vs Intérieur) | $d_z = 0{,}25$ | $0{,}95$ | $> 0{,}999$ | $> 0{,}99$ | $> 0{,}94$ |
| **1A-iii : Corrélation $r(Y, A)$** (test contre $|r| = 0{,}70$) | $\Delta z_{\text{Fisher}} = 0{,}20$ | $0{,}92$ | $> 0{,}99$ | $> 0{,}99$ | $> 0{,}95$ |
| **1B : Exposant libre $p$** ($L_1$ vs $L_2$, 54 centroïdes frontières FR/EN) | $\Delta p = 0{,}40$ (SE centroïde $\approx 0{,}018$) | $> 0{,}98$ | $> 0{,}999$ | $> 0{,}99$ | $> 0{,}96$ |
| **1C-i : Bijection Rolls $Z = 2$** (chaque cellule vs concurrent) | $\Delta p_{\text{acc}} = 0{,}12$ | $0{,}96$ | $> 0{,}999$ | $> 0{,}99$ | $> 0{,}95$ |
| **1C-ii : Échange contralatéral `L1–L4`** ($M_{\text{contra}}$ vs $M_{\text{central}}$) | $\Delta\text{RMSE} \ge 0{,}10$ sur 28 centroïdes de paires | $> 0{,}95$ | $> 0{,}99$ | $> 0{,}98$ | $> 0{,}95$ |

Avec 24 items stratifiés par participant (plan incomplet équilibré BIBD garantissant que chaque jalon du Tableau 1b est évalué par au moins $n \approx 290$ participants, soit $\text{SE}_{\text{centroïde}} \approx 0{,}016$ sur $[-1, 1]$) + les 4 scénarios Rolls $Z = 2$ évalués par tous les participants ($N \ge 600$), la précision des centroïdes assure une séparation non ambiguë entre $p = 1$ et $p = 2$ ainsi qu'entre échange contralatéral et inversion centrale pure.

---

## 4. Critères d'Exclusion, Contrôle Qualité et Invariance Linguistique

1. **Critères d'exclusion pré-enregistrés (appliqués en aveugle avant toute analyse d'hypothèse) :**
   - Échec à $\ge 2$ sur 4 items de contrôle d'attention explicites insérés aléatoirement ;
   - Temps total de complétion $< 40\%$ de la médiane de la cohorte (speeders) ou absence totale de variance sur les échelles $X$ et $Y$ ($\text{SD}_X < 0{,}15$ et $\text{SD}_Y < 0{,}15$, straight-lining) ;
   - Taux de données manquantes $> 20\%$ sur la session.
2. **Gestion des données manquantes (< 20 % par participant) :** Vraisemblance complète sur les observations présentes (aucune suppression *listwise* arbitraire ; sensibilité par imputation multiple vérifiée si taux global $> 5\%$).
3. **Invariance transculturelle FR vs EN :** Chaque test 1A, 1B et 1C est d'abord rapporté sur l'échantillon global ($N \ge 600$), puis répliqué séparément dans les cohortes FR ($n \ge 300$) et EN ($n \ge 300$). L'invariance structurale des centroïdes $(X, Y, A)$ entre FR et EN est quantifiée par congruence de Tucker ($\phi \ge 0{,}90$) et corrélation de Procrustes ; toute divergence significative entre cohortes est rapportée comme limite d'universalité lexicale (cf. Jackson et al., 2019 ; Mesquita et al., 2017) sans ajustement *post hoc* des seuils.

---

## 5. Tableau de Plan d'Étude (Study Design Table — Format Stage 1 Registered Report)

| Question de recherche | Hypothèse | Plan d'échantillonnage | Plan d'analyse (`study1_analysis_pipeline.py`) | Interprétation selon les résultats possibles |
|:---|:---|:---|:---|:---|
| **Q1A.** L'axe `Y` mesure-t-il la contrôlabilité instrumentale stricte indépendamment de l'activation autonome `A`, et `A` structure-t-il radialement la surface remplie du Tableau 1b ? | **H1A-i :** $Y_{\text{agentique}} > Y_{\text{aversif faible ctrl}}$ ($d_z \ge 0{,}50$).<br>**H1A-ii :** $A_{\text{périmètre}} > A_{\text{intérieur}}$ ($d_z \ge 0{,}40$).<br>**H1A-iii :** $|r(Y, A)| \le 0{,}70$ et 3 canaux $(X, Y, A)$ > 2D Russell $(V, A)$. | $N_{\text{analysable}} \ge 600$ (300 FR + 300 EN), 24 jalons stratifiés du Tableau 1b / sujet en aveugle sur échelles VAS $(X, Y, A, V)$. Puissance $> 0{,}99$ ($\alpha = 0{,}01$), BFDA $> 0{,}99$. | Contrastes appariés intra-sujets ($d_z$, IC 95 %, JZS $\text{BF}_{10}/\text{BF}_{01}$), corrélation $r(Y, A)$ (essai & centroïdes), PSIS-LOO-CV / WAIC surface remplie vs anneau plat vs 2D Russell. | **Corroboré :** $d_z(Y) \ge 0{,}50$, $d_z(A) \ge 0{,}40$, $\text{BF}_{10} > 10$, $|r(Y, A)| \le 0{,}70$, victoire LOO-CV.<br>**Réfuté :** $d_z(Y) < 0{,}30$ OU $d_z(A) < 0{,}20$ OU $|r(Y, A)| > 0{,}70$ OU $\text{BF}_{01} > 10$ OU défaite LOO-CV $\Rightarrow$ rejet de l'Option 1A / surface remplie. |
| **Q1B.** La frontière de capacité ($A = 1$) obéit-elle au losange $L_1$ ($p \approx 1$) contre le circomplexe euclidien $L_2$ ($p = 2$) et un modèle sans budget radial ? | **H1B (P1) :** Sur les jalons frontières ($A$ haut), $\hat{p} \in [0{,}80, 1{,}35]$ et $M_{L_1}$ surpasse $M_{L_2}$ et $M_{\text{free}}$ ($\text{BF}_{10} > 10$, $\Delta\text{ELPD}_{\text{LOO}} > 2\,\text{SE}$). | Mêmes $N \ge 600$ participants ; 54 centroïdes frontières FR/EN couvrant $Z \in \{2, 3, 4, 5\}$ sur VAS continues (anti-plafond). Puissance $> 0{,}99$, BFDA $> 0{,}99$. | Estimation bayésienne libre de $p$ sur $r_2(\theta) = R / (|\cos\theta|^p + |\sin\theta|^p)^{1/p}$ (prior symétrique centré à $\sqrt{2}$), comparaison PSIS-LOO-CV, WAIC et BF contre $M_{L_2}$ ($p=2$) et $M_{\text{free}}$ ($b_1 \ge 0$). | **Corroboré :** $\hat{p} \in [0{,}80, 1{,}35]$, ICr 95 % excluant $1{,}70$, $\text{BF}_{10} > 10$ et victoire LOO-CV vs $L_2$ et $M_{\text{free}}$.<br>**Réfuté (ABANDON $L_1$) :** $\hat{p} \ge 1{,}70$ OU victoire $L_2$ / $M_{\text{free}}$ en LOO-CV OU $\text{BF}_{01} > 10$ $\Rightarrow$ abandon explicite de la métrique $L_1$. |
| **Q1C.** Les 4 contingences de Rolls (`Rew±/Pun±`) prédisent-elles en aveugle les 4 diagonales de $Z = 2$ (dont `Calme`), et les 4 paires latérales `L1–L4` vérifient-elles l'échange $|X| \leftrightarrow |Y|$ sans exiger $A' = A$ ? | **H1C-i :** `Rew+→Désir`, `Rew−→Colère`, `Pun+→Dégoût`, `Pun−→Calme` en 1re position ($\text{BF}_{10} > 10$ par cellule) et Rolls $2 \times 2$ > Valence 1D en LOO-CV.<br>**H1C-ii :** Sur `L1–L4`, $\text{Corr}(\Delta_{\text{dom}}(s), -\Delta_{\text{dom}}(s')) > 0{,}50$ et $M_{\text{contra}}$ > $M_{\text{central}}$ ($\text{BF}_{10} > 10$, $\Delta\text{ELPD} > 2\,\text{SE}$) avec $A'$ libre. | Mêmes $N \ge 600$ participants ; 4 scénarios Rolls non lexicalisés / sujet ($2\,400+$ obs) + 28 centroïdes de paires latérales `L1–L4` FR/EN. Puissance $> 0{,}99$, BFDA $> 0{,}98$. | Classification 8 prototypes ($Z = 2$), BF Beta-Binomial par cellule vs concurrent, LOO-CV / WAIC Dirichlet-Multinomial vs Valence 1D ; RMSE, $\Delta_{\text{dom}}$, BF et LOO-CV de $f_{\text{contra}}$ vs $f_{\text{central}}(-x, -y)$ + audit descriptif de $A$ (*Fierté↔Honte* vs *Sérénité↔Angoisse*). | **Corroboré :** 4/4 cellules Rolls top-1 ($\text{BF}_{10} > 10$) + victoire LOO-CV ET $\text{Corr}(\Delta_{\text{dom}}) > 0{,}50$ + victoire LOO-CV/BF de $M_{\text{contra}}$ sur $M_{\text{central}}$.<br>**Réfuté :** Échec d'une seule cellule Rolls OU défaite LOO-CV OU $\text{Corr}(\Delta_{\text{dom}}) \le 0$ OU victoire de l'inversion centrale $(-x, -y)$ OU $\text{BF}_{01} > 10$. |

---

## 6. Vérification Technique Pré-Gel OSF (`pilot_pipeline_dry_run` & `synthetic_identifiability_check`, `V3 = 0`)

Avant le gel du protocole sur OSF (`https://osf.io/z89sg`) et avant toute collecte sur sujets humains (`V3 = 0`), deux vérifications strictement synthétiques ont été exécutées sur le dépôt :

1. **Vérification d'identifiabilité du modèle comportemental v3.0 (préparation Étude 2 — `extensions/in_silico/scripts/v3_identifiability_check.py`, `synthetic_identifiability_check`, `V3 = 0`) :**
   - Modèle parcimonieux orthogonalisé à 5 paramètres libres $(\rho, p, \gamma_A, \chi, \beta)$ résolvant intégralement la colinéarité v2 (`alpha_0 / gamma_alpha = -0.813`, `beta_X / beta_Y = +0.667`).
   - Testé sur $N = 80$ agents synthétiques ($T = 240$ essais $2 \times 2$, réponses Likert 1–7 ordinales, 10 % MCAR, 5 % bruit moteur, graine `20260301`) : $\min r_{\text{recovery}} = 0{,}9263 \ge 0{,}70$ et $\max |r_{\text{off-diag}}| = 0{,}1737 < 0{,}35$ ; orthogonalité Option 1A vérifiée ($\text{Corr}(A, \text{sgn}(Y)) = -0{,}0125$) ; asymétrie Option 3b vérifiée (`0.4879` en Charge négative vs `0.0549` en Décharge positive).
2. **Dry-run exécutable du pipeline confirmatoire d'Étude 1 (`protocols/study1_analysis_pipeline.py --dry-run`, `pilot_pipeline_dry_run`, `V3 = 0`) :**
   - Exécuté sur deux jeux pilotes simulés ($N_{\text{brut}} = 640$, $N_{\text{analysable}} = 613$) : confirme à la fois la **corroboration exacte** des Tests 1A, 1B et 1C sous processus générateur CARTOGRAFFECT v3.0 et leur **réfutation automatique (`REFUTED`)** sous un processus générateur rival ($L_2$ $p = 2$, inversion centrale pure, couplage $Y/A$, valence 1D) — garantissant l'absence de biais de confirmation codé dans le pipeline.

---

## 7. Éthique, Science Ouverte et Déclaration de Transparence IA

- **Éthique et consentement :** Collecte anonyme en ligne auprès d'adultes majeurs consentants après approbation d'un comité d'éthique de la recherche indépendant (IRB / CER) ; aucune donnée nominative ni biométrique collectée en Étude 1 ; rémunération équitable conforme aux standards Prolific ($\ge 9{,}00$ £/h ou équivalent CAD/EUR).
- **Science ouverte (TOP Niveau 3 / FAIR4RS) :** Gel horodaté du présent protocole et du script `protocols/study1_analysis_pipeline.py` sur OSF (`https://osf.io/z89sg`) avant inclusion du premier participant ; publication intégrale des données brutes anonymisées (CC-BY-4.0), du code d'analyse exact (AGPL-3.0-or-later) et du manuscrit Stage 2 quel que soit le verdict (corroboration ou réfutation).
- **Transparence IA :** L'auteur (Manuel Cabelguen, Ph. D., psychologue clinicien et non mathématicien formel) conçoit et assume intégralement l'architecture théorique, les hypothèses falsifiables et le plan expérimental ; des outils d'IA générative ont assisté l'implémentation logicielle du pipeline et la formalisation Lean 4, publiés en accès libre pour audit indépendant.

---

## Références Clés du Protocole

- Carver, C. S., & Harmon-Jones, E. (2009). Anger is an approach-related affect: Evidence and implications. *Psychological Bulletin*, *135*(2), 183–204.
- Fontaine, J. R., Scherer, K. R., Roesch, E. B., & Ellsworth, P. C. (2007). The world of emotions is not two-dimensional. *Psychological Science*, *18*(12), 1050–1057.
- Jackson, J. C., et al. (2019). Emotion semantics show both cultural variation and universal structure. *Science*, *366*(6472), 1517–1522.
- Mesquita, B., Boiger, M., & De Leersnyder, J. (2017). Doing emotions: The role of culture in everyday emotions. *European Review of Social Psychology*, *28*(1), 95–133.
- Rolls, E. T. (2014). *Emotion and decision-making explained*. Oxford University Press.
- Rothbaum, F., Weisz, J. R., & Snyder, S. S. (1982). Changing the world and changing the self: A two-process model of perceived control. *Journal of Personality and Social Psychology*, *42*(1), 5–37.
- Rouder, J. N., Speckman, P. L., Sun, D., Morey, R. D., & Iverson, G. (2009). Bayesian $t$ tests for accepting and rejecting the null hypothesis. *Psychonomic Bulletin & Review*, *16*(2), 225–237.
- Russell, J. A. (1980). A circumplex model of affect. *Journal of Personality and Social Psychology*, *39*(6), 1161–1178.
- Schönbrodt, F. D., & Wagenmakers, E.-J. (2018). Bayes factor design analysis: Planning for compelling evidence. *Psychonomic Bulletin & Review*, *25*(1), 128–142.
- Vehtari, A., Gelman, A., & Gabry, J. (2017). Practical Bayesian model evaluation using leave-one-out cross-validation and WAIC. *Statistics and Computing*, *27*(5), 1413–1432.
