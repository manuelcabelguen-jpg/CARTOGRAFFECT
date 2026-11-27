"""
Suite de tests unitaires pour `cartograffect_predictive_engine.py`,
vérifiant la parité exacte v3.0 avec le noyau formel Lean 4 (`DECISIONS_V3.md` :
Options 1A, 2a, 3b et discrétisation bornée, `z_max = 5` par défaut, fondation `Z = 2`).
"""

import unittest
import numpy as np

from cartograffect_predictive_engine import (
    CATALOGUE_ETATS,
    INDEX_PAR_AC,
    ORDRE_ATTENTE,
    ORDRE_CONTROLE,
    CircuitCirculaireCartograffect,
    DiagnosticRupturesErgodicite,
    DomainePossiblesAttentionnel,
    EtatCircuitCirculaire,
    EtatCorpsEnvironnement,
    EtatLoiUnifiee,
    EtatsCachesPerceptifs,
    EtatsCachesSubjectifs,
    InterfaceAttentionnelle,
    MoteurPredictifCartograffect,
    ParametresLoiUnifiee,
    ParametresMoteur,
    RegimeContingenceZ2,
    ReponseIsoleeCircuit,
    SimulateurUnifieCartograffect,
    antagoniste_noyau,
    assembler_reponses_isolees,
    budget_spatial,
    calculer_reduction_information,
    canaux_retour_croisement_ii,
    classifier_coherence,
    compter_resolutions_actives,
    contingence_couplage_z2,
    contingence_diagonale_z2,
    entropie_shannon_bits,
    est_transition_verticale_valide_2a,
    est_valide_noyau_affectif,
    mettre_a_jour_accumulateur,
    mettre_a_jour_strate_r5,
    mode_renforcement_actif_vers_regime,
    noyau_profondeur_canonique_poids,
    partage_precision_logistique,
    position_croisement_i,
    position_croisement_ii,
    potentiel_lyapunov,
    projeter_noyau_affectif,
    rayon_couronne,
    repartir_rayon,
    secteur_dominant_xy,
    transduction_l1,
    transduction_l1_inverse,
)


class TestTopologieEtGeometrie(unittest.TestCase):
    def test_bijection_l1_et_transposition_croisements(self) -> None:
        positions_i = set()
        positions_ii = set()
        canaux_subj = set()
        canaux_perc = set()
        for a in ORDRE_ATTENTE:
            for c in ORDRE_CONTROLE:
                x, y, z0 = transduction_l1(a, c)
                self.assertEqual(z0, 0)
                if a == 0 and c == 0:
                    self.assertEqual((x, y), (0, 0))
                else:
                    self.assertEqual(abs(x) + abs(y), 2)
                self.assertEqual(transduction_l1_inverse(x, y), (a, c))

                pi = position_croisement_i(a, c)
                pii = position_croisement_ii(a, c)
                self.assertEqual(pii, (pi[1], pi[0]))
                positions_i.add(pi)
                positions_ii.add(pii)

                cs, cp = canaux_retour_croisement_ii(a, c)
                canaux_subj.add((cs.regime_a, cs.contexte_c))
                canaux_perc.add((cp.regime_c, cp.contexte_a))

        self.assertEqual(len(positions_i), 9)
        self.assertEqual(len(positions_ii), 9)
        self.assertEqual(len(canaux_subj), 9)
        self.assertEqual(len(canaux_perc), 9)
        self.assertEqual(position_croisement_i(0, 0), (0, 2))
        self.assertEqual(position_croisement_ii(0, 0), (2, 0))

    def test_geometrie_noyau_affectif_et_secteurs_neutres_1a(self) -> None:
        self.assertEqual(projeter_noyau_affectif(0, 0, 0, suspension_descendante=False), (0, 0, 0))
        self.assertEqual(projeter_noyau_affectif(0, 0, 2, suspension_descendante=False), (0, 0, 0))
        self.assertEqual(projeter_noyau_affectif(0, 0, 2, suspension_descendante=True), (0, 0, 2))
        self.assertEqual(projeter_noyau_affectif(0, 0, 5, suspension_descendante=True), (0, 0, 5))
        self.assertEqual(projeter_noyau_affectif(-1, +1, 1), (0, 0, 1))

        for z in (0, 1, 2, 3, 4, 5):
            for a in ORDRE_ATTENTE:
                for c in ORDRE_CONTROLE:
                    for pa, pc in ((1, 1), (1, 3), (3, 1)):
                        pt = projeter_noyau_affectif(a, c, z, pi_a=pa, pi_c=pc, suspension_descendante=True)
                        self.assertTrue(est_valide_noyau_affectif(*pt))
                        ant = antagoniste_noyau(*pt)
                        self.assertTrue(est_valide_noyau_affectif(*ant))
                        self.assertEqual(antagoniste_noyau(*ant), pt)

        # Nomenclature fonctionnelle neutre Option 1A (sans assimilation (-X, +Y) -> joie)
        self.assertEqual(secteur_dominant_xy(-1, 3), "controlPos")
        self.assertEqual(secteur_dominant_xy(1, -3), "controlNeg")
        self.assertEqual(secteur_dominant_xy(-3, 1), "expectationNeg")
        self.assertEqual(secteur_dominant_xy(3, -1), "expectationPos")
        self.assertIsNone(secteur_dominant_xy(-1, 1))
        self.assertIsNone(secteur_dominant_xy(0, 0))

        self.assertEqual(projeter_noyau_affectif(-1, +1, 3, pi_a=1, pi_c=3), (-1, 3, 3))
        self.assertEqual(antagoniste_noyau(-1, 3, 3), (3, -1, 3))
        self.assertEqual(rayon_couronne(0), 0)
        self.assertEqual(rayon_couronne(1), 0)
        self.assertEqual(rayon_couronne(5), 8)
        self.assertEqual(repartir_rayon(0, 1, 5), (1, 1))
        self.assertFalse(est_valide_noyau_affectif(-1, 1, 0))


class TestMatriceMarkovEtAsymetrieP2Option3b(unittest.TestCase):
    def test_parite_exacte_avec_noyau_entier_lean(self) -> None:
        params = ParametresMoteur(
            rho=0.60, kappa=0.60, delta_a=0.15, delta_c=0.10,
            gamma_a=0.70, gamma_c=0.70, epsilon=0.15,
            q_pos_a=0.35, q_pos_c=0.35, chi=0.25, beta=0.0,
        )
        moteur = MoteurPredictifCartograffect(params)
        W = moteur.construire_noyau_entier(scale=100)
        T = moteur.construire_matrice_transition(gain_precision=1.0, niveau_z=2)

        somme_attendue = 4 * (100 ** 6)
        self.assertTrue(np.all(W.sum(axis=1) == somme_attendue))
        self.assertTrue(np.allclose(T, W / somme_attendue, atol=1e-12))
        self.assertTrue(np.allclose(T.sum(axis=1), 1.0, atol=1e-12))

    def test_loi_lyapunov_canonique_libre(self) -> None:
        p = 0.8
        moteur = MoteurPredictifCartograffect(ParametresMoteur.canonique_libre(p))
        T = moteur.construire_matrice_transition()
        V = [potentiel_lyapunov(n.a, n.c) for n in CATALOGUE_ETATS]

        for i in range(9):
            for j in range(9):
                if T[i, j] > 0.0:
                    self.assertLessEqual(V[j], V[i])

        eigs_sorted = np.sort(np.real(np.linalg.eigvals(T)))
        diag_sorted = np.sort(np.diag(T))
        self.assertTrue(np.allclose(eigs_sorted, diag_sorted, atol=1e-12))

        rapport = moteur.analyser_dynamique()
        self.assertTrue(rapport.convergence_veille_garantie)
        for n in CATALOGUE_ETATS:
            cle = f"{n.code} {n.couplage_croisement_ii}"
            self.assertAlmostEqual(rapport.temps_absorption_moyens[cle], V[n.index] / p, places=4)

    def test_asymetrie_p2_option_3b_charge_negative_uniquement(self) -> None:
        # 1. Noyau markovien 9x9 à bruit exogène nul (epsilon = 0, chi = 0.25 > 0) :
        #    seuls les 2 pôles en Charge négative (Peur, Tristesse) bifurquent vers les diagonales.
        p_3b = ParametresMoteur(
            rho=0.60, kappa=0.60, gamma_a=0.70, gamma_c=0.70,
            epsilon=0.0, q_pos_a=0.35, q_pos_c=0.35, chi=0.25,
        )
        W = MoteurPredictifCartograffect(p_3b).construire_noyau_entier(scale=100)

        idx_peur = INDEX_PAR_AC[(-1, 0)]
        idx_tristesse = INDEX_PAR_AC[(0, -1)]
        idx_courage = INDEX_PAR_AC[(+1, 0)]
        idx_joie = INDEX_PAR_AC[(0, +1)]
        idx_desir = INDEX_PAR_AC[(+1, +1)]
        idx_colere = INDEX_PAR_AC[(-1, +1)]
        idx_calme = INDEX_PAR_AC[(+1, -1)]
        idx_degout = INDEX_PAR_AC[(-1, -1)]

        # Peur (-2, 0, 2) -> Colère et Dégoût > 0
        self.assertGreater(int(W[idx_peur, idx_colere]), 0)
        self.assertGreater(int(W[idx_peur, idx_degout]), 0)
        # Tristesse (0, -2, 2) -> Calme et Dégoût > 0
        self.assertGreater(int(W[idx_tristesse, idx_calme]), 0)
        self.assertGreater(int(W[idx_tristesse, idx_degout]), 0)
        # Courage (2, 0, 2) et Joie (0, 2, 2) -> 0 auto-déstabilisation vers les diagonales à bruit nul
        self.assertEqual(int(W[idx_courage, idx_desir]), 0)
        self.assertEqual(int(W[idx_courage, idx_calme]), 0)
        self.assertEqual(int(W[idx_joie, idx_desir]), 0)
        self.assertEqual(int(W[idx_joie, idx_colere]), 0)

        # 2. Parité exacte sur le noyau inter-strates `noyau_profondeur_canonique_poids` (canonicalDepthWeight)
        self.assertGreater(
            noyau_profondeur_canonique_poids((-2, 0, 2), (-2, 2, 3)),
            noyau_profondeur_canonique_poids((-2, 0, 2), (-4, 0, 3)),
        )
        self.assertGreater(
            noyau_profondeur_canonique_poids((0, -2, 2), (2, -2, 3)),
            noyau_profondeur_canonique_poids((0, -2, 2), (0, -4, 3)),
        )
        self.assertEqual(noyau_profondeur_canonique_poids((2, 0, 2), (2, 2, 3)), 0)
        self.assertEqual(noyau_profondeur_canonique_poids((2, 0, 2), (2, -2, 3)), 0)
        self.assertEqual(noyau_profondeur_canonique_poids((0, 2, 2), (2, 2, 3)), 0)
        self.assertEqual(noyau_profondeur_canonique_poids((0, 2, 2), (-2, 2, 3)), 0)
        # Brisure explicite de l'équivariance dynamique sous l'antagoniste statique
        ant_p = antagoniste_noyau(-2, 0, 2)
        ant_q = antagoniste_noyau(-2, 2, 3)
        self.assertNotEqual(
            noyau_profondeur_canonique_poids((-2, 0, 2), (-2, 2, 3)),
            noyau_profondeur_canonique_poids(ant_p, ant_q),
        )

    def test_ergodicite_et_contre_exemples_eps_1(self) -> None:
        rep_ok = MoteurPredictifCartograffect(ParametresMoteur.homeostasique(epsilon=0.15)).analyser_dynamique()
        self.assertTrue(rep_ok.ergodique_global)
        self.assertEqual(rep_ok.rang_systeme_stationnaire, 9)
        self.assertEqual(rep_ok.nb_eigs_unitaires, 1)
        self.assertGreater(min(rep_ok.distribution_stationnaire.values()), 0.0)

        rep_eps1 = MoteurPredictifCartograffect(ParametresMoteur.homeostasique(epsilon=1.0)).analyser_dynamique()
        self.assertFalse(rep_eps1.ergodique_global)
        self.assertEqual(rep_eps1.indice_coherence_stationnaire, 0.0)

        p_sym_eps1 = ParametresMoteur(
            rho=0.50, kappa=0.50, delta_a=0.30, delta_c=0.30,
            gamma_a=0.70, gamma_c=0.70, epsilon=1.0, q_pos_a=0.35, q_pos_c=0.35, chi=0.25,
        )
        rep_sym_eps1 = MoteurPredictifCartograffect(p_sym_eps1).analyser_dynamique()
        self.assertTrue(rep_sym_eps1.ergodique_global)

        p_pass = ParametresMoteur(
            rho=0.50, kappa=0.50, delta_a=0.20, delta_c=0.20,
            gamma_a=0.50, gamma_c=0.50, epsilon=0.0, q_pos_a=0.0, q_pos_c=0.0, chi=0.0,
        )
        T_pass = MoteurPredictifCartograffect(p_pass).construire_matrice_transition()
        V_vec = np.array([potentiel_lyapunov(n.a, n.c) for n in CATALOGUE_ETATS], dtype=float)
        idx_peur = INDEX_PAR_AC[(-1, 0)]
        derive_peur = float(V_vec[idx_peur] - (T_pass[idx_peur] @ V_vec))
        self.assertAlmostEqual(derive_peur, 0.50 + 2 * 0.20, places=12)


class TestCircuitCirculaireEtCanalAutonome1A(unittest.TestCase):
    def test_point_fixe_veille_et_decouplage_canal_autonome_1a(self) -> None:
        circuit = CircuitCirculaireCartograffect()

        veille = EtatCircuitCirculaire.veille_basale()
        tr_v = circuit.executer_cycle_6_operations(veille, t=0)
        self.assertEqual(tr_v.coord_noyau_affectif, (0, 0, 0))
        self.assertEqual(tr_v.etat_suivant, veille)

        # Option 1A : deux états identiques sur (A, C, Z) mais d'activation autonome A distincte
        # projettent exactement sur la même coordonnée (X, Y, Z) tout en préservant leur canal A >= 0.
        base_kwargs = dict(
            subjectif_cache=EtatsCachesSubjectifs(ecart_modele=2, revisable=False, suspension_descendante=True),
            perceptif_cache=EtatsCachesPerceptifs(ecart_afferent=2, controlable=False),
            corps_env=EtatCorpsEnvironnement(perturbation_exogene=0),
            attention=InterfaceAttentionnelle(precision_allouee=2, seuil_engagement=1, profondeur_persistance=1, precision_a=1, precision_c=3),
        )
        etat_angoisse_a_haut = EtatCircuitCirculaire(**base_kwargs, activation_autonome=0.92)
        etat_desespoir_a_bas = EtatCircuitCirculaire(**base_kwargs, activation_autonome=0.12)

        tr_haut = circuit.executer_cycle_6_operations(etat_angoisse_a_haut)
        tr_bas = circuit.executer_cycle_6_operations(etat_desespoir_a_bas)
        self.assertEqual(tr_haut.coord_noyau_affectif, (-1, -3, 3))
        self.assertEqual(tr_bas.coord_noyau_affectif, (-1, -3, 3))
        p_haut = CircuitCirculaireCartograffect.vers_coordonnees_cartograffect(tr_haut)
        p_bas = CircuitCirculaireCartograffect.vers_coordonnees_cartograffect(tr_bas)
        self.assertEqual(p_haut["coordonnees_noyau"], p_bas["coordonnees_noyau"])
        self.assertAlmostEqual(p_haut["activation_autonome"], 0.92)
        self.assertAlmostEqual(p_bas["activation_autonome"], 0.12)

        with self.assertRaises(ValueError):
            EtatCircuitCirculaire(**base_kwargs, activation_autonome=-0.1)


class TestLoiUnifieeEtPasAPasOption2a(unittest.TestCase):
    def test_z_max_5_par_defaut_et_pas_a_pas_strict_2a(self) -> None:
        sim = SimulateurUnifieCartograffect()
        self.assertEqual(sim.params_loi.z_max, 5)

        e = EtatLoiUnifiee(ac=(-1, -1), r_accumulateur=0.0, z_strate=0, rho_hat=0.5, kappa_hat=0.5)
        traces = sim.simuler_sequence(e, [(-1, -1)] * 40, maj_efficacites=False)
        for tr in traces:
            self.assertLessEqual(tr.r_suivant, sim.params_loi.borne_accumulateur + 1e-12)
            self.assertTrue(est_valide_noyau_affectif(*tr.coord_noyau_suivante))
            self.assertTrue(est_transition_verticale_valide_2a(tr.z_precedent, tr.z_suivant))
        self.assertEqual(traces[-1].z_suivant, 5)

        # Court-circuit descendant unique 2 -> 0 (sans passage par Surprise Z = 1)
        self.assertEqual(mettre_a_jour_strate_r5(2, 0.0), 0)
        self.assertEqual(mettre_a_jour_strate_r5(1, 0.0), 0)
        self.assertEqual(mettre_a_jour_strate_r5(3, 0.0), 2)
        self.assertTrue(est_transition_verticale_valide_2a(2, 0))
        self.assertFalse(est_transition_verticale_valide_2a(2, 1))
        self.assertFalse(est_transition_verticale_valide_2a(0, 5))
        self.assertFalse(est_transition_verticale_valide_2a(5, 2))

    def test_assemblage_reponses_isolees_rejette_sauts_directs_2a(self) -> None:
        with self.assertRaises(ValueError):
            DomainePossiblesAttentionnel(0, 0, 0)
        # Saut direct 0 -> 5 ou 1 -> 5 interdit par Option 2a
        with self.assertRaises(ValueError):
            assembler_reponses_isolees(
                ReponseIsoleeCircuit("A", -1),
                ReponseIsoleeCircuit("C", +1),
                z_precedent=0,
                z_cible=5,
            )
        with self.assertRaises(ValueError):
            assembler_reponses_isolees(
                ReponseIsoleeCircuit("A", -1),
                ReponseIsoleeCircuit("C", +1),
                z_precedent=2,
                z_cible=1,
            )

        # Cascade séquentielle rapide 0 -> 1 -> 2 -> 3 -> 4 -> 5 autorisée pas-à-pas
        z_prev = 0
        for z_step in (1, 2, 3, 4, 5):
            asm = assembler_reponses_isolees(
                ReponseIsoleeCircuit("A", -1),
                ReponseIsoleeCircuit("C", +1),
                z_precedent=z_prev,
                z_cible=z_step,
                pi_a=1,
                pi_c=3,
            )
            self.assertEqual(asm.z_courant, z_step)
            payload = asm.vers_export_octaedrique()
            self.assertTrue(payload["valide_noyau_affectif"])
            self.assertTrue(payload["transition_2a_valide"])
            self.assertIn("in R_+^2", payload["typage_bayesien_v3"])
            z_prev = z_step

    def test_reduction_information_et_diagnostic_ruptures(self) -> None:
        h_p, h_r, dh = calculer_reduction_information([1.0 / 9.0] * 9)
        self.assertAlmostEqual(h_p, np.log2(9.0), places=10)
        self.assertEqual(h_r, 0.0)
        self.assertAlmostEqual(dh, np.log2(9.0), places=10)
        self.assertEqual(entropie_shannon_bits([1.0, 0.0, 0.0]), 0.0)

        diag_sain = MoteurPredictifCartograffect(
            ParametresMoteur.homeostasique(epsilon=0.05)
        ).diagnostiquer_ruptures_ergodicite()
        self.assertIsInstance(diag_sain, DiagnosticRupturesErgodicite)
        self.assertTrue(diag_sain.est_ergodique_sain)


class TestContingencesZ2EtSeparationRMoinsPavlovien(unittest.TestCase):
    def test_distinction_r_moins_actif_vs_securite_pavlovienne_et_borne_z2(self) -> None:
        # 1. R+ et R- opérant actif exigent tous deux Y > 0 et siègent en (+1, +1, 2) [Désir]
        r_plus = mode_renforcement_actif_vers_regime("positiveAddition")
        r_moins_operant = mode_renforcement_actif_vers_regime("negativeEscapeAvoidance")
        self.assertEqual(r_plus, RegimeContingenceZ2("activeOperantReinforcement"))
        self.assertEqual(r_moins_operant, RegimeContingenceZ2("activeOperantReinforcement"))
        self.assertEqual(r_moins_operant.agentivite_instrumentale, "activeOperant")

        reg_desir = contingence_diagonale_z2(1, 1, 2)
        reg_calme = contingence_diagonale_z2(1, -1, 2)
        self.assertEqual(reg_desir, r_moins_operant)
        # 2. Calme (+1, -1, 2) = sécurité pavlovienne passive / accommodation (Y < 0), distinct de R-
        self.assertEqual(reg_calme, RegimeContingenceZ2("pavlovianPassiveSafety"))
        assert reg_calme is not None
        self.assertEqual(reg_calme.issue_adaptative, "favorable")
        self.assertEqual(reg_calme.agentivite_instrumentale, "nonOperantAccommodation")
        self.assertNotEqual(reg_calme, r_moins_operant)

        # 3. Aucun relèvement universel sur Z != 2 (notamment Z = 3..7)
        for a in ORDRE_ATTENTE:
            for c in ORDRE_CONTROLE:
                expected_z2 = contingence_couplage_z2(a, c)
                for pa, pc in ((1, 1), (1, 3), (3, 1)):
                    pt2 = projeter_noyau_affectif(a, c, 2, pi_a=pa, pi_c=pc, suspension_descendante=True)
                    self.assertEqual(contingence_diagonale_z2(*pt2), expected_z2)
                    for z_hors in (0, 1, 3, 4, 5, 6, 7):
                        ptz = projeter_noyau_affectif(a, c, z_hors, pi_a=pa, pi_c=pc, suspension_descendante=True)
                        self.assertIsNone(contingence_diagonale_z2(*ptz))


if __name__ == "__main__":
    unittest.main()
