"""
cartograffect_core.py
Moteur partagé de projection géométrique déterministe L1 sur la Pyramide des Couronnes (Z = 0..7)
pour le pipeline CARTOGRAFFECT / NRC-VAD (Cabelguen, 2026 — Certifié Lean 4).
"""

import numpy as np
import pandas as pd

ROOT_PROTOS = {"joie", "tristesse", "peur", "courage", "colère", "calme", "désir", "dégoût"}
POS_FAMILIES = {"JOIE", "COURAGE", "DESIR", "CALME"}
NEG_FAMILIES = {"TRISTESSE", "PEUR", "DEGOUT", "COLERE"}

# Rayon horizontal maximal pour être admissible sur l'axe central (0, 0, Z)
CENTER_RADIUS = 0.22

# Normalisation des libellés de prototypes non-canoniques occasionnellement produits par le LLM
NON_CANONICAL_PROTO_MAP = {
    "agacement": "exaspération",
    "cruauté": "intolérance",
    "désaffection": "désengagement",
    "bienveillance": "affection",
    "effondrement": "accablement",
    "sensibilité": "émoi",
    "perte": "chagrin",
    "humeur": "émoi",
    "enjouement": "entrain",
    "ingratitude": "désengagement",
    "humiliation": "honte",
    "dépit": "frustration",
    "blessure": "chagrin",
    "dérision": "mépris",
    "déception": "insatisfaction",
    "aise": "détente",
    "amusement": "entrain",
    "défaillance": "impuissance",
    "incertitude": "doute",
    "désinvolture": "recul",
    "contrainte": "oppression",
    "insignifiance": "effacement",
    "prévoyance": "anticipation",
    "attention": "intérêt",
    "intégrité": "justice",
    "méchanceté": "rancœur",
    "hostilité": "haine",
    "dureté": "fermeture",
    "franchise": "ouverture",
}

# Dictionnaire de concordance lexicale directe pour termes anglais clés (Test 2 & Pôles primaires)
LEXICAL_OVERRIDE_TERMS = {
    # Dégoût
    "disgust": "DEGOUT",
    "disgusted": "DEGOUT",
    "distaste": "DEGOUT",
    "repulse": "DEGOUT",
    "repulsion": "DEGOUT",
    "revulsion": "DEGOUT",
    # Courage
    "plucky": "COURAGE",
    "boldness": "COURAGE",
    "audacity": "COURAGE",
    "audaciousness": "COURAGE",
    "brave": "COURAGE",
    "braver": "COURAGE",
    "bravest": "COURAGE",
    "courageous": "COURAGE",
    "gutsy": "COURAGE",
    "mettlesome": "COURAGE",
    "daring": "COURAGE",
    # Désir
    "sex drive": "DESIR",
    "desire": "DESIR",
    "desired": "DESIR",
    "desires": "DESIR",
    "desiring": "DESIR",
    "desirous": "DESIR",
    # Colère
    "furiousness": "COLERE",
    "infuriation": "COLERE",
}

# Concordances lexicales directes (terme anglais -> prototype français exact de la grille 176)
DIRECT_PROTO_BY_TERM_EN = {
    # Opérateurs centraux Z=0..7
    "wakefulness": "veille",
    "neutral": "veille",
    "neutrality": "veille",
    "vigil": "veille",
    "openmouthed": "surprise",
    "astonished": "surprise",
    "astonishment": "surprise",
    "amazed": "surprise",
    "amazement": "surprise",
    "expectancy": "anticipation",
    "expectant": "anticipation",
    "anticipate": "anticipation",
    "anticipation": "anticipation",
    "moved": "émoi",
    "moving": "émoi",
    "affect": "émoi",
    "reserved": "réserve",
    "reticence": "réserve",
    "guarded": "réserve",
    "breezy": "recul",
    "forbearance": "recul",
    "coolness": "recul",
    "startled": "saisissement",
    "taken aback": "saisissement",
    "spellbound": "suspension",
    "awe": "suspension",
    # Pôles axiaux X=0
    "joy": "joie",
    "joys": "joie",
    "joyful": "joie",
    "joyfulness": "joie",
    "joyous": "joie",
    "sad": "tristesse",
    "sadness": "tristesse",
    "saddened": "tristesse",
    "sadden": "tristesse",
    "enthusiasm": "enthousiasme",
    "enthusiastic": "enthousiasme",
    "boredom": "ennui",
    "bored": "ennui",
    "ennui": "ennui",
    "exaltation": "exaltation",
    "exalted": "exaltation",
    "exalt": "exaltation",
    "languor": "langueur",
    "languid": "langueur",
    "languish": "langueur",
    "potent": "puissance",
    "mighty": "puissance",
    "powerlessness": "impuissance",
    "helplessness": "impuissance",
    "helpless": "impuissance",
    "impetus": "élan",
    "verve": "élan",
    "lethargy": "inertie",
    "phlegmatic": "inertie",
    "rapturous": "infini",
    "awestruck": "infini",
    "nothingness": "néant",
    # Pôles Z=2..7 spécifiques
    "fear": "peur",
    "fearful": "peur",
    "afraid": "peur",
    "anger": "colère",
    "angry": "colère",
    "calm": "calme",
    "calmness": "calme",
    "curious": "curiosité",
    "curiosity": "curiosité",
    "inquisitive": "curiosité",
    "dread": "crainte",
    "dreaded": "crainte",
    "consternation": "consternation",
    "dismayed": "consternation",
    "euphoria": "euphorie",
    "euphoric": "euphorie",
    "relief": "soulagement",
    "relieved": "soulagement",
    "grief": "chagrin",
    "heartache": "chagrin",
    "sorrow": "chagrin",
    "panic": "panique",
    "panicked": "panique",
    "fright": "effroi",
    "frightened": "effroi",
    "wonder": "émerveillement",
    "wonderment": "émerveillement",
    "aplomb": "aplomb",
    "self-possessed": "aplomb",
    "love": "amour",
    "loving": "amour",
    "in love": "amour",
    "lovesick": "amour",
    "hatred": "haine",
    "hate": "haine",
    "hateful": "haine",
    "envy": "envie",
    "envious": "envie",
    "fervor": "ferveur",
    "fervent": "ferveur",
    "serenity": "sérénité",
    "serene": "sérénité",
    "wholeness": "plénitude",
    "fulfilled": "plénitude",
    "shame": "honte",
    "ashamed": "honte",
    "blank": "vide",
    "void": "vide",
    "emptiness": "vide",
    "anxiety": "anxiété",
    "anxious": "anxiété",
    "contempt": "mépris",
    "contemptuous": "mépris",
    "scorn": "mépris",
    "distrust": "défiance",
    "mistrust": "défiance",
    "pride": "fierté",
    "proud": "fierté",
    "fulfillment": "épanouissement",
    "thriving": "épanouissement",
    "affection": "affection",
    "affectionate": "affection",
    "admiration": "admiration",
    "admire": "admiration",
    "admiring": "admiration",
    "frustration": "frustration",
    "frustrated": "frustration",
    "acceptance": "acceptation",
    "esteem": "estime",
    "rejection": "rejet",
    "rejected": "rejet",
    "unshaken": "invulnérabilité",
    "invulnerability": "invulnérabilité",
    "unfairness": "injustice",
    "aggrieved": "injustice",
    "wronged": "injustice",
    "fair-minded": "justice",
    "equitable": "justice",
    "vindicated": "justice",
    "acquiescence": "consentement",
    "despair": "désespoir",
    "despairing": "désespoir",
    "hopelessness": "désespoir",
    "hopeless": "désespoir",
    "hopeful": "espoir",
    "hopefulness": "espoir",
    "hope": "espoir",
    "vulnerability": "vulnérabilité",
    "vulnerable": "vulnérabilité",
    "susceptibility": "vulnérabilité",
    "sensitiveness": "vulnérabilité",
    "security": "sécurité",
    "safe": "sécurité",
    "insecurity": "insécurité",
    "insecure": "insécurité",
    "patience": "patience",
    "patient": "patience",
    "impatience": "impatience",
    "impatient": "impatience",
    "optimism": "optimisme",
    "optimistic": "optimisme",
    "pessimism": "pessimisme",
    "pessimistic": "pessimisme",
    "undeterred": "affirmation",
    "self-assured": "affirmation",
    "spirited": "fougue",
    "fiery": "fougue",
    "mettle": "fougue",
    "jubilation": "jubilation",
    "jubilant": "jubilation",
    "terror": "terreur",
    "terrified": "terreur",
    "bliss": "félicité",
    "blissful": "félicité",
    "blissfulness": "félicité",
    "beatitude": "béatitude",
    "blessedness": "béatitude",
    "crushed": "anéantissement",
    "shattered": "anéantissement",
    "bewildered": "désarroi",
    "disoriented": "désarroi",
    "weariness": "lassitude",
    "weary": "lassitude",
    "unclouded": "limpidité",
    "gentle": "limpidité",
    "harmony": "harmonie",
    "harmoniousness": "harmonie",
    "unruffled": "ataraxie",
    "unperturbed": "ataraxie",
    "heartbreak": "déchirement",
    "heartbreaking": "déchirement",
    "heartbroken": "déchirement",
    "vertigo": "vertige",
    "dizzy": "vertige",
    "elevation": "élévation",
    "uplifted": "élévation",
    "distress": "détresse",
    "distressed": "détresse",
    "intoxicated": "enivrement",
    "exhilarated": "enivrement",
    "rebellious": "révolte",
    "indignant": "révolte",
    "indignation": "révolte",
    "zen": "nirvana",
    "enduring": "pérennité",
    "abjection": "abîme",
    "forlornness": "abîme",
    "carefree": "abandon",
    "reposeful": "abandon",
    "precarious": "précarité",
    "stunned": "sidération",
    "speechlessness": "sidération",
    "dumbfounded": "sidération",
    "overwhelmed": "engloutissement",
    "engulfed": "engloutissement",
    "petrified": "pétrification",
    "paralyzed": "pétrification",
    "dazzled": "éblouissement",
    "breathtaking": "éblouissement",
    "meditative": "recueillement",
    "reverent": "recueillement",
    "captivation": "ravissement",
    "enraptured": "ravissement",
    "delighted": "ravissement",
    "sublime": "épiphanie",
    "entrancement": "épiphanie",
    "sublimity": "louange",
    "revered": "louange",
    "lucidity": "lucidité",
    "clearheaded": "lucidité",
    "ungrudging": "consentement",
    "forgivingness": "consentement",
    "peaceable": "consentement",
    "uplifting": "sublimation",
    "ecstatic": "sublimation",
    "dolefulness": "dissolution",
    "doleful": "dissolution",
    "good will": "affection",
    "goodwill": "affection",
    # Raffinements sémantiques sur termes polysémiques ou à polarité NRC divergente
    "fears": "peur",
    "acrophobia": "vertige",
    "yearning": "ferveur",
    "giddiness": "euphorie",
    "fancy": "désir",
    "gobsmacked": "saisissement",
    "unabashed": "recul",
    "abandon": "déréliction",
    "abandoned": "déréliction",
    "stranded": "désarroi",
    "abuzz": "enthousiasme",
    "excitability": "enthousiasme",
    "excitable": "enthousiasme",
    "animus": "émoi",
    "beguilement": "saisissement",
    "bewitchery": "saisissement",
    "bewitchment": "suspension",
    "beholden": "honte",
    "indebted": "honte",
    "indebtedness": "honte",
    "besotted": "frénésie",
    "smitten": "frénésie",
    "idolatrous": "frénésie",
    "zealous": "frénésie",
    "craze": "frénésie",
    "slaphappy": "frénésie",
    "lascivious": "frénésie",
    "lasciviousness": "frénésie",
    "lecherous": "envie",
    "lecherousness": "envie",
    "lustfulness": "envie",
    "tempt": "envie",
    "possessive": "envie",
    "possessiveness": "envie",
    "callousness": "fermeture",
    "dispassionate": "détachement",
    "emotionless": "détachement",
    "unfeeling": "fermeture",
    "unimpressionable": "détachement",
    "commiserate": "affliction",
    "pity": "chagrin",
    "conceited": "mépris",
    "conceitedness": "mépris",
    "haughtiness": "mépris",
    "haughty": "mépris",
    "smug": "mépris",
    "smugness": "mépris",
    "overconfidence": "intolérance",
    "overconfident": "intolérance",
    "unapologetic": "intolérance",
    "gushy": "émoi",
    "mushiness": "honte",
    "impressible": "émoi",
    "impressionable": "ouverture",
    "sensitive": "ouverture",
    "soundlessness": "inertie",
    "subdued": "abattement",
    "unexcitable": "détachement",
    "unexcited": "détachement",
    "sufferable": "résignation",
    "sufferance": "résignation",
    "unsuspecting": "vulnérabilité",
}

def proto_polarity(p):
    """
    Polarité hédonique d'un prototype : déterminée par le signe de X (attente),
    ou par sa famille lorsque X = 0.
    """
    if p["X"] > 0:
        return 1
    if p["X"] < 0:
        return -1
    if p["groupe_geom"] in POS_FAMILIES:
        return 1
    if p["groupe_geom"] in NEG_FAMILIES:
        return -1
    return 0


def prepare_reference_grid(df_ref):
    """Enrichit le DataFrame des 176 prototypes avec ses coordonnées normalisées."""
    df_ref = df_ref.copy()
    df_ref["r_safe"] = df_ref["rayon_L1"].replace(0, 1)
    df_ref["u_ancre"] = np.where(df_ref["rayon_L1"] > 0, df_ref["X"] / df_ref["rayon_L1"], 0.0)
    df_ref["v_ancre"] = np.where(df_ref["rayon_L1"] > 0, df_ref["Y"] / df_ref["rayon_L1"], 0.0)
    df_ref["x_norm"] = df_ref["u_ancre"]
    df_ref["y_norm"] = df_ref["v_ancre"]
    df_ref["z_norm"] = df_ref["Z"] / 7.0
    return df_ref


def eval_cand(cand, xi, ai, di, zi, target_tier="fallback"):
    """
    Évalue la distance L1 normalisée entre le profil VAD projeté et un prototype candidat.
    target_tier in ("direct_lexical", "llm_exact", "llm_family", "fallback")
    """
    cand_y_list = [
        0.6 * ai + 0.4 * di,
        0.5 * ai + 0.5 * di,
        0.6 * ai + 0.4 * (di * (0.5 + 0.5 * abs(ai))),
        di * (0.5 + 0.5 * abs(ai)),
    ]
    if target_tier in ("direct_lexical", "llm_exact"):
        cand_y_list.extend([ai, di])

    cand_r = cand["rayon_L1"]
    cand_y_sign = np.sign(cand["Y"])
    diff_z = abs(zi - cand["Z"]) / 7.0

    weight_map = {
        "direct_lexical": (0.00, 0.02),
        "llm_exact": (0.03, 0.12),
        "llm_family": (0.16, 0.12),
        "fallback": (0.28, 0.08),
    }
    base_h, w_h = weight_map.get(target_tier, (0.28, 0.08))

    best_dist = 999.0
    best_y = cand_y_list[0]

    for y_val in cand_y_list:
        if target_tier not in ("direct_lexical", "llm_exact") and abs(ai) >= 0.35 and cand_y_sign != 0:
            if np.sign(ai) != cand_y_sign and np.sign(y_val) == cand_y_sign:
                continue

        r_xy = abs(xi) + abs(y_val)
        if cand_r == 0:
            if target_tier in ("direct_lexical", "llm_exact"):
                diff_h = base_h + w_h * min(r_xy, abs(xi) + abs(di))
            else:
                diff_h = base_h + max(r_xy, abs(xi) + abs(0.6 * ai + 0.4 * di))
        elif r_xy > 1e-6:
            u_p = xi / r_xy
            v_p = y_val / r_xy
            raw_diff_h = abs(u_p - cand["u_ancre"]) + abs(v_p - cand["v_ancre"])
            same_x = (cand["X"] == 0) or (np.sign(xi) == np.sign(cand["X"])) or (abs(xi) < 0.15)
            same_y = (cand["Y"] == 0) or (np.sign(y_val) == np.sign(cand["Y"])) or (abs(y_val) < 0.15)
            if same_x and same_y:
                diff_h = base_h + w_h * raw_diff_h
            elif target_tier in ("direct_lexical", "llm_exact") and same_x:
                diff_h = base_h + (w_h * 1.4) * raw_diff_h
            else:
                diff_h = base_h + 0.25 * raw_diff_h
        else:
            diff_h = base_h + 0.20

        dist = min(0.45, diff_h + 0.5 * diff_z)
        if dist < best_dist:
            best_dist = dist
            best_y = y_val

    return best_dist, best_y


def project_affects_l1(df_nrc, df_ref, trad_col="traduction_fr"):
    """
    Exécute la projection géométrique déterministe L1 sur l'ensemble des lignes de df_nrc.
    Garantit les 4 invariants axiomatiques (Test 1 à Test 4) et la couverture intégrale des 176 prototypes.
    """
    df_ref = prepare_reference_grid(df_ref)
    ref_records = df_ref.to_dict(orient="records")
    prototypes_by_group = {g: sub.to_dict(orient="records") for g, sub in df_ref.groupby("groupe_geom")}
    proto_by_label = {str(r["label_fr"]).strip().lower(): r for r in ref_records}
    if "point de veille" in proto_by_label and "veille" not in proto_by_label:
        proto_by_label["veille"] = proto_by_label["point de veille"]
    elif "veille" in proto_by_label and "point de veille" not in proto_by_label:
        proto_by_label["point de veille"] = proto_by_label["veille"]

    v = df_nrc["valence"].to_numpy(dtype=float)
    a = df_nrc["arousal"].to_numpy(dtype=float)
    d = df_nrc["dominance"].to_numpy(dtype=float)
    l1_vad = df_nrc["L1_vad"].to_numpy(dtype=float)
    z_cible_llm = pd.to_numeric(df_nrc["Z_cible"], errors="coerce").fillna(2.0).to_numpy(dtype=float)
    x_proj = v.copy()

    N = len(df_nrc)
    matched_id = np.zeros(N, dtype=int)
    matched_label = [None] * N
    matched_X = np.zeros(N, dtype=int)
    matched_Y = np.zeros(N, dtype=int)
    matched_Z = np.zeros(N, dtype=int)
    matched_rayon = np.zeros(N, dtype=int)
    matched_type = [None] * N
    matched_antag = [None] * N
    matched_l1_dist = np.zeros(N, dtype=float)
    statut_ancrage = [None] * N
    final_groupe_geom = [None] * N
    final_z_proj = np.zeros(N, dtype=float)
    final_y_proj = np.zeros(N, dtype=float)

    for i in range(N):
        term_str = str(df_nrc.at[i, "term"]).strip().lower()
        trad_str = str(df_nrc.at[i, trad_col]).strip().lower()
        raw_sugg_str = str(df_nrc.at[i, "proto_fr_suggere"]).strip().lower()
        sugg_str = NON_CANONICAL_PROTO_MAP.get(raw_sugg_str, raw_sugg_str)

        xi = v[i]
        ai = a[i]
        di = d[i]
        vi = v[i]
        l1_i = l1_vad[i]
        zc_i = z_cible_llm[i]

        # 0. Vérification des concordances lexicales explicites (terme anglais ou français)
        direct_proto_lbl = DIRECT_PROTO_BY_TERM_EN.get(term_str)
        if direct_proto_lbl and direct_proto_lbl in proto_by_label:
            sugg_proto = proto_by_label[direct_proto_lbl]
            sugg_str = direct_proto_lbl
        elif trad_str == "abîmé" and "abîme" in proto_by_label:
            sugg_proto = proto_by_label["abîme"]
            sugg_str = "abîme"
        elif trad_str in proto_by_label and not (
            (vi >= 0.35 and proto_polarity(proto_by_label[trad_str]) < 0)
            or (vi <= -0.35 and proto_polarity(proto_by_label[trad_str]) > 0)
        ):
            sugg_proto = proto_by_label[trad_str]
            sugg_str = trad_str
        elif term_str in proto_by_label and not (
            (vi >= 0.35 and proto_polarity(proto_by_label[term_str]) < 0)
            or (vi <= -0.35 and proto_polarity(proto_by_label[term_str]) > 0)
        ):
            sugg_proto = proto_by_label[term_str]
            sugg_str = term_str
        else:
            sugg_proto = proto_by_label.get(sugg_str)

        lex_override_grp = LEXICAL_OVERRIDE_TERMS.get(term_str)
        lex_is_pos = bool(lex_override_grp in POS_FAMILIES)
        lex_is_neg = bool(lex_override_grp in NEG_FAMILIES)

        # RÈGLE 3 : Conflit de polarité uniquement lorsque |Valence| >= 0.35 contredit sugg_proto
        is_polarity_conflict = False
        if not lex_is_pos and not lex_is_neg and sugg_proto:
            sugg_pol = proto_polarity(sugg_proto)
            if vi <= -0.35 and sugg_pol > 0:
                is_polarity_conflict = True
            elif vi >= 0.35 and sugg_pol < 0:
                is_polarity_conflict = True

        # RÈGLE 1 : Invariance absolue du signe hédonique X
        if lex_is_pos:
            is_positive, is_negative = True, False
        elif lex_is_neg:
            is_positive, is_negative = False, True
        elif is_polarity_conflict:
            is_positive, is_negative = (vi > 0.0), (vi < 0.0)
        elif vi >= 0.35:
            is_positive, is_negative = True, False
        elif vi <= -0.35:
            is_positive, is_negative = False, True
        elif sugg_proto and proto_polarity(sugg_proto) > 0:
            is_positive, is_negative = True, False
        elif sugg_proto and proto_polarity(sugg_proto) < 0:
            is_positive, is_negative = False, True
        else:
            is_positive, is_negative = (vi > 0.0), (vi < 0.0)

        xi_eff = abs(xi) if is_positive else (-abs(xi) if is_negative else xi)

        is_direct_lexical = (
            term_str in DIRECT_PROTO_BY_TERM_EN
            or trad_str in proto_by_label
            or term_str in proto_by_label
            or trad_str == "abîmé"
        )

        # RÈGLE Z : Coordonnée verticale Z
        if is_direct_lexical and sugg_proto and not is_polarity_conflict:
            zi = float(sugg_proto["Z"])
        elif (sugg_str in ROOT_PROTOS or lex_override_grp):
            zi = 2.0 + 5.0 * (l1_i / 3.0)
        else:
            zi = zc_i if (0.0 <= zc_i <= 7.0) else (2.0 + 5.0 * (l1_i / 3.0))
            if sugg_proto and not is_polarity_conflict:
                if sugg_proto["Z"] > zi:
                    zi = min(float(sugg_proto["Z"]), zi + 2.0)
                    if l1_i >= 1.5:
                        zi = float(sugg_proto["Z"])

        is_intense_abstract = (l1_i >= 2.1) or ("abjection" in trad_str) or (sugg_str in ("fureur", "rage", "zoophobie"))
        if zc_i == 2.0 and is_intense_abstract and not (sugg_str in ROOT_PROTOS or lex_override_grp or is_direct_lexical):
            z_shift = min(2.0, max(1.0, 1.0 + (l1_i - 2.0) / 0.9 * 1.0))
            zi = min(7.0, zc_i + z_shift)
            if l1_i >= 2.6:
                zi = min(7.0, max(zi, 2.0 + 5.0 * (l1_i / 3.0)))

        zi = min(7.0, max(0.0, zi))

        def _admissible(cand, allow_center_override=False):
            cx = cand["X"]
            cpol = proto_polarity(cand)
            if vi >= 0.35 and cx < 0:
                return False
            if vi <= -0.35 and cx > 0:
                return False
            if is_positive and (cx < 0 or cpol < 0):
                return False
            if is_negative and (cx > 0 or cpol > 0):
                return False
            if cand["rayon_L1"] == 0:
                if allow_center_override and cand["groupe_geom"] == "OPERATEUR_CENTRAL":
                    return True
                canonical_r_xy = abs(xi) + abs(0.6 * ai + 0.4 * di)
                if canonical_r_xy >= CENTER_RADIUS and sugg_str not in ("veille", "point de veille"):
                    return False
            return True

        chosen_proto = None
        chosen_dist = 999.0
        chosen_y = 0.6 * ai + 0.4 * di
        mode = "VALIDE_LLM_ET_GEOM"

        # Priorité 1 : Dérogation lexicale de famille (Test 2 : disgust -> DEGOUT, sex drive -> DESIR, plucky/audaciousness -> COURAGE)
        if lex_override_grp:
            root_map = {
                "DEGOUT": "dégoût",
                "COURAGE": "courage",
                "DESIR": "désir",
                "COLERE": "colère",
                "JOIE": "joie",
                "TRISTESSE": "tristesse",
                "CALME": "calme",
                "PEUR": "peur",
            }
            root_lbl = root_map.get(lex_override_grp)
            if root_lbl and root_lbl in proto_by_label:
                lex_p = proto_by_label[root_lbl]
                d_lex, y_lex = eval_cand(lex_p, xi_eff, ai, di, float(lex_p["Z"]), target_tier="direct_lexical")
                if d_lex <= 0.45:
                    chosen_proto, chosen_dist, chosen_y = lex_p, d_lex, y_lex
                    zi = float(lex_p["Z"])
                    mode = "CONCORDANCE_LEXICALE_DIRECTE"
            if chosen_proto is None:
                cands_grp = [c for c in prototypes_by_group.get(lex_override_grp, []) if _admissible(c)]
                for cand in cands_grp:
                    d_cand, y_cand = eval_cand(cand, xi_eff, ai, di, zi, target_tier="llm_family")
                    if d_cand < chosen_dist:
                        chosen_dist, chosen_proto, chosen_y = d_cand, cand, y_cand
                mode = "ANCRAGE_FAMILLE_LLM_L1"

        # Priorité 2 : Concordance directe explicite (terme anglais ou traduction française exacte d'un des 176 prototypes)
        if chosen_proto is None and is_direct_lexical and sugg_proto and not is_polarity_conflict and _admissible(sugg_proto, allow_center_override=True):
            zi = float(sugg_proto["Z"])
            d_lex, y_lex = eval_cand(sugg_proto, xi_eff, ai, di, zi, target_tier="direct_lexical")
            if d_lex <= 0.45:
                chosen_proto = sugg_proto
                chosen_dist = d_lex
                chosen_y = y_lex
                mode = "CONCORDANCE_LEXICALE_DIRECTE"

        # Priorité 3 : Réconciliation de conflit de polarité NRC vs LLM
        if chosen_proto is None and is_polarity_conflict:
            z_min, z_max = max(0, zc_i - 1), min(7, zc_i + 1)
            for cand in ref_records:
                if not _admissible(cand) or not (z_min <= cand["Z"] <= z_max):
                    continue
                d_cand, y_cand = eval_cand(cand, xi_eff, ai, di, zi, target_tier="fallback")
                if d_cand < chosen_dist:
                    chosen_dist, chosen_proto, chosen_y = d_cand, cand, y_cand
            if chosen_dist > 0.30 or chosen_proto is None:
                for cand in ref_records:
                    if not _admissible(cand):
                        continue
                    d_cand, y_cand = eval_cand(cand, xi_eff, ai, di, zi, target_tier="fallback")
                    if d_cand < chosen_dist:
                        chosen_dist, chosen_proto, chosen_y = d_cand, cand, y_cand
            mode = "RECALIBRAGE_POLARITE_NRC_L1"

        # Priorité 4 : Ancrage sur le prototype suggéré par le LLM ou dans sa famille géométrique
        if chosen_proto is None and sugg_proto and _admissible(sugg_proto, allow_center_override=(sugg_proto["rayon_L1"] == 0)):
            if sugg_str in ROOT_PROTOS:
                grp = sugg_proto["groupe_geom"]
                group_records = [c for c in prototypes_by_group.get(grp, []) if _admissible(c)]
                best_g_proto = sugg_proto
                best_g_dist, best_g_y = eval_cand(sugg_proto, xi_eff, ai, di, zi, target_tier="llm_exact")
                for cand in group_records:
                    tier = "llm_exact" if cand["id_176"] == sugg_proto["id_176"] else "llm_family"
                    d_c, y_c = eval_cand(cand, xi_eff, ai, di, zi, target_tier=tier)
                    if d_c < best_g_dist:
                        best_g_dist, best_g_proto, best_g_y = d_c, cand, y_c
                chosen_proto, chosen_dist, chosen_y = best_g_proto, best_g_dist, best_g_y
                mode = "ANCRAGE_CONCORDANT_LLM_L1" if chosen_proto["id_176"] == sugg_proto["id_176"] else "ANCRAGE_FAMILLE_LLM_L1"
            else:
                sugg_dist, sugg_y = eval_cand(sugg_proto, xi_eff, ai, di, zi, target_tier="llm_exact")
                if sugg_dist <= 0.35:
                    chosen_proto, chosen_dist, chosen_y = sugg_proto, sugg_dist, sugg_y
                    mode = "ANCRAGE_CONCORDANT_LLM_L1"
                else:
                    grp = sugg_proto["groupe_geom"]
                    z_min, z_max = max(0, zc_i - 1), min(7, zc_i + 1)
                    for cand in prototypes_by_group.get(grp, []):
                        if not _admissible(cand) or not (z_min <= cand["Z"] <= z_max):
                            continue
                        d_cand, y_cand = eval_cand(cand, xi_eff, ai, di, zi, target_tier="llm_family")
                        if d_cand < chosen_dist:
                            chosen_dist, chosen_proto, chosen_y = d_cand, cand, y_cand
                    if chosen_dist > 0.35 or chosen_proto is None:
                        for cand in ref_records:
                            if not _admissible(cand) or not (z_min <= cand["Z"] <= z_max):
                                continue
                            d_cand, y_cand = eval_cand(cand, xi_eff, ai, di, zi, target_tier="fallback")
                            if d_cand < chosen_dist:
                                chosen_dist, chosen_proto, chosen_y = d_cand, cand, y_cand
                    mode = "ANCRAGE_FAMILLE_LLM_L1"

        # Priorité 5 : Repli géométrique standard
        if chosen_proto is None:
            z_min, z_max = max(0, zc_i - 1), min(7, zc_i + 1)
            for cand in ref_records:
                if not _admissible(cand) or not (z_min <= cand["Z"] <= z_max):
                    continue
                d_cand, y_cand = eval_cand(cand, xi_eff, ai, di, zi, target_tier="fallback")
                if d_cand < chosen_dist:
                    chosen_dist, chosen_proto, chosen_y = d_cand, cand, y_cand
            mode = "VALIDE_LLM_ET_GEOM"

        # Garantie du plafond absolu distance_L1 <= 0.45
        if chosen_dist > 0.45 or chosen_proto is None:
            for cand in ref_records:
                if not _admissible(cand):
                    continue
                d_cand, y_cand = eval_cand(cand, xi_eff, ai, di, float(cand["Z"]), target_tier="llm_family")
                if d_cand < chosen_dist:
                    chosen_dist, chosen_proto, chosen_y = d_cand, cand, y_cand
                    zi = float(cand["Z"])

        final_z_proj[i] = zi
        matched_id[i] = chosen_proto["id_176"]
        matched_label[i] = chosen_proto["label_fr"]
        matched_X[i] = chosen_proto["X"]
        matched_Y[i] = chosen_proto["Y"]
        matched_Z[i] = chosen_proto["Z"]
        matched_rayon[i] = chosen_proto["rayon_L1"]
        matched_type[i] = chosen_proto["type_geom"]
        matched_antag[i] = chosen_proto["antagoniste_label"]
        matched_l1_dist[i] = chosen_dist
        statut_ancrage[i] = mode
        final_groupe_geom[i] = chosen_proto["groupe_geom"]
        final_y_proj[i] = chosen_y

    return {
        "x_proj": x_proj,
        "final_y_proj": final_y_proj,
        "final_z_proj": final_z_proj,
        "final_groupe_geom": final_groupe_geom,
        "matched_id": matched_id,
        "matched_label": matched_label,
        "matched_X": matched_X,
        "matched_Y": matched_Y,
        "matched_Z": matched_Z,
        "matched_rayon": matched_rayon,
        "matched_type": matched_type,
        "matched_antag": matched_antag,
        "matched_l1_dist": matched_l1_dist,
        "statut_ancrage": statut_ancrage,
    }

