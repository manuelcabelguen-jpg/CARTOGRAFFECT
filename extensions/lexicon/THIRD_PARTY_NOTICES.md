# Avis Juridiques, Propriété Intellectuelle et Attributions Tierces (THIRD-PARTY NOTICES)

**Projet : CARTOGRAFFECT® — Modèle Formel, Pyramide Topologique 3D et Dictionnaire Vectoriel Multi-Strates**

---

## 1. Titularité Principale et Enregistrement Officiel des Droits d'Auteur

- **Titulaire exclusif des droits patrimoniaux et moraux** : **Manuel Cabelguen**
- **Marque et œuvre protégée** : **CARTOGRAFFECT®**
- **Enregistrement officiel** : Office de la propriété intellectuelle du Canada (**OPIC / CIPO**), **Certificat d'enregistrement de droit d'auteur n° 1233199**.
- **Juridiction applicable** : *Loi sur le droit d'auteur* du Canada (L.R.C. (1985), ch. C-42) et conventions internationales applicables (Convention de Berne).

---

## 2. Régime de Double Licence du Dépôt CARTOGRAFFECT®

Ce dépôt est placé sous un régime strict de **double licence** distinguant l'implémentation logicielle/formelle et le corpus théorique/taxonomique :

### 2.1 Code Source, Preuves Formelles Lean 4 et Visualiseurs (`GNU AGPLv3`)
L'ensemble du code source algorithmique, des scripts de traitement, des preuves formelles mécanisées sous Lean 4 et des interfaces interactives est distribué sous licence **GNU Affero General Public License v3.0 (ou ultérieure)** (`SPDX-License-Identifier: AGPL-3.0-or-later`) :
- `src/` (modules Python de projection géométrique, d'interpolation RBF/k-NN, de validation CCA/Procrustes et de construction du dictionnaire multi-strates)
- `scripts/` et scripts d'orchestration à la racine (`*.py`)
- `Cartograffect/*.lean`, `Cartograffect/Validation/*.lean` et `Lexicon176.lean` (spécifications et théorèmes certifiés sous Lean 4.35.0)
- `*.html` (explorateurs topologiques 3D interactifs)

### 2.2 Architecture Théorique, Taxonomie et Tables Dérivées (`CC BY-NC-SA 4.0`)
L'architecture théorique (modèle octaédrique $L_1$ à 176 prototypes, diamant 303, stratification verticale en 6 strates sémantiques de l'expérience humaine), la documentation scientifique et les tables de coordonnées géométriques dérivées sont mises à disposition sous licence **Creative Commons Attribution - Pas d'Utilisation Commerciale - Partage dans les Mêmes Conditions 4.0 International** (`SPDX-License-Identifier: CC-BY-NC-SA-4.0`) :
- `docs/` (documentation théorique, épistémologique et mathématique)
- `tables/` et fichiers `.tsv` / `.json` de paramètres projetés et synthèses statistiques du modèle CARTOGRAFFECT®
- Architecture conceptuelle et taxonomie des 6 strates verticales ($Z$)

Toute exploitation commerciale de la taxonomie, des coordonnées géométriques ou du modèle théorique CARTOGRAFFECT® requiert une licence commerciale explicite accordée par le titulaire (Manuel Cabelguen).

---

## 3. Attributions Académiques Strictes et Ressources Tierces

Conformément aux meilleures pratiques scientifiques et au respect absolu du droit d'auteur (notamment l'article 29 de la *Loi sur le droit d'auteur* du Canada relatif à l'utilisation équitable aux fins de recherche et d'étude privée), **aucun fichier brut propriétaire tiers n'est redistribué en tant que tel** (`data/raw_third_party/` est exclu du suivi de version). Les coordonnées, indices et classifications présents dans ce dépôt constituent des **transformations mathématiques et géométriques dérivées originales** (projections octaédriques $L_1$, ratios componantiels et interpolations à noyau).

### 3.1 Paradigme GRID et Component Process Model (CPM) — CISA / Université de Genève
Les ancres théoriques componantielles (5 composantes fonctionnelles, 142 descripteurs d'évaluation cognitive, de symptômes corporels, d'expressions motrices, de tendances à l'action et de ressenti subjectif) et les 24 prototypes émotionnels canoniques s'appuient sur les travaux publiés du **Centre Interfacultaire en Sciences Affectives (CISA, Université de Genève)** :
- **Scherer, K. R.** (2005). What are emotions? And how can they be measured? *Social Science Information*, 44(4), 695–729. https://doi.org/10.1177/0539018405058216
- **Fontaine, J. R. J., Scherer, K. R., Roesch, E. B., & Ellsworth, P. C.** (2007). The world of emotions is not two-dimensional. *Psychological Science*, 18(12), 1050–1057. https://doi.org/10.1111/j.1467-9280.2007.02024.x
- **Fontaine, J. R. J., Scherer, K. R., & Soriano, C.** (Eds.). (2013). *Components of Emotional Meaning: A Sourcebook*. Oxford University Press. https://doi.org/10.1093/acprof:oso/9780199592746.001.0001

### 3.2 Lexique NRC-VAD (Valence, Arousal, Dominance) — CNRC / NRC Canada
Les normes psychométriques dimensionnelles de Valence, d'Activation (*Arousal*) et de Dominance (*Dominance*) utilisées comme signaux d'entrée pour l'alignement géométrique proviennent du **NRC Valence, Arousal, and Dominance (NRC-VAD) Lexicon** publié par le Conseil national de recherches du Canada (CNRC / NRC), utilisé à des fins de recherche académique non commerciale conformément à la *NRC Research License* :
- **Mohammad, S. M.** (2018). Obtaining reliable human ratings of valence, arousal, and dominance for 20,000 English words. In *Proceedings of the 56th Annual Meeting of the Association for Computational Linguistics (ACL 2018)* (pp. 174–184). Melbourne, Australia. https://aclanthology.org/P18-1017/

### 3.3 Base Lexicale DIMA et Normes Affectives Françaises — Utilisation Équitable de Recherche
L'indexation morpho-sémantique différentielle des prédicats d'affects français (catégories causatives vs expérientielles, classes d'antonymie et intensité différentielle) et le croisement psychométrique francophone mobilisent à titre de référence de recherche équitable (*Fair Dealing for Research*, art. 29 LDA Canada) :
- **Le Pesant, D.** (2023). *Dictionnaire électronique des Mots d'Affect (DIMA — Groupes 1 & 2)*. Université Paris Nanterre / MoDyCo (CNRS UMR 7114).
- **Ric, F., Alexopoulos, T., Muller, D., & Aubé, B.** (2013). Emotional norms for 524 French personality trait words / Base FANCat (*French Affective Norms for Categorization*). *Behavior Research Methods*, 45(2), 414–421.
- **Haidt, J.** (2003). The moral emotions. In R. J. Davidson, K. R. Scherer, & H. H. Goldsmith (Eds.), *Handbook of Affective Sciences* (pp. 852–870). Oxford University Press. (Référence théorique pour la Strate 4 : Éthique & Morale).
- **Schwartz, S. H.** (2012). An overview of the Schwartz theory of basic values. *Online Readings in Psychology and Culture*, 2(1), 11. https://doi.org/10.9707/2307-0919.1116 (Référence théorique pour la Strate 5 : Axiologie & Valeurs).

### 3.4 Nomenclature Lexicographique Française Ouverte (Zéro Source Commerciale)
La nomenclature de lemmes français, l'étiquetage morpho-syntaxique et les marqueurs de domaines utilisés pour la couverture des 6 strates sémantiques (en particulier l'extension des strates éthique, axiologique et politique/civique) reposent **exclusivement sur des ressources lexicographiques publiques et ouvertes du CNRS et de l'enseignement supérieur** :
- **Lexique 3.83** : **New, B., Pallier, C., Brysbaert, M., & Ferrand, L.** (2004). Lexique 2 : A new French lexical database. *Behavior Research Methods, Instruments, & Computers*, 36(3), 516–524. Distribué sous licence ouverte **CC BY-SA 4.0** (http://www.lexique.org).
- **GLAWI (CLLE-ERSS, CNRS UMR 5263)** : **Sajous, F., & Hathout, N.** (2015). GLAWI, a free XML-encoded Machine-Readable Dictionary built from the French Wiktionary. In *Proceedings of the eLex 2015 Conference* (pp. 405–426). Herstmonceux Castle, UK. Ressource lexicographique structurée distribuée sous licence libre **CC BY-SA 3.0 / 4.0** (http://redac.univ-tlse2.fr/lexicons/glawi.html).
- **Morphalou 3.1 & Trésor de la Langue Française informatisé (TLFi)** : **CNRS / ATILF** (Analyse et Traitement Informatique de la Langue Française, UMR 7118, Université de Lorraine & CNRS) — Ressources morphologiques et lexicales distribuées sous **Licence Ouverte / Open Licence Etalab** et **CC BY-SA** (https://www.ortolang.fr/market/lexicons/morphalou).

> **Garantie d'indépendance éditoriale** : Aucune définition, liste propriétaire ou donnée issue de dictionnaires commerciaux (tels que *Larousse*, *Le Robert*, *Hachette* ou équivalents sous droits réservés) n'est extraite, copiée ou incorporée dans ce dépôt.

