# Mini-article 1 — Cartographier les émotions en 3D : comment le modèle CARTOGRAFFECT traduit le vécu affectif en inférence active

- **Série :** Vulgarisation scientifique CARTOGRAFFECT *in silico* (1/5)
- **Thème :** Architecture formelle, espace affectif à 176 états et inférence active hiérarchique
- **Mots-clés :** inférence active, POMDP, espace affectif 3D, précision, Lean 4, dissipation allostatique
- **Temps de lecture estimé :** 5 minutes

---

## Résumé standard

**Contexte :** Les modèles informatiques classiques de la psychiatrie computationnelle résument souvent l'état émotionnel à un score unique positif ou négatif (la *valence* unidimensionnelle), ce qui distingue mal des situations cliniquement opposées comme une dépression figée dans l'impuissance et une anxiété agitée.

**Objectif :** Présenter de façon claire l'architecture **CARTOGRAFFECT**, sa traduction mathématique en un modèle probabiliste inversible d'inférence active, et les garanties mises en place pour éviter tout biais programmé à l'avance.

**Méthode :** La spécification formelle du modèle (certifiée en Lean 4 par 25 tests d'isomorphisme) définit un espace discret tridimensionnel de **176 états** organisé selon deux axes horizontaux — l'**Attente** ($X$) et le **Contrôle** ($Y$) — et une **Profondeur** verticale ($Z \in \{0,\dots,7\}$). Cet espace est couplé à un processus décisionnel partiellement observable (`POMDP`) hiérarchique à deux étages sous `pymdp`/JAX, piloté par **8 paramètres individuels ($\theta$)**.

**Résultats :** L'agent ne lit jamais les étiquettes cachées de l'environnement (comme un bloc étiqueté « rémission » ou « difficulté ») grâce à une interface purement sensorielle (`sensory_payload()`). La mise à jour bayésienne s'effectue en une seule passe (zéro double-comptage), et la persistance émotionnelle augmente naturellement avec $Z$ via des concentrations de Dirichlet exponentielles ($\alpha_z = \alpha_0 e^{\gamma_\alpha z}$) qui ralentissent la dissipation allostatique.

**Conclusion :** CARTOGRAFFECT fournit un pont rigoureux, traçable et testable entre la richesse phénoménologique du vécu émotionnel et la précision quantitative de l'inférence active.

---

## 1. L'idée centrale : une boussole émotionnelle à trois dimensions

Pour expliquer comment une émotion se forme, bascule puis s'apaise, CARTOGRAFFECT remplace le traditionnel « thermomètre de bonne ou mauvaise humeur » par une **boussole en relief à trois axes**, appelée $(X, Y, Z)$ :

1. **L'axe $X$ — L'Attente (révisabilité épistémique) :** *« Est-ce que le monde se comporte comme je m'y attendais ? »*
   - Vers les valeurs négatives ($X < 0$), les surprises s'accumulent : les indices deviennent ambigus, les règles changent, l'incertitude pèse (*Peur*, *Doute*, *Méfiance*).
   - Vers les valeurs positives ($X > 0$), l'environnement reste lisible ou l'agent ose s'ouvrir à la nouveauté (*Courage*, *Curiosité*).
2. **L'axe $Y$ — Le Contrôle (capacité pragmatique) :** *« Est-ce que mes actions produisent le résultat voulu ? »*
   - Vers les valeurs négatives ($Y < 0$), les tentatives échouent de façon répétée et l'action semble vaine (*Tristesse*, *Ennui*, *Impuissance*).
   - Vers les valeurs positives ($Y > 0$), la mobilisation reste forte ou l'action porte ses fruits (*Joie*, *Colère* lorsque l'action reste tendue malgré l'incertitude).
3. **L'axe $Z$ — La Profondeur allostatique ($Z = 0$ à $7$) :** *« À quel point cet état est-il ancré et difficile à inverser ? »*
   - À $Z = 0$ se trouve le **Point de Veille** $(0, 0, 0)$, l'état calme de disponibilité basale.
   - À $Z = 1$ apparaît la **Surprise** $(0, 0, 1)$, rupture d'attention encore neutre.
   - De $Z = 2$ à $Z = 7$, l'émotion se déploie sur des anneaux de plus en plus larges et tenaces.

### Pourquoi exactement 176 états ?

La carte n'est pas une grille carrée choisie au hasard. Elle obéit à une géométrie très précise :
- **8 opérateurs centraux** sur la colonne centrale $(0, 0, Z)$ de $Z = 0$ à $Z = 7$ : *Point de Veille* ($Z=0$), *Surprise* ($Z=1$), *Anticipation* ($Z=2$), *Émoi* ($Z=3$), *Réserve* ($Z=4$), *Recul* ($Z=5$), *Saisissement* ($Z=6$) et *Suspension* ($Z=7$).
- **168 états périphériques** répartis sur six couronnes en losange ($Z = 2$ à $7$). À chaque strate $Z$, la somme des valeurs absolues des deux axes est constante : $|X| + |Y| = 2Z - 2$. En $Z = 2$, la couronne comporte 8 émotions primaires (*Joie, Tristesse, Peur, Courage, Désir, Dégoût, Colère, Calme*) ; en $Z = 7$, elle en compte 48 (jusqu'à *Infini* en $(0, +12, 7)$).

Au total, $8 + (8 + 16 + 24 + 32 + 40 + 48) = 176$ états exactement. L'ensemble de ces règles géométriques est vérifié automatiquement par **25 tests d'isomorphisme avec la preuve formelle Lean 4** (au sein d'une suite de **50 tests automatisés** tous validés).

---

## 2. Comment fonctionne l'agent virtuel : deux étages qui dialoguent sans tricher

Pour simuler un participant humain placé face à une tâche de décision incertaine, le modèle assemble deux étages en inférence active (`pymdp`), c'est-à-dire deux boucles qui prédisent ce qui va arriver et mettent à jour leurs croyances à la lumière des observations :

```text
  Monde simulé (Bandit non stationnaire)
        │
        │  [Observe uniquement indice + résultat via sensory_payload()]
        ▼
  ┌─────────────────────────────────────────────────────────────────────┐
  │ ÉTAGE 1 — Moteur de tâche (TaskInferenceEngine)                     │
  │  • Infère la règle cachée et sa capacité de contrôle                │
  │  • Calcule la surprise bayésienne et deux gradients lissés (∇A, ∇C) │
  └─────────────────────────────────────────────────────────────────────┘
        │
        │  [Envoie 3 signaux lissés (obs_A, obs_C, niveau de persistance)]
        ▼
  ┌─────────────────────────────────────────────────────────────────────┐
  │ ÉTAGE 2 — Moteur affectif (AffectivePOMDPEngine, 176 états)         │
  │  • Met à jour la probabilité d'occuper chacun des 176 états         │
  │  • Arbitre entre approfondir, rééquilibrer X/Y ou dissiper vers 0   │
  └─────────────────────────────────────────────────────────────────────┘
```

### Trois garde-fous anti-triche intégrés dès la conception

En modélisation, le grand piège consiste à « souffler la réponse » à l'algorithme ou à compter deux fois le même indice pour grossir artificiellement un effet. L'architecture auditée verrouille trois protections strictes :

1. **Aucune fuite des variables cachées :** l'environnement connaît en interne s'il est dans un bloc difficile ou en rémission (`d_obj`, `is_remission`), mais l'agent ne passe que par la méthode `sensory_payload()`. Il ne « devine » qu'un environnement s'est calmé qu'après avoir réellement constaté des issues neutres.
2. **Inférence en une seule passe (zéro double-comptage) :** chaque indice avant le choix et chaque résultat après l'action ne mettent à jour les croyances et les matrices d'apprentissage (Dirichlet `pA`/`pB`) qu'**une seule fois** par essai.
3. **Neutralité préalable sur $Z = 2$ :** au départ, la matrice de transition $B(Z=2)$ traite exactement à égalité les états axiaux (*Joie, Peur*...) et les états diagonaux (*Colère, Calme*...), avec un écart numérique inférieur à $10^{-16}$. Si une asymétrie apparaît en simulation, elle vient du fonctionnement du système, pas d'un coup de pouce caché.

---

## 3. Ce qui varie d'une personne à l'autre : les 8 paramètres $\theta$

Deux mécanismes clés relient la profondeur $Z$ au vécu clinique :
- **La rigidité croissante (inertie de Dirichlet) :** à la strate $z$, la confiance dans les croyances déjà installées suit $\alpha_z = \alpha_0 \exp(\gamma_\alpha z)$. Plus on descend dans des émotions profondes, plus il faut d'observations contraires pour faire évoluer la croyance.
- **Le freinage du retour au calme :** le taux de dissipation effectif diminue en profondeur selon la loi :
  $$\eta_{\text{eff}}(Z) = \operatorname{clip}\!\left(\frac{\eta_{\text{diss}}}{1 + 0.18\,\alpha_z},\; 0.005,\; 1.0\right)$$
  Autrement dit, une émotion de surface ($Z = 2$) s'efface rapidement dès que la menace cesse, alors qu'une détresse profonde ($Z = 5$ ou $6$) résiste longtemps même quand la situation redevient favorable.

Avec **8 paramètres seulement** ($\tau_A, \tau_C, \lambda, \alpha_0, \gamma_\alpha, \eta_{\text{diss}}, \beta_X, \beta_Y$, dont la primauté épistémique $\beta_X > \beta_Y > 0$), décrits en détail dans le [glossaire du sommaire](README.md), tout le comportement dynamique d'un individu est résumé de façon compacte et mesurable.

---

## À retenir en 3 points

1. **La géométrie a un sens psychologique :** CARTOGRAFFECT ne classe pas les émotions en liste alphabétique, mais selon l'incertitude épistémique ($X$), le sentiment de maîtrise ($Y$) et l'inertie temporelle ($Z$).
2. **L'agent est aveugle aux étiquettes du scénario :** il infère la sécurité ou le danger uniquement par ses observations sensorielles, en une seule passe probabiliste.
3. **Les 176 états obéissent à des règles mathématiques vérifiées :** chaque coordonnée et chaque contrainte sont testées face à la spécification formelle Lean 4.

## Limites et portée

Ce premier volet décrit l'architecture théorique et computationnelle *in silico*. Les 176 étiquettes linguistiques (*Joie*, *Doute*, *Désespoir*...) servent de repères lexicaux associés aux coordonnées discrètes $(X, Y, Z)$, et les seuils ou pondérations internes relèvent d'un modèle génératif normatif dont la pertinence doit être jugée par ses prédictions falsifiables ([Mini-article 2](02_trois_predictions_falsifiables.md)), sa portée clinique ([Mini-article 3](03_quatre_profils_cliniques.md)), son identifiabilité empirique ([Mini-article 4](04_fiabilite_mesure_et_comparaison_modeles.md)) et son extension pan-nosologique transdiagnostique ([Mini-article 5](05_psychiatrie_computationnelle_dsm5_et_interventions.md)).
