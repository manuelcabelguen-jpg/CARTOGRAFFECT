# Annexe A : Algorithme du système émotionnel par catégories et groupes (Z = 0 à Z = 7)

Ce document présente l’architecture géométrique et l’inventaire formel des **176 entrées** de l’espace affectif : le Point de Veille (0, 0, 0), les sept opérateurs centraux — Surprise (0, 0, 1), Anticipation (0, 0, 2), Émoi (0, 0, 3), Réserve (0, 0, 4), Recul (0, 0, 5), Saisissement (0, 0, 6) et Suspension (0, 0, 7) —, ainsi que les **168 positions affectives** réparties sur les couronnes Z = 2 à Z = 7. Les coordonnées horizontales X et Y situent chaque affect selon la révisabilité du modèle interne et la contrôlabilité de la situation ; la coordonnée verticale Z indique la profondeur temporelle et le degré d’abstraction cognitive du traitement, et non une intensité affective. Cette grille décrit des relations structurelles de placement et d’antagonisme régulateur, sans constituer à elle seule un outil diagnostique clinique ni une preuve intrinsèque d’opposition sémantique. Afin de garantir que cette architecture algorithmique est exempte de toute contradiction déductive, l’intégralité des règles de placement, de conservation géométrique, d’antagonisme et de partition taxonomique des 176 positions a fait l’objet d’une vérification formelle assistée par ordinateur à l’aide du prouveur de théorèmes Lean 4 (version 4.35.0), certifiée sans axiome ad hoc ni preuve incomplète.

- Axe X — Attente (révisabilité du modèle interne) : arbitrage épistémique entre le maintien des croyances acquises et leur mise à jour pour réduire l’ambiguïté.
- Axe Y — Contrôle (contrôlabilité du monde) : capacité pragmatique d’action visant à transformer la situation et à réduire le risque encouru (Parr et al., 2022).
- Axe Z — Profondeur : profondeur temporelle et niveau d’abstraction cognitive du traitement affectif.
- Modulation attentionnelle (Précision) : la précision agit comme un facteur de pondération réglant la sensibilité du système aux écarts de prédiction (Feldman & Friston, 2010) ; elle gouverne le seuil de basculement et la fluidité des transitions entre strates adjacentes le long de l’Axe Z, sans constituer une coordonnée spatiale indépendante.

## 1. Loi des couronnes et organisation des strates de l’espace affectif

La loi des couronnes détermine l’ensemble des positions géométriquement admissibles au sein de l’espace affectif. Si les opérateurs centraux (Surprise, Anticipation, Émoi, Réserve, Recul, Saisissement et Suspension) président à l’orientation des trajectoires à chaque strate, la grille géométrique fixe la topologie des emplacements tandis que la cinétique empirique de passage d’une coordonnée à une autre relève de la dynamique du modèle. Dans cet inventaire, le signe (positif, négatif ou nul) et la coordonnée dominante (X ou Y) servent à positionner rigoureusement les affects dans l’espace tridimensionnel.

- Strate Z = 0 : Point de Veille (0, 0, 0), origine structurale et équilibre basal du modèle.
- Strate Z = 1 : occupée uniquement par la Surprise (0, 0, 1), opérateur ascendant de rupture et de saillance perceptive, sans couronne périphérique.
- Strate Z = 2 : première couronne de huit prototypes fondamentaux, déployée autour de l’Anticipation (0, 0, 2), opérateur central descendant d’orientation : Joie (0, +2, 2), Tristesse (0, −2, 2), Peur (−2, 0, 2), Courage (+2, 0, 2), Désir (+1, +1, 2), Colère (−1, +1, 2), Calme (+1, −1, 2) et Dégoût (−1, −1, 2).
- Strates Z = 3 à Z = 7 : déploiement des couronnes successives autour de leurs opérateurs centraux respectifs situés en (0, 0, Z).

Règle géométrique du rayon et de l’effectif des couronnes : À partir de la strate Z = 2, toutes les positions périphériques d’une même couronne se répartissent sur un losange dont le rayon (correspondant à la somme des déplacements absolus sur l’Axe X et sur l’Axe Y) est égal au double du rang de la strate diminué de deux unités, soit un rayon de 2 en Z = 2, de 4 en Z = 3, de 6 en Z = 4, de 8 en Z = 5, de 10 en Z = 6 et de 12 en Z = 7. Le nombre de positions à coordonnées entières sur chaque losange s’élève au quadruple de ce rayon (soit huit fois le rang de la strate diminué d’une unité) : les couronnes Z = 2 à Z = 7 comportent ainsi exactement 8, 16, 24, 32, 40 et 48 positions périphériques, auxquelles s’ajoutent, au centre de chaque plan, les opérateurs (0, 0, Z).

## 2. Typologie géométrique des positions et groupes d’orientation

Au sein de chaque couronne, les coordonnées se répartissent selon trois types géométriques distincts :

- Positions axiales : situées directement sur l’un des deux axes principaux, l’autre coordonnée étant nulle (X = 0 ou Y = 0).
- Positions diagonales : caractérisées par une implication égale et non nulle sur chacun des deux axes (valeur absolue de X égale à la valeur absolue de Y).
- Positions latérales : caractérisées par deux coordonnées non nulles mais d’amplitudes inégales (valeur absolue de X différente de la valeur absolue de Y) ; elles apparaissent à partir de la strate Z = 3, dès que le rayon du losange dépasse deux unités.

Dans cet inventaire, les intitulés de groupes JOIE, TRISTESSE, PEUR et COURAGE désignent des secteurs d’orientation géométrique définis par l’axe dominant et son signe (respectivement Y positif dominant, Y négatif dominant, X négatif dominant et X positif dominant), et non une qualification morale, clinique ou hédonique de l’affect. Une émotion de tonalité douloureuse ou aversive peut ainsi appartenir géométriquement au groupe d’orientation JOIE dès lors qu’elle comporte une forte mobilisation motrice dominante en Y positif associée à une fermeture en X négatif (comme la Consternation, la Haine ou la Terreur), tout comme un état d’apaisement agréable peut appartenir au groupe d’orientation TRISTESSE lorsqu’il associe un relâchement moteur en Y négatif à une ouverture cognitive en X positif (comme le Soulagement, la Sérénité ou la Béatitude).

## 3. Répertoire systématique des strates et catégories (Z = 0 à Z = 7)

Note de lecture : Chaque catégorie N regroupe l’opérateur central et les positions périphériques de la strate Z = N, présentées successivement selon leur typologie géométrique : positions axiales, positions latérales (à partir de Z = 3), puis positions diagonales.

### STRATE Z = 0 : Point de Veille

- Point de Veille (X0/Y0/Z0) : origine structurale et équilibre homéostatique basal du modèle.

### STRATE Z = 1 : Opérateur de Surprise

- Surprise (X0/Y0/Z1) : opérateur central ascendant de rupture et de saillance perceptive (sans couronne périphérique à cette strate).

### CATÉGORIE 2 : Affects primaires et prototypes fondamentaux (8 positions, Z = 2, rayon = 2)

- Opérateur central : Anticipation (X0/Y0/Z2) — opérateur descendant d’orientation vers la première couronne.

Positions axiales (4) :

- Axe Y (Joie / Tristesse) : Joie (X0/Y+2/Z2), Tristesse (X0/Y-2/Z2).
- Axe X (Peur / Courage) : Peur (X-2/Y0/Z2), Courage (X+2/Y0/Z2).

Positions diagonales (4) :

- Diagonale de compensation (Colère / Calme) : Colère (X-1/Y+1/Z2), Calme (X+1/Y-1/Z2).
- Diagonale de congruence (Désir / Dégoût) : Désir (X+1/Y+1/Z2), Dégoût (X-1/Y-1/Z2).

### CATÉGORIE 3 : Émotions réactives (16 positions, Z = 3, rayon = 4)

- Opérateur central : Émoi (X0/Y0/Z3).

Positions axiales (4) :

- Groupe JOIE (1) : Enthousiasme (X0/Y+4/Z3).
- Groupe TRISTESSE (1) : Ennui (X0/Y-4/Z3).
- Groupe PEUR (1) : Crainte (X-4/Y0/Z3).
- Groupe COURAGE (1) : Curiosité (X+4/Y0/Z3).

Positions latérales (8) :

- Groupe JOIE (2) : Consternation (X-1/Y+3/Z3), Euphorie (X+1/Y+3/Z3).
- Groupe TRISTESSE (2) : Soulagement (X+1/Y-3/Z3), Chagrin (X-1/Y-3/Z3).
- Groupe PEUR (2) : Panique (X-3/Y+1/Z3), Effroi (X-3/Y-1/Z3).
- Groupe COURAGE (2) : Émerveillement (X+3/Y-1/Z3), Aplomb (X+3/Y+1/Z3).

Positions diagonales (4) :

- Groupe COLÈRE (1) : Exaspération (X-2/Y+2/Z3).
- Groupe CALME (1) : Détente (X+2/Y-2/Z3).
- Groupe DÉSIR (1) : Attrait (X+2/Y+2/Z3).
- Groupe DÉGOÛT (1) : Retrait (X-2/Y-2/Z3).

### CATÉGORIE 4 : États émotionnels relationnels et sentiments réflexifs (24 positions, Z = 4, rayon = 6)

- Opérateur central : Réserve (X0/Y0/Z4).

Positions axiales (4) :

- Groupe JOIE (1) : Exaltation (X0/Y+6/Z4).
- Groupe TRISTESSE (1) : Langueur (X0/Y-6/Z4).
- Groupe PEUR (1) : Doute (X-6/Y0/Z4).
- Groupe COURAGE (1) : Assurance (X+6/Y0/Z4).

Positions latérales (16) :

- Groupe JOIE (4) : Envie (X-2/Y+4/Z4), Haine (X-1/Y+5/Z4), Amour (X+1/Y+5/Z4), Ferveur (X+2/Y+4/Z4).
- Groupe TRISTESSE (4) : Sérénité (X+2/Y-4/Z4), Plénitude (X+1/Y-5/Z4), Honte (X-2/Y-4/Z4), Vide (X-1/Y-5/Z4).
- Groupe PEUR (4) : Anxiété (X-4/Y+2/Z4), Manque (X-5/Y+1/Z4), Mépris (X-5/Y-1/Z4), Défiance (X-4/Y-2/Z4).
- Groupe COURAGE (4) : Fierté (X+4/Y+2/Z4), Épanouissement (X+5/Y+1/Z4), Affection (X+5/Y-1/Z4), Admiration (X+4/Y-2/Z4).

Positions diagonales (4) :

- Groupe COLÈRE (1) : Frustration (X-3/Y+3/Z4).
- Groupe CALME (1) : Acceptation (X+3/Y-3/Z4).
- Groupe DÉSIR (1) : Estime (X+3/Y+3/Z4).
- Groupe DÉGOÛT (1) : Rejet (X-3/Y-3/Z4).

### CATÉGORIE 5 : Dispositions, orientations et traits affectifs durables (32 positions, Z = 5, rayon = 8)

- Opérateur central : Recul (X0/Y0/Z5).

Positions axiales (4) :

- Groupe JOIE (1) : Puissance (X0/Y+8/Z5).
- Groupe TRISTESSE (1) : Impuissance (X0/Y-8/Z5).
- Groupe PEUR (1) : Méfiance (X-8/Y0/Z5).
- Groupe COURAGE (1) : Confiance (X+8/Y0/Z5).

Positions latérales (24) :

- Groupe JOIE (6) : Invulnérabilité (X+1/Y+7/Z5), Attachement (X+2/Y+6/Z5), Engagement (X+3/Y+5/Z5), Désenchantement (X-2/Y+6/Z5), Intolérance (X-3/Y+5/Z5), Injustice (X-1/Y+7/Z5).
- Groupe TRISTESSE (6) : Quiétude (X+3/Y-5/Z5), Sécurité (X+2/Y-6/Z5), Patience (X+1/Y-7/Z5), Pessimisme (X-2/Y-6/Z5), Fermeture (X-3/Y-5/Z5), Désespoir (X-1/Y-7/Z5).
- Groupe PEUR (6) : Insécurité (X-6/Y+2/Z5), Inquiétude (X-5/Y+3/Z5), Impatience (X-7/Y+1/Z5), Vulnérabilité (X-7/Y-1/Z5), Détachement (X-6/Y-2/Z5), Désengagement (X-5/Y-3/Z5).
- Groupe COURAGE (6) : Optimisme (X+6/Y+2/Z5), Ouverture (X+5/Y+3/Z5), Espoir (X+7/Y+1/Z5), Enchantement (X+6/Y-2/Z5), Tolérance (X+5/Y-3/Z5), Justice (X+7/Y-1/Z5).

Positions diagonales (4) :

- Groupe COLÈRE (1) : Insatisfaction (X-4/Y+4/Z5).
- Groupe CALME (1) : Satisfaction (X+4/Y-4/Z5).
- Groupe DÉSIR (1) : Intérêt (X+4/Y+4/Z5).
- Groupe DÉGOÛT (1) : Désintérêt (X-4/Y-4/Z5).

### CATÉGORIE 6 : Identités affectives (40 positions, Z = 6, rayon = 10)

- Opérateur central : Saisissement (X0/Y0/Z6).

Positions axiales (4) :

- Groupe JOIE (1) : Élan (X0/Y+10/Z6).
- Groupe TRISTESSE (1) : Inertie (X0/Y-10/Z6).
- Groupe PEUR (1) : Effacement (X-10/Y0/Z6).
- Groupe COURAGE (1) : Affirmation (X+10/Y0/Z6).

Positions latérales (32) :

- Groupe JOIE (8) : Ardeur (X+3/Y+7/Z6), Angoisse (X-3/Y+7/Z6), Allégresse (X+4/Y+6/Z6), Fureur (X-4/Y+6/Z6), Fougue (X+2/Y+8/Z6), Frénésie (X-2/Y+8/Z6), Jubilation (X+1/Y+9/Z6), Terreur (X-1/Y+9/Z6).
- Groupe TRISTESSE (8) : Béatitude (X+3/Y-7/Z6), Accablement (X-3/Y-7/Z6), Apaisement (X+4/Y-6/Z6), Morosité (X-4/Y-6/Z6), Contemplation (X+2/Y-8/Z6), Prostration (X-2/Y-8/Z6), Félicité (X+1/Y-9/Z6), Désolation (X-1/Y-9/Z6).
- Groupe PEUR (8) : Irritation (X-6/Y+4/Z6), Amertume (X-6/Y-4/Z6), Affolement (X-7/Y+3/Z6), Écrasement (X-7/Y-3/Z6), Fébrilité (X-8/Y+2/Z6), Anéantissement (X-8/Y-2/Z6), Désarroi (X-9/Y+1/Z6), Lassitude (X-9/Y-1/Z6).
- Groupe COURAGE (8) : Entrain (X+6/Y+4/Z6), Placidité (X+6/Y-4/Z6), Liesse (X+7/Y+3/Z6), Limpidité (X+7/Y-3/Z6), Extase (X+8/Y+2/Z6), Équanimité (X+8/Y-2/Z6), Exultation (X+9/Y+1/Z6), Harmonie (X+9/Y-1/Z6).

Positions diagonales (4) :

- Groupe COLÈRE (1) : Tourment (X-5/Y+5/Z6).
- Groupe CALME (1) : Ataraxie (X+5/Y-5/Z6).
- Groupe DÉSIR (1) : Triomphe (X+5/Y+5/Z6).
- Groupe DÉGOÛT (1) : Abattement (X-5/Y-5/Z6).

### CATÉGORIE 7 : Sentiments transcendantaux (48 positions, Z = 7, rayon = 12)

- Opérateur central : Suspension (X0/Y0/Z7) — marque l’arrêt ou la mise en suspens du modèle génératif face à l’incommensurable.

Positions axiales (4) :

- Groupe JOIE (1) : Infini (X0/Y+12/Z7).
- Groupe TRISTESSE (1) : Néant (X0/Y-12/Z7).
- Groupe PEUR (1) : Déréliction (X-12/Y0/Z7).
- Groupe COURAGE (1) : Communion (X+12/Y0/Z7).

Positions latérales (40) :

- Groupe JOIE (10) : Transcendance (X+2/Y+10/Z7), Déchirement (X-2/Y+10/Z7), Exubérance (X+4/Y+8/Z7), Horreur (X-4/Y+8/Z7), Renaissance (X+1/Y+11/Z7), Vertige (X-1/Y+11/Z7), Élévation (X+3/Y+9/Z7), Détresse (X-3/Y+9/Z7), Enivrement (X+5/Y+7/Z7), Révolte (X-5/Y+7/Z7).
- Groupe TRISTESSE (10) : Nirvana (X+2/Y-10/Z7), Perdition (X-2/Y-10/Z7), Paix (X+4/Y-8/Z7), Oppression (X-4/Y-8/Z7), Pérennité (X+1/Y-11/Z7), Abîme (X-1/Y-11/Z7), Abandon (X+3/Y-9/Z7), Damnation (X-3/Y-9/Z7), Silence (X+5/Y-7/Z7), Résignation (X-5/Y-7/Z7).
- Groupe PEUR (10) : Hantise (X-10/Y+2/Z7), Isolement (X-10/Y-2/Z7), Affliction (X-8/Y+4/Z7), Mélancolie (X-8/Y-4/Z7), Précarité (X-11/Y+1/Z7), Déchéance (X-11/Y-1/Z7), Sidération (X-9/Y+3/Z7), Engloutissement (X-9/Y-3/Z7), Tumulte (X-7/Y+5/Z7), Pétrification (X-7/Y-5/Z7).
- Groupe COURAGE (10) : Éblouissement (X+10/Y+2/Z7), Recueillement (X+10/Y-2/Z7), Rayonnement (X+8/Y+4/Z7), Contentement (X+8/Y-4/Z7), Ravissement (X+11/Y+1/Z7), Épiphanie (X+11/Y-1/Z7), Louange (X+9/Y+3/Z7), Lucidité (X+9/Y-3/Z7), Effusion (X+7/Y+5/Z7), Consentement (X+7/Y-5/Z7).

Positions diagonales (4) :

- Groupe COLÈRE (1) : Rage (X-6/Y+6/Z7).
- Groupe CALME (1) : Impassibilité (X+6/Y-6/Z7).
- Groupe DÉSIR (1) : Sublimation (X+6/Y+6/Z7).
- Groupe DÉGOÛT (1) : Dissolution (X-6/Y-6/Z7).

**Bilan des effectifs :** Les six couronnes Z = 2 à Z = 7 réunissent 8 + 16 + 24 + 32 + 40 + 48 = 168 positions affectives périphériques. En y ajoutant le Point de Veille (0, 0, 0) et les sept opérateurs centraux (de Z = 1 à Z = 7), l’architecture complète du système émotionnel totalise 176 entrées distinctes. L’exhaustivité, l’unicité des coordonnées et la disjonction stricte des sous-ensembles formant cette partition de 176 états sont formellement démontrées et certifiées sous Lean 4.

## 4. Logique de placement et règles de correspondance antagoniste

À chaque strate Z, la géométrie associe à toute position périphérique un correspondant antagoniste unique situé sur la même couronne. Cette mise en correspondance repose sur un principe général d’inversion des polarités et d’échange des dominantes : la géométrie fixe la coordonnée opposée, tandis que la tension de sens psychologique et phénoménologique entre les deux états vient valider le placement retenu. Sur le plan formel, le caractère strictement involutif de ces opérateurs de symétrie (toute transformation appliquée deux fois restituant l’état initial sans perte ni dérive de strate ou de rayon) ainsi que l’appariement bijectif des 24 positions axiales, des 24 positions diagonales et des 120 positions latérales (60 paires controlatérales) ont été mathématiquement vérifiés sous Lean 4, étant entendu que cette consistance déductive interne ne se substitue pas à l’épreuve empirique des faits.

1. Correspondance axiale (positions où X = 0 ou Y = 0) : Elle s’opère le long de l’axe principal concerné par inversion centrale, en changeant le signe de la coordonnée non nulle tout en conservant sa valeur absolue. Exemple : Joie (X0/Y+2/Z2) ↔ Tristesse (X0/Y-2/Z2).
2. Correspondance diagonale (positions où les valeurs absolues de X et de Y sont égales et non nulles) : Elle s’opère également par inversion centrale le long des diagonales principales, en inversant simultanément le signe de X et le signe de Y. Exemple : Colère (X-1/Y+1/Z2) ↔ Calme (X+1/Y-1/Z2).
3. Correspondance controlatérale (positions latérales où X et Y sont non nuls et d’amplitudes inégales) : Elle s’opère par réflexion diagonale, qui inverse le signe de chacune des deux coordonnées tout en permutant leurs valeurs absolues (l’amplitude dominante sur un axe devenant l’amplitude dominante de signe opposé sur l’autre axe, et la coordonnée secondaire conservant de même sa valeur absolue sur l’axe perpendiculaire avec inversion de son signe). Lorsque X et Y sont de signes opposés, cette réflexion permute directement les coordonnées ; lorsqu’ils sont de même signe, elle les permute en inversant leurs signes. L’image d’une position latérale appartient ainsi systématiquement au groupe d’orientation perpendiculaire selon quatre liaisons fixes : Joie (avec X > 0) ↔ Peur (avec Y < 0) ; Joie (avec X < 0) ↔ Courage (avec Y < 0) ; Tristesse (avec X > 0) ↔ Peur (avec Y > 0) ; Tristesse (avec X < 0) ↔ Courage (avec Y > 0). Les 60 paires controlatérales des strates Z = 3 à Z = 7 (respectivement 4, 8, 12, 16 et 20 paires) obéissent sans exception à cette règle géométrique. Exemples : Haine (X-1/Y+5/Z4) ↔ Affection (X+5/Y-1/Z4) ; Invulnérabilité (X+1/Y+7/Z5) ↔ Vulnérabilité (X-7/Y-1/Z5).

Précision phénoménologique pour la strate Z = 7 : Pour les sentiments transcendantaux, la correspondance controlatérale conjugue le croisement géométrique avec une polarité existentielle vécue. Ainsi, l’Abandon (X+3/Y-9/Z7) désigne ici l’acte de s’abandonner en confiance au flux d’une expérience englobante (et non le fait passif d’être abandonné par autrui, qui relève du Rejet en Z = 4), trouvant son exact antagoniste dans la Sidération (X-9/Y+3/Z7), où l’effraction de l’incommensurable fige le sujet au lieu de l’absorber.

### Liste intégrale des correspondances axiales (Z = 2 à Z = 7)

- Strate Z = 2 : Joie (X0/Y+2/Z2) ↔ Tristesse (X0/Y-2/Z2) ; Peur (X-2/Y0/Z2) ↔ Courage (X+2/Y0/Z2).
- Strate Z = 3 : Enthousiasme (X0/Y+4/Z3) ↔ Ennui (X0/Y-4/Z3) ; Crainte (X-4/Y0/Z3) ↔ Curiosité (X+4/Y0/Z3).
- Strate Z = 4 : Exaltation (X0/Y+6/Z4) ↔ Langueur (X0/Y-6/Z4) ; Doute (X-6/Y0/Z4) ↔ Assurance (X+6/Y0/Z4).
- Strate Z = 5 : Puissance (X0/Y+8/Z5) ↔ Impuissance (X0/Y-8/Z5) ; Méfiance (X-8/Y0/Z5) ↔ Confiance (X+8/Y0/Z5).
- Strate Z = 6 : Élan (X0/Y+10/Z6) ↔ Inertie (X0/Y-10/Z6) ; Effacement (X-10/Y0/Z6) ↔ Affirmation (X+10/Y0/Z6).
- Strate Z = 7 : Infini (X0/Y+12/Z7) ↔ Néant (X0/Y-12/Z7) ; Déréliction (X-12/Y0/Z7) ↔ Communion (X+12/Y0/Z7).

### Liste intégrale des correspondances diagonales (Z = 2 à Z = 7)

- Strate Z = 2 : Colère (X-1/Y+1/Z2) ↔ Calme (X+1/Y-1/Z2) ; Désir (X+1/Y+1/Z2) ↔ Dégoût (X-1/Y-1/Z2).
- Strate Z = 3 : Exaspération (X-2/Y+2/Z3) ↔ Détente (X+2/Y-2/Z3) ; Attrait (X+2/Y+2/Z3) ↔ Retrait (X-2/Y-2/Z3).
- Strate Z = 4 : Frustration (X-3/Y+3/Z4) ↔ Acceptation (X+3/Y-3/Z4) ; Estime (X+3/Y+3/Z4) ↔ Rejet (X-3/Y-3/Z4).
- Strate Z = 5 : Insatisfaction (X-4/Y+4/Z5) ↔ Satisfaction (X+4/Y-4/Z5) ; Intérêt (X+4/Y+4/Z5) ↔ Désintérêt (X-4/Y-4/Z5).
- Strate Z = 6 : Tourment (X-5/Y+5/Z6) ↔ Ataraxie (X+5/Y-5/Z6) ; Triomphe (X+5/Y+5/Z6) ↔ Abattement (X-5/Y-5/Z6).
- Strate Z = 7 : Rage (X-6/Y+6/Z7) ↔ Impassibilité (X+6/Y-6/Z7) ; Sublimation (X+6/Y+6/Z7) ↔ Dissolution (X-6/Y-6/Z7).

### Liste intégrale des 60 paires de correspondances controlatérales (Z = 3 à Z = 7)

- Strate Z = 3 (4 paires) : Consternation (X-1/Y+3/Z3) ↔ Émerveillement (X+3/Y-1/Z3) ; Euphorie (X+1/Y+3/Z3) ↔ Effroi (X-3/Y-1/Z3) ; Soulagement (X+1/Y-3/Z3) ↔ Panique (X-3/Y+1/Z3) ; Chagrin (X-1/Y-3/Z3) ↔ Aplomb (X+3/Y+1/Z3).
- Strate Z = 4 (8 paires) : Envie (X-2/Y+4/Z4) ↔ Admiration (X+4/Y-2/Z4) ; Haine (X-1/Y+5/Z4) ↔ Affection (X+5/Y-1/Z4) ; Amour (X+1/Y+5/Z4) ↔ Mépris (X-5/Y-1/Z4) ; Ferveur (X+2/Y+4/Z4) ↔ Défiance (X-4/Y-2/Z4) ; Sérénité (X+2/Y-4/Z4) ↔ Anxiété (X-4/Y+2/Z4) ; Plénitude (X+1/Y-5/Z4) ↔ Manque (X-5/Y+1/Z4) ; Honte (X-2/Y-4/Z4) ↔ Fierté (X+4/Y+2/Z4) ; Vide (X-1/Y-5/Z4) ↔ Épanouissement (X+5/Y+1/Z4).
- Strate Z = 5 (12 paires) : Invulnérabilité (X+1/Y+7/Z5) ↔ Vulnérabilité (X-7/Y-1/Z5) ; Attachement (X+2/Y+6/Z5) ↔ Détachement (X-6/Y-2/Z5) ; Engagement (X+3/Y+5/Z5) ↔ Désengagement (X-5/Y-3/Z5) ; Désenchantement (X-2/Y+6/Z5) ↔ Enchantement (X+6/Y-2/Z5) ; Intolérance (X-3/Y+5/Z5) ↔ Tolérance (X+5/Y-3/Z5) ; Injustice (X-1/Y+7/Z5) ↔ Justice (X+7/Y-1/Z5) ; Quiétude (X+3/Y-5/Z5) ↔ Inquiétude (X-5/Y+3/Z5) ; Sécurité (X+2/Y-6/Z5) ↔ Insécurité (X-6/Y+2/Z5) ; Patience (X+1/Y-7/Z5) ↔ Impatience (X-7/Y+1/Z5) ; Pessimisme (X-2/Y-6/Z5) ↔ Optimisme (X+6/Y+2/Z5) ; Fermeture (X-3/Y-5/Z5) ↔ Ouverture (X+5/Y+3/Z5) ; Désespoir (X-1/Y-7/Z5) ↔ Espoir (X+7/Y+1/Z5).
- Strate Z = 6 (16 paires) : Ardeur (X+3/Y+7/Z6) ↔ Écrasement (X-7/Y-3/Z6) ; Béatitude (X+3/Y-7/Z6) ↔ Affolement (X-7/Y+3/Z6) ; Angoisse (X-3/Y+7/Z6) ↔ Limpidité (X+7/Y-3/Z6) ; Accablement (X-3/Y-7/Z6) ↔ Liesse (X+7/Y+3/Z6) ; Allégresse (X+4/Y+6/Z6) ↔ Amertume (X-6/Y-4/Z6) ; Apaisement (X+4/Y-6/Z6) ↔ Irritation (X-6/Y+4/Z6) ; Fureur (X-4/Y+6/Z6) ↔ Placidité (X+6/Y-4/Z6) ; Morosité (X-4/Y-6/Z6) ↔ Entrain (X+6/Y+4/Z6) ; Fougue (X+2/Y+8/Z6) ↔ Anéantissement (X-8/Y-2/Z6) ; Contemplation (X+2/Y-8/Z6) ↔ Fébrilité (X-8/Y+2/Z6) ; Frénésie (X-2/Y+8/Z6) ↔ Équanimité (X+8/Y-2/Z6) ; Prostration (X-2/Y-8/Z6) ↔ Extase (X+8/Y+2/Z6) ; Jubilation (X+1/Y+9/Z6) ↔ Lassitude (X-9/Y-1/Z6) ; Félicité (X+1/Y-9/Z6) ↔ Désarroi (X-9/Y+1/Z6) ; Terreur (X-1/Y+9/Z6) ↔ Harmonie (X+9/Y-1/Z6) ; Désolation (X-1/Y-9/Z6) ↔ Exultation (X+9/Y+1/Z6).
- Strate Z = 7 (20 paires) : Transcendance (X+2/Y+10/Z7) ↔ Isolement (X-10/Y-2/Z7) ; Nirvana (X+2/Y-10/Z7) ↔ Hantise (X-10/Y+2/Z7) ; Déchirement (X-2/Y+10/Z7) ↔ Recueillement (X+10/Y-2/Z7) ; Perdition (X-2/Y-10/Z7) ↔ Éblouissement (X+10/Y+2/Z7) ; Exubérance (X+4/Y+8/Z7) ↔ Mélancolie (X-8/Y-4/Z7) ; Paix (X+4/Y-8/Z7) ↔ Affliction (X-8/Y+4/Z7) ; Horreur (X-4/Y+8/Z7) ↔ Contentement (X+8/Y-4/Z7) ; Oppression (X-4/Y-8/Z7) ↔ Rayonnement (X+8/Y+4/Z7) ; Ravissement (X+11/Y+1/Z7) ↔ Abîme (X-1/Y-11/Z7) ; Épiphanie (X+11/Y-1/Z7) ↔ Vertige (X-1/Y+11/Z7) ; Précarité (X-11/Y+1/Z7) ↔ Pérennité (X+1/Y-11/Z7) ; Déchéance (X-11/Y-1/Z7) ↔ Renaissance (X+1/Y+11/Z7) ; Élévation (X+3/Y+9/Z7) ↔ Engloutissement (X-9/Y-3/Z7) ; Abandon (X+3/Y-9/Z7) ↔ Sidération (X-9/Y+3/Z7) ; Détresse (X-3/Y+9/Z7) ↔ Lucidité (X+9/Y-3/Z7) ; Damnation (X-3/Y-9/Z7) ↔ Louange (X+9/Y+3/Z7) ; Enivrement (X+5/Y+7/Z7) ↔ Pétrification (X-7/Y-5/Z7) ; Silence (X+5/Y-7/Z7) ↔ Tumulte (X-7/Y+5/Z7) ; Révolte (X-5/Y+7/Z7) ↔ Consentement (X+7/Y-5/Z7) ; Résignation (X-5/Y-7/Z7) ↔ Effusion (X+7/Y+5/Z7).

## 5. Tableau récapitulatif des coordonnées et effectifs (Z = 0 à Z = 7)

| Strate (Z) | Élément / Opérateur ou Couronne | Coordonnées / Rayon du losange | Effectif | Règle structurelle / Description |
|---|---|---|---:|---|
| Z = 0 | Point de Veille (origine) | (0, 0, 0) — Rayon 0 | 1 | Origine structurale et équilibre basal |
| Z = 1 | Surprise (opérateur ascendant) | (0, 0, 1) — Rayon 0 | 1 | Opérateur de rupture et de saillance perceptive |
| Z = 2 | Anticipation (opérateur central) | (0, 0, 2) | 1 | Opérateur descendant d’orientation |
| | Couronne 2 : Affects primaires et prototypes | Somme des déplacements X et Y = 2 | 8 | 4 positions axiales + 4 positions diagonales |
| Z = 3 | Émoi (opérateur central) | (0, 0, 3) | 1 | Opérateur central de la strate réactive |
| | Couronne 3 : Émotions réactives | Somme des déplacements X et Y = 4 | 16 | 4 axiales + 8 latérales + 4 diagonales |
| Z = 4 | Réserve (opérateur central) | (0, 0, 4) | 1 | Opérateur central de la strate réflexive |
| | Couronne 4 : Sentiments réflexifs et relationnels | Somme des déplacements X et Y = 6 | 24 | 4 axiales + 16 latérales + 4 diagonales |
| Z = 5 | Recul (opérateur central) | (0, 0, 5) | 1 | Opérateur central des dispositions durables |
| | Couronne 5 : Dispositions, orientations et humeurs | Somme des déplacements X et Y = 8 | 32 | 4 axiales + 24 latérales + 4 diagonales |
| Z = 6 | Saisissement (opérateur central) | (0, 0, 6) | 1 | Opérateur central des identités affectives |
| | Couronne 6 : Identités affectives | Somme des déplacements X et Y = 10 | 40 | 4 axiales + 32 latérales + 4 diagonales |
| Z = 7 | Suspension (opérateur central) | (0, 0, 7) | 1 | Opérateur central des sentiments transcendantaux |
| | Couronne 7 : Sentiments transcendantaux | Somme des déplacements X et Y = 12 | 48 | 4 axiales + 40 latérales + 4 diagonales |
| **Total Centres** | Point de Veille + 7 Opérateurs centraux | Positions (0, 0, Z) de Z = 0 à Z = 7 | **8** | Axe central d’amorçage et de réorientation |
| **Total Couronnes** | Positions affectives périphériques | Couronnes Z = 2 à Z = 7 | **168** | 8 + 16 + 24 + 32 + 40 + 48 positions |
| **TOTAL MODÈLE** | Ensemble de l’architecture affective (Z = 0 à 7) | 8 centres + 168 positions | **176** | |

---

## Certification formelle et disponibilité du code source

L’architecture mathématique et lexicale présentée dans cette annexe est intégralement formalisée et vérifiée mécaniquement sous l’assistant de preuve **Lean 4** (version 4.35.0, Lake 5.0.0 ; de Moura & Ullrich, 2021) au sein du dépôt en accès libre sous double licence GNU AGPLv3 (code source et preuves formelles) et CC BY-NC-SA 4.0 (architecture théorique et taxonomie) (https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT, version v1.0.1 ; archivage pérenne Zenodo : https://doi.org/10.5281/zenodo.23833938 ; enregistrement de droit d’auteur OPIC n° 1233199). Le code source se structure en cinq modules formels (`PredictiveEngine`, `CoreAffect`, `AffectiveMatrix`, `AffectiveTaxonomy`, `Lexicon176`) complétés par une suite d’audit automatisée (`AuditTests`).

L’audit axiomatique (`#print axioms`) certifie 17 théorèmes principaux avec zéro déclaration inachevée (`sorry` ou `admit`) et zéro axiome *ad hoc* :

1. **Huit théorèmes purement constructifs** (démontrés par réduction computationnelle directe dans le noyau logique, sans dépendre d’aucun axiome externe) : l’involutivité de la polarité prédictive (`Polarity.invert_involutive`), la partition stricte des régimes de couplage (`coupling_regime_partition`), la conservation budgétaire de la première couronne (`z2_budget_conservation`), la permutation controlatérale des amplitudes (`contralateral_swaps_amplitudes`), le dénombrement combinatoire des 176 positions (`inventory_176_certified`), ainsi que la cardinalité exacte (`all176Entries_length`), l’unicité géométrique stricte des coordonnées (`all176Entries_unique_points`) et la clôture algébrique par symétrie antagoniste (`all176Entries_closed_under_antagonist`) des 176 entrées du lexique affectif.
2. **Neuf théorèmes structurels** (reposant exclusivement sur les axiomes fondationnels standards de la théorie des types dépendants de Lean : `propext`, `Quot.sound` et `Classical.choice`) : l’induction valide du Noyau par le Moteur (`engine_induces_valid_core_affect`), la réallocation axiale vers diagonale (`axial_to_diagonal_reallocation`), la validité de l’opérateur de dissipation allostatique (`dissipationStep_valid`), la préservation de la validité et l’involutivité de l’opérateur antagoniste (`antagonistPoint_preserves_validity`, `antagonistPoint_involutive`), l’exhaustivité et l’exclusivité mutuelle des groupes taxonomiques (`taxonomy_group_exhaustive`, `taxonomy_group_exclusive`), la validité géométrique L₁ des 176 entrées lexicales (`all176Entries_geometrically_valid`) et la cohérence déductive globale de bout en bout du modèle (`end_to_end_coherence`).
