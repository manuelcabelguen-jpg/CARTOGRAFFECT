# AVERTISSEMENT D'ARCHIVE — Tables Lexicales TSV v2.1.0 (Ancien Axe Y Hybride)

> [!WARNING]
> **Statut épistémique v3.0.0 — Archive exploratoire historique hors cœur normatif (`V3 = 0`)**
>
> Les tables lexicales TSV présentes dans ce répertoire (`extensions/lexicon/`) — en particulier :
> - `CARTOGRAFFECT_Full_Dictionary_MultiStrata.tsv`
> - `nrc_llm_classified.tsv`
> - `nrc_candidates_filtered.tsv`
>
> ainsi que les tables dérivées associées (`nrc_affect_audit.tsv`, `CARTOGRAFFECT_NRC_Lexicon_Complet.tsv`, `CARTOGRAFFECT_176_Dual_L1_L2_CPM.tsv`, `CARTOGRAFFECT_303_Dual_L1_L2_Sphere_Complete.tsv`, `CARTOGRAFFECT_Diamant_303_*.tsv`, `CARTOGRAFFECT_OpenData_CNRS_Lexique_GLAWI_3D.tsv`) — **ont été générées sous l'ancienne architecture v2.1.0**.

## Pourquoi ces tables ne relèvent pas du cœur normatif v3.0.0

Conformément aux quatre arbitrages irréversibles verrouillés dans [`../../DECISIONS_V3.md`](../../DECISIONS_V3.md) :

1. **Ancien axe `Y` hybride (obsolète en v3.0.0 — Option 1A) :**
   Ces tables v2.1.0 ont été construites à l'aide de proxys linéaires mêlant Dominance (`D`) et Activation physiologique / *Arousal* (`A`) (par exemple `y_raw = 0.60 * D + 0.40 * A` ou `0.60 * A + 0.40 * D`). Dans la version **v3.0.0**, l'axe `Y` mesure **exclusivement la contrôlabilité instrumentale perçue**, tandis que l'activation physiologique et la mobilisation allostatique sont externalisées dans un **canal autonome indépendant `A >= 0`**. En conséquence, le placement v2.1.0 des états aversifs à faible contrôle (`Y < 0` à `A` élevé en v3.0.0) et des états d'accommodation en `(X > 0, Y < 0)` diffère structurellement du modèle normatif v3.0.0.
2. **Discrétisation v2 à 176 cases / 303 pôles (hors périmètre normatif — Arbitrage 4) :**
   Ces tables projettent des lexèmes sur le pavage exploratoire `Z ∈ {0, ..., 7}` (176 prototypes) ou sur l'extension axiologique `Z ∈ [-7, +7]` (« Diamant 303 »), alors que le cœur normatif v3.0.0 (`docs/01-Article_Cartograffect.md`, `Cartograffect/`) modélise `Z ∈ [0, 5]` en profondeur hiérarchique continue et restreint la discrétisation canonique à `Z ∈ {0, 1, 2}` (11 états).
3. **Métadonnées historiques résiduelles (`grid24_nearest`, etc.) :**
   Certaines colonnes historiques de `CARTOGRAFFECT_Full_Dictionary_MultiStrata.tsv` conservent des colonnes issues des anciens scripts exploratoires GRID-24 archivés en Phase 1 dans [`../../archive/deprecated_synthetic_v2/`](../../archive/deprecated_synthetic_v2/). Ces colonnes n'ont **aucune valeur de validation empirique ou psychométrique (`V3 = 0`)**.

## Politique de conservation

- **Intégrité historique préservée :** Aucune donnée de ces tables TSV historiques n'a été altérée afin de préserver la traçabilité exacte de la version archivée `v2.1.0`.
- **Usage autorisé :** Inspection historique, audits de reproductibilité comparative v2.1.0 → v3.0.0 et développement ultérieur d'un pipeline lexical natif v3.0.0 découplant explicitement `Y` (contrôlabilité instrumentale) et `A >= 0` (activation autonome).
- **Provenance des corpus tiers :** Voir [`../../DATA_PROVENANCE.md`](../../DATA_PROVENANCE.md) et [`EPISTEMIC_STATUS.md`](EPISTEMIC_STATUS.md).
