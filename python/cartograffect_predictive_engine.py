"""
cartograffect_predictive_engine.py
==================================
Moteur prédictif cybernétique en boucle fermée pour le modèle CARTOGRAFFECT®.

Strictement isomorphe à la formalisation Lean 4 (`Cartograffect/PredictiveCircuit.lean`,
`Cartograffect/CoreAffect.lean`, `Cartograffect/AffectiveMatrix.lean`) et fidèle au
circuit continu de la Figure 1 (2 boucles × 3 circuits, 6 opérations de frontière).

Implémente :
  1. L'isomorphisme exact Phi : Omega_II ([A/C]) <-> Omega_I ((X,Y,0)) sous contrainte L1 = 2,
     ainsi que la dualité transposée exacte entre le Croisement I et le Croisement II.
  2. La projection perceptible certifiée Pi_Z : (A,C,Z,pi_A,pi_C,susp) -> (X,Y,Z) conforme
     à la loi des couronnes (Z = 0 Veille, Z = 1 Surprise, Z >= 2 avec R(Z) = 2Z - 2) et
     l'opérateur d'antagonisme exact (axial, diagonal, controlatéral).
  3. Les 6 opérations du circuit computationnel continu :
       - Op. 1 : Sortie interne de l'Interface Subjective (+X / -X / 0 via Anticipation)
       - Op. 2 : Sortie interne de l'Interface Perceptive (+Y / -Y / 0 via Surprise)
       - Op. 3 : Croisement Attentionnel I (perceptible par l'Agent) -> voies réflexive & action
       - Op. 4 : Croisement Attentionnel II (rétroactif sub-personnel) -> 9 canaux A/C et C/A
       - Op. 5 : Entrée externe dans les [États cachés] subjectifs
       - Op. 6 : Entrée externe dans les [États cachés] perceptifs (+ Corps & Environnement)
  4. Le noyau entier exact `construire_noyau_entier` (somme 4*scale^4, miroir de `circuitWeight`),
     la matrice de transition markovienne couplée T (9x9), le spectre exact, le contrôle
     d'ergodicité globale (0 < epsilon < 1) et la simulation du circuit continu fermé.

Dépendances : numpy >= 1.24 (bibliothèque standard Python >= 3.10).
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Tuple
import numpy as np


# =============================================================================
# 1. CONSTANTES TOPOLOGIQUES, BIJECTION L1 ET TRANSPOSITION DES CROISEMENTS
# =============================================================================

# Ordre canonique des modalités sur chaque boucle : (Neutre, Charge/Incertain, Décharge/Certain)
ORDRE_ATTENTE: Tuple[int, int, int] = (0, -1, +1)
ORDRE_CONTROLE: Tuple[int, int, int] = (0, -1, +1)

# Ordre spatial sur les grilles 3x3 du Croisement I et du Croisement II (Figure 1)
ORDRE_GRILLE_A: Tuple[int, int, int] = (0, -1, +1)   # A0, A-, A+
ORDRE_GRILLE_C: Tuple[int, int, int] = (+1, -1, 0)   # C+, C-, C0

LABELS_A: Dict[int, str] = {0: "A0", -1: "A-", +1: "A+"}
LABELS_C: Dict[int, str] = {0: "C0", -1: "C-", +1: "C+"}
GRADIENTS_ENERGETIQUES: Dict[int, str] = {0: "Neutre", -1: "Charge", +1: "Décharge"}


def _valider_modalites(a: int, c: int) -> None:
    if a not in ORDRE_ATTENTE or c not in ORDRE_CONTROLE:
        raise ValueError(f"États invalides : a={a}, c={c}. Attendus dans {{0, -1, +1}}.")


def transduction_l1(a: int, c: int) -> Tuple[int, int, int]:
    """
    Opérateur bijectif Phi(a, c) -> (X, Y, 0) projetant le Croisement II [A/C]
    vers le plan proto-spatial du Croisement I sous conservation L1 = 2 (hors Veille).
    """
    _valider_modalites(a, c)
    if a == 0 and c == 0:
        return (0, 0, 0)
    denom = abs(a) + abs(c)
    x = int((2 * a) / denom)
    y = int((2 * c) / denom)
    return (x, y, 0)


def transduction_l1_inverse(x: int, y: int) -> Tuple[int, int]:
    """
    Opérateur réciproque Phi^{-1}(X, Y) -> (a, c) défini sur l'origine (0, 0)
    et sur tout point entier de norme L1 |X| + |Y| = 2.
    """
    if not ((x == 0 and y == 0) or (abs(x) + abs(y) == 2)):
        raise ValueError(
            f"Coordonnée proto-spatiale invalide ({x}, {y}) : attendu (0, 0) ou |X|+|Y|=2."
        )
    a = 1 if x > 0 else (-1 if x < 0 else 0)
    c = 1 if y > 0 else (-1 if y < 0 else 0)
    return (a, c)


def position_croisement_i(a: int, c: int) -> Tuple[int, int]:
    """Position (ligne, colonne) sur la grille 3x3 du Croisement I (Veille en (0, 2))."""
    _valider_modalites(a, c)
    return (ORDRE_GRILLE_A.index(a), ORDRE_GRILLE_C.index(c))


def position_croisement_ii(a: int, c: int) -> Tuple[int, int]:
    """Position (ligne, colonne) sur la grille 3x3 du Croisement II (transposée exacte de I)."""
    _valider_modalites(a, c)
    return (ORDRE_GRILLE_C.index(c), ORDRE_GRILLE_A.index(a))


def poids_attentionnels_l1(a: int, c: int) -> Tuple[float, float]:
    """
    Partage de la ressource attentionnelle (w_X, w_Y) imposé par |X|+|Y|=2 :
      - État pur (un seul axe actif) : poids 1.0 sur l'axe actif.
      - État mixte (deux axes actifs) : poids 0.5 sur chaque axe (goulot attentionnel).
      - Axe neutre (0) : poids 1.0.
    """
    x, y, _ = transduction_l1(a, c)
    w_x = (abs(x) / 2.0) if a != 0 else 1.0
    w_y = (abs(y) / 2.0) if c != 0 else 1.0
    return (w_x, w_y)


def potentiel_lyapunov(a: int, c: int) -> int:
    """
    Fonction de Lyapunov discrète V(a, c) mesurant l'écart résiduel :
      v(Neutre=0) = 0, v(Décharge=+1) = 1, v(Charge=-1) = 2.
    V(s) = 0 ssi s = Veille (0, 0).
    """
    _valider_modalites(a, c)
    energie = {0: 0, +1: 1, -1: 2}
    return energie[a] + energie[c]


def classifier_coherence(a: int, c: int) -> str:
    """Typologie de cohérence entre milieu interne (Attente A) et milieu externe (Contrôle C)."""
    _valider_modalites(a, c)
    if a == 0 and c == 0:
        return "equilibre_homeostatique"
    if a == 0 or c == 0:
        return "unilateral_axial"
    if a == +1 and c == +1:
        return "decharge_congruente"
    if a == -1 and c == -1:
        return "impasse_double_charge"
    return "tension_compensatoire"


@dataclass(frozen=True)
class CanalRetourSubjectif:
    """Canal sub-personnel `A/C` issu du Croisement II vers l'Interface Subjective."""
    regime_a: str
    contexte_c: int
    etiquette: str


@dataclass(frozen=True)
class CanalRetourPerceptif:
    """Canal sub-personnel `C/A` issu du Croisement II vers l'Interface Perceptive."""
    regime_c: str
    contexte_a: int
    etiquette: str


def canaux_retour_croisement_ii(
    a: int,
    c: int,
) -> Tuple[CanalRetourSubjectif, CanalRetourPerceptif]:
    """Produit les deux canaux injectifs `(A/C, C/A)` vers les interfaces cachées."""
    _valider_modalites(a, c)
    ch_subj = CanalRetourSubjectif(
        regime_a=GRADIENTS_ENERGETIQUES[a],
        contexte_c=c,
        etiquette=f"{LABELS_A[a]}/{LABELS_C[c]}",
    )
    ch_perc = CanalRetourPerceptif(
        regime_c=GRADIENTS_ENERGETIQUES[c],
        contexte_a=a,
        etiquette=f"{LABELS_C[c]}/{LABELS_A[a]}",
    )
    return (ch_subj, ch_perc)


# =============================================================================
# 2. GÉOMÉTRIE CERTIFIÉE DU NOYAU AFFECTIF (LOI DES COURONNES & ANTAGONISME)
# =============================================================================

def rayon_couronne(z: int) -> int:
    """Rayon R(Z) de la couronne à la strate Z : 0 pour Z < 2, 2Z - 2 pour Z >= 2."""
    if z < 0:
        raise ValueError(f"La strate Z doit être >= 0 (reçu : {z}).")
    return 0 if z < 2 else 2 * z - 2


def est_valide_noyau_affectif(x: int, y: int, z: int) -> bool:
    """Prédicat exact `isValidCoreAffect` de `Cartograffect/CoreAffect.lean`."""
    if z < 0:
        return False
    return (x == 0 and y == 0) or (z >= 2 and abs(x) + abs(y) == 2 * z - 2)


def repartir_rayon(d: int, pi_a: int, pi_c: int) -> Tuple[int, int]:
    """
    Miroir exact de `CoreAffect.apportionRay` : répartit R(d+2) = 2d + 2 au prorata
    de `(pi_a, pi_c)` lorsque les deux gradients A et C sont engagés.
    """
    if d < 0 or pi_a < 0 or pi_c < 0:
        raise ValueError(f"Arguments négatifs invalides : d={d}, pi_a={pi_a}, pi_c={pi_c}.")
    r = 2 * d + 2
    if pi_a == pi_c:
        return (d + 1, d + 1)
    total = pi_a + pi_c
    if pi_a < pi_c:
        raw = (2 * r * pi_a + total) // (2 * total)
        ax = max(1, min(d + 1, raw))
        return (ax, r - ax)
    raw = (2 * r * pi_c + total) // (2 * total)
    ay = max(1, min(d + 1, raw))
    return (r - ay, ay)


def projeter_noyau_affectif(
    a: int,
    c: int,
    z: int,
    pi_a: int = 1,
    pi_c: int = 1,
    suspension_descendante: bool = False,
) -> Tuple[int, int, int]:
    """
    Projection perceptible certifiée Pi_Z : `(a, c, z) -> (X, Y, Z)` (miroir exact de
    `PredictiveCircuit.projectPerceptible`), garantissant `est_valide_noyau_affectif`.
    """
    _valider_modalites(a, c)
    if z < 0 or pi_a < 0 or pi_c < 0:
        raise ValueError(f"Paramètres géométriques invalides : z={z}, pi_a={pi_a}, pi_c={pi_c}.")
    if a == 0 and c == 0:
        return (0, 0, z) if (suspension_descendante and z >= 2) else (0, 0, 0)
    if z == 0:
        return (0, 0, 0)
    if z == 1:
        return (0, 0, 1)
    d = z - 2
    r = 2 * d + 2
    if a != 0 and c == 0:
        return (a * r, 0, z)
    if a == 0 and c != 0:
        return (0, c * r, z)
    ax, ay = repartir_rayon(d, pi_a, pi_c)
    return (a * ax, c * ay, z)


def antagoniste_noyau(x: int, y: int, z: int) -> Tuple[int, int, int]:
    """
    Miroir exact de `AffectiveMatrix.antagonistPoint` :
      - Axial ou diagonal : symétrie centrale `(-X, -Y, Z)`.
      - Latéral (`|X| != |Y|`, `X != 0`, `Y != 0`) : réflexion controlatérale.
    """
    if x == 0 or y == 0 or abs(x) == abs(y):
        return (-x, -y, z)
    if (x > 0 and y < 0) or (x < 0 and y > 0):
        return (y, x, z)
    return (-y, -x, z)


@dataclass(frozen=True)
class NoeudConfiguration:
    """Représentation canonique d'une des 9 configurations du moteur prédictif."""
    index: int
    code: str
    a: int
    c: int
    couplage_croisement_ii: str
    coord_proto_spatiale: Tuple[int, int, int]
    coord_couronne_z2: Tuple[int, int, int]
    pos_croisement_i: Tuple[int, int]
    pos_croisement_ii: Tuple[int, int]
    norme_l1: int
    poids_x: float
    poids_y: float
    energie_lyapunov: int
    gradient_a: str
    gradient_c: str
    coherence_interne_externe: str
    statut_topologique: str


def _construire_catalogue_configurations() -> Tuple[NoeudConfiguration, ...]:
    statuts = {
        (0, 0): "Veille homéostatique (Point fixe)",
        (0, -1): "Charge pragmatique pure",
        (0, +1): "Décharge pragmatique pure",
        (-1, 0): "Charge épistémique pure",
        (-1, -1): "Double Charge (Impasse cognitive/motrice)",
        (-1, +1): "Charge épistémique / Décharge pragmatique",
        (+1, 0): "Décharge épistémique pure",
        (+1, -1): "Décharge épistémique / Charge pragmatique",
        (+1, +1): "Double Décharge (Maîtrise optimale)",
    }
    catalogue: List[NoeudConfiguration] = []
    idx = 0
    for a in ORDRE_ATTENTE:
        for c in ORDRE_CONTROLE:
            x0, y0, z0 = transduction_l1(a, c)
            wx, wy = poids_attentionnels_l1(a, c)
            coord_z2 = projeter_noyau_affectif(a, c, 2)
            catalogue.append(
                NoeudConfiguration(
                    index=idx,
                    code=f"s{idx + 1}",
                    a=a,
                    c=c,
                    couplage_croisement_ii=f"[{LABELS_A[a]}/{LABELS_C[c]}]",
                    coord_proto_spatiale=(x0, y0, z0),
                    coord_couronne_z2=coord_z2,
                    pos_croisement_i=position_croisement_i(a, c),
                    pos_croisement_ii=position_croisement_ii(a, c),
                    norme_l1=abs(x0) + abs(y0),
                    poids_x=wx,
                    poids_y=wy,
                    energie_lyapunov=potentiel_lyapunov(a, c),
                    gradient_a=GRADIENTS_ENERGETIQUES[a],
                    gradient_c=GRADIENTS_ENERGETIQUES[c],
                    coherence_interne_externe=classifier_coherence(a, c),
                    statut_topologique=statuts[(a, c)],
                )
            )
            idx += 1
    return tuple(catalogue)


CATALOGUE_ETATS: Tuple[NoeudConfiguration, ...] = _construire_catalogue_configurations()
INDEX_PAR_AC: Dict[Tuple[int, int], int] = {
    (n.a, n.c): n.index for n in CATALOGUE_ETATS
}
INDEX_PAR_XY: Dict[Tuple[int, int], int] = {
    (n.coord_proto_spatiale[0], n.coord_proto_spatiale[1]): n.index for n in CATALOGUE_ETATS
}


# =============================================================================
# 3. PARAMÈTRES DES INTERFACES CACHÉES ET PROFILS DYNAMIQUES
# =============================================================================

@dataclass(frozen=True)
class ParametresMoteur:
    """
    Paramètres structurels des boucles interne/externe et des quatre transitions d'interface :
      - rho, kappa         : Révisabilité subjective (A- -> A+) et contrôlabilité perçue (C- -> C+)
      - delta_a, delta_c   : Taux d'extinction passive (- -> 0, sans passage par la Décharge +)
      - gamma_a, gamma_c   : Taux de désengagement homéostatique (+ -> 0)
      - epsilon            : Volatilité / Surprise exogène issue de Corps & Environnement
      - q_pos_a, q_pos_c   : Propension directe vers la décharge (0 -> +) sous perturbation
      - chi                : Contagion croisée P2 (majore eps via eps + chi*(1-eps) sur Charge -1)
      - beta               : Couplage signé A/C et C/A sur la boucle courte [0, 0.5]
      - feedback_action    : Atténuation afférente par la boucle comportementale C+
      - feedback_reflexive : Amplification de révisabilité par la voie réflexive en profondeur Z
    """
    rho: float = 0.75
    kappa: float = 0.75
    delta_a: float = 0.0
    delta_c: float = 0.0
    gamma_a: float = 0.60
    gamma_c: float = 0.60
    epsilon: float = 0.0
    q_pos_a: float = 0.35
    q_pos_c: float = 0.35
    chi: float = 0.25
    beta: float = 0.0
    feedback_action: float = 0.0
    feedback_reflexive: float = 0.0

    def __post_init__(self) -> None:
        for nom in (
            "rho", "kappa", "delta_a", "delta_c", "gamma_a", "gamma_c", "epsilon",
            "q_pos_a", "q_pos_c", "chi", "feedback_action", "feedback_reflexive",
        ):
            val = getattr(self, nom)
            if not (0.0 <= val <= 1.0):
                raise ValueError(f"Le paramètre '{nom}' doit appartenir à [0, 1] (reçu : {val}).")
        if self.rho + self.delta_a > 1.0 + 1e-12:
            raise ValueError(
                f"Contrainte stochastique violée : rho + delta_a = {self.rho + self.delta_a:.4f} > 1."
            )
        if self.kappa + self.delta_c > 1.0 + 1e-12:
            raise ValueError(
                f"Contrainte stochastique violée : kappa + delta_c = {self.kappa + self.delta_c:.4f} > 1."
            )
        if not (0.0 <= self.beta <= 0.5):
            raise ValueError(f"Le paramètre 'beta' doit appartenir à [0, 0.5] (reçu : {self.beta}).")

    # --- Profils prédéfinis ---
    @classmethod
    def homeostasique(cls, epsilon: float = 0.05) -> ParametresMoteur:
        """Agent flexible en mode circulaire complet (couplage croisé signé actif)."""
        return cls(
            rho=0.80, kappa=0.80, delta_a=0.0, delta_c=0.0,
            gamma_a=0.70, gamma_c=0.70, epsilon=epsilon,
            q_pos_a=0.35, q_pos_c=0.35, chi=0.25, beta=0.20,
        )

    @classmethod
    def canonique_libre(cls, p: float = 0.8) -> ParametresMoteur:
        """Régime libre canonique symétrique (V décroissant, tau(s) = V(s)/p exact)."""
        return cls(
            rho=p, kappa=p, delta_a=0.0, delta_c=0.0,
            gamma_a=p, gamma_c=p, epsilon=0.0,
            q_pos_a=0.0, q_pos_c=0.0, chi=0.0, beta=0.0,
        )

    @classmethod
    def canonique_perturbe(cls, epsilon: float = 0.15) -> ParametresMoteur:
        """Régime canonique sans modulation croisée signée (isomorphe au noyau Lean de base)."""
        return cls(
            rho=0.80, kappa=0.80, delta_a=0.0, delta_c=0.0,
            gamma_a=0.70, gamma_c=0.70, epsilon=epsilon,
            q_pos_a=0.0, q_pos_c=0.0, chi=0.0, beta=0.0,
        )

    @classmethod
    def extinction_passive(cls, delta: float = 0.40, epsilon: float = 0.15) -> ParametresMoteur:
        """Axe (i) : habituation / pseudo-veille instable (rho=kappa=0, extinction passive delta > 0)."""
        return cls(
            rho=0.0, kappa=0.0, delta_a=delta, delta_c=delta,
            gamma_a=0.60, gamma_c=0.60, epsilon=epsilon,
            q_pos_a=0.0, q_pos_c=0.0, chi=0.0, beta=0.0,
        )

    @classmethod
    def clivage_sous_couplage(cls, epsilon: float = 0.15) -> ParametresMoteur:
        """Axe (iii) : sous-couplage P1 sans P2 (chi = 0, dissociation Attente/Contrôle)."""
        return cls(
            rho=0.80, kappa=0.80, delta_a=0.0, delta_c=0.0,
            gamma_a=0.70, gamma_c=0.70, epsilon=epsilon,
            q_pos_a=0.35, q_pos_c=0.35, chi=0.0, beta=0.0,
        )

    @classmethod
    def contagion_sur_couplage(cls, epsilon: float = 0.15, chi: float = 0.95) -> ParametresMoteur:
        """Axe (iii) : sur-couplage P2 (chi élevé -> avalanche vers Double Charge (-1, -1, 2))."""
        return cls(
            rho=0.60, kappa=0.60, delta_a=0.0, delta_c=0.0,
            gamma_a=0.70, gamma_c=0.70, epsilon=epsilon,
            q_pos_a=0.0, q_pos_c=0.0, chi=chi, beta=0.0,
        )

    @classmethod
    def surcharge_allostatique(cls, epsilon: float = 0.90) -> ParametresMoteur:
        """Axe (iii) : saturation exogène chronique (epsilon >> rho, kappa -> pi*_Veille -> 0)."""
        return cls(
            rho=0.25, kappa=0.25, delta_a=0.0, delta_c=0.0,
            gamma_a=0.60, gamma_c=0.60, epsilon=epsilon,
            q_pos_a=0.15, q_pos_c=0.15, chi=0.25, beta=0.0,
        )

    @classmethod
    def rigidite_epistemique(cls, epsilon: float = 0.0, chi: float = 0.0) -> ParametresMoteur:
        """Blocage de l'Interface Subjective (rho = delta_a = 0) : piégeage en Charge épistémique."""
        return cls(
            rho=0.0, kappa=0.75, delta_a=0.0, delta_c=0.0,
            gamma_a=0.60, gamma_c=0.60, epsilon=epsilon,
            q_pos_a=0.35, q_pos_c=0.35, chi=chi, beta=0.0,
        )

    @classmethod
    def impuissance_pragmatique(cls, epsilon: float = 0.0, chi: float = 0.0) -> ParametresMoteur:
        """Blocage de l'Interface Perceptive (kappa = delta_c = 0) : piégeage en Charge motrice."""
        return cls(
            rho=0.75, kappa=0.0, delta_a=0.0, delta_c=0.0,
            gamma_a=0.60, gamma_c=0.60, epsilon=epsilon,
            q_pos_a=0.35, q_pos_c=0.35, chi=chi, beta=0.0,
        )

    @classmethod
    def impasse_double_charge(cls, epsilon: float = 0.0, chi: float = 0.0) -> ParametresMoteur:
        """Double blocage (rho = kappa = 0, delta = 0) : piégeage en Double Charge (-1, -1, 2) [Dégoût]."""
        return cls(
            rho=0.0, kappa=0.0, delta_a=0.0, delta_c=0.0,
            gamma_a=0.60, gamma_c=0.60, epsilon=epsilon,
            q_pos_a=0.35, q_pos_c=0.35, chi=chi, beta=0.0,
        )

    @classmethod
    def perseveration(cls, epsilon: float = 0.0, chi: float = 0.0) -> ParametresMoteur:
        """Incapacité de désengagement (gamma_a = gamma_c = 0) : blocage en Décharge."""
        return cls(
            rho=0.80, kappa=0.80, delta_a=0.0, delta_c=0.0,
            gamma_a=0.0, gamma_c=0.0, epsilon=epsilon,
            q_pos_a=0.35, q_pos_c=0.35, chi=chi, beta=0.0,
        )


# =============================================================================
# 4. ANALYSE SPECTRALE & NOYAU MARKOVIEN COUPLÉ (MOTEUR PRÉDICTIF)
# =============================================================================

@dataclass
class RapportAnalytique:
    """Résultat complet de l'analyse spectrale et ergodique de la matrice T (9x9)."""
    parametres: ParametresMoteur
    gain_precision: float
    niveau_z: int
    goulot_l1_sature: bool
    matrice_T: np.ndarray
    valeurs_propres: np.ndarray
    rayon_spectral_transitoire: Optional[float]
    rang_systeme_stationnaire: Optional[int]
    nb_eigs_unitaires: int
    etats_absorbants: List[str]
    convergence_veille_garantie: bool
    ergodique_global: bool
    diagnostic_regime: str
    temps_absorption_moyens: Optional[Dict[str, float]]
    distribution_stationnaire: Optional[Dict[str, float]]
    indice_coherence_stationnaire: Optional[float]


class MoteurPredictifCartograffect:
    """
    Moteur markovien couplé sur les 9 configurations du circuit continu,
    strictement aligné avec `Cartograffect/PredictiveCircuit.lean`.
    """

    def __init__(
        self,
        parametres: Optional[ParametresMoteur] = None,
        seed: Optional[int] = None,
    ) -> None:
        self.params: ParametresMoteur = parametres or ParametresMoteur.homeostasique()
        self._rng: np.random.Generator = np.random.default_rng(seed)

    @staticmethod
    def _noyau_marginal(
        plasticite: float,
        extinction_passive: float,
        desengagement: float,
        eps_neutre: float,
        eps_decharge: float,
        q_pos: float,
    ) -> np.ndarray:
        """
        Matrice de transition élémentaire 3x3 dans la base (0, -1, +1) :
            ligne 0 (Neutre)   : [1 - eps_0,         eps_0 * (1 - q_pos), eps_0 * q_pos]
            ligne 1 (Charge)   : [delta,             1 - p - delta,       p]
            ligne 2 (Décharge) : [(1 - eps_2) * g,   eps_2,               (1 - eps_2) * (1 - g)]
        """
        p = float(np.clip(plasticite, 0.0, 1.0))
        d = float(np.clip(extinction_passive, 0.0, max(0.0, 1.0 - p)))
        g = float(np.clip(desengagement, 0.0, 1.0))
        e0 = float(np.clip(eps_neutre, 0.0, 1.0))
        e2 = float(np.clip(eps_decharge, 0.0, 1.0))
        q = float(np.clip(q_pos, 0.0, 1.0))
        return np.array(
            [
                [1.0 - e0, e0 * (1.0 - q), e0 * q],
                [d, 1.0 - p - d, p],
                [(1.0 - e2) * g, e2, (1.0 - e2) * (1.0 - g)],
            ],
            dtype=np.float64,
        )

    def goulot_l1_est_sature(self, gain_precision: float = 1.0) -> bool:
        """Indique si `gain_precision` sature les poids mixtes (w=0.5) à 1.0, annulant le goulot L1."""
        p = self.params
        return any(
            val > 0.0 and val * 0.5 * gain_precision >= 1.0
            for val in (p.rho, p.kappa, p.gamma_a, p.gamma_c)
        )

    def construire_noyau_entier(self, scale: int = 100) -> np.ndarray:
        """
        Construit la matrice entière exacte W (9x9) miroir de `PredictiveCircuit.circuitWeight`
        (chaque ligne somme exactement à `4 * scale^6`). Nécessite `beta = feedback_* = 0`.
        """
        if scale <= 0:
            raise ValueError("Le facteur entier `scale` doit être strictement positif.")
        p = self.params
        rho_i = round(p.rho * scale)
        kap_i = round(p.kappa * scale)
        da_i = min(scale - rho_i, round(p.delta_a * scale))
        dc_i = min(scale - kap_i, round(p.delta_c * scale))
        ga_i = round(p.gamma_a * scale)
        gc_i = round(p.gamma_c * scale)
        eps_i = round(p.epsilon * scale)
        qa_i = round(p.q_pos_a * scale)
        qc_i = round(p.q_pos_c * scale)
        chi_i = round(p.chi * scale)

        def _mw(
            rate: int,
            delta: int,
            deseng: int,
            q_pos: int,
            other_charged: bool,
            w2: int,
            src: int,
            dst: int,
        ) -> int:
            e2 = (scale * eps_i + chi_i * (scale - eps_i)) if other_charged else (scale * eps_i)
            m2 = scale * scale
            if src == 0:
                if dst == 0:
                    return 2 * scale * (m2 - e2)
                if dst == -1:
                    return 2 * e2 * (scale - q_pos)
                return 2 * e2 * q_pos
            if src == -1:
                if dst == 0:
                    return m2 * (2 * delta)
                if dst == -1:
                    return m2 * (2 * scale - w2 * rate - 2 * delta)
                return m2 * (w2 * rate)
            # src == +1
            if dst == 0:
                return (m2 - e2) * (w2 * deseng)
            if dst == -1:
                return 2 * scale * e2
            return (m2 - e2) * (2 * scale - w2 * deseng)

        dtype = np.int64 if scale <= 1000 else object
        W = np.zeros((9, 9), dtype=dtype)
        for src_n in CATALOGUE_ETATS:
            w2_a = 2 if src_n.a == 0 else abs(src_n.coord_proto_spatiale[0])
            w2_c = 2 if src_n.c == 0 else abs(src_n.coord_proto_spatiale[1])
            other_charged_a = src_n.c == -1
            other_charged_c = src_n.a == -1
            for dst_n in CATALOGUE_ETATS:
                mw_a = _mw(rho_i, da_i, ga_i, qa_i, other_charged_a, w2_a, src_n.a, dst_n.a)
                mw_c = _mw(kap_i, dc_i, gc_i, qc_i, other_charged_c, w2_c, src_n.c, dst_n.c)
                W[src_n.index, dst_n.index] = mw_a * mw_c
        return W

    def construire_matrice_transition(
        self,
        gain_precision: float = 1.0,
        niveau_z: int = 2,
    ) -> np.ndarray:
        """
        Construit la matrice stochastique globale T (9x9) du circuit continu :
          - P1 : contrainte allocative L1 via `(w_X, w_Y)` ;
          - P2 : contagion croisée exacte `eps_eff = eps + chi*(1-eps)*I(Charge complementaire)` ;
          - Extinction passive `(delta_a, delta_c)` vs résolution active `(rho, kappa)`.
        """
        if gain_precision <= 0.0:
            raise ValueError("Le gain_precision psi doit être strictement positif.")
        if niveau_z < 0:
            raise ValueError("Le niveau_z doit être un entier positif ou nul.")

        T = np.zeros((9, 9), dtype=np.float64)
        p = self.params
        mod_reflexif = 1.0 + p.feedback_reflexive * (max(0, niveau_z - 2) / 5.0)

        for noeud in CATALOGUE_ETATS:
            mod_croise_a = 1.0 + p.beta * noeud.c
            mod_croise_c = 1.0 + p.beta * noeud.a

            rho_eff = min(1.0, p.rho * noeud.poids_x * gain_precision * mod_croise_a * mod_reflexif)
            ga_eff = min(1.0, p.gamma_a * noeud.poids_x * gain_precision)
            kap_eff = min(1.0, p.kappa * noeud.poids_y * gain_precision * mod_croise_c)
            gc_eff = min(1.0, p.gamma_c * noeud.poids_y * gain_precision)

            # Axe (ii) — Principe P2 : contagion croisée portée exclusivement par une Charge (-1)
            e_eff_a = p.epsilon + p.chi * (1.0 - p.epsilon) if noeud.c == -1 else p.epsilon
            e_eff_c_base = p.epsilon + p.chi * (1.0 - p.epsilon) if noeud.a == -1 else p.epsilon
            mod_action_eps = max(0.0, 1.0 - p.feedback_action) if noeud.c == +1 else 1.0
            e_eff_c = min(1.0, e_eff_c_base * mod_action_eps)

            P_A = self._noyau_marginal(rho_eff, p.delta_a, ga_eff, e_eff_a, e_eff_a, p.q_pos_a)
            P_C = self._noyau_marginal(kap_eff, p.delta_c, gc_eff, e_eff_c, e_eff_c, p.q_pos_c)

            idx_a = ORDRE_ATTENTE.index(noeud.a)
            idx_c = ORDRE_CONTROLE.index(noeud.c)
            T[noeud.index, :] = np.outer(P_A[idx_a], P_C[idx_c]).ravel()

        return T

    def analyser_dynamique(
        self,
        gain_precision: float = 1.0,
        niveau_z: int = 2,
    ) -> RapportAnalytique:
        """
        Analyse spectrale et ergodique rigoureuse de T (9x9) :
          - Distinction stricte `epsilon == 0.0` vs `0 < epsilon < 1` vs `epsilon == 1.0`
          - Distinction résolution active (`rho, kappa > 0`) vs extinction passive (`delta > 0, rho/kappa = 0`)
          - Contrôle du rang linéaire et des valeurs propres unitaires pour certifier l'ergodicité
          - Temps moyens d'absorption vers Veille via N = (I_8 - Q)^(-1) en régime absorbant
        """
        T = self.construire_matrice_transition(gain_precision=gain_precision, niveau_z=niveau_z)
        eigvals = np.linalg.eigvals(T)
        eigvals = eigvals[np.argsort(-np.abs(eigvals))]
        nb_eigs_unitaires = int(np.sum(np.isclose(np.abs(eigvals), 1.0, atol=1e-9)))
        sature = self.goulot_l1_est_sature(gain_precision)

        absorbants = [
            f"{CATALOGUE_ETATS[i].code} {CATALOGUE_ETATS[i].couplage_croisement_ii}"
            for i in range(9)
            if np.isclose(T[i, i], 1.0, atol=1e-12)
        ]

        p = self.params
        convergence_veille = False
        ergodique_global = False
        pseudo_veille = (p.rho == 0.0 and p.delta_a > 0.0) or (p.kappa == 0.0 and p.delta_c > 0.0)
        rayon_transitoire: Optional[float] = None
        rang_sys: Optional[int] = None
        temps_absorption: Optional[Dict[str, float]] = None
        dist_stationnaire: Optional[Dict[str, float]] = None
        coherence_stat: Optional[float] = None

        if p.epsilon == 0.0:
            Q = T[1:, 1:]
            q_eigs = np.linalg.eigvals(Q)
            rayon_transitoire = float(np.max(np.abs(q_eigs)))

            if rayon_transitoire < 1.0 - 1e-12:
                convergence_veille = True
                diagnostic = (
                    "Convergence globale asymptotiquement stable vers Veille (0, 0, 0) "
                    f"(rayon spectral transitoire = {rayon_transitoire:.4f})."
                )
                N = np.linalg.inv(np.eye(8) - Q)
                tau = N @ np.ones(8)
                temps_absorption = {"s1 [A0/C0]": 0.0}
                for k in range(8):
                    n = CATALOGUE_ETATS[k + 1]
                    temps_absorption[f"{n.code} {n.couplage_croisement_ii}"] = round(float(tau[k]), 4)
                dist_stationnaire = {
                    f"{n.code} {n.couplage_croisement_ii}": (1.0 if n.index == 0 else 0.0)
                    for n in CATALOGUE_ETATS
                }
                coherence_stat = 1.0
            else:
                diagnostic = self._diagnostiquer_blocage(absorbants)
        else:
            A_sys = np.vstack([T.T - np.eye(9), np.ones((1, 9))])
            b_sys = np.zeros(10)
            b_sys[-1] = 1.0
            rang_sys = int(np.linalg.matrix_rank(A_sys))
            pi_star, *_ = np.linalg.lstsq(A_sys, b_sys, rcond=None)
            pi_star = np.clip(pi_star, 0.0, 1.0)
            if pi_star.sum() > 0.0:
                pi_star /= pi_star.sum()

            dist_stationnaire = {
                f"{n.code} {n.couplage_croisement_ii}": round(float(pi_star[n.index]), 4)
                for n in CATALOGUE_ETATS
            }
            coherence_stat = round(float(pi_star[0]), 4)
            rayon_transitoire = float(np.abs(eigvals[1]))

            eps_ergodique_avec_extinction = (
                p.epsilon == 1.0 and p.delta_a > 0.0 and p.delta_c > 0.0
            )
            ergodique_global = (
                ((0.0 < p.epsilon < 1.0) or eps_ergodique_avec_extinction)
                and (p.rho > 0.0 or p.delta_a > 0.0)
                and (p.kappa > 0.0 or p.delta_c > 0.0)
                and p.gamma_a > 0.0
                and p.gamma_c > 0.0
                and rang_sys == 9
                and nb_eigs_unitaires == 1
                and float(np.min(pi_star)) > 0.0
            )

            if ergodique_global:
                detail_eps = (
                    "epsilon = 1.00 avec delta_a, delta_c > 0"
                    if eps_ergodique_avec_extinction
                    else "0 < epsilon < 1"
                )
                diagnostic = (
                    "Régime ergodique stationnaire global sur les 9 états "
                    f"({detail_eps}, rang={rang_sys}, cohérence Veille pi*_1 = {coherence_stat:.4f})."
                )
            elif p.epsilon >= 1.0 and (p.delta_a == 0.0 or p.delta_c == 0.0):
                diagnostic = (
                    f"Régime saturé (epsilon = {p.epsilon:.2f} >= 1, delta_a=0 ou delta_c=0) : "
                    "perte d'irréductibilité sur la Veille "
                    f"(pi*_1 = {coherence_stat:.4f}, rang={rang_sys}, |eig|=1 : {nb_eigs_unitaires})."
                )
            else:
                diagnostic = (
                    f"Régime perturbé avec blocage ou réductibilité (rang={rang_sys}, "
                    f"cohérence Veille pi*_1 = {coherence_stat:.4f}) : "
                    + self._diagnostiquer_blocage(absorbants)
                )

        if pseudo_veille:
            diagnostic += (
                " [Pseudo-veille instable : retour sans résolution active (rho=0 ou kappa=0 avec delta>0).]"
            )
        if sature:
            diagnostic += " [Attention : gain_precision sature le goulot L1.]"

        return RapportAnalytique(
            parametres=p,
            gain_precision=gain_precision,
            niveau_z=niveau_z,
            goulot_l1_sature=sature,
            matrice_T=T,
            valeurs_propres=eigvals,
            rayon_spectral_transitoire=rayon_transitoire,
            rang_systeme_stationnaire=rang_sys,
            nb_eigs_unitaires=nb_eigs_unitaires,
            etats_absorbants=absorbants,
            convergence_veille_garantie=convergence_veille,
            ergodique_global=ergodique_global,
            diagnostic_regime=diagnostic,
            temps_absorption_moyens=temps_absorption,
            distribution_stationnaire=dist_stationnaire,
            indice_coherence_stationnaire=coherence_stat,
        )

    def _diagnostiquer_blocage(self, absorbants: List[str]) -> str:
        p = self.params
        causes: List[str] = []
        bloque_a = (p.rho == 0.0 and p.delta_a == 0.0)
        bloque_c = (p.kappa == 0.0 and p.delta_c == 0.0)
        if bloque_a and bloque_c:
            causes.append("Impasse double charge (rho=delta_a=0 et kappa=delta_c=0 : piège en A-/C-)")
        else:
            if bloque_a:
                if p.chi > 0.0 or p.epsilon > 0.0:
                    causes.append("Rigidité épistémique (rho=delta_a=0 : classe fermée {s4, s5, s6})")
                else:
                    causes.append("Rigidité épistémique (rho=delta_a=0 : singleton absorbant s4)")
            if bloque_c:
                if p.chi > 0.0 or p.epsilon > 0.0:
                    causes.append("Impuissance pragmatique (kappa=delta_c=0 : classe fermée {s2, s5, s8})")
                else:
                    causes.append("Impuissance pragmatique (kappa=delta_c=0 : singleton absorbant s2)")
        if p.gamma_a == 0.0 or p.gamma_c == 0.0:
            causes.append("Persévération / Hyper-certitude (gamma_a=0 ou gamma_c=0 : maintien en Décharge)")
        pseudo_veille = (p.rho == 0.0 and p.delta_a > 0.0) or (p.kappa == 0.0 and p.delta_c > 0.0)
        if pseudo_veille:
            causes.append(
                "Support restreint par extinction passive sans résolution active (rho=0 ou kappa=0, delta>0)"
            )
        elif p.chi == 0.0 and p.epsilon > 0.0 and not (bloque_a or bloque_c):
            causes.append("Clivage sous-couplé (chi=0) ou surcharge fonctionnelle")
        if not causes:
            causes.append("Support stationnaire restreint ou convergence lente.")
        return " ; ".join(causes) + f" (états absorbants stricts : {len(absorbants)})"

    def evoluer_distribution(
        self,
        pi_0: np.ndarray,
        nb_cycles: int = 20,
        gain_precision: float = 1.0,
        niveau_z: int = 2,
    ) -> np.ndarray:
        """
        Évolution déterministe exacte pi_{t+1} = pi_t @ T.
        Vérifie la positivité et la normalisation de `pi_0`.
        """
        pi = np.asarray(pi_0, dtype=np.float64)
        if pi.shape != (9,) or np.any(pi < 0.0) or not np.isclose(pi.sum(), 1.0, atol=1e-6):
            raise ValueError(
                "pi_0 doit être un vecteur de probabilité positif de dimension 9 sommant à 1."
            )
        T = self.construire_matrice_transition(gain_precision=gain_precision, niveau_z=niveau_z)
        trajectoire = np.zeros((nb_cycles + 1, 9), dtype=np.float64)
        trajectoire[0] = pi
        for t in range(nb_cycles):
            trajectoire[t + 1] = trajectoire[t] @ T
        return trajectoire


# =============================================================================
# 5. CIRCUIT CIRCULAIRE CONTINU À 6 OPÉRATEURS (ÉTATS CACHÉS + CORPS/ENV.)
# =============================================================================

@dataclass(frozen=True)
class EtatsCachesSubjectifs:
    """`[États cachés]` de l'Interface Subjective."""
    ecart_modele: int = 0
    revisable: bool = True
    suspension_descendante: bool = False


@dataclass(frozen=True)
class EtatsCachesPerceptifs:
    """`[États cachés]` de l'Interface Perceptive."""
    ecart_afferent: int = 0
    controlable: bool = True


@dataclass(frozen=True)
class EtatCorpsEnvironnement:
    """Milieu externe `Corps et Environnement`."""
    perturbation_exogene: int = 0


@dataclass(frozen=True)
class InterfaceAttentionnelle:
    """Pondération attentionnelle (hors coordonnées spatiales, cf. `AttentionalInterface`)."""
    precision_allouee: int = 0
    seuil_engagement: int = 1
    profondeur_persistance: int = 0
    precision_a: int = 1
    precision_c: int = 1

    @property
    def est_engagee(self) -> bool:
        return self.precision_allouee >= self.seuil_engagement


@dataclass(frozen=True)
class EtatCircuitCirculaire:
    """État global fermé du circuit continu à 6 opérateurs."""
    subjectif_cache: EtatsCachesSubjectifs
    perceptif_cache: EtatsCachesPerceptifs
    corps_env: EtatCorpsEnvironnement
    seuil_sensoriel: int = 1
    seuil_resorption: int = 1
    attention: InterfaceAttentionnelle = InterfaceAttentionnelle()

    def __post_init__(self) -> None:
        if self.seuil_resorption > self.seuil_sensoriel:
            raise ValueError(
                f"Invariant d'hystérésis violé : seuil_resorption ({self.seuil_resorption}) > "
                f"seuil_sensoriel ({self.seuil_sensoriel})."
            )

    @classmethod
    def veille_basale(cls) -> EtatCircuitCirculaire:
        return cls(
            subjectif_cache=EtatsCachesSubjectifs(0, True, False),
            perceptif_cache=EtatsCachesPerceptifs(0, True),
            corps_env=EtatCorpsEnvironnement(0),
        )


@dataclass(frozen=True)
class TraceCycle6Operations:
    """Trace complète d'une itération à travers les 6 opérations du circuit continu."""
    t: int
    # Op. 1 & 2 : Sorties internes vers les boucles
    sortie_subjective_a: int
    sortie_perceptive_c: int
    noeud_courant: NoeudConfiguration
    # Op. 3 : Croisement I perceptible par l'Agent + voies macroscopiques
    coord_proto_spatiale: Tuple[int, int, int]
    coord_noyau_affectif: Tuple[int, int, int]
    coord_antagoniste: Tuple[int, int, int]
    voie_ascendante_reflexive: str
    voie_descendante_politique: str
    # Op. 4 : Croisement II rétroactif sub-personnel
    canal_subjectif: CanalRetourSubjectif
    canal_perceptif: CanalRetourPerceptif
    # Op. 5 & 6 : États mis à jour à t+1
    etat_suivant: EtatCircuitCirculaire
    sortie_suivante_ac: Tuple[int, int]
    energie_lyapunov: int
    delta_energie: int


class CircuitCirculaireCartograffect:
    """
    Exécuteur déterministe de la boucle fermée continue à 6 opérations (Figure 1),
    isomorphe à `circularCycle` dans `Cartograffect/PredictiveCircuit.lean`.
    """

    @staticmethod
    def op1_sortie_subjective(etat: EtatCircuitCirculaire) -> int:
        """Op. 1 (Interne) : `[États cachés subj.] --Anticipation--> (+X, -X, 0)`."""
        if etat.subjectif_cache.ecart_modele < etat.seuil_resorption:
            return 0
        return +1 if etat.subjectif_cache.revisable else -1

    @staticmethod
    def op2_sortie_perceptive(etat: EtatCircuitCirculaire) -> int:
        """Op. 2 (Interne) : `[États cachés perc.] --Surprise--> (+Y, -Y, 0)`."""
        if etat.perceptif_cache.ecart_afferent < etat.seuil_resorption:
            return 0
        return +1 if etat.perceptif_cache.controlable else -1

    def op3_croisement_i_perceptible(
        self,
        etat: EtatCircuitCirculaire,
    ) -> Tuple[Tuple[int, int, int], Tuple[int, int, int]]:
        """
        Op. 3 (Croisement I perceptible) : `(A, C) -> (X, Y, 0) -> (X, Y, Z)` certifié valide.
        """
        a = self.op1_sortie_subjective(etat)
        c = self.op2_sortie_perceptive(etat)
        proto = transduction_l1(a, c)
        att = etat.attention
        susp = etat.subjectif_cache.suspension_descendante
        if a == 0 and c == 0:
            z = (att.profondeur_persistance + 2) if susp else 0
        elif not att.est_engagee:
            z = (att.profondeur_persistance + 2) if susp else 1
        else:
            z = att.profondeur_persistance + 2
        coord_z = projeter_noyau_affectif(
            a, c, z, pi_a=att.precision_a, pi_c=att.precision_c, suspension_descendante=susp
        )
        return (proto, coord_z)

    def op4_croisement_ii_retroactif(
        self,
        etat: EtatCircuitCirculaire,
    ) -> Tuple[CanalRetourSubjectif, CanalRetourPerceptif]:
        """Op. 4 (Croisement II sub-personnel) : produit les canaux injectifs `A/C` et `C/A`."""
        a = self.op1_sortie_subjective(etat)
        c = self.op2_sortie_perceptive(etat)
        return canaux_retour_croisement_ii(a, c)

    @staticmethod
    def op5_entree_subjective(
        etat: EtatCircuitCirculaire,
        canal: CanalRetourSubjectif,
        coord_noyau: Tuple[int, int, int],
    ) -> EtatsCachesSubjectifs:
        """Op. 5 (Externe) : réintègre les 9 canaux `A/C` et la voie ascendante réflexive."""
        sc = etat.subjectif_cache
        next_ecart = max(0, sc.ecart_modele - 1) if canal.regime_a == "Décharge" else sc.ecart_modele
        next_revisable = sc.revisable or (
            canal.regime_a == "Charge" and canal.contexte_c == +1 and coord_noyau[2] >= 2
        )
        next_susp = False if (canal.regime_a == "Neutre" and canal.contexte_c == 0) else sc.suspension_descendante
        return EtatsCachesSubjectifs(
            ecart_modele=next_ecart,
            revisable=next_revisable,
            suspension_descendante=next_susp,
        )

    @staticmethod
    def op6_entree_perceptive(
        etat: EtatCircuitCirculaire,
        canal: CanalRetourPerceptif,
        coord_noyau: Tuple[int, int, int],
    ) -> Tuple[EtatsCachesPerceptifs, EtatCorpsEnvironnement]:
        """Op. 6 (Externe) : réintègre les 9 canaux `C/A` et les signaux afférents de `Corps & Env.`."""
        pc = etat.perceptif_cache
        reduced = (
            max(0, pc.ecart_afferent - 1)
            if (canal.regime_c == "Décharge" and coord_noyau[1] > 0)
            else pc.ecart_afferent
        )
        next_ecart = reduced + etat.corps_env.perturbation_exogene
        return (
            EtatsCachesPerceptifs(ecart_afferent=next_ecart, controlable=pc.controlable),
            etat.corps_env,
        )

    def executer_cycle_6_operations(
        self,
        etat: EtatCircuitCirculaire,
        t: int = 0,
    ) -> TraceCycle6Operations:
        """Exécute un cycle complet fermé des 6 opérations."""
        a = self.op1_sortie_subjective(etat)
        c = self.op2_sortie_perceptive(etat)
        noeud = CATALOGUE_ETATS[INDEX_PAR_AC[(a, c)]]

        proto, coord_z = self.op3_croisement_i_perceptible(etat)
        coord_ant = antagoniste_noyau(*coord_z)
        ch_subj, ch_perc = self.op4_croisement_ii_retroactif(etat)

        next_subj = self.op5_entree_subjective(etat, ch_subj, coord_z)
        next_perc, next_env = self.op6_entree_perceptive(etat, ch_perc, coord_z)

        etat_suivant = EtatCircuitCirculaire(
            subjectif_cache=next_subj,
            perceptif_cache=next_perc,
            corps_env=next_env,
            seuil_sensoriel=etat.seuil_sensoriel,
            seuil_resorption=etat.seuil_resorption,
            attention=etat.attention,
        )
        a_next = self.op1_sortie_subjective(etat_suivant)
        c_next = self.op2_sortie_perceptive(etat_suivant)

        voie_asc = (
            f"Voie réflexive (X={coord_z[0]:+d}, Z={coord_z[2]}) -> "
            f"Interface Subjective [revisable={etat.subjectif_cache.revisable}]"
        )
        voie_desc = (
            f"Politique motrice (Y={coord_z[1]:+d}, Z={coord_z[2]}) -> "
            f"Corps & Env. [perturbation={etat.corps_env.perturbation_exogene}]"
        )

        return TraceCycle6Operations(
            t=t,
            sortie_subjective_a=a,
            sortie_perceptive_c=c,
            noeud_courant=noeud,
            coord_proto_spatiale=proto,
            coord_noyau_affectif=coord_z,
            coord_antagoniste=coord_ant,
            voie_ascendante_reflexive=voie_asc,
            voie_descendante_politique=voie_desc,
            canal_subjectif=ch_subj,
            canal_perceptif=ch_perc,
            etat_suivant=etat_suivant,
            sortie_suivante_ac=(a_next, c_next),
            energie_lyapunov=noeud.energie_lyapunov,
            delta_energie=potentiel_lyapunov(a_next, c_next) - noeud.energie_lyapunov,
        )

    def simuler_circuit(
        self,
        etat_initial: EtatCircuitCirculaire,
        nb_cycles: int = 10,
    ) -> List[TraceCycle6Operations]:
        """Simule la circularité continue du circuit sur `nb_cycles` itérations."""
        historique: List[TraceCycle6Operations] = []
        etat = etat_initial
        for t in range(nb_cycles):
            trace = self.executer_cycle_6_operations(etat, t=t)
            historique.append(trace)
            etat = trace.etat_suivant
        return historique

    @staticmethod
    def vers_coordonnees_cartograffect(trace: TraceCycle6Operations) -> Dict[str, Any]:
        """
        Exporte un état du circuit au format standardisé `CoreAffect` / `AffectiveMatrix`
        (strictement valide au sens d'`isValidCoreAffect`).
        """
        x, y, z = trace.coord_noyau_affectif
        ax, ay, az = trace.coord_antagoniste
        return {
            "t": trace.t,
            "code_etat": trace.noeud_courant.code,
            "couplage_AC": trace.noeud_courant.couplage_croisement_ii,
            "coordonnees_noyau": {"X": x, "Y": y, "Z": z},
            "coordonnees_antagoniste": {"X": ax, "Y": ay, "Z": az},
            "valide_noyau_affectif": est_valide_noyau_affectif(x, y, z),
            "rayon_couronne_z": rayon_couronne(z),
            "coherence_interne_externe": trace.noeud_courant.coherence_interne_externe,
            "canaux_croisement_ii": {
                "vers_subjective": trace.canal_subjectif.etiquette,
                "vers_perceptive": trace.canal_perceptif.etiquette,
            },
            "energie_libre_lyapunov": trace.energie_lyapunov,
            "delta_energie": trace.delta_energie,
            "statut": trace.noeud_courant.statut_topologique,
        }


# =============================================================================
# 6. LOI UNIFIÉE : ACCUMULATEUR R_t, STRATE Z_t (COURT-CIRCUIT R5) & PARTAGE
# =============================================================================

SEUILS_MONTEE_DEFAUT: Tuple[float, ...] = (0.4, 0.8, 1.3, 1.8, 2.3, 2.8, 3.3, 3.8)
SEUILS_DESCENTE_DEFAUT: Tuple[float, ...] = (0.2, 0.4, 0.7, 1.1, 1.5, 1.9, 2.4, 2.9)


def budget_spatial(z: int) -> int:
    """Budget géométrique B(Z) de la couronne : 0 pour Z < 2, 2Z - 2 pour Z >= 2."""
    if z < 0:
        raise ValueError(f"La strate Z doit être >= 0 (reçu : {z}).")
    return 0 if z < 2 else 2 * z - 2


def compter_resolutions_actives(src_ac: Tuple[int, int], dst_ac: Tuple[int, int]) -> int:
    """
    Compte les résolutions actives strictes Charge (-1) -> Décharge (+1) lors du pas t -> t+1.
    Une extinction passive (-1 -> 0) retourne 0 et ne réduit pas l'accumulateur via -eta.
    """
    _valider_modalites(*src_ac)
    _valider_modalites(*dst_ac)
    res_a = 1 if (src_ac[0] == -1 and dst_ac[0] == +1) else 0
    res_c = 1 if (src_ac[1] == -1 and dst_ac[1] == +1) else 0
    return res_a + res_c


def partage_precision_logistique(
    rho_hat: float,
    kappa_hat: float,
    a: int,
    c: int,
    beta: float = 2.0,
    alpha: float = 0.25,
) -> Tuple[float, float]:
    """
    Partage dynamique normalisé (pi_A_norm, pi_C_norm) sommant à 1.0 par loi logistique :
        pi_A / B(Z) = sigma(beta * [(rho_hat - kappa_hat) + alpha * (I(a=-1) - I(c=-1))]).
    En Double Charge (-1, -1), le terme en alpha s'annule exactement.

    Note : implémente la sigmoïde logistique transcendante (1 + e^{-u})^{-1} (contrairement
    à l'homologue purement entier `PredictiveCircuit.symmetricSigmoid` 0.5*(1 + u/(|u|+K))
    sous Lean 4 `Init`, qui partage exactement les mêmes propriétés d'antisymétrie, de
    positivité et de normalisation).
    """
    _valider_modalites(a, c)
    if beta <= 0.0:
        raise ValueError(f"La sensibilité beta doit être strictement positive (reçu : {beta}).")
    if alpha < 0.0:
        raise ValueError(f"Le poids alpha doit être >= 0 (reçu : {alpha}).")
    ind_a = 1.0 if a == -1 else 0.0
    ind_c = 1.0 if c == -1 else 0.0
    u = float(beta * ((rho_hat - kappa_hat) + alpha * (ind_a - ind_c)))
    if u >= 0.0:
        pi_a = 1.0 / (1.0 + float(np.exp(-min(u, 60.0))))
    else:
        eu = float(np.exp(max(u, -60.0)))
        pi_a = eu / (1.0 + eu)
    return (pi_a, 1.0 - pi_a)


def mettre_a_jour_accumulateur(
    r: float,
    pi_a_norm: float,
    pi_c_norm: float,
    src_ac: Tuple[int, int],
    dst_ac: Tuple[int, int],
    lam: float = 0.80,
    eta: float = 0.60,
) -> float:
    """
    Équation 1 (positive et bornée par 1/(1-lambda)) :
        R_{t+1} = max(0, lambda * R_t + pi_A * I(a=-1) + pi_C * I(c=-1) - eta * I_res(t)).
    """
    if not (0.0 <= lam < 1.0):
        raise ValueError(f"Le facteur allostatique lambda doit appartenir à [0, 1) (reçu : {lam}).")
    if eta < 0.0 or r < 0.0:
        raise ValueError("Les quantités r et eta doivent être >= 0.")
    _valider_modalites(*src_ac)
    _valider_modalites(*dst_ac)
    contrib = (pi_a_norm if src_ac[0] == -1 else 0.0) + (pi_c_norm if src_ac[1] == -1 else 0.0)
    relief = eta * compter_resolutions_actives(src_ac, dst_ac)
    return max(0.0, lam * r + contrib - relief)


def mettre_a_jour_strate_r5(
    z: int,
    r_next: float,
    seuils_montee: Tuple[float, ...] = SEUILS_MONTEE_DEFAUT,
    seuils_descente: Tuple[float, ...] = SEUILS_DESCENTE_DEFAUT,
    z_max: int = 7,
) -> int:
    """
    Équation 2 avec hystérésis et court-circuit explicite R5 :
      - Montée si R_{t+1} > theta_up(Z)
      - Descente si R_{t+1} < theta_down(Z), avec court-circuit direct Z in {1, 2} -> 0
        afin de ne jamais transiter par la Surprise (Z = 1) en redescente.
    """
    if not (0 <= z <= z_max):
        raise ValueError(f"Strate Z invalide : {z} (attendu dans [0, {z_max}]).")
    idx = min(z, len(seuils_montee) - 1)
    if r_next > seuils_montee[idx]:
        return min(z_max, z + 1)
    if r_next < seuils_descente[idx]:
        if z <= 2:
            return 0
        return z - 1
    return z


def mettre_a_jour_efficacites(
    rho_hat: float,
    kappa_hat: float,
    src_ac: Tuple[int, int],
    dst_ac: Tuple[int, int],
    mu: float = 0.25,
) -> Tuple[float, float]:
    """Mise à jour par moyenne mobile exponentielle (EMA) des efficacités perçues (rho_hat, kappa_hat)."""
    if not (0.0 <= mu <= 1.0):
        raise ValueError(f"Le taux d'apprentissage mu doit appartenir à [0, 1] (reçu : {mu}).")
    new_rho = rho_hat
    new_kap = kappa_hat
    if src_ac[0] == -1:
        cible_a = 1.0 if dst_ac[0] == +1 else 0.0
        new_rho = (1.0 - mu) * rho_hat + mu * cible_a
    if src_ac[1] == -1:
        cible_c = 1.0 if dst_ac[1] == +1 else 0.0
        new_kap = (1.0 - mu) * kappa_hat + mu * cible_c
    return (new_rho, new_kap)


@dataclass(frozen=True)
class ParametresLoiUnifiee:
    """Paramètres de la loi unifiée couplant R_t, Z_t et le partage dynamique (pi_A, pi_C)."""
    lam: float = 0.80
    eta: float = 0.60
    beta: float = 2.0
    alpha: float = 0.25
    mu_efficacite: float = 0.25
    z_max: int = 7
    scale_quantification: int = 1000
    seuils_montee: Tuple[float, ...] = SEUILS_MONTEE_DEFAUT
    seuils_descente: Tuple[float, ...] = SEUILS_DESCENTE_DEFAUT

    def __post_init__(self) -> None:
        if not (0.0 <= self.lam < 1.0):
            raise ValueError(f"lambda doit appartenir à [0, 1) (reçu : {self.lam}).")
        if self.eta < 0.0 or self.beta <= 0.0 or self.alpha < 0.0:
            raise ValueError("Paramètres négatifs ou nuls invalides dans ParametresLoiUnifiee.")
        if self.z_max < 2:
            raise ValueError("z_max doit être >= 2.")
        if len(self.seuils_montee) <= self.z_max or len(self.seuils_descente) <= self.z_max:
            raise ValueError("Les tables de seuils doivent couvrir 0..z_max.")
        for k in range(self.z_max + 1):
            if self.seuils_descente[k] >= self.seuils_montee[k]:
                raise ValueError(f"Hystérésis violée à Z={k} : theta_down >= theta_up.")

    @property
    def borne_accumulateur(self) -> float:
        return 1.0 / (1.0 - self.lam)


@dataclass(frozen=True)
class EtatLoiUnifiee:
    """État courant du système dynamique complet (Moteur + Accumulateur R_t + Strate Z_t)."""
    ac: Tuple[int, int] = (0, 0)
    r_accumulateur: float = 0.0
    z_strate: int = 0
    rho_hat: float = 0.5
    kappa_hat: float = 0.5
    suspension_descendante: bool = False


@dataclass(frozen=True)
class TraceLoiUnifiee:
    """Journal d'un pas d'évolution de la loi unifiée."""
    t: int
    ac_precedent: Tuple[int, int]
    ac_suivant: Tuple[int, int]
    resolutions_actives: int
    pi_a_norm: float
    pi_c_norm: float
    r_suivant: float
    z_precedent: int
    z_suivant: int
    budget_z_suivant: int
    coord_noyau_suivante: Tuple[int, int, int]
    rho_hat_suivant: float
    kappa_hat_suivant: float
    etat_suivant: EtatLoiUnifiee


class SimulateurUnifieCartograffect:
    """
    Simulateur intégré de l'Axe (iv) reliant les transitions markoviennes sur (A, C),
    l'accumulateur de récurrence R_t, la dynamique de strate Z_t (avec court-circuit R5)
    et la projection discrète sur les 176 positions via `repartir_rayon` (`apportionRay`).
    """

    def __init__(
        self,
        params_loi: Optional[ParametresLoiUnifiee] = None,
        moteur: Optional[MoteurPredictifCartograffect] = None,
    ) -> None:
        self.params_loi: ParametresLoiUnifiee = params_loi or ParametresLoiUnifiee()
        self.moteur: MoteurPredictifCartograffect = moteur or MoteurPredictifCartograffect(
            ParametresMoteur.homeostasique()
        )

    def pas_unifie(
        self,
        etat: EtatLoiUnifiee,
        ac_suivant: Tuple[int, int],
        t: int = 0,
        maj_efficacites: bool = True,
    ) -> TraceLoiUnifiee:
        """Exécute un pas déterministe `(etat, ac_suivant) -> TraceLoiUnifiee`."""
        p = self.params_loi
        _valider_modalites(*etat.ac)
        _valider_modalites(*ac_suivant)

        pi_a_norm, pi_c_norm = partage_precision_logistique(
            etat.rho_hat,
            etat.kappa_hat,
            etat.ac[0],
            etat.ac[1],
            beta=p.beta,
            alpha=p.alpha,
        )
        n_res = compter_resolutions_actives(etat.ac, ac_suivant)
        r_next = mettre_a_jour_accumulateur(
            etat.r_accumulateur,
            pi_a_norm,
            pi_c_norm,
            etat.ac,
            ac_suivant,
            lam=p.lam,
            eta=p.eta,
        )
        z_next = mettre_a_jour_strate_r5(
            etat.z_strate,
            r_next,
            seuils_montee=p.seuils_montee,
            seuils_descente=p.seuils_descente,
            z_max=p.z_max,
        )

        # Mise à jour causale des efficacités perçues avant déploiement spatial à t+1
        if maj_efficacites:
            rho_next, kap_next = mettre_a_jour_efficacites(
                etat.rho_hat, etat.kappa_hat, etat.ac, ac_suivant, mu=p.mu_efficacite
            )
        else:
            rho_next, kap_next = etat.rho_hat, etat.kappa_hat

        # Quantification entière sur [1, scale-1] pour le partage discret `apportionRay`
        pi_a_next, _ = partage_precision_logistique(
            rho_next,
            kap_next,
            ac_suivant[0],
            ac_suivant[1],
            beta=p.beta,
            alpha=p.alpha,
        )
        scale_q = p.scale_quantification
        qi_a = max(1, min(scale_q - 1, round(pi_a_next * scale_q)))
        qi_c = max(1, scale_q - qi_a)

        susp_next = etat.suspension_descendante or (z_next >= 2)
        if ac_suivant == (0, 0) and z_next == 0:
            susp_next = False

        coord_next = projeter_noyau_affectif(
            ac_suivant[0],
            ac_suivant[1],
            z_next,
            pi_a=qi_a,
            pi_c=qi_c,
            suspension_descendante=susp_next,
        )

        etat_next = EtatLoiUnifiee(
            ac=ac_suivant,
            r_accumulateur=r_next,
            z_strate=z_next,
            rho_hat=rho_next,
            kappa_hat=kap_next,
            suspension_descendante=susp_next,
        )
        return TraceLoiUnifiee(
            t=t,
            ac_precedent=etat.ac,
            ac_suivant=ac_suivant,
            resolutions_actives=n_res,
            pi_a_norm=pi_a_norm,
            pi_c_norm=pi_c_norm,
            r_suivant=r_next,
            z_precedent=etat.z_strate,
            z_suivant=z_next,
            budget_z_suivant=budget_spatial(z_next),
            coord_noyau_suivante=coord_next,
            rho_hat_suivant=rho_next,
            kappa_hat_suivant=kap_next,
            etat_suivant=etat_next,
        )

    def simuler_sequence(
        self,
        etat_initial: EtatLoiUnifiee,
        sequence_ac: List[Tuple[int, int]],
        maj_efficacites: bool = True,
    ) -> List[TraceLoiUnifiee]:
        """Simule une séquence imposée de couplages `(a, c)` le long de la loi unifiée."""
        traces: List[TraceLoiUnifiee] = []
        etat = etat_initial
        for t, ac_suiv in enumerate(sequence_ac):
            tr = self.pas_unifie(etat, ac_suiv, t=t, maj_efficacites=maj_efficacites)
            traces.append(tr)
            etat = tr.etat_suivant
        return traces

    def simuler_stochastique(
        self,
        etat_initial: EtatLoiUnifiee,
        nb_cycles: int = 30,
        gain_precision: float = 1.0,
    ) -> List[TraceLoiUnifiee]:
        """Échantillonne la trajectoire stochastique couplée `T(Z_t)` sur `nb_cycles` itérations."""
        traces: List[TraceLoiUnifiee] = []
        etat = etat_initial
        for t in range(nb_cycles):
            T = self.moteur.construire_matrice_transition(
                gain_precision=gain_precision, niveau_z=etat.z_strate
            )
            idx_courant = INDEX_PAR_AC[etat.ac]
            probas = T[idx_courant]
            idx_suiv = int(self.moteur._rng.choice(9, p=probas / probas.sum()))
            noeud_suiv = CATALOGUE_ETATS[idx_suiv]
            tr = self.pas_unifie(etat, (noeud_suiv.a, noeud_suiv.c), t=t, maj_efficacites=True)
            traces.append(tr)
            etat = tr.etat_suivant
        return traces


# =============================================================================
# 7. DÉMONSTRATION ET VÉRIFICATION EXÉCUTABLE
# =============================================================================

if __name__ == "__main__":
    print("=== 1. RÉGIME CANONIQUE LIBRE (epsilon = 0, tau(s) = V(s)/p) ===")
    moteur_libre = MoteurPredictifCartograffect(ParametresMoteur.canonique_libre(0.8), seed=42)
    rapport_libre = moteur_libre.analyser_dynamique()
    print(rapport_libre.diagnostic_regime)
    for lbl, tau_val in (rapport_libre.temps_absorption_moyens or {}).items():
        print(f"  {lbl:12s} -> {tau_val:.2f} cycles")

    print("\n=== 2. CONTRÔLE DE PARITÉ ENTIÈRE (scale=100, dénominateur 4*100^6) ===")
    moteur_parite = MoteurPredictifCartograffect(
        ParametresMoteur(
            rho=0.60, kappa=0.60, delta_a=0.15, delta_c=0.10,
            gamma_a=0.70, gamma_c=0.70, epsilon=0.15,
            q_pos_a=0.35, q_pos_c=0.35, chi=0.25, beta=0.0,
        )
    )
    W = moteur_parite.construire_noyau_entier(scale=100)
    T = moteur_parite.construire_matrice_transition()
    err = float(np.max(np.abs(T - W / (4 * 100**6))))
    print(f"Écart max |T - W/(4*100^6)| = {err:.2e}")
    print(f"Peur (-2,0) -> Colère (-1,+1) : T = {T[INDEX_PAR_AC[(-1, 0)], INDEX_PAR_AC[(-1, 1)]]:.4f}")

    print("\n=== 3. DIAGNOSTIC DES 5 RUPTURES D'ERGODICITÉ & EXTINCTION PASSIVE ===")
    for nom, params in [
        ("Rigidité épistémique (chi=0)", ParametresMoteur.rigidite_epistemique()),
        ("Rigidité épistémique (chi=0.25)", ParametresMoteur.rigidite_epistemique(epsilon=0.0, chi=0.25)),
        ("Impasse double charge", ParametresMoteur.impasse_double_charge()),
        ("Extinction passive", ParametresMoteur.extinction_passive(delta=0.40, epsilon=0.15)),
        ("Saturation epsilon=1.0", ParametresMoteur.homeostasique(epsilon=1.0)),
        ("Surcharge allostatique", ParametresMoteur.surcharge_allostatique(epsilon=0.90)),
        ("Homéostasique epsilon=0.05", ParametresMoteur.homeostasique(epsilon=0.05)),
    ]:
        rep = MoteurPredictifCartograffect(params).analyser_dynamique()
        print(f"  [{nom}] ergodique={rep.ergodique_global} | {rep.diagnostic_regime}")

    print("\n=== 4. SIMULATION DU CIRCUIT CONTINU À 6 OPÉRATIONS ===")
    circuit = CircuitCirculaireCartograffect()
    etat_init = EtatCircuitCirculaire(
        subjectif_cache=EtatsCachesSubjectifs(ecart_modele=2, revisable=False, suspension_descendante=True),
        perceptif_cache=EtatsCachesPerceptifs(ecart_afferent=2, controlable=True),
        corps_env=EtatCorpsEnvironnement(perturbation_exogene=0),
        attention=InterfaceAttentionnelle(precision_allouee=3, seuil_engagement=1, profondeur_persistance=1, precision_a=1, precision_c=3),
    )
    for tr in circuit.simuler_circuit(etat_init, nb_cycles=4):
        payload = CircuitCirculaireCartograffect.vers_coordonnees_cartograffect(tr)
        print(
            f"t={payload['t']} | {payload['couplage_AC']} -> Noyau={payload['coordonnees_noyau']} "
            f"(valide={payload['valide_noyau_affectif']}) | Antagoniste={payload['coordonnees_antagoniste']} "
            f"| V={payload['energie_libre_lyapunov']}"
        )

    print("\n=== 5. LOI UNIFIÉE (R_t, Z_t, partage logistique) & LATÉRALE CONSTERNATION ===")
    sim = SimulateurUnifieCartograffect()
    e0 = EtatLoiUnifiee(ac=(-1, -1), r_accumulateur=0.0, z_strate=0, rho_hat=0.1, kappa_hat=0.9)
    seq = [(-1, -1), (-1, -1), (-1, -1), (-1, +1), (+1, +1), (0, 0), (0, 0), (0, 0), (0, 0)]
    for tr in sim.simuler_sequence(e0, seq, maj_efficacites=False):
        print(
            f"t={tr.t} | {tr.ac_precedent}->{tr.ac_suivant} (res={tr.resolutions_actives}) | "
            f"R={tr.r_suivant:.3f} | Z:{tr.z_precedent}->{tr.z_suivant} | "
            f"Noyau={tr.coord_noyau_suivante}"
        )
