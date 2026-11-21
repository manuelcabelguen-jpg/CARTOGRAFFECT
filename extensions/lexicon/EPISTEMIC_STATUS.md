# Statut Épistémique — `extensions/lexicon/` (Strate 1 : Extensions Lexicales et Psychométriques)

Ce sous-projet appartient à la **Strate 1 (Extensions exploratoires et validations psychométriques)** du compendium unifié **CARTOGRAFFECT®**. Conformément à la hiérarchie épistémique stricte du projet, il est **asservi à la Strate 0 (Noyau formel canonique)** et ne modifie aucun axiome ni théorème de la fondation Hexa-Prover (113 théorèmes constructifs).

---

## 1. Ce qui relève de la Strate 0 (Noyau Formel Certifié)

Les invariants suivants sont importés directement depuis [`Cartograffect/Lexicon176.lean`](../../Cartograffect/Lexicon176.lean) et [`Cartograffect/CoreAffect.lean`](../../Cartograffect/CoreAffect.lean) sans réécriture ni altération :

1. **Géométrie discrète $L_1$ des 176 états ($Z \in \{0, \dots, 7\}$) :**
   - Loi des couronnes $R(Z) = |X| + |Y| = 2(Z - 1)$ pour tout état périphérique ($Z \ge 2$).
   - Parité paire $(X + Y) \equiv 0 \pmod 2$ et cardinaux par strate $N(Z) = 8(Z - 1) + 1$ ($1 + 1 + 9 + 17 + 25 + 33 + 41 + 49 = 176$).
2. **Nomenclature canonique du pôle d'origine $(0, 0, 0)$ :**
   - Le sommet basal à $Z = 0$ porte le libellé canonique **`"Point de Veille"`** dans [`Cartograffect/Lexicon176.lean`](../../Cartograffect/Lexicon176.lean).
   - Le script [`01_build_ref176.py`](01_build_ref176.py) lit directement `../../Cartograffect/Lexicon176.lean`. Un alias de compatibilité en lecture (`"Veille"` $\leftrightarrow$ `"Point de Veille"`) est maintenu dans [`cartograffect_core.py`](cartograffect_core.py) et [`src/validate_emotion_wheels.py`](src/validate_emotion_wheels.py) uniquement pour permettre la lecture des tables `.tsv` historiques pré-générées.
3. **Antagonisme involutif 3D $\mathcal{A}(P)$ :**
   - Symétrie centrale pour les états axiaux et diagonaux, et réflexion controlatérale $(Y, X, Z)$ / $(-Y, -X, Z)$ pour les états intermédiaires ($\mathcal{A}(\mathcal{A}(P)) = P$).
   - Les 4 lemmes algébriques supplémentaires sur `polarity3D` et `zAntipodal3D` sont isolés dans [`lean/PolarityAntipodal3D.lean`](lean/PolarityAntipodal3D.lean) (hors des 113 théorèmes du Noyau Hexa-Prover) en important `Cartograffect.Lexicon176`.

---

## 2. Ce qui relève de la Strate 1 (Projections Heuristiques, Psychométriques et Exploratoires)

Les modules suivants constituent des **opérationnalisations empiriques, interpolations numériques ou extensions théoriques en cours d'arbitrage** :

### 2.1 Validation psychométrique externe Scherer GRID / CPM et Roues des Émotions
- **Fichiers :** [`lean/SchererGRID.lean`](lean/SchererGRID.lean), [`lean/EmotionWheelsChallenge.lean`](lean/EmotionWheelsChallenge.lean), [`lean/AuditGeometricLexicalPlacement.lean`](lean/AuditGeometricLexicalPlacement.lean), [`src/validate_emotion_wheels.py`](src/validate_emotion_wheels.py).
- **Statut épistémique :**
  - Les preuves Lean 4 de `extensions/lexicon/lean/` certifient la **cohérence arithmétique exacte** des 24 ancres empiriques du *Component Process Model* (Scherer, Fontaine et al., 2013, 142 features) avec la grille $L_1$ et réfutent constructivement l'hypothèse d'antagonisme polaire 2D à rayon fixe (Plutchik / GEW) au profit de l'involution 3D.
  - En revanche, l'**extension des profils CPM des 24 ancres GRID aux 176 prototypes puis aux 15 037 / 16 183 lemmes français** ([`CARTOGRAFFECT_176_GRID_CPM_Interpolated.tsv`](CARTOGRAFFECT_176_GRID_CPM_Interpolated.tsv)) repose sur une **interpolation numérique hybride RBF + $k$-NN** dans l'espace continu $(V, A, D)$ et sur l'indice heuristique `Ratio_Z` (rapport entre sous-composantes cognitivo-normatives et somatiques-expressives).
  - De même, l'homéomorphisme radial $L_1 \leftrightarrow L_2$ (projection de la double pyramide polyédrique sur la sphère riemannienne centrée en $Z_{\text{eq}} = 7$) est un **outil géométrique continu de visualisation et d'isotropie angulaire**, distinct de la métrique discrète $L_1$ du Noyau.

### 2.2 Pipeline de projection lexicale (NRC-VAD v2.1, DIMA, FANCat, GLAWI/Lexique 3.83)
- **Fichiers :** [`02_prefilter_nrc.py`](02_prefilter_nrc.py), [`03_classify_batches_gemini.py`](03_classify_batches_gemini.py), [`03b_affect_audit_gemini.py`](03b_affect_audit_gemini.py), [`04_direct_l1_projection.py`](04_direct_l1_projection.py), [`dima_mapping.py`](dima_mapping.py), [`10_project_55k_nrc_vad_diamond_303.py`](10_project_55k_nrc_vad_diamond_303.py).
- **Statut épistémique :**
  - Les coordonnées $(V, A, D) \in [-1, +1]^3$ des lexiques tiers sont projetées sur $(X, Y, Z)$ au moyen d'une **combinaison linéaire heuristique** pour l'axe de Contrôle ($y_{\text{raw}} = 0.60\,D + 0.40\,A$ ou $0.60\,A + 0.40\,D$ selon le script) et d'une estimation continue de profondeur $z_{\text{ded}} = \text{clip}(1.2 + 3.2\,r_{L_1}, 1.5, 7.0)$, suivie d'une classification assistée par LLM (`gemini-3.8-flash`) et d'un appariement par paliers.
  - Ces projections constituent un **atlas psycholinguistique empirique** et non une déduction formelle du Noyau.
  - **Politique des données tierces :** Les fichiers bruts sous licence tierce (`NRC-VAD-Lexicon-v2.1.txt`, `DIMA_GROUPE_*.xlsx`, `FANCatdatabaseRevisee.xlsx`) ainsi que la projection intégrale `CARTOGRAFFECT_55K_NRC_VAD_Diamant_303.tsv` sont **exclus du suivi Git** (`.gitignore`).

### 2.3 Extension Axiologique $Z \in [-7, -1]$ (« Diamant 303 »)
- **Fichiers :** [`01b_prepare_diamond_z_minus.py`](01b_prepare_diamond_z_minus.py), [`02b_audit_and_consolidate_databases.py`](02b_audit_and_consolidate_databases.py), [`08_project_diamond_303_lexicon.py`](08_project_diamond_303_lexicon.py), [`ref_303_diamant_z.tsv`](ref_303_diamant_z.tsv).
- **Statut épistémique :**
  - L'hémisphère supérieur à profondeur négative $Z \in \{-7, \dots, -1\}$ (127 pôles axiologiques de valeurs, forces et engagements, complétant les 176 états $Z \ge 0$ pour former un octaèdre de $303$ pôles recollé à l'équateur $Z = +7$) ainsi que la **structure triadique aristotélicienne à $Z = -6$** ($D_-$ déficit / $V$ valeur centrale / $D_+$ excès) constituent un **programme d'extension théorique de Strate 1**, non intégré à l'article canonique `v1.0.2` ni aux 113 théorèmes du Noyau Hexa-Prover.
  - **Note de divergence lexicale documentée :** Dans le Diamant 303 (`01b_prepare_diamond_z_minus.py`), deux libellés de $Z > 0$ ont été substitués localement (`(0, -6, 4)` *Langueur* $\to$ *Solitude* ; `(-6, 4, 6)` *Rancœur* $\to$ *Irritation*). Le Noyau formel (`Cartograffect/Lexicon176.lean`) conserve l'autorité exclusive avec **`Langueur`** et **`Rancœur`**.
