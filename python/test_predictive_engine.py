"""
Suites de tests unitaires pour `cartograffect_predictive_engine.py`,
vérifiant l'isomorphisme exact avec `Cartograffect/PredictiveCircuit.lean`,
`Cartograffect/CoreAffect.lean` et `Cartograffect/AffectiveMatrix.lean`.
"""

import unittest
import numpy as np

from cartograffect_predictive_engine import (
    CATALOGUE_ETATS,
    INDEX_PAR_AC,
    ORDRE_ATTENTE,
    ORDRE_CONTROLE,
    AssemblageReponsesIsolees,
    CircuitCirculaireCartograffect,
    ContingenceOperante,
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
    ReponseIsoleeCircuit,
    RoleOperant,
    SimulateurUnifieCartograffect,
    antagoniste_noyau,
    assembler_reponses_isolees,
    budget_spatial,
    calculer_reduction_information,
    canaux_retour_croisement_ii,
    classifier_coherence,
    classifier_role_operant,
    compter_resolutions_actives,
    contingence_couplage,
    contingence_diagonale_z2,
    contingence_quadrant,
    entropie_shannon_bits,
    est_valide_noyau_affectif,
    mettre_a_jour_accumulateur,
    mettre_a_jour_strate_r5,
    partage_precision_logistique,
    poids_attentionnels_l1,
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

    def test_geometrie_noyau_affectif_et_suspension_r5(self) -> None:
        # Point de Veille vs Suspension descendante R5
        self.assertEqual(projeter_noyau_affectif(0, 0, 0, suspension_descendante=False), (0, 0, 0))
        self.assertEqual(projeter_noyau_affectif(0, 0, 2, suspension_descendante=False), (0, 0, 0))
        self.assertEqual(projeter_noyau_affectif(0, 0, 2, suspension_descendante=True), (0, 0, 2))
        self.assertEqual(projeter_noyau_affectif(0, 0, 5, suspension_descendante=True), (0, 0, 5))

        # Surprise Z=1
        self.assertEqual(projeter_noyau_affectif(-1, +1, 1), (0, 0, 1))

        # Couronne Z=2 et Z>=3 avec partage asymétrique (Consternation (-1, +3, 3) et Sidération (-9, +3, 7))
        for z in (0, 1, 2, 3, 5, 7):
            for a in ORDRE_ATTENTE:
                for c in ORDRE_CONTROLE:
                    for pa, pc in ((1, 1), (1, 3), (3, 1)):
                        pt = projeter_noyau_affectif(a, c, z, pi_a=pa, pi_c=pc, suspension_descendante=True)
                        self.assertTrue(est_valide_noyau_affectif(*pt))
                        ant = antagoniste_noyau(*pt)
                        self.assertTrue(est_valide_noyau_affectif(*ant))
                        self.assertEqual(antagoniste_noyau(*ant), pt)

        self.assertEqual(projeter_noyau_affectif(-1, +1, 3, pi_a=1, pi_c=3), (-1, 3, 3))
        self.assertEqual(antagoniste_noyau(-1, 3, 3), (3, -1, 3))
        self.assertEqual(projeter_noyau_affectif(-1, +1, 7, pi_a=9, pi_c=3), (-9, 3, 7))
        self.assertEqual(antagoniste_noyau(-9, 3, 7), (3, -9, 7))
        self.assertEqual(rayon_couronne(0), 0)
        self.assertEqual(rayon_couronne(1), 0)
        self.assertEqual(rayon_couronne(7), 12)
        self.assertEqual(repartir_rayon(0, 1, 5), (1, 1))
        self.assertFalse(est_valide_noyau_affectif(-1, 1, 0))


class TestMatriceMarkovEtSpectre(unittest.TestCase):
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

        # Monotonie stricte V(s_{t+1}) <= V(s_t) sur toute transition possible
        for i in range(9):
            for j in range(9):
                if T[i, j] > 0.0:
                    self.assertLessEqual(V[j], V[i])

        # Spectre exact = diagonale (T triangulaire inférieure dans l'ordre de V)
        eigs_sorted = np.sort(np.real(np.linalg.eigvals(T)))
        diag_sorted = np.sort(np.diag(T))
        self.assertTrue(np.allclose(eigs_sorted, diag_sorted, atol=1e-12))

        # Temps d'absorption exact tau(s) = V(s) / p
        rapport = moteur.analyser_dynamique()
        self.assertTrue(rapport.convergence_veille_garantie)
        for n in CATALOGUE_ETATS:
            cle = f"{n.code} {n.couplage_croisement_ii}"
            self.assertAlmostEqual(rapport.temps_absorption_moyens[cle], V[n.index] / p, places=4)

    def test_bifurcations_p2_et_acces_direct_decharge(self) -> None:
        moteur = MoteurPredictifCartograffect(ParametresMoteur.homeostasique(epsilon=0.05))
        T = moteur.construire_matrice_transition()

        idx_veille = INDEX_PAR_AC[(0, 0)]
        idx_joie = INDEX_PAR_AC[(0, +1)]
        idx_courage = INDEX_PAR_AC[(+1, 0)]
        idx_desir = INDEX_PAR_AC[(+1, +1)]
        idx_peur = INDEX_PAR_AC[(-1, 0)]
        idx_colere = INDEX_PAR_AC[(-1, +1)]
        idx_degout = INDEX_PAR_AC[(-1, -1)]

        # Accès direct depuis Veille vers Décharge
        self.assertGreater(T[idx_veille, idx_joie], 0.0)
        self.assertGreater(T[idx_veille, idx_courage], 0.0)
        self.assertGreater(T[idx_veille, idx_desir], 0.0)

        # Bifurcation P2 : Peur (-2, 0) -> Colère (-1, +1) et Dégoût (-1, -1)
        self.assertGreater(T[idx_peur, idx_colere], 0.0)
        self.assertGreater(T[idx_peur, idx_degout], 0.0)

        # P2 portée exclusivement par Charge (-1) : Joie (0, +2) garde chi inactif sur A (eps = epsilon)
        eps_joie_desir = T[idx_joie, idx_desir]
        moteur_sans_chi = MoteurPredictifCartograffect(ParametresMoteur.clivage_sous_couplage(epsilon=0.05))
        T0 = moteur_sans_chi.construire_matrice_transition()
        self.assertAlmostEqual(
            T0[idx_peur, idx_colere],
            (1.0 - 0.80) * 0.05 * 0.35,
            places=10,
        )
        self.assertAlmostEqual(T[idx_joie, idx_desir], T0[idx_joie, idx_desir] * 1.0 + 0.0, places=4)
        self.assertGreater(eps_joie_desir, 0.0)

    def test_ergodicite_et_contre_exemples_eps_1(self) -> None:
        # Régime ergodique global valide pour 0 < epsilon < 1
        rep_ok = MoteurPredictifCartograffect(ParametresMoteur.homeostasique(epsilon=0.15)).analyser_dynamique()
        self.assertTrue(rep_ok.ergodique_global)
        self.assertEqual(rep_ok.rang_systeme_stationnaire, 9)
        self.assertEqual(rep_ok.nb_eigs_unitaires, 1)
        self.assertGreater(min(rep_ok.distribution_stationnaire.values()), 0.0)

        # Contre-exemple 1 : epsilon = 1.0 -> Veille transitoire (pi*_1 = 0), pas ergodique global
        rep_eps1 = MoteurPredictifCartograffect(ParametresMoteur.homeostasique(epsilon=1.0)).analyser_dynamique()
        self.assertFalse(rep_eps1.ergodique_global)
        self.assertEqual(rep_eps1.indice_coherence_stationnaire, 0.0)

        # Contre-exemple 1bis : epsilon = 1.0 avec extinction passive asymétrique (delta_c = 0) -> saturé
        p_asym_sat = ParametresMoteur(
            rho=0.50, kappa=0.50, delta_a=0.30, delta_c=0.0,
            gamma_a=0.70, gamma_c=0.70, epsilon=1.0, q_pos_a=0.35, q_pos_c=0.35, chi=0.25,
        )
        rep_asym_sat = MoteurPredictifCartograffect(p_asym_sat).analyser_dynamique()
        self.assertFalse(rep_asym_sat.ergodique_global)
        self.assertEqual(rep_asym_sat.indice_coherence_stationnaire, 0.0)
        self.assertIn("Régime saturé", rep_asym_sat.diagnostic_regime)

        # Cas bord : epsilon = 1.0 avec extinction passive bilatérale (delta_a, delta_c > 0) -> ergodique
        p_sym_eps1 = ParametresMoteur(
            rho=0.50, kappa=0.50, delta_a=0.30, delta_c=0.30,
            gamma_a=0.70, gamma_c=0.70, epsilon=1.0, q_pos_a=0.35, q_pos_c=0.35, chi=0.25,
        )
        rep_sym_eps1 = MoteurPredictifCartograffect(p_sym_eps1).analyser_dynamique()
        self.assertTrue(rep_sym_eps1.ergodique_global)
        self.assertGreater(rep_sym_eps1.indice_coherence_stationnaire, 0.0)

        # Contre-exemple 2 : epsilon = 1.0, rho = kappa = 1.0, gain = 2.0 -> rang 8, périodique
        p_per = ParametresMoteur(rho=1.0, kappa=1.0, gamma_a=0.7, gamma_c=0.7, epsilon=1.0)
        rep_per = MoteurPredictifCartograffect(p_per).analyser_dynamique(gain_precision=2.0)
        self.assertFalse(rep_per.ergodique_global)
        self.assertTrue(rep_per.goulot_l1_sature)
        self.assertEqual(rep_per.rang_systeme_stationnaire, 8)
        self.assertGreater(rep_per.nb_eigs_unitaires, 1)

        # Axe (i) : Extinction passive -> accélération apparente rho + 2*delta_a en régime libre
        p_pass = ParametresMoteur(
            rho=0.50, kappa=0.50, delta_a=0.20, delta_c=0.20,
            gamma_a=0.50, gamma_c=0.50, epsilon=0.0, q_pos_a=0.0, q_pos_c=0.0, chi=0.0,
        )
        T_pass = MoteurPredictifCartograffect(p_pass).construire_matrice_transition()
        V_vec = np.array([potentiel_lyapunov(n.a, n.c) for n in CATALOGUE_ETATS], dtype=float)
        idx_peur = INDEX_PAR_AC[(-1, 0)]
        derive_peur = float(V_vec[idx_peur] - (T_pass[idx_peur] @ V_vec))
        self.assertAlmostEqual(derive_peur, 0.50 + 2 * 0.20, places=12)

        rep_pseudo = MoteurPredictifCartograffect(ParametresMoteur.extinction_passive()).analyser_dynamique()
        self.assertIn("Pseudo-veille instable", rep_pseudo.diagnostic_regime)

        # Axe (iii) : classes récurrentes fermées {s4, s5, s6} et surcharge allostatique
        T_rig_p2 = MoteurPredictifCartograffect(
            ParametresMoteur.rigidite_epistemique(epsilon=0.0, chi=0.25)
        ).construire_matrice_transition()
        indices_a_neg = [n.index for n in CATALOGUE_ETATS if n.a == -1]
        indices_a_nonneg = [n.index for n in CATALOGUE_ETATS if n.a != -1]
        self.assertAlmostEqual(float(T_rig_p2[np.ix_(indices_a_neg, indices_a_nonneg)].sum()), 0.0, places=12)
        self.assertGreater(float(T_rig_p2[INDEX_PAR_AC[(-1, 0)], INDEX_PAR_AC[(-1, -1)]]), 0.0)

        rep_surch = MoteurPredictifCartograffect(ParametresMoteur.surcharge_allostatique(0.90)).analyser_dynamique()
        self.assertLess(rep_surch.indice_coherence_stationnaire, 0.01)

    def test_denombrement_etats_absorbants_profils_bloques(self) -> None:
        rep_rig = MoteurPredictifCartograffect(ParametresMoteur.rigidite_epistemique(0.0)).analyser_dynamique()
        self.assertFalse(rep_rig.convergence_veille_garantie)
        self.assertEqual(len(rep_rig.etats_absorbants), 2)

        rep_imp = MoteurPredictifCartograffect(ParametresMoteur.impuissance_pragmatique(0.0)).analyser_dynamique()
        self.assertFalse(rep_imp.convergence_veille_garantie)
        self.assertEqual(len(rep_imp.etats_absorbants), 2)

        rep_dc0 = MoteurPredictifCartograffect(ParametresMoteur.impasse_double_charge(0.0)).analyser_dynamique()
        self.assertEqual(len(rep_dc0.etats_absorbants), 4)
        rep_dc1 = MoteurPredictifCartograffect(ParametresMoteur.impasse_double_charge(0.15)).analyser_dynamique()
        self.assertEqual(len(rep_dc1.etats_absorbants), 1)
        self.assertEqual(rep_dc1.etats_absorbants[0], "s5 [A-/C-]")

        rep_per0 = MoteurPredictifCartograffect(ParametresMoteur.perseveration(0.0)).analyser_dynamique()
        self.assertEqual(len(rep_per0.etats_absorbants), 4)
        rep_per1 = MoteurPredictifCartograffect(ParametresMoteur.perseveration(0.15)).analyser_dynamique()
        self.assertEqual(len(rep_per1.etats_absorbants), 0)


class TestCircuitCirculaire6Operations(unittest.TestCase):
    def test_point_fixe_veille_et_convergence_flexible(self) -> None:
        circuit = CircuitCirculaireCartograffect()

        # Veille basale = point fixe exact
        veille = EtatCircuitCirculaire.veille_basale()
        tr_v = circuit.executer_cycle_6_operations(veille, t=0)
        self.assertEqual(tr_v.coord_noyau_affectif, (0, 0, 0))
        self.assertEqual(tr_v.etat_suivant, veille)

        # Décroissance stricte jusqu'à Veille en régime flexible sans perturbation
        etat_init = EtatCircuitCirculaire(
            subjectif_cache=EtatsCachesSubjectifs(ecart_modele=2, revisable=True, suspension_descendante=True),
            perceptif_cache=EtatsCachesPerceptifs(ecart_afferent=3, controlable=True),
            corps_env=EtatCorpsEnvironnement(perturbation_exogene=0),
            attention=InterfaceAttentionnelle(precision_allouee=2, seuil_engagement=1, profondeur_persistance=1, precision_a=1, precision_c=3),
        )
        traces = circuit.simuler_circuit(etat_init, nb_cycles=5)
        ecart_prev = 5
        for tr in traces:
            payload = CircuitCirculaireCartograffect.vers_coordonnees_cartograffect(tr)
            self.assertTrue(payload["valide_noyau_affectif"])
            ecart_next = (
                tr.etat_suivant.subjectif_cache.ecart_modele
                + tr.etat_suivant.perceptif_cache.ecart_afferent
            )
            if ecart_prev > 0:
                self.assertLess(ecart_next, ecart_prev)
            ecart_prev = ecart_next
        self.assertEqual(traces[-1].coord_noyau_affectif, (0, 0, 0))
        self.assertEqual(classifier_coherence(0, 0), "equilibre_homeostatique")

    def test_hysteresis_maintien_sous_seuil_sensoriel(self) -> None:
        circuit = CircuitCirculaireCartograffect()
        # Fenêtre de rémanence : resorption=1 <= ecart=1 < sensoriel=3 -> reste mobilisé
        etat = EtatCircuitCirculaire(
            subjectif_cache=EtatsCachesSubjectifs(ecart_modele=1, revisable=False, suspension_descendante=False),
            perceptif_cache=EtatsCachesPerceptifs(ecart_afferent=1, controlable=False),
            corps_env=EtatCorpsEnvironnement(perturbation_exogene=0),
            seuil_sensoriel=3,
            seuil_resorption=1,
            attention=InterfaceAttentionnelle(precision_allouee=1, seuil_engagement=1),
        )
        tr = circuit.executer_cycle_6_operations(etat)
        self.assertEqual(tr.coord_noyau_affectif, (-1, -1, 2))
        self.assertEqual(tr.noeud_courant.coherence_interne_externe, "impasse_double_charge")

    def test_validation_entrees(self) -> None:
        with self.assertRaises(ValueError):
            ParametresMoteur(rho=1.2)
        with self.assertRaises(ValueError):
            ParametresMoteur(beta=0.7)
        with self.assertRaises(ValueError):
            EtatCircuitCirculaire(
                subjectif_cache=EtatsCachesSubjectifs(),
                perceptif_cache=EtatsCachesPerceptifs(),
                corps_env=EtatCorpsEnvironnement(),
                seuil_sensoriel=1,
                seuil_resorption=2,
            )
        moteur = MoteurPredictifCartograffect()
        with self.assertRaises(ValueError):
            moteur.construire_matrice_transition(gain_precision=0.0)
        pi_neg = np.array([1.2, -0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
        with self.assertRaises(ValueError):
            moteur.evoluer_distribution(pi_neg, nb_cycles=5)
        with self.assertRaises(ValueError):
            ParametresMoteur(rho=0.7, delta_a=0.4)
        with self.assertRaises(ValueError):
            ParametresLoiUnifiee(lam=1.0)


class TestLoiUnifieeAxesIV(unittest.TestCase):
    def test_accumulateur_positif_borne_et_resolution_vs_extinction(self) -> None:
        # Résolution active (-1 -> +1) donne relief -eta, extinction passive (-1 -> 0) donne 0
        self.assertEqual(compter_resolutions_actives((-1, 0), (+1, 0)), 1)
        self.assertEqual(compter_resolutions_actives((-1, 0), (0, 0)), 0)
        r_actif = mettre_a_jour_accumulateur(1.0, 0.5, 0.5, (-1, 0), (+1, 0), lam=0.8, eta=0.6)
        r_passif = mettre_a_jour_accumulateur(1.0, 0.5, 0.5, (-1, 0), (0, 0), lam=0.8, eta=0.6)
        self.assertLess(r_actif, r_passif)
        self.assertAlmostEqual(r_passif - r_actif, 0.6, places=12)

        # Positivité garantie malgré -eta élevé
        self.assertEqual(mettre_a_jour_accumulateur(0.0, 0.5, 0.5, (-1, -1), (+1, +1), lam=0.8, eta=5.0), 0.0)

        # Escalade Z=0 -> Z=7 sous Double Charge persistante et borne 1/(1-lambda)
        sim = SimulateurUnifieCartograffect()
        e = EtatLoiUnifiee(ac=(-1, -1), r_accumulateur=0.0, z_strate=0, rho_hat=0.5, kappa_hat=0.5)
        traces = sim.simuler_sequence(e, [(-1, -1)] * 60, maj_efficacites=False)
        for tr in traces:
            self.assertLessEqual(tr.r_suivant, sim.params_loi.borne_accumulateur + 1e-12)
            self.assertTrue(est_valide_noyau_affectif(*tr.coord_noyau_suivante))
        self.assertEqual(traces[-1].z_suivant, 7)

    def test_court_circuit_r5_descente_et_partage_logistique(self) -> None:
        # Hystérésis + R5 : depuis Z=2, redescente directe à 0 sans jamais passer par Surprise (1)
        self.assertEqual(mettre_a_jour_strate_r5(2, 0.0), 0)
        self.assertEqual(mettre_a_jour_strate_r5(1, 0.0), 0)
        self.assertEqual(mettre_a_jour_strate_r5(3, 0.0), 2)
        for z in range(2, 8):
            self.assertNotEqual(mettre_a_jour_strate_r5(z, 0.0), 1)

        # Loi logistique : annulation de alpha en Double Charge et antisymétrie exacte
        pa_dc1, pc_dc1 = partage_precision_logistique(0.7, 0.3, -1, -1, beta=2.0, alpha=0.8)
        pa_dc2, pc_dc2 = partage_precision_logistique(0.7, 0.3, -1, -1, beta=2.0, alpha=0.0)
        self.assertAlmostEqual(pa_dc1, pa_dc2, places=12)
        self.assertAlmostEqual(pa_dc1 + pc_dc1, 1.0, places=12)

        pa_flip, _ = partage_precision_logistique(0.3, 0.7, -1, -1, beta=2.0, alpha=0.8)
        self.assertAlmostEqual(pa_flip, pc_dc1, places=12)

        # Pont vers apportionRay : atteinte de Consternation (-1, 3, 3) sous Colère et monde malléable
        sim = SimulateurUnifieCartograffect()
        etat_col = EtatLoiUnifiee(
            ac=(-1, -1), r_accumulateur=1.5, z_strate=2, rho_hat=0.1, kappa_hat=0.9,
            suspension_descendante=True,
        )
        tr = sim.pas_unifie(etat_col, (-1, +1), maj_efficacites=False)
        self.assertEqual(tr.z_suivant, 3)
        self.assertEqual(tr.budget_z_suivant, budget_spatial(3))
        self.assertEqual(tr.coord_noyau_suivante, (-1, 3, 3))


class TestArbitragesA1A4EtRuptures(unittest.TestCase):
    def test_stochasticite_exacte_et_independance_p1_p2(self) -> None:
        profils = [
            ParametresMoteur.homeostasique(epsilon=0.05),
            ParametresMoteur.canonique_libre(0.8),
            ParametresMoteur.extinction_passive(delta=0.40, epsilon=0.15),
            ParametresMoteur.clivage_sous_couplage(epsilon=0.15),
            ParametresMoteur.contagion_sur_couplage(epsilon=0.15, chi=0.95),
            ParametresMoteur.surcharge_allostatique(epsilon=0.90),
        ]
        for params in profils:
            T = MoteurPredictifCartograffect(params).construire_matrice_transition()
            self.assertEqual(T.shape, (9, 9))
            self.assertTrue(np.all(T >= 0.0))
            self.assertTrue(np.allclose(T.sum(axis=1), 1.0, atol=1e-12))

        # Indépendance P1 / P2 :
        # - P1 fixe (w_X, w_Y) indépendamment de chi
        # - Sans P2 (chi = 0), la surprise sortante sur l'axe complémentaire ne dépend pas de l'état de Charge
        t_chi0 = MoteurPredictifCartograffect(
            ParametresMoteur(rho=0.8, kappa=0.8, epsilon=0.15, q_pos_a=0.35, q_pos_c=0.35, chi=0.0)
        ).construire_matrice_transition()
        t_chi_pos = MoteurPredictifCartograffect(
            ParametresMoteur(rho=0.8, kappa=0.8, epsilon=0.15, q_pos_a=0.35, q_pos_c=0.35, chi=0.60)
        ).construire_matrice_transition()

        # Depuis A0/C+ (pas de Charge), T reste strictement identique quand chi varie
        idx_joie = INDEX_PAR_AC[(0, +1)]
        self.assertTrue(np.allclose(t_chi0[idx_joie], t_chi_pos[idx_joie], atol=1e-12))
        # Depuis A-/C0 (Charge en A), seul C subit la contagion P2 (A reste soumis à w_X=1.0 -> rho)
        idx_peur = INDEX_PAR_AC[(-1, 0)]
        self.assertGreater(
            t_chi_pos[idx_peur, INDEX_PAR_AC[(-1, -1)]],
            t_chi0[idx_peur, INDEX_PAR_AC[(-1, -1)]],
        )

    def test_rejet_z0_dans_interface_attentionnelle_et_projection_directe_z(self) -> None:
        # Veille (0,0,0) siège exclusivement au Croisement I : Z=0 doit être rejeté dans l'Interface Attentionnelle
        with self.assertRaises(ValueError):
            DomainePossiblesAttentionnel(0, 0, 0)
        with self.assertRaises(ValueError):
            assembler_reponses_isolees(
                ReponseIsoleeCircuit("A", 0, z_projete=0),
                ReponseIsoleeCircuit("C", 0, z_projete=0),
            )

        # Projection directe de Z >= 1 (court-circuitage sans incrémentation séquentielle)
        asm_z1 = assembler_reponses_isolees(
            ReponseIsoleeCircuit("A", 0, z_projete=1),
            ReponseIsoleeCircuit("C", 0, z_projete=1),
        )
        self.assertEqual(asm_z1.domaine.notation_symbolique, "{0, 0, Z}")
        self.assertEqual(asm_z1.coord_octaedrique, (0, 0, 1))
        self.assertNotEqual(asm_z1.coord_octaedrique, (0, 0, 0))

        # Saut direct vers Z=5 en quadrant (-X, +Y, Z) avec partage asymétrique
        asm_z5 = assembler_reponses_isolees(
            ReponseIsoleeCircuit("A", -1, z_projete=5),
            ReponseIsoleeCircuit("C", +1, z_projete=3),
            pi_a=1,
            pi_c=3,
        )
        self.assertEqual(asm_z5.z_projete, 5)
        self.assertEqual(asm_z5.domaine.notation_symbolique, "{-X, +Y, Z}")
        self.assertEqual(asm_z5.domaine.base_projective_croisement_i, (-1, 1, 0))
        self.assertEqual(asm_z5.domaine.rayon_couronne, 8)
        self.assertEqual(abs(asm_z5.coord_octaedrique[0]) + abs(asm_z5.coord_octaedrique[1]), 8)
        self.assertEqual(asm_z5.coord_octaedrique[2], 5)
        payload = asm_z5.vers_export_octaedrique()
        self.assertTrue(payload["valide_noyau_affectif"])
        self.assertGreaterEqual(payload["delta_h_bits"], 0.0)

    def test_reduction_information_delta_h_non_negatif(self) -> None:
        # Sélection déterministe sur 9 possibles -> ΔH = log2(9) bits > 0
        h_p, h_r, dh = calculer_reduction_information([1.0 / 9.0] * 9)
        self.assertAlmostEqual(h_p, np.log2(9.0), places=10)
        self.assertEqual(h_r, 0.0)
        self.assertAlmostEqual(dh, np.log2(9.0), places=10)
        self.assertGreaterEqual(dh, 0.0)

        # Réduction partielle (de 8 états équiprobables vers 2 états équiprobables) -> ΔH = 2.0 bits
        h_p2, h_r2, dh2 = calculer_reduction_information([0.125] * 8, [0.5, 0.5])
        self.assertAlmostEqual(h_p2, 3.0, places=10)
        self.assertAlmostEqual(h_r2, 1.0, places=10)
        self.assertAlmostEqual(dh2, 2.0, places=10)

        # Entropie nulle -> ΔH = 0.0
        self.assertEqual(entropie_shannon_bits([1.0, 0.0, 0.0]), 0.0)
        with self.assertRaises(ValueError):
            calculer_reduction_information([1.0, 0.0], [0.5, 0.5])

    def test_diagnostic_automatique_5_ruptures_ergodicite(self) -> None:
        # 0. Régime sain ergodique : 0 rupture
        diag_sain = MoteurPredictifCartograffect(
            ParametresMoteur.homeostasique(epsilon=0.05)
        ).diagnostiquer_ruptures_ergodicite()
        self.assertIsInstance(diag_sain, DiagnosticRupturesErgodicite)
        self.assertTrue(diag_sain.est_ergodique_sain)
        self.assertEqual(diag_sain.ruptures_detectees, ())

        # 1. Rigidité épistémique (rho = 0)
        diag_rig = MoteurPredictifCartograffect(
            ParametresMoteur.rigidite_epistemique(epsilon=0.05, chi=0.25)
        ).diagnostiquer_ruptures_ergodicite()
        self.assertFalse(diag_rig.est_ergodique_sain)
        self.assertIn("rigidite_epistemique", diag_rig.ruptures_detectees)

        # 2. Impuissance pragmatique (kappa = 0)
        diag_imp = MoteurPredictifCartograffect(
            ParametresMoteur.impuissance_pragmatique(epsilon=0.05, chi=0.25)
        ).diagnostiquer_ruptures_ergodicite()
        self.assertFalse(diag_imp.est_ergodique_sain)
        self.assertIn("impuissance_pragmatique", diag_imp.ruptures_detectees)

        # 3. Persévération (gamma = 0)
        diag_per = MoteurPredictifCartograffect(
            ParametresMoteur.perseveration(epsilon=0.05, chi=0.25)
        ).diagnostiquer_ruptures_ergodicite()
        self.assertFalse(diag_per.est_ergodique_sain)
        self.assertIn("perseveration", diag_per.ruptures_detectees)

        # 4a. Clivage (chi -> 0)
        diag_cliv = MoteurPredictifCartograffect(
            ParametresMoteur.clivage_sous_couplage(epsilon=0.15)
        ).diagnostiquer_ruptures_ergodicite()
        self.assertFalse(diag_cliv.est_ergodique_sain)
        self.assertIn("clivage_contagion", diag_cliv.ruptures_detectees)
        self.assertEqual(diag_cliv.sous_type_clivage_contagion, "clivage")

        # 4b. Contagion (chi -> 1)
        diag_cont = MoteurPredictifCartograffect(
            ParametresMoteur.contagion_sur_couplage(epsilon=0.15, chi=0.95)
        ).diagnostiquer_ruptures_ergodicite()
        self.assertFalse(diag_cont.est_ergodique_sain)
        self.assertIn("clivage_contagion", diag_cont.ruptures_detectees)
        self.assertEqual(diag_cont.sous_type_clivage_contagion, "contagion")

        # 5. Surcharge allostatique (epsilon >> rho, kappa)
        diag_sur = MoteurPredictifCartograffect(
            ParametresMoteur.surcharge_allostatique(epsilon=0.90)
        ).diagnostiquer_ruptures_ergodicite()
        self.assertFalse(diag_sur.est_ergodique_sain)
        self.assertIn("surcharge_allostatique", diag_sur.ruptures_detectees)


class TestEndToEndBridgeOperant(unittest.TestCase):
    def test_circuit_coupling_operant_bridge_and_all_strata_invariance(self) -> None:
        # [1/10] circuit_coupling_operant_bridge : Z=2 et Z=d+2 >= 2
        for a in ORDRE_ATTENTE:
            for c in ORDRE_CONTROLE:
                expected = contingence_couplage(a, c)
                for susp in (False, True):
                    for pa, pc in ((1, 1), (1, 3), (3, 1)):
                        pt2 = projeter_noyau_affectif(a, c, 2, pi_a=pa, pi_c=pc, suspension_descendante=susp)
                        self.assertEqual(contingence_diagonale_z2(*pt2), expected)
                        for d in (0, 1, 3, 5):
                            ptz = projeter_noyau_affectif(a, c, d + 2, pi_a=pa, pi_c=pc, suspension_descendante=susp)
                            self.assertEqual(contingence_quadrant(ptz[0], ptz[1]), expected)

        # [4/10] & [5/10] operant_quadrant_lifting_all_strata & operant_antagonist_invariance_all_strata
        for z in range(2, 8):
            r = 2 * z - 2
            for ax in range(1, r):
                ay = r - ax
                for sx in (-1, +1):
                    for sy in (-1, +1):
                        x, y = sx * ax, sy * ay
                        c1 = contingence_quadrant(x, y)
                        self.assertIsNotNone(c1)
                        assert c1 is not None
                        self.assertEqual(c1.effect == "Reinforcement", x > 0)
                        self.assertEqual(c1.effect == "Punishment", x < 0)
                        self.assertEqual(c1.op == "Addition", x * y > 0)
                        self.assertEqual(c1.op == "Removal", x * y < 0)

                        ant_x, ant_y, _ = antagoniste_noyau(x, y, z)
                        c2 = contingence_quadrant(ant_x, ant_y)
                        self.assertIsNotNone(c2)
                        assert c2 is not None
                        self.assertNotEqual(c1.effect, c2.effect)
                        self.assertEqual(c1.op, c2.op)

    def test_p2_markov_contagion_and_z7_transcendental_lineages(self) -> None:
        # [3/10] p2_markov_contagion_enters_operant_punishment
        moteur = MoteurPredictifCartograffect(ParametresMoteur.homeostasique(epsilon=0.15))
        W = moteur.construire_noyau_entier(scale=100)
        idx_peur = INDEX_PAR_AC[(-1, 0)]
        idx_colere = INDEX_PAR_AC[(-1, +1)]
        idx_degout = INDEX_PAR_AC[(-1, -1)]
        self.assertGreater(int(W[idx_peur, idx_colere]), 0)
        self.assertGreater(int(W[idx_peur, idx_degout]), 0)
        self.assertIsNone(contingence_couplage(-1, 0))
        self.assertEqual(contingence_couplage(-1, +1), ContingenceOperante("Punishment", "Removal"))
        self.assertEqual(contingence_couplage(-1, -1), ContingenceOperante("Punishment", "Addition"))

        # [7/10] operant_lineages_reach_z7_transcendentals : Sublimation, Impassibilité, Dissolution, Rage
        self.assertEqual(
            classifier_role_operant(6, 6, 7),
            RoleOperant("pureOperant", None, ContingenceOperante("Reinforcement", "Addition")),
        )
        self.assertEqual(
            classifier_role_operant(6, -6, 7),
            RoleOperant("pureOperant", None, ContingenceOperante("Reinforcement", "Removal")),
        )
        self.assertEqual(
            classifier_role_operant(-6, -6, 7),
            RoleOperant("pureOperant", None, ContingenceOperante("Punishment", "Addition")),
        )
        self.assertEqual(
            classifier_role_operant(-6, 6, 7),
            RoleOperant("pureOperant", None, ContingenceOperante("Punishment", "Removal")),
        )
        self.assertEqual(
            classifier_role_operant(-1, 3, 3),
            RoleOperant("blendedLateral", "joie", ContingenceOperante("Punishment", "Removal")),
        )
        self.assertEqual(classifier_role_operant(-2, 0, 2), RoleOperant("preOperantAxial", "peur", None))
        self.assertEqual(classifier_role_operant(0, 0, 0), RoleOperant("centralOperator", None, None))


if __name__ == "__main__":
    unittest.main()
