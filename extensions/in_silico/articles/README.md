# CARTOGRAFFECT *in silico* — Série de mini-articles scientifiques vulgarisés

Cette collection rassemble **cinq mini-articles scientifiques accessibles** conçus pour expliquer clairement — sans jargon inutile mais sans rien sacrifier à l'exactitude des données — l'ensemble des simulations *in silico* réalisées sur le modèle **CARTOGRAFFECT** en inférence active.

Chaque mini-article s'ouvre sur un **résumé scientifique standard** structuré en cinq temps (*Contexte, Objectif, Méthode, Résultats, Conclusion*), suivi d'une explication intuitive par analogies, des tableaux de résultats vérifiés, d'un guide de lecture des figures générées et d'un bilan honnête des limites.

---

## Sommaire des mini-articles

| N° | Mini-article | Question scientifique vulgarisée | Jeu de données & résultats |
| :---: | :--- | :--- | :--- |
| **1** | [Cartographier les émotions en 3D : comment CARTOGRAFFECT traduit le vécu affectif en inférence active](01_architecture_cartograffect_vulgarisation.md) | Comment transformer des notions psychologiques (*attente, contrôle, profondeur émotionnelle*) en un agent mathématique sans boîte noire ni « triche » ? | Architecture à **176 états** certifiée isomorphe à Lean 4, boucle POMDP à 2 niveaux, **8 paramètres** individuels $\theta$. |
| **2** | [Tests de cohérence *in silico* (Expérience 1)](02_trois_predictions_falsifiables.md) | P1 (test de cohérence numérique du projecteur budgétaire $L_1$) et P2–P3 (cohérence générative interne *in silico*, `V3 = 0`) | **Expérience 1** ($N = 1\,000$ trajectoires / condition) + [Figure 1](../results/fig1_falsifiable_predictions.png). |
| **3** | [Quatre façons de traverser le stress : résilience, inhibition, agitation et rigidité](03_quatre_profils_cliniques.md) | En ne modifiant **que** les 8 réglages $\theta$ d'un même agent face aux mêmes épreuves, retrouve-t-on quatre trajectoires synthétiques distinctes et reproductibles ? | **Expérience 2** ($N = 20$ graines appariées × 4 profils) + [Figure 2](../results/fig2_clinical_phenotypes.png). |
| **4** | [Peut-on mesurer ces 8 paramètres et prouver que le modèle bat ses rivaux ?](04_fiabilite_mesure_et_comparaison_modeles.md) | À partir des seuls choix et réactions d'un agent simulé dans une tâche de 280 essais, retrouve-t-on fidèlement ses 8 paramètres et distingue-t-on CARTOGRAFFECT de modèles plus simples ? | **Expérience 3** ($M = 500$ + 10 NUTS + $4 \times 100$ modèles) + [Figures 3a](../results/fig3a_parameter_recovery.png) & [3b](../results/fig3b_model_recovery.png). |
| **5** | `[QUARANTAINE — SYNTHETIC EXPLORATORY ONLY — V3 = 0]` [Simulations synthétiques sur 8 et 26 régimes paramétriques inspirés du DSM-5](../exploratory_synthetic/05_psychiatrie_computationnelle_dsm5_et_interventions.md) | Exploration purement synthétique de lois *a priori* multivariées dans $\theta$ (`V3 = 0`, zéro donnée clinique humaine, isolée dans `exploratory_synthetic/`). | **Expériences 4 & 5** (quarantaine [`exploratory_synthetic/`](../exploratory_synthetic/)), [Figures 4a–4d](../results/dsm5_phenotyping/fig4a_xyz_occupation_densities.png) & [Figures 5a–5e](../results/dsm5_full_nosology/fig5a_xyz_occupation_atlas_26.png). |

> **Statut global de validation :** les **18 critères prédéfinis** du cœur (Expériences 1–3) sont validés (`ALL_CRITERIA_PASSED = True`, [results/validation_summary.md](../results/validation_summary.md)), les campagnes pan-DSM-5 des **Expériences 4 & 5** ont abouti sans erreur ([rapport Exp. 4](../results/dsm5_phenotyping/dsm5_separability_and_phenotyping_summary.json), [rapport Exp. 5](../results/dsm5_full_nosology/full_dsm5_separability_and_nosology_summary.json)), et l'ensemble des **57 tests `pytest`** du dépôt réussit (`0` échec).

---

## Glossaire vulgarisé — Les 8 paramètres individuels ($\theta$)

Dans CARTOGRAFFECT, chaque individu simulé est décrit par **8 curseurs** regroupés sous la lettre $\theta$. Rien d'autre ne change d'un profil clinique à l'autre dans l'Expérience 2 (`pure_theta_only = True`).

| Paramètre | Nom simple | Métaphore du quotidien | Quand il est **élevé** | Quand il est **faible** |
| :---: | :--- | :--- | :--- | :--- |
| `tau_A` ($\tau_A$) | Seuil de sensibilité à l'**Attente** | « À partir de quelle taille de surprise est-ce que je réagis ? » | Filtre beaucoup : il faut un gros décalage entre attente et réalité pour faire bouger $X$ (risque de verrouillage sur $X = 0$). | Très réactif : la moindre incohérence ou ambiguïté déplace l'axe d'attente $X$. |
| `tau_C` ($\tau_C$) | Seuil de sensibilité au **Contrôle** | « À partir de quelle perte d'efficacité est-ce que je me sens impuissant ? » | Tolère mieux les ratés avant de basculer sur l'axe $Y$. | Réagit vite à toute baisse perçue de contrôle sur l'environnement. |
| `lambda` ($\lambda$) | Poids d'**arbitrage budgétaire** $L_1$ | « Partager une même enveloppe entre attente et contrôle » | Compétition forte ($\lambda \to 1$) : ce qui est investi sur l'axe $X$ réduit d'autant la marge sur $Y$. | Indépendance ($\lambda \to 0$) : les deux axes varient chacun de leur côté sans contrainte commune. |
| `alpha_0` ($\alpha_0$) | **Inertie émotionnelle** de base | « Poids de la boule de neige au départ » | L'agent croit fortement à la persistance de son état actuel dès les strates peu profondes. | État très fluide et facile à réviser au fil des événements. |
| `gamma_alpha` ($\gamma_\alpha$) | **Croissance de l'inertie** avec la profondeur $Z$ | « Plus la vallée est profonde, plus ses parois sont raides » | L'inertie grimpe très vite ($\alpha_z = \alpha_0 e^{\gamma_\alpha z}$) dès que l'émotion s'approfondit. | L'inertie augmente modérément d'une couche à l'autre. |
| `eta_diss` ($\eta_{\text{diss}}$) | Taux de **dissipation allostatique** | « Vitesse du thermostat de retour au calme » | Lorsque la situation redevient neutre et sûre, l'agent revient vite vers le *Point de Veille* $(0, 0, 0)$. | Récupération lente ; même quand le danger a disparu, l'état affectif reste collé en profondeur. |
| `beta_X` ($\beta_X$) | Poids **épistémique** (clarté / compréhension) | « Priorité accordée à réduire l'incertitude » | L'agent investit fortement pour explorer ou réagir aux surprises et à l'ambiguïté ($\beta_X > \beta_Y$). | Moins sensible au besoin d'expliquer l'imprévu. |
| `beta_Y` ($\beta_Y$) | Poids **pragmatique** (récompense / action) | « Priorité accordée à obtenir un résultat concret » | Fortement guidé par le gain ou le contrôle immédiat de l'action. | Pondère moins la valeur pragmatique directe par rapport à l'incertitude. |

---

## Petit guide pour lire les chiffres statistiques sans jargon

Pour éviter de buter sur les symboles présents dans les tableaux scientifiques, voici comment les interpréter simplement :

- **$r$ (corrélation de Pearson, entre $-1$ et $+1$) :** mesure si deux quantités bougent ensemble. Proche de $+1$, elles montent de concert (par exemple entre vraie valeur et valeur estimée) ; proche de $-1$, quand l'une monte, l'autre descend (arbitrage budgétaire) ; proche de $0$, elles sont indépendantes.
- **$p$ et $p_{\text{Holm}}$ (valeur-$p$ brute et corrigée de Holm-Bonferroni) :** probabilité d'observer une telle différence par pur hasard si l'effet n'existait pas. Plus $p$ est petit (par exemple $< 0.01$ ou $< 10^{-5}$), plus l'effet est crédible. La correction de **Holm-Bonferroni** évite qu'à force de faire beaucoup de tests d'un coup, l'un d'eux paraisse significatif par simple chance.
- **$d$, $d_z$ et $r_{rb}$ (tailles d'effet) :** là où $p$ dit « l'effet n'est pas dû au hasard », la taille d'effet dit « l'effet est grand ou minuscule ». Pour $d$ ou $d_z$ (Cohen), $0.2$ est petit, $0.8$ déjà grand ; ici plusieurs effets atteignent $1.5$ à $8.3$. Le rang-bisérial $r_{rb}$ varie de $0$ à $1$ : à $1.000$, tous les individus appariés vont dans le même sens.
- **IC 95 % et couverture :** fourchette dans laquelle se trouve la vraie valeur avec 95 % de confiance. Une « couverture » proche de 95 % (objectif ici $\ge 85\,\%$) confirme que le modèle ne sous-estime ni ne surestime son incertitude.
- **$\hat{R}$ (*R-hat*) et ESS (*Effective Sample Size*) :** diagnostics d'un échantillonnage bayésien MCMC (algorithme NUTS). Si $\hat{R} < 1.02$, deux chaînes lancées indépendamment ont convergé vers exactement la même réponse ; si l'ESS est élevé ($\ge 400$), les tirages contiennent suffisamment d'information indépendante pour être fiables.
- **BIC, WAIC et $pxp$ (comparaison de modèles) :** le BIC et le WAIC départagent des modèles concurrents en récompensant ceux qui expliquent bien les données tout en sanctionnant la complexité inutile. Le **$pxp$** (*protected exceedance probability*) donne la probabilité qu'un modèle soit réellement le plus fréquent dans la population simulée, même après prise en compte du risque qu'aucune différence n'existe ; un seuil $> 0.95$ est considéré comme très fort.
- **Coefficient $\kappa$ de Cohen, silhouette et distance de Mahalanobis (séparabilité multivariée) :** $\kappa$ mesure la précision d'un classement en corrigeant la part due au hasard ; la silhouette (de $-1$ à $+1$) évalue si les individus sont proches de leur propre cohorte et éloignés des autres ; la distance de Mahalanobis mesure l'écart entre deux cohortes en tenant compte de leur dispersion interne corrélée.
- **MANOVA ($\Lambda_{\text{Wilks}}$ et trace de Pillai), $BC$ de Sarle et classification de Ward ($c_{\text{coph}}$) :** $\Lambda_{\text{Wilks}} \to 0$ et une trace de Pillai élevée indiquent une forte discrimination multivariée entre groupes ; le coefficient de bimodalité de Sarle ($BC > 0.556$) signale une distribution à deux pics (comme hypervigilance vs dissociation dans le TSPT) ; enfin, l'arbre de Ward regroupe hiérarchiquement les profils les plus proches, avec une fidélité mesurée par la corrélation cophénétique $c_{\text{coph}}$.

---

## Comment parcourir la série

1. **Débuter par le [Mini-article 1](01_architecture_cartograffect_vulgarisation.md)** pour visualiser la « boussole 3D » à 176 états et comprendre les règles anti-triche du moteur.
2. **Enchaîner avec les Mini-articles [2](02_trois_predictions_falsifiables.md), [3](03_quatre_profils_cliniques.md), [4](04_fiabilite_mesure_et_comparaison_modeles.md) et [5](05_psychiatrie_computationnelle_dsm5_et_interventions.md)** dans l'ordre du programme complet : *validité mécaniste → 4 prototypes cliniques → mesurabilité bayésienne → nosologie pan-DSM-5 & réponses thérapeutiques*.

