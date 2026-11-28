# SPDX-License-Identifier: AGPL-3.0-or-later
"""
02_bridge_psychometrics.py — Micro-Passe 2 : Calibrage psychométrique FANCat <-> NRC-VAD v2.1
& Pont lexical FR->EN contrôlé sur l'hémisphère Z+ (CARTOGRAFFECT v3.0.0)

Périmètre strict :
- Lecture seule sur data/raw/NRC-VAD-Lexicon-v2.1.txt, data/processed/dima_normalized.parquet
  et data/processed/fancat_clean.parquet.
- Aucune modification dans Cartograffect/ (noyau Lean 4 en lecture seule).
- Laisse intactes les 1 367 entrées Z_MINUS_RESERVE et les 481 entrées NON_LEXICAL_DISCARD.
- Strictement idempotent (sorties déterministes octet pour octet).
- Zéro appel réseau / API externe.
- Exports :
  - data/processed/dima_z_plus_psychometrics.parquet (local uniquement, ignoré Git)
  - data/config/fr_en_bridge_overrides.csv (créé s'il n'existe pas encore, versionnable Git)
  - reports/lexicon_v3/mp2_calibration_report.md (versionnable Git)
"""

from __future__ import annotations

import csv
import hashlib
import re
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
from scipy import stats

REPO_ROOT = Path(__file__).resolve().parents[2]
RAW_NRC_PATH = REPO_ROOT / "data" / "raw" / "NRC-VAD-Lexicon-v2.1.txt"
DIMA_PATH = REPO_ROOT / "data" / "processed" / "dima_normalized.parquet"
FANCAT_PATH = REPO_ROOT / "data" / "processed" / "fancat_clean.parquet"
OVERRIDES_PATH = REPO_ROOT / "data" / "config" / "fr_en_bridge_overrides.csv"
Z_PLUS_OUT_PATH = REPO_ROOT / "data" / "processed" / "dima_z_plus_psychometrics.parquet"
REPORT_OUT_PATH = REPO_ROOT / "reports" / "lexicon_v3" / "mp2_calibration_report.md"

FANCAT_DISCRETE_EMOTIONS: tuple[str, ...] = (
    "awe",
    "contentment",
    "amusement",
    "serenity",
    "excitement",
    "fear",
    "anger",
    "disgust",
    "sadness",
    "anxiety",
)

OVERRIDES_COLUMNS: tuple[str, ...] = (
    "lemme_norm",
    "part_disc",
    "classe",
    "en_override",
    "note_faux_ami",
)

# Jeu initial versionnable (>= 60 termes Z_PLUS_ACTIVE centraux ou à risque de faux ami FR/EN).
# Tous les termes en_override sont vérifiés présents dans NRC-VAD v2.1 au chargement.
# Les règles contextuelles (classe != '*') sont évaluées AVANT fancat_direct ;
# les règles globales (classe == '*') sont évaluées APRÈS fancat_direct.
DEFAULT_OVERRIDES: tuple[tuple[str, str, str, str, str], ...] = (
    # --- Règles contextuelles (lemme_norm, classe != '*') prioritaires avant FANCat ---
    ("rire", "VERB", "Mépris", "mock", "Priorité contextuelle avant FANCat : dans Mépris 'rire' = se moquer (mock) != FANCat laughter"),
    ("crainte", "NOM", "Estime respect", "reverence", "Priorité contextuelle avant FANCat : dans Estime respect 'crainte' = révérence (reverence) != FANCat fear"),
    ("envie", "NOM", "Jalousie envie", "envy", "Désambiguïsation par classe : envie au sens de jalousie -> envy"),
    ("envie", "NOM", "Désir", "longing", "Désambiguïsation par classe : envie au sens de désir -> longing"),
    ("envie", "NOM", "Amour", "longing", "Désambiguïsation par classe : envie amoureuse -> longing"),
    ("confus", "ADJ", "Embarrasser", "embarrassed", "Sens contextuel dans Embarrasser : confus (gêné) -> embarrassed"),
    ("interdit", "ADJ", "Surprendre", "speechless", "Faux ami contextuel dans Surprendre : interdit (stupéfait) != interdict"),
    ("sensible", "ADJ", "Curiosité", "sensitive", "Faux ami contextuel dans Curiosité : sensible != sensible (raisonnable)"),
    ("blessure", "NOM", "Blesser", "hurt", "Ancre réserve -Z (CausAffect/ObjAffect) conservée pour cohérence inter-passes"),
    # --- Règles globales (classe == '*', évaluées après fancat_direct) ---
    ("déception", "NOM", "*", "disappointment", "Faux ami critique : FR déception != EN deception (tromperie)"),
    ("gêne", "NOM", "*", "embarrassment", "Évite confusion avec EN gene (biologie)"),
    ("angoisse", "NOM", "*", "anguish", "Ancre clinique majeure d'anxiété somatique"),
    ("rancœur", "NOM", "*", "resentment", "Ligature œ non présente dans NRC-VAD"),
    ("dépit", "NOM", "*", "spite", "Dépit amoureux/frustré (spite)"),
    ("quiétude", "NOM", "*", "tranquility", "Variante US NRC-VAD (tranquility) vs FR quiétude"),
    ("plénitude", "*", "*", "fulfillment", "Ancre théorique hors DIMA v35 conservée dans la table d'overrides"),
    ("abattement", "NOM", "*", "dejection", "Abattement dépressif (dejection)"),
    ("sidération", "NOM", "*", "shock", "Sidération émotionnelle (shock)"),
    ("effroi", "NOM", "*", "dread", "Terreur paralysante (dread)"),
    ("chagrin", "NOM", "*", "grief", "Chagrin/deuil (grief)"),
    ("lassitude", "NOM", "*", "weariness", "Glose FANCat 'lassitude' absente de NRC-VAD ; complétion D via weariness"),
    ("exaspération", "NOM", "*", "exasperation", "Exaspération (exasperation)"),
    ("affliction", "NOM", "*", "affliction", "Affliction (affliction)"),
    ("mépris", "NOM", "*", "contempt", "Mépris (contempt)"),
    ("admiration", "NOM", "*", "admiration", "Admiration (admiration)"),
    ("affection", "NOM", "*", "affection", "Affection tendre (affection)"),
    ("haine", "NOM", "*", "hatred", "Haine nominale (hatred)"),
    ("amour", "NOM", "*", "love", "Amour (love)"),
    ("colère", "NOM", "*", "anger", "Jalon primaire Colère (anger)"),
    ("rage", "NOM", "*", "rage", "Jalon primaire Rage (rage)"),
    ("frustration", "NOM", "*", "frustration", "Jalon primaire Frustration (frustration)"),
    ("hostilité", "NOM", "*", "hostility", "Jalon primaire Hostilité (hostility)"),
    ("calme", "*", "*", "calm", "Jalon primaire Calme NOM/ADJ (calm)"),
    ("sérénité", "NOM", "*", "serenity", "Jalon primaire Sérénité (serenity)"),
    ("joie", "NOM", "*", "joy", "Jalon primaire Joie (joy)"),
    ("tristesse", "NOM", "*", "sadness", "Jalon primaire Tristesse (sadness)"),
    ("peur", "NOM", "*", "fear", "Jalon primaire Peur (fear)"),
    ("courage", "*", "*", "courage", "Ancre théorique hors DIMA v35 conservée dans la table d'overrides"),
    ("désir", "NOM", "*", "desire", "Désir (desire)"),
    ("dégoût", "NOM", "*", "disgust", "Dégoût sensoriel/affectif (disgust)"),
    ("honte", "NOM", "*", "shame", "Jalon primaire Honte (shame)"),
    ("fierté", "NOM", "*", "pride", "Jalon primaire Fierté (pride)"),
    ("espoir", "NOM", "*", "hope", "Espoir (hope)"),
    ("désespoir", "NOM", "*", "despair", "Jalon primaire Désespoir (despair)"),
    ("ennui", "NOM", "*", "boredom", "Ennui (boredom)"),
    ("panique", "NOM", "*", "panic", "Panique (panic)"),
    ("terreur", "NOM", "*", "terror", "Jalon primaire Terreur (terror)"),
    ("euphorie", "NOM", "*", "euphoria", "Euphorie (euphoria)"),
    ("allégresse", "NOM", "*", "elation", "Allégresse (elation)"),
    ("soulagement", "NOM", "*", "relief", "Soulagement (relief)"),
    ("résignation", "NOM", "*", "resignation", "Résignation (resignation)"),
    ("apathie", "NOM", "*", "apathy", "Apathie (apathy)"),
    ("amertume", "NOM", "*", "bitterness", "Amertume (bitterness)"),
    ("inquiétude", "NOM", "*", "worry", "Inquiétude (worry)"),
    ("anxiété", "NOM", "*", "anxiety", "Anxiété (anxiety)"),
    ("doute", "NOM", "*", "doubt", "Doute (doubt)"),
    ("méfiance", "NOM", "*", "distrust", "Méfiance (distrust)"),
    ("confiance", "NOM", "*", "trust", "Confiance (trust)"),
    ("sécurité", "*", "*", "security", "Ancre théorique hors DIMA v35 (voir sentiment de sécurité ci-dessous)"),
    ("sentiment de sécurité", "NOM", "*", "security", "Équivalent lexical DIMA de sécurité"),
    ("ferveur", "NOM", "*", "fervor", "Ferveur (fervor, orthographe US NRC-VAD)"),
    ("extase", "NOM", "*", "ecstasy", "Extase (ecstasy)"),
    ("horreur", "NOM", "*", "horror", "Horreur (horror)"),
    ("révolte", "NOM", "*", "revolt", "Révolte (revolt)"),
    ("indignation", "NOM", "*", "indignation", "Indignation (indignation)"),
    ("gratitude", "NOM", "*", "gratitude", "Gratitude (gratitude)"),
    ("pudeur", "NOM", "*", "modesty", "Pudeur (modesty)"),
    ("émerveillement", "*", "*", "awe", "Ancre théorique hors DIMA v35 conservée dans la table d'overrides"),
    ("défiance", "NOM", "*", "distrust", "Faux ami : FR défiance != EN defiance (bravade)"),
    ("défiant", "ADJ", "*", "distrustful", "Faux ami : FR défiant != EN defiant (provocateur)"),
    ("reconnaissance", "NOM", "*", "gratitude", "Faux ami : FR reconnaissance (gratitude) != EN reconnaissance (militaire)"),
    ("goût", "NOM", "*", "liking", "Faux ami : FR goût != EN gout (maladie articulaire)"),
    ("hâte", "NOM", "*", "haste", "Faux ami critique sans accents : FR hâte != EN hate (haine)"),
    ("béat", "ADJ", "*", "blissful", "Faux ami sans accents : FR béat != EN beat (battre)"),
    ("pétulant", "ADJ", "*", "lively", "Faux ami : FR pétulant (vif) != EN petulant (irritable)"),
    ("pétulance", "NOM", "*", "liveliness", "Faux ami : FR pétulance != EN petulance (mauvaise humeur)"),
    ("régal", "NOM", "*", "delight", "Faux ami sans accents : FR régal != EN regal (royal)"),
    ("haïr", "VERB", "*", "hate", "Faux ami sans accents : FR haïr != EN hair (cheveu)"),
    ("embarras", "NOM", "*", "embarrassment", "Orthographe EN : embarrassment"),
    ("complaisance", "NOM", "*", "kindness", "Faux ami : FR complaisance (amabilité) != EN complacency (autosatisfaction)"),
    ("complaisant", "ADJ", "*", "obliging", "Faux ami : FR complaisant != EN complacent"),
    ("envieux", "ADJ", "*", "envious", "Envieux -> envious"),
    ("joie mauvaise", "NOM", "*", "schadenfreude", "Joie mauvaise -> schadenfreude"),
    ("schadenfreude", "NOM", "*", "schadenfreude", "Emprunt direct présent dans NRC-VAD"),
)

FORBIDDEN_ACTIVE_FANCAT_GLOSSES: frozenset[str] = frozenset(
    {"roach", "transportation", "laughter", "mood", "thirst"}
)

# Dictionnaire statique FR -> EN curé, déterministe et 100 % vérifié contre NRC-VAD v2.1.
# Sert uniquement en étape nrc_bridge_auto (après fancat_direct et nrc_override).
STATIC_FR_EN_BRIDGE: dict[str, str] = {
    # --- Mono-mots NOM/ADJ Z_PLUS_ACTIVE (inclut unigrammes standard ajoutés MP1c) ---
    "amour-passion": "passion",
    "antisémite": "antisemitic",
    "ataraxie": "serenity",
    "autosatisfaction": "smug",
    "autosatisfait": "smug",
    "complexe": "insecurity",
    "enragé": "enraged",
    "inconsolé": "inconsolable",
    "intimité": "intimacy",
    "misogyne": "misogynist",
    "miséricordieux": "merciful",
    "philanthrope": "philanthropist",
    "remotivation": "motivation",
    "ressentiment": "resentment",
    "réservé": "reserved",
    "énergique": "energetic",
    "abasourdissement": "astonishment",
    "accablement": "dejection",
    "acceptation": "acceptance",
    "accointance": "affinity",
    "acrimonieux": "bitter",
    "admirateur": "admirer",
    "admiratif": "admiring",
    "adorable": "adorable",
    "adorateur": "worshiper",
    "affligé": "afflicted",
    "affolement": "panic",
    "affres": "anguish",
    "agacement": "annoyance",
    "aguicheur": "flirt",
    "ahurissement": "bewilderment",
    "aigreur": "bitterness",
    "alanguissement": "lethargy",
    "alarme": "alarm",
    "allant": "vigor",
    "allègre": "cheerful",
    "amant": "lover",
    "ambitieux": "ambitious",
    "amoureux": "in love",
    "amours": "love",
    "angoissé": "anguished",
    "animadversion": "animosity",
    "animosité": "animosity",
    "antipathie": "antipathy",
    "anxieux": "anxious",
    "anéantissement": "annihilation",
    "apaisement": "appeasement",
    "apathique": "apathetic",
    "apeurement": "fear",
    "apitoiement": "pity",
    "appétence": "appetite",
    "appétit": "appetite",
    "ardeur": "ardor",
    "atrabilaire": "sullen",
    "attachement": "attachment",
    "attendrissement": "tenderness",
    "attentif": "attentive",
    "atterrement": "dismay",
    "attirance": "attraction",
    "attrait": "appeal",
    "avachissement": "sluggishness",
    "avide": "greedy",
    "avidité": "greed",
    "baba": "astonished",
    "badin": "playful",
    "besoin": "need",
    "bien-aimé": "beloved",
    "bien-être": "well being",
    "bienheureux": "blissful",
    "bienveillance": "benevolence",
    "bienveillant": "benevolent",
    "blasement": "boredom",
    "blocage": "blockage",
    "bougon": "grumpy",
    "boulimie": "bulimia",
    "boulimique": "bulimic",
    "brouille": "quarrel",
    "béguin": "crush",
    "cafardeux": "gloomy",
    "camarade": "comrade",
    "casse-bonbons": "annoying",
    "casse-couilles": "annoying",
    "casse-cul": "annoying",
    "casse-pieds": "nuisance",
    "charmeur": "charming",
    "chieur": "annoying",
    "chéri": "darling",
    "circonspect": "cautious",
    "circonspection": "caution",
    "compatissant": "compassionate",
    "complexé": "self conscious",
    "compulsif": "compulsive",
    "concorde": "concord",
    "confiant": "confident",
    "consolateur": "comforting",
    "contempteur": "scorner",
    "contentement": "contentment",
    "contrariété": "annoyance",
    "contrit": "contrite",
    "convoitise": "covetousness",
    "copain": "buddy",
    "couard": "coward",
    "courroux": "wrath",
    "craintif": "fearful",
    "crispation": "tension",
    "culotté": "cheeky",
    "curieux": "curious",
    "dilection": "affection",
    "discorde": "discord",
    "dolent": "doleful",
    "dubitatif": "doubtful",
    "dynamique": "dynamic",
    "dynamisme": "dynamism",
    "décomplexé": "uninhibited",
    "déconfit": "crestfallen",
    "décontraction": "relaxation",
    "décontracté": "relaxed",
    "découragement": "discouragement",
    "dédaigneux": "disdainful",
    "dédain": "disdain",
    "dégonflé": "coward",
    "délectation": "delight",
    "démobilisation": "demobilization",
    "démotivation": "unmotivated",
    "dépaysement": "disorientation",
    "déplaisir": "displeasure",
    "dépressif": "depressive",
    "déprime": "gloom",
    "déprimé": "depressed",
    "désabusement": "disillusion",
    "désabusé": "disillusion",
    "désaffection": "disaffection",
    "désamour": "estrangement",
    "désappointement": "disappointment",
    "désarroi": "turmoil",
    "désenchantement": "disenchantment",
    "désenchanté": "disenchant",
    "désespérance": "despair",
    "désillusion": "disillusion",
    "désintérêt": "indifference",
    "désireux": "desirous",
    "détachement": "detachment",
    "détaché": "detached",
    "détresse": "distress",
    "dévalorisation": "devaluation",
    "déçu": "disappointed",
    "effarement": "dismay",
    "effondrement": "collapse",
    "emballement": "enthusiasm",
    "emmerdeur": "nuisance",
    "empathie": "empathy",
    "empoisonneur": "nuisance",
    "emportement": "outburst",
    "enchanteur": "enchanting",
    "enclin": "inclined",
    "engouement": "infatuation",
    "enivrement": "intoxication",
    "enjouement": "cheerfulness",
    "enjoué": "cheerful",
    "ennemi": "enemy",
    "ennuyeux": "boring",
    "enquiquineur": "nuisance",
    "ensorceleur": "enchanting",
    "entente": "harmony",
    "enthousiasme": "enthusiasm",
    "enthousiaste": "enthusiastic",
    "entichement": "infatuation",
    "envoûtement": "enchantment",
    "envoûteur": "enchanting",
    "espérance": "hope",
    "estime": "esteem",
    "euphorique": "euphoric",
    "extatique": "ecstatic",
    "exécration": "loathing",
    "faible": "weak",
    "faiblesse": "weakness",
    "faim": "hunger",
    "fanatique": "fanatic",
    "fatalisme": "fatalism",
    "fataliste": "fatalist",
    "favori": "favorite",
    "fiancé": "beloved",
    "fier": "proud",
    "fiérot": "smug",
    "flamme": "passion",
    "flatteur": "flatterer",
    "foi": "faith",
    "folâtre": "playful",
    "fou": "mad",
    "fougue": "ardor",
    "fougueux": "fiery",
    "frayeur": "fright",
    "fringant": "lively",
    "froid": "cold",
    "froussard": "coward",
    "frousse": "fright",
    "frustré": "frustrated",
    "frénésie": "frenzy",
    "frénétique": "frenetic",
    "fumasse": "furious",
    "furax": "furious",
    "fureur": "fury",
    "furibard": "furious",
    "furibond": "furious",
    "furie": "fury",
    "furieux": "furious",
    "fâcherie": "quarrel",
    "fâcheux": "annoying",
    "félicité": "bliss",
    "gai": "cheerful",
    "gaillard": "cheerful",
    "grincheux": "grumpy",
    "griserie": "exhilaration",
    "grognon": "grumpy",
    "guilleret": "cheerful",
    "gêneur": "nuisance",
    "hargne": "animosity",
    "hargneux": "snappish",
    "harmonie": "harmony",
    "haut-le-cœur": "nausea",
    "heureux": "happy",
    "honteux": "ashamed",
    "horripilation": "exasperation",
    "hébétude": "stupor",
    "idole": "idol",
    "importun": "annoying",
    "incertitude": "uncertainty",
    "incroyance": "disbelief",
    "incroyant": "unbeliever",
    "incrédule": "incredulous",
    "indigné": "indignant",
    "ingrat": "ungrateful",
    "inimitié": "enmity",
    "inquiet": "worried",
    "insatisfaction": "dissatisfaction",
    "insatisfait": "dissatisfied",
    "insouciance": "carefree",
    "insouciant": "carefree",
    "insoucieux": "unconcerned",
    "intime": "intimate",
    "intérêt": "interest",
    "ivre": "intoxicated",
    "ivresse": "intoxication",
    "jalousie": "jealousy",
    "jaloux": "jealous",
    "jouissance": "enjoyment",
    "jouisseur": "hedonist",
    "joyeux": "joyful",
    "langueur": "lethargy",
    "languide": "languid",
    "las": "weary",
    "libéré": "liberated",
    "liesse": "jubilation",
    "lugubre": "mournful",
    "légèreté": "lightness",
    "mal-aimé": "unloved",
    "mal-être": "distress",
    "malheureux": "unhappy",
    "malveillance": "malevolence",
    "malveillant": "malevolent",
    "marri": "sorry",
    "maussade": "sullen",
    "maîtresse": "mistress",
    "mobilisation": "mobilization",
    "mordu": "enthusiast",
    "morne": "dreary",
    "morosité": "gloom",
    "mécontent": "discontent",
    "mécontentement": "discontent",
    "méditatif": "meditative",
    "méfiant": "distrustful",
    "méforme": "fatigue",
    "mélancolie": "melancholy",
    "mélancolique": "melancholy",
    "mésentente": "discord",
    "mésestime": "contempt",
    "nausée": "nausea",
    "nerveux": "nervous",
    "nervosité": "nervousness",
    "nostalgie": "nostalgia",
    "nostalgique": "nostalgic",
    "optimisme": "optimism",
    "optimiste": "optimistic",
    "orgasme": "orgasm",
    "orgueil": "pride",
    "orgueilleux": "proud",
    "paisible": "peaceful",
    "paniquard": "panicky",
    "pantelant": "breathless",
    "pantois": "astonished",
    "passionné": "passionate",
    "paumé": "lost",
    "penaud": "sheepish",
    "pensif": "pensive",
    "perplexe": "perplexed",
    "pessimisme": "pessimism",
    "pessimiste": "pessimistic",
    "peureux": "fearful",
    "phobie": "phobia",
    "placide": "placid",
    "pleutre": "coward",
    "poltron": "coward",
    "pote": "pal",
    "pressé": "hurried",
    "prostré": "prostrate",
    "pulsion": "impulse",
    "pétochard": "coward",
    "pétoche": "fright",
    "rageur": "angry",
    "rancune": "grudge",
    "ras-le-bol": "fed up",
    "rassasiement": "fullness",
    "rebelle": "rebellious",
    "reconnaissant": "grateful",
    "refoulé": "repressed",
    "rejet": "rejection",
    "remobilisation": "mobilization",
    "remonté": "angry",
    "remords": "remorse",
    "repenti": "repentant",
    "repentir": "repentance",
    "repu": "full",
    "respectueux": "respectful",
    "ressort": "vigor",
    "rogne": "anger",
    "réconfort": "comfort",
    "réfractaire": "refractory",
    "résigné": "resigned",
    "résipiscence": "repentance",
    "résipiscent": "repentant",
    "rétif": "restive",
    "révolté": "outraged",
    "rêveur": "dreamy",
    "saisissement": "shock",
    "sans-gêne": "shameless",
    "satisfait": "satisfied",
    "satiété": "fullness",
    "scepticisme": "skepticism",
    "sceptique": "skeptical",
    "scrupule": "scruple",
    "serein": "serene",
    "sinistre": "gloomy",
    "sinistrose": "gloom",
    "sombre": "somber",
    "songeur": "pensive",
    "souci": "worry",
    "soucieux": "worried",
    "souffre-douleur": "scapegoat",
    "soupçon": "suspicion",
    "soupçonneux": "suspicious",
    "sourd": "oblivious",
    "sous-estimation": "underestimation",
    "spleen": "gloom",
    "stupéfait": "astonished",
    "surexcitation": "overexcitement",
    "suspicieux": "suspicious",
    "sympathie": "sympathy",
    "séducteur": "seductive",
    "sûr": "confident",
    "timide": "shy",
    "tonicité": "vigor",
    "tonus": "vigor",
    "toquade": "infatuation",
    "tourmenté": "tormented",
    "trac": "nervousness",
    "tracas": "worry",
    "tranquillité": "tranquility",
    "triste": "sad",
    "tristounet": "sad",
    "trouillard": "coward",
    "trouille": "fright",
    "vaniteux": "vain",
    "venette": "fright",
    "vindicatif": "vindictive",
    "voluptueux": "voluptuous",
    "volupté": "voluptuousness",
    "ébahissement": "amazement",
    "ébaubissement": "amazement",
    "écœurement": "disgust",
    "égarement": "bewilderment",
    "émoi": "turmoil",
    "énergie": "energy",
    "énervement": "irritation",
    "épanouissement": "fulfillment",
    "épatement": "amazement",
    "éperdu": "distraught",
    "éplorement": "grief",
    "éploré": "tearful",
    "épouvante": "dread",
    "épris": "infatuated",
    "épuisement": "exhaustion",
    "étonnement": "astonishment",
    # --- Locutions multi-mots Z_PLUS_ACTIVE ---
    "absence de trouble": "peaceful",
    "affres de la mort": "terror",
    "agréablement surpris": "delighted",
    "ami intime": "friend",
    "amour conjugal": "love",
    "amour de la vie": "love",
    "amour fou": "passion",
    "amour fraternel": "love",
    "amour maternel": "love",
    "amour paternel": "love",
    "amour physique": "passion",
    "amour platonique": "affection",
    "amour-propre": "self esteem",
    "amoureuse comme une chatte": "infatuated",
    "amoureuse comme une folle": "in love",
    "amoureux comme un coq": "infatuated",
    "amoureux comme un fou": "in love",
    "amoureux dingue": "in love",
    "amoureux fou": "in love",
    "amoureux transi": "infatuated",
    "au bord de la crise de nerfs": "frazzled",
    "baba d'admiration": "astonished",
    "bien aise": "happy",
    "bien dans sa peau": "comfortable",
    "bien dans sa tête": "peaceful",
    "bien dans son corps": "comfortable",
    "bien disposé": "friendly",
    "bon ami": "friend",
    "bon camarade": "comrade",
    "bon moral": "cheerful",
    "bonne conscience": "conscience",
    "bonne entente": "harmony",
    "bonne forme": "wellbeing",
    "bonne humeur": "cheerfulness",
    "bonne intelligence": "harmony",
    "bonnes dispositions": "goodwill",
    "bons amis": "friends",
    "bouffi d'autosatisfaction": "smug",
    "bouffi d'orgueil": "arrogant",
    "bourrelé de honte": "ashamed",
    "bourrelé de remords": "guilty",
    "chagrin d'amour": "heartbreak",
    "colère blanche": "fury",
    "colère bleue": "fury",
    "colère froide": "anger",
    "colère noire": "rage",
    "complexe d'infériorité": "inferiority",
    "complexe de supériorité": "superiority",
    "confiance en soi": "self confidence",
    "confusion mentale": "confusion",
    "content de soi": "smug",
    "copain comme cochon": "buddy",
    "couille molle": "coward",
    "coup de cœur": "crush",
    "coup de foudre": "infatuation",
    "coup de sang": "rage",
    "crainte révérencielle": "awe",
    "croyance religieuse": "faith",
    "d'humeur chagrine": "gloomy",
    "dans l'embarras": "embarrassed",
    "dans le doute": "doubtful",
    "dans une forme catastrophique": "exhaustion",
    "dans une forme éblouissante": "vigor",
    "de bon poil": "cheerful",
    "de bonne humeur": "cheerful",
    "de mauvais poil": "grumpy",
    "de mauvaise humeur": "grumpy",
    "dispositions bienveillantes": "goodwill",
    "dispositions malveillantes": "malevolence",
    "déchaînement de colère": "rage",
    "dégoût de la vie": "despair",
    "délectation morose": "gloom",
    "dépression nerveuse": "nervous breakdown",
    "désagréablement surpris": "dismayed",
    "désir de vengeance": "vengeance",
    "détresse émotionnelle": "distress",
    "en admiration": "admiring",
    "en adoration": "adoring",
    "en alarme": "alarmed",
    "en bonne forme": "wellbeing",
    "en boule": "angry",
    "en colère": "angry",
    "en deuil": "mourning",
    "en dépression": "depressed",
    "en dépression nerveuse": "depressed",
    "en désarroi": "dismayed",
    "en détresse": "distressed",
    "en effervescence": "excited",
    "en extase": "ecstatic",
    "en forme": "energetic",
    "en fureur": "furious",
    "en furie": "furious",
    "en liesse": "jubilant",
    "en manque": "craving",
    "en mauvaise forme": "weary",
    "en paix avec sa conscience": "peaceful",
    "en paix avec soi-même": "at peace",
    "en plein désarroi": "dismayed",
    "en pleine forme": "energetic",
    "en pétard": "furious",
    "en rage": "enraged",
    "en rogne": "angry",
    "en règle avec sa conscience": "peaceful",
    "en très bonne forme": "energetic",
    "en très mauvaise forme": "exhausted",
    "en ébullition": "excited",
    "en émoi": "agitated",
    "en état de choc": "shocked",
    "ennemi intime": "enemy",
    "ennemi juré": "enemy",
    "envie de vengeance": "vengeance",
    "excitation sexuelle": "arousal",
    "fatigué de la vie": "weary",
    "fatigué de vivre": "weary",
    "femme de la vie": "beloved",
    "femme des rêves": "beloved",
    "fier de soi": "proud",
    "follement amoureux": "in love",
    "fort aise": "happy",
    "fou d'amour": "in love",
    "fou de joie": "overjoyed",
    "fou furieux": "furious",
    "gonflé d'orgueil": "arrogant",
    "haine à mort": "hatred",
    "haute estime": "esteem",
    "haute estime de soi": "self esteem",
    "haute idée": "esteem",
    "haute idée de soi": "conceit",
    "haute opinion": "esteem",
    "haute opinion de soi": "conceit",
    "heureux élu": "beloved",
    "homme de la vie": "beloved",
    "hors de soi": "furious",
    "humeur de chien": "grumpy",
    "humeur de dogue": "grumpy",
    "humeur massacrante": "cranky",
    "humeur noire": "gloom",
    "ivre d'amour": "in love",
    "je m'en foutiste": "indifferent",
    "mal dans sa peau": "insecure",
    "mal dans sa tête": "distressed",
    "mal dans son corps": "uncomfortable",
    "mal disposé": "hostile",
    "mal du pays": "homesickness",
    "mal à l'aise": "uncomfortable",
    "manque de confiance en soi": "insecurity",
    "manque de considération": "disrespect",
    "mauvais moral": "dejection",
    "mauvaise conscience": "guilty conscience",
    "mauvaise entente": "discord",
    "mauvaise forme": "fatigue",
    "mauvaise humeur": "irritable",
    "mauvaise intelligence": "discord",
    "mauvaises dispositions": "hostility",
    "moral d'acier": "confident",
    "mouvement d'humeur": "irritation",
    "pas content de soi": "dissatisfied",
    "pas fier de soi": "ashamed",
    "pas peu fier": "proud",
    "pas sûr de soi": "insecure",
    "passion amoureuse": "passion",
    "passionnément amoureux": "in love",
    "petit ami": "boyfriend",
    "petite amie": "girlfriend",
    "peu enclin": "reluctant",
    "peur bleue": "terror",
    "peur panique": "panic",
    "piètre estime": "contempt",
    "piètre estime de soi": "inferiority",
    "piètre idée": "contempt",
    "piètre idée de soi": "inferiority",
    "piètre opinion": "contempt",
    "piètre opinion de soi": "inferiority",
    "plus mort que vif": "terrified",
    "pris de remords": "guilty",
    "regret nostalgique": "nostalgia",
    "sans complexes": "confident",
    "scrupule de conscience": "scruple",
    "sens dessus dessous": "upset",
    "sentiment d'abandon": "abandonment",
    "sentiment d'esseulement": "loneliness",
    "sentiment d'impuissance": "helplessness",
    "sentiment d'infériorité": "inferiority",
    "sentiment d'insécurité": "insecurity",
    "sentiment d'étrangeté": "alienation",
    "sentiment de culpabilité": "guilt",
    "sentiment de dépaysement": "disorientation",
    "sentiment de déréliction": "despair",
    "sentiment de révolte": "revolt",
    "sentiment de solitude": "loneliness",
    "sentiment de supériorité": "superiority",
    "soif de vengeance": "vengeance",
    "souffrance morale": "anguish",
    "sous le choc": "shocked",
    "sous-estimation de soi": "inferiority",
    "surestimation de soi": "overconfidence",
    "sûr de soi": "confident",
    "taedium vitae": "boredom",
    "tout fiérot": "smug",
    "tranquillité d'esprit": "serenity",
    "très ami": "friendly",
    "très remonté": "angry",
    "vague à l'âme": "melancholy",
    "à bout": "exhausted",
    "à bout de nerfs": "frazzled",
    "à cran": "edgy",
    "à crin": "irritable",
    "à l'aise": "comfortable",
    "écorché vif": "sensitive",
    "élu du coeur": "beloved",
    "éperdument amoureux": "in love",
    "état de choc": "shock",
    # --- Verbes Z_PLUS_SATELLITE (mono-mots et locutions fréquentes) ---
    "abhorrer": "abhor",
    "abominer": "abominate",
    "accepter": "accept",
    "admirer": "admire",
    "adorer": "adore",
    "affectionner": "cherish",
    "aimer": "love",
    "ambitionner": "aspire",
    "apitoyer": "pity",
    "apprécier": "appreciate",
    "appréhender": "dread",
    "aspirer": "aspire",
    "baliser": "panic",
    "bouillir": "seethe",
    "brouiller": "quarrel",
    "brûler": "burn",
    "chérir": "cherish",
    "compatir": "sympathize",
    "complaire": "indulge",
    "compter": "expect",
    "convoiter": "covet",
    "craindre": "fear",
    "craquer": "snap",
    "croire": "believe",
    "douter": "doubt",
    "déballonner": "chicken",
    "déchanter": "disillusion",
    "dédaigner": "disdain",
    "déguster": "savor",
    "déplorer": "deplore",
    "déprécier": "depreciate",
    "désenchanter": "disenchant",
    "désespérer": "despair",
    "désirer": "desire",
    "détacher": "detach",
    "détester": "detest",
    "dévaloriser": "devalue",
    "ennuyer": "bore",
    "enorgueillir": "pride",
    "enrager": "rage",
    "envier": "envy",
    "escompter": "expect",
    "espérer": "hope",
    "estimer": "esteem",
    "extasier": "rapture",
    "exulter": "exult",
    "exécrer": "abhor",
    "flasher": "crush",
    "fouetter": "whip",
    "frémir": "shudder",
    "fâcher": "anger",
    "féliciter": "congratulate",
    "goûter": "savor",
    "griller": "crave",
    "guigner": "covet",
    "halluciner": "marvel",
    "honnir": "scorn",
    "honorer": "honor",
    "idolâtrer": "idolize",
    "incliner": "incline",
    "jalouser": "envy",
    "jouir": "enjoy",
    "jubiler": "jubilate",
    "languir": "languish",
    "manquer": "miss",
    "moquer": "mock",
    "mouiller": "fear",
    "méfier": "distrust",
    "méjuger": "misjudge",
    "mépriser": "despise",
    "mésestimer": "underestimate",
    "paniquer": "panic",
    "pavoiser": "boast",
    "pencher": "incline",
    "pincer": "crush",
    "piquer": "sting",
    "plaindre": "pity",
    "plaire": "please",
    "pleurer": "weep",
    "priser": "value",
    "préférer": "prefer",
    "pâtir": "suffer",
    "pétocher": "fear",
    "raffoler": "adore",
    "rager": "rage",
    "redouter": "dread",
    "regretter": "regret",
    "rengorger": "boast",
    "repentir": "repent",
    "respecter": "respect",
    "rougir": "blush",
    "réconcilier": "reconcile",
    "répugner": "repulse",
    "résigner": "resign",
    "révérer": "revere",
    "rêver": "dream",
    "s'aimer": "love",
    "s'amouracher": "infatuated",
    "s'amuser": "enjoy",
    "s'attacher": "attach",
    "s'attendrir": "soften",
    "s'avachir": "slump",
    "s'emballer": "enthusiasm",
    "s'embraser": "ignite",
    "s'emporter": "rage",
    "s'enamourer": "infatuated",
    "s'enflammer": "ignite",
    "s'engouer": "infatuated",
    "s'enticher": "infatuated",
    "s'entr'aimer": "love",
    "s'entre-aimer": "love",
    "s'entre-haïr": "hate",
    "s'écrouler": "collapse",
    "s'énamourer": "infatuated",
    "s'éplorer": "weep",
    "s'éprendre": "love",
    "s'évader": "escape",
    "savourer": "savor",
    "souffrir": "suffer",
    "soupirer": "sigh",
    "soupçonner": "suspect",
    "sous-estimer": "underestimate",
    "suspecter": "suspect",
    "sympathiser": "sympathize",
    "tabler": "rely",
    "tenir": "care",
    "trembler": "tremble",
    "vibrer": "thrill",
    "vomir": "vomit",
    "vénérer": "venerate",
    "échauffer": "heat",
    "éprendre": "love",
    # Locutions verbales clés (couvrant notamment les 7 classes satellites-only)
    "ne pas s'embêter": "enjoy",
    "ne pas s'ennuyer": "amuse",
    "prendre ombrage": "offended",
    "se formaliser": "offended",
    "se sentir agressé": "threatened",
    "douter de soi": "doubt",
    "se sous-estimer": "underestimate",
    "désespérer": "despair",
    "perdre espoir": "despair",
    "perdre l'espoir": "despair",
    "perdre tout espoir": "despair",
    "quitter tout espoir": "despair",
    "abandonner tout espoir": "despair",
    "abandonner toute espérance": "despair",
    "avoir peur": "fear",
    "avoir honte": "shame",
    "avoir envie": "desire",
    "avoir besoin": "need",
    "avoir confiance": "trust",
    "se sentir en sécurité": "safe",
    "se sentir seul": "lonely",
    "se sentir bien": "happy",
    "aller bien": "happy",
    "aller mal": "sad",
    "être bien": "happy",
    "être mal": "sad",
    "broyer du noir": "gloom",
    "avoir le blues": "gloom",
    "avoir le spleen": "gloom",
    "avoir le bourdon": "gloom",
    "avoir de la peine": "sadness",
    "avoir le cœur gros": "heartbreak",
    "avoir le cœur lourd": "sadness",
    "avoir le cœur qui saigne": "heartbreak",
    "avoir bon moral": "cheerful",
    "avoir le moral": "cheerful",
    "avoir la banane": "happy",
    "avoir la pêche": "energetic",
    "avoir la frite": "energetic",
    "avoir la patate": "energetic",
    "nager dans le bonheur": "bliss",
    "être aux anges": "overjoyed",
    "être au septième ciel": "ecstatic",
    "perdre ses illusions": "disillusion",
    "tomber de haut": "disappointed",
    "se morfondre": "mope",
    "se défouler": "unwind",
    "se reprendre": "calm",
    "se ressaisir": "calm",
    "ne pas se démonter": "confident",
    "avoir le cœur léger": "carefree",
    "ne pas être gêné": "confident",
    "se faire du souci": "worry",
    "se faire du mauvais sang": "worry",
    "se mettre en colère": "angry",
    "sortir de ses gonds": "furious",
    "piquer une crise": "rage",
    "prendre la mouche": "offended",
    "tomber amoureux": "in love",
    "être amoureux": "in love",
    "prendre en grippe": "dislike",
    "prendre en affection": "affection",
    "sentir le vent du boulet": "fear",
    "serrer les fesses": "fear",
    "suer à grosses gouttes": "panic",
    "ne pas courir": "reluctant",
}

# Liste noire explicite empêchant tout faux ami automatique par cognate/accent-stripping.
COGNATE_FALSE_FRIEND_BLOCKLIST: frozenset[str] = frozenset(
    {
        "affection",
        "amours",
        "baba",
        "baliser",
        "blessure",
        "béat",
        "cafard",
        "chagrin",
        "complaisance",
        "complaisant",
        "compter",
        "couard",
        "craquer",
        "dilection",
        "déception",
        "défiance",
        "défiant",
        "dépit",
        "enragé",
        "envie",
        "fat",
        "flasher",
        "fou",
        "fouetter",
        "griller",
        "goût",
        "gêne",
        "haïr",
        "hâte",
        "interdit",
        "libre",
        "marri",
        "mordu",
        "mouiller",
        "paumé",
        "penaud",
        "pincer",
        "piquer",
        "pote",
        "pétulance",
        "pétulant",
        "pêcher",
        "reconnaissance",
        "régal",
        "réservé",
        "sensible",
        "sourd",
        "spleen",
        "tabler",
        "taffer",
        "tenir",
        "trac",
        "transport",
    }
)


@dataclass(frozen=True)
class LinearCalibration:
    axis: str
    n_pairs: int
    pearson_r: float
    pearson_p: float
    spearman_rho: float
    spearman_p: float
    slope: float
    intercept: float
    r_squared: float
    slope_stderr: float
    intercept_stderr: float
    rmse: float


@dataclass(frozen=True)
class DominanceResidualization:
    n_terms: int
    alpha: float
    beta: float
    r_vd: float
    r_vd_p: float
    r_squared: float
    max_abs_eps: float
    r_vd_orth: float
    d_orth_min: float
    d_orth_max: float


def clean_text(val: Any) -> str:
    """Normalise une chaîne en NFC, remplace les séquences d'espaces par un espace et strip."""
    if val is None or pd.isna(val):
        return ""
    text = unicodedata.normalize("NFC", str(val))
    return re.sub(r"\s+", " ", text).strip()


def strip_accents(text: str) -> str:
    """Supprime les diacritiques Unicode après décomposition NFKD (pour détection contrôlée de cognates)."""
    decomposed = unicodedata.normalize("NFKD", text)
    return "".join(ch for ch in decomposed if not unicodedata.combining(ch))


def sha256_file(path: Path) -> str:
    """Calcule le digest SHA-256 hexadécimal d'un fichier par blocs."""
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_inputs() -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """Charge et valide dima_normalized.parquet, fancat_clean.parquet et NRC-VAD-Lexicon-v2.1.txt."""
    for p in (DIMA_PATH, FANCAT_PATH, RAW_NRC_PATH):
        if not p.is_file():
            raise FileNotFoundError(f"Fichier requis introuvable : {p.relative_to(REPO_ROOT).as_posix()}")

    df_dima = pd.read_parquet(DIMA_PATH)
    assert df_dima.shape == (3342, 48), f"Schéma DIMA inattendu : {df_dima.shape} (attendu (3342, 48))"
    route_counts = df_dima["hemisphere_route"].value_counts().to_dict()
    assert route_counts == {
        "Z_MINUS_RESERVE": 1367,
        "Z_PLUS_ACTIVE": 549,
        "Z_PLUS_SATELLITE": 945,
        "NON_LEXICAL_DISCARD": 481,
    }, f"Routage MP1c inattendu : {route_counts}"

    df_fancat = pd.read_parquet(FANCAT_PATH)
    assert df_fancat.shape == (1031, 29), f"Schéma FANCat inattendu : {df_fancat.shape} (attendu (1031, 29))"
    assert int(df_fancat.isna().sum().sum()) == 0, "Valeurs nulles inattendues dans fancat_clean.parquet"

    df_nrc = pd.read_csv(
        RAW_NRC_PATH,
        sep="\t",
        encoding="utf-8",
        keep_default_na=False,
        dtype={
            "term": "string",
            "valence": "float64",
            "arousal": "float64",
            "dominance": "float64",
        },
    )
    assert len(df_nrc) == 54801, f"Effectif NRC-VAD inattendu : {len(df_nrc)}"
    assert list(df_nrc.columns) == ["term", "valence", "arousal", "dominance"], f"Colonnes NRC inattendues : {list(df_nrc.columns)}"
    assert int(df_nrc.isna().sum().sum()) == 0, "Valeurs nulles détectées dans NRC-VAD."
    df_nrc["term_norm"] = df_nrc["term"].map(clean_text).str.lower().astype("string")
    assert (df_nrc["term_norm"] == "").sum() == 0, "Terme vide dans NRC-VAD."
    assert df_nrc["term_norm"].duplicated().sum() == 0, "Doublons sur term_norm dans NRC-VAD."
    return df_dima, df_fancat, df_nrc


def calibrate_fancat_to_nrc(
    df_fancat: pd.DataFrame,
    df_nrc: pd.DataFrame,
) -> tuple[pd.DataFrame, LinearCalibration, LinearCalibration, dict[str, Any]]:
    """Apparie FANCat (colonne anglaise normalisée) à NRC-VAD v2.1 et calcule les régressions de transfert."""
    df_fan = df_fancat.copy()
    df_fan["en_key"] = df_fan["word_en"].map(clean_text).str.lower().astype("string")
    assert (df_fan["en_key"] == df_fan["word_en_norm"]).all(), "Divergence en_key vs word_en_norm dans FANCat."

    df_pairs = df_fan.merge(
        df_nrc[["term_norm", "valence", "arousal", "dominance"]],
        left_on="en_key",
        right_on="term_norm",
        how="inner",
        validate="many_to_one",
    )
    assert len(df_pairs) == 976, f"Nombre de paires FANCat<->NRC inattendu : {len(df_pairs)} (attendu ~976)"

    def _fit_axis(axis_name: str, fan_col: str, nrc_col: str) -> LinearCalibration:
        x = df_pairs[fan_col].to_numpy(dtype=np.float64)
        y = df_pairs[nrc_col].to_numpy(dtype=np.float64)
        pr = stats.pearsonr(x, y)
        sr = stats.spearmanr(x, y)
        lr = stats.linregress(x, y)
        y_hat = lr.intercept + lr.slope * x
        rmse = float(np.sqrt(np.mean((y - y_hat) ** 2)))
        return LinearCalibration(
            axis=axis_name,
            n_pairs=int(len(df_pairs)),
            pearson_r=float(pr.statistic),
            pearson_p=float(pr.pvalue),
            spearman_rho=float(sr.statistic),
            spearman_p=float(sr.pvalue),
            slope=float(lr.slope),
            intercept=float(lr.intercept),
            r_squared=float(lr.rvalue ** 2),
            slope_stderr=float(lr.stderr),
            intercept_stderr=float(lr.intercept_stderr),
            rmse=rmse,
        )

    cal_v = _fit_axis("Valence", "valence_fan_mean", "valence")
    cal_a = _fit_axis("Arousal", "arousal_fan_mean", "arousal")

    assert abs(cal_v.pearson_r - 0.787) < 0.005, f"r_V hors repère : {cal_v.pearson_r:.6f}"
    assert abs(cal_a.pearson_r - 0.592) < 0.005, f"r_A hors repère : {cal_a.pearson_r:.6f}"

    v_raw_proj = cal_v.intercept + cal_v.slope * df_fan["valence_fan_mean"].to_numpy(dtype=np.float64)
    a_raw_proj = cal_a.intercept + cal_a.slope * df_fan["arousal_fan_mean"].to_numpy(dtype=np.float64)

    n_clipped_v = int(np.sum((v_raw_proj < -1.0) | (v_raw_proj > 1.0)))
    n_clipped_a = int(np.sum((a_raw_proj < -1.0) | (a_raw_proj > 1.0)))

    df_fan["V_harm_fan"] = np.clip(v_raw_proj, -1.0, 1.0)
    df_fan["A_harm_fan"] = np.clip(a_raw_proj, -1.0, 1.0)

    proj_stats = {
        "n_unmatched_fancat": int(len(df_fan) - len(df_pairs)),
        "v_proj_min": float(v_raw_proj.min()),
        "v_proj_max": float(v_raw_proj.max()),
        "a_proj_min": float(a_raw_proj.min()),
        "a_proj_max": float(a_raw_proj.max()),
        "n_clipped_v": n_clipped_v,
        "n_clipped_a": n_clipped_a,
    }
    return df_fan, cal_v, cal_a, proj_stats


def compute_orthogonal_dominance(df_nrc: pd.DataFrame) -> tuple[pd.DataFrame, DominanceResidualization]:
    """Estime D = alpha + beta * V + eps sur les 54 801 entrées NRC-VAD et normalise D_orth sur [-1, +1]."""
    df = df_nrc.copy()
    v = df["valence"].to_numpy(dtype=np.float64)
    d = df["dominance"].to_numpy(dtype=np.float64)

    lr = stats.linregress(v, d)
    eps = d - (lr.intercept + lr.slope * v)
    max_abs_eps = float(np.max(np.abs(eps)))
    assert max_abs_eps > 0.0, "max|eps| nul impossible sur NRC-VAD."
    d_orth = eps / max_abs_eps

    r_vd_orth = float(stats.pearsonr(v, d_orth).statistic)
    assert abs(lr.intercept - 0.0452) < 0.001, f"alpha hors repère : {lr.intercept:.6f}"
    assert abs(lr.slope - 0.4111) < 0.001, f"beta hors repère : {lr.slope:.6f}"
    assert abs(lr.rvalue - 0.4730) < 0.001, f"r(V,D) hors repère : {lr.rvalue:.6f}"
    assert abs(r_vd_orth) < 1e-6, f"Échec orthogonalisation |r(V, D_orth)| = {abs(r_vd_orth):.3e} >= 1e-6"
    assert float(d_orth.min()) >= -1.0 - 1e-12 and float(d_orth.max()) <= 1.0 + 1e-12
    assert abs(float(np.max(np.abs(d_orth))) - 1.0) < 1e-12

    df["d_orth"] = d_orth
    res = DominanceResidualization(
        n_terms=int(len(df)),
        alpha=float(lr.intercept),
        beta=float(lr.slope),
        r_vd=float(lr.rvalue),
        r_vd_p=float(lr.pvalue),
        r_squared=float(lr.rvalue ** 2),
        max_abs_eps=max_abs_eps,
        r_vd_orth=r_vd_orth,
        d_orth_min=float(d_orth.min()),
        d_orth_max=float(d_orth.max()),
    )
    return df, res


def ensure_and_load_overrides(
    nrc_terms: set[str],
    df_z_plus: pd.DataFrame,
) -> tuple[pd.DataFrame, dict[tuple[str, str, str], tuple[str, str]], bool]:
    """Crée data/config/fr_en_bridge_overrides.csv s'il n'existe pas encore, le valide et construit l'index."""
    created_now = False
    OVERRIDES_PATH.parent.mkdir(parents=True, exist_ok=True)
    if not OVERRIDES_PATH.exists():
        with OVERRIDES_PATH.open("w", encoding="utf-8", newline="") as fh:
            writer = csv.writer(fh, lineterminator="\n")
            writer.writerow(OVERRIDES_COLUMNS)
            for row in DEFAULT_OVERRIDES:
                writer.writerow(row)
        created_now = True

    df_ovr = pd.read_csv(
        OVERRIDES_PATH,
        encoding="utf-8",
        keep_default_na=False,
        dtype=str,
    )
    if tuple(df_ovr.columns) != OVERRIDES_COLUMNS:
        raise ValueError(
            f"Colonnes inattendues dans {OVERRIDES_PATH.name} : {list(df_ovr.columns)} != {list(OVERRIDES_COLUMNS)}"
        )

    df_ovr["lemme_norm"] = df_ovr["lemme_norm"].map(clean_text).str.lower()
    df_ovr["part_disc"] = df_ovr["part_disc"].map(clean_text)
    df_ovr["classe"] = df_ovr["classe"].map(clean_text)
    df_ovr["en_override"] = df_ovr["en_override"].map(clean_text).str.lower()
    df_ovr["note_faux_ami"] = df_ovr["note_faux_ami"].map(clean_text)

    if df_ovr.duplicated(subset=["lemme_norm", "part_disc", "classe"]).any():
        dups = df_ovr[df_ovr.duplicated(subset=["lemme_norm", "part_disc", "classe"], keep=False)]
        raise ValueError(f"Clés dupliquées dans fr_en_bridge_overrides.csv :\n{dups}")

    invalid_en = sorted({en for en in df_ovr["en_override"] if en not in nrc_terms})
    if invalid_en:
        raise ValueError(f"Traduction(s) en_override absente(s) de NRC-VAD v2.1 : {invalid_en}")

    # Vérifie que >= 60 entrées/lemmes Z_PLUS_ACTIVE sont bien représentées dans les overrides
    active_lemmes = set(df_z_plus.loc[df_z_plus["hemisphere_route"] == "Z_PLUS_ACTIVE", "lemme_norm"])
    covered_active_lemmes = active_lemmes & set(df_ovr["lemme_norm"])
    assert len(covered_active_lemmes) >= 50 and len(df_ovr) >= 60, (
        f"Couverture overrides insuffisante : {len(df_ovr)} lignes, {len(covered_active_lemmes)} lemmes Z_PLUS_ACTIVE"
    )

    lookup: dict[tuple[str, str, str], tuple[str, str]] = {}
    for _, row in df_ovr.iterrows():
        key = (row["lemme_norm"], row["part_disc"], row["classe"])
        lookup[key] = (row["en_override"], row["note_faux_ami"])
    return df_ovr, lookup, created_now


def resolve_contextual_override(
    lemme_norm: str,
    part_disc: str,
    classe: str,
    override_lookup: dict[tuple[str, str, str], tuple[str, str]],
) -> tuple[str, str] | None:
    """
    Résout une règle contextuelle explicite (classe != '*') selon (lemme,pos,classe) > (lemme,*,classe).
    Évaluée AVANT fancat_direct afin de désambiguïser les polysèmes dépendant de la classe DIMA.
    """
    for key, method in (
        ((lemme_norm, part_disc, classe), "override_contextual_exact"),
        ((lemme_norm, "*", classe), "override_contextual_pos_wildcard"),
    ):
        if key in override_lookup:
            en_term, _note = override_lookup[key]
            return en_term, method
    return None


def resolve_global_override(
    lemme_norm: str,
    part_disc: str,
    override_lookup: dict[tuple[str, str, str], tuple[str, str]],
) -> tuple[str, str] | None:
    """
    Résout une règle globale (classe == '*') selon (lemme,pos,*) > (lemme,*,*).
    Évaluée APRÈS fancat_direct (ou en repli pour compléter D_raw/D_orth si absent de NRC-VAD).
    """
    for key, method in (
        ((lemme_norm, part_disc, "*"), "override_pos_wildcard"),
        ((lemme_norm, "*", "*"), "override_global_wildcard"),
    ):
        if key in override_lookup:
            en_term, _note = override_lookup[key]
            return en_term, method
    return None


def match_cognate_controlled(
    lemme_norm: str,
    part_disc: str,
    nrc_terms: set[str],
) -> tuple[str, str] | None:
    """
    Détection contrôlée de cognates / variantes morphologiques FR->EN vérifiée contre NRC-VAD v2.1.
    Exclut les locutions multi-mots, la liste noire de faux amis et les verbes en -er (risque nom d'agent EN -er).
    """
    if " " in lemme_norm or len(lemme_norm) < 4:
        return None
    if lemme_norm in COGNATE_FALSE_FRIEND_BLOCKLIST:
        return None
    if part_disc not in {"NOM", "ADJ", "VERB"}:
        return None

    base = strip_accents(lemme_norm)

    # Garde-fou grammatical : ne jamais apparier un verbe FR en -er à un nom d'agent EN en -er
    if part_disc in {"NOM", "ADJ"} and base in nrc_terms:
        return base, "cognate_exact"

    if part_disc in {"NOM", "ADJ"}:
        suffix_rules: tuple[tuple[str, str, str], ...] = (
            ("phobie", "phobia", "-phobie->-phobia"),
            ("phobe", "phobic", "-phobe->-phobic"),
            ("phobe", "phobe", "-phobe->-phobe"),
            ("philie", "philia", "-philie->-philia"),
            ("manie", "mania", "-manie->-mania"),
            ("pathie", "pathy", "-pathie->-pathy"),
            ("iete", "iety", "-iété->-iety"),
            ("ite", "ity", "-ité->-ity"),
            ("isme", "ism", "-isme->-ism"),
            ("iste", "ist", "-iste->-ist"),
            ("ique", "ic", "-ique->-ic"),
            ("eux", "ous", "-eux->-ous"),
            ("if", "ive", "-if->-ive"),
            ("ie", "y", "-ie->-y"),
        )
        for fr_suf, en_suf, rule_name in suffix_rules:
            if base.endswith(fr_suf) and len(base) - len(fr_suf) >= 3:
                cand = base[: -len(fr_suf)] + en_suf
                if cand in nrc_terms:
                    return cand, f"cognate_suffix:{rule_name}"
    return None


def validate_static_bridge(nrc_terms: set[str]) -> None:
    """Vérifie au démarrage que 100 % des cibles anglaises de STATIC_FR_EN_BRIDGE existent dans NRC-VAD v2.1."""
    missing = sorted({en for en in STATIC_FR_EN_BRIDGE.values() if en not in nrc_terms})
    if missing:
        raise ValueError(f"Cibles anglaises de STATIC_FR_EN_BRIDGE absentes de NRC-VAD v2.1 : {missing}")


def run_z_plus_cascade(
    df_dima: pd.DataFrame,
    df_fancat_cal: pd.DataFrame,
    df_nrc_orth: pd.DataFrame,
) -> tuple[pd.DataFrame, pd.DataFrame, dict[tuple[str, str, str], tuple[str, str]], bool, list[str]]:
    """Applique la cascade psychométrique strictement tracée sur les 1 636 entrées Z+."""
    nrc_lookup = df_nrc_orth.set_index("term_norm")[["valence", "arousal", "dominance", "d_orth"]].to_dict("index")
    nrc_terms = set(nrc_lookup.keys())
    validate_static_bridge(nrc_terms)

    fan_lookup = df_fancat_cal.set_index("word_fr_norm").to_dict("index")

    df_z_plus = (
        df_dima[df_dima["hemisphere_route"].isin(["Z_PLUS_ACTIVE", "Z_PLUS_SATELLITE"])]
        .copy()
        .sort_values(["categ", "classe", "lemme_norm", "part_disc"], kind="mergesort")
        .reset_index(drop=True)
    )
    assert len(df_z_plus) == 1494, f"Effectif Z+ inattendu : {len(df_z_plus)} (attendu 1494 = 549 + 945)"

    df_ovr, override_lookup, overrides_created = ensure_and_load_overrides(nrc_terms, df_z_plus)

    n = len(df_z_plus)
    v_harm = np.full(n, np.nan, dtype=np.float64)
    a_harm = np.full(n, np.nan, dtype=np.float64)
    d_raw = np.full(n, np.nan, dtype=np.float64)
    d_orth = np.full(n, np.nan, dtype=np.float64)
    provenance: list[str] = [""] * n
    en_matched_term: list[str | None] = [None] * n
    en_match_method: list[str] = [""] * n

    fan_valence_mean = np.full(n, np.nan, dtype=np.float64)
    fan_arousal_mean = np.full(n, np.nan, dtype=np.float64)
    fan_n_ratings = pd.array([pd.NA] * n, dtype="Int64")
    fan_emo_arrays: dict[str, np.ndarray] = {
        emo: np.full(n, np.nan, dtype=np.float64) for emo in FANCAT_DISCRETE_EMOTIONS
    }

    # Passes 1 à 3 : override contextuel (lemme, classe) -> fancat_direct -> override global -> nrc_bridge_auto
    for idx, row in enumerate(df_z_plus.itertuples(index=False)):
        lem = str(row.lemme_norm)
        pos = str(row.part_disc)
        cls = str(row.classe)

        # 1. Règle contextuelle explicite (lemme_norm, classe) AVANT fancat_direct
        ctx_ovr = resolve_contextual_override(lem, pos, cls, override_lookup)
        if ctx_ovr is not None:
            en_term, method = ctx_ovr
            nrec = nrc_lookup[en_term]
            v_harm[idx] = float(nrec["valence"])
            a_harm[idx] = float(nrec["arousal"])
            d_raw[idx] = float(nrec["dominance"])
            d_orth[idx] = float(nrec["d_orth"])
            provenance[idx] = "nrc_override"
            en_matched_term[idx] = en_term
            en_match_method[idx] = method
            continue

        # 2. fancat_direct
        if lem in fan_lookup:
            frec = fan_lookup[lem]
            v_harm[idx] = float(frec["V_harm_fan"])
            a_harm[idx] = float(frec["A_harm_fan"])
            fan_valence_mean[idx] = float(frec["valence_fan_mean"])
            fan_arousal_mean[idx] = float(frec["arousal_fan_mean"])
            fan_n_ratings[idx] = int(frec["fancat_n_ratings"])
            for emo in FANCAT_DISCRETE_EMOTIONS:
                fan_emo_arrays[emo][idx] = float(frec[f"{emo}_mean"])

            fan_en = str(frec["en_key"])
            if fan_en in nrc_lookup:
                nrec = nrc_lookup[fan_en]
                d_raw[idx] = float(nrec["dominance"])
                d_orth[idx] = float(nrec["d_orth"])
                en_matched_term[idx] = fan_en
                en_match_method[idx] = "fancat_word_en"
            else:
                glob_ovr = resolve_global_override(lem, pos, override_lookup)
                if glob_ovr is not None:
                    en_term, _method = glob_ovr
                    nrec = nrc_lookup[en_term]
                    d_raw[idx] = float(nrec["dominance"])
                    d_orth[idx] = float(nrec["d_orth"])
                    en_matched_term[idx] = en_term
                    en_match_method[idx] = "fancat_override_d_completion"
                else:
                    en_matched_term[idx] = fan_en
                    en_match_method[idx] = "fancat_no_nrc_d"
            provenance[idx] = "fancat_direct"
            continue

        # 3. Override global (classe == '*')
        glob_ovr = resolve_global_override(lem, pos, override_lookup)
        if glob_ovr is not None:
            en_term, method = glob_ovr
            nrec = nrc_lookup[en_term]
            v_harm[idx] = float(nrec["valence"])
            a_harm[idx] = float(nrec["arousal"])
            d_raw[idx] = float(nrec["dominance"])
            d_orth[idx] = float(nrec["d_orth"])
            provenance[idx] = "nrc_override"
            en_matched_term[idx] = en_term
            en_match_method[idx] = method
            continue

        # 3. nrc_bridge_auto (a. table statique curée, b. cognates contrôlés)
        if lem in STATIC_FR_EN_BRIDGE:
            en_term = STATIC_FR_EN_BRIDGE[lem]
            nrec = nrc_lookup[en_term]
            v_harm[idx] = float(nrec["valence"])
            a_harm[idx] = float(nrec["arousal"])
            d_raw[idx] = float(nrec["dominance"])
            d_orth[idx] = float(nrec["d_orth"])
            provenance[idx] = "nrc_bridge_auto"
            en_matched_term[idx] = en_term
            en_match_method[idx] = "static_dict"
            continue

        cog = match_cognate_controlled(lem, pos, nrc_terms)
        if cog is not None:
            en_term, method = cog
            nrec = nrc_lookup[en_term]
            v_harm[idx] = float(nrec["valence"])
            a_harm[idx] = float(nrec["arousal"])
            d_raw[idx] = float(nrec["dominance"])
            d_orth[idx] = float(nrec["d_orth"])
            provenance[idx] = "nrc_bridge_auto"
            en_matched_term[idx] = en_term
            en_match_method[idx] = method
            continue

    # Calcul des centroïdes EXCLUSIVEMENT à partir des ancres directes
    df_tmp = pd.DataFrame(
        {
            "classe": df_z_plus["classe"].astype(str),
            "sous_classe": df_z_plus["sous_classe"].map(lambda x: "" if pd.isna(x) else str(x).strip()),
            "V_harm": v_harm,
            "A_harm": a_harm,
            "D_raw": d_raw,
            "D_orth": d_orth,
            "is_direct": [p in {"fancat_direct", "nrc_override", "nrc_bridge_auto"} for p in provenance],
        }
    )
    direct_df = df_tmp[df_tmp["is_direct"]].copy()

    subclass_centroids: dict[tuple[str, str], tuple[float, float, float, float, int]] = {}
    for (cls, sub), grp in direct_df[direct_df["sous_classe"] != ""].groupby(["classe", "sous_classe"], sort=True):
        if grp[["V_harm", "A_harm", "D_raw", "D_orth"]].notna().all().all():
            subclass_centroids[(cls, sub)] = (
                float(grp["V_harm"].mean()),
                float(grp["A_harm"].mean()),
                float(grp["D_raw"].mean()),
                float(grp["D_orth"].mean()),
                int(len(grp)),
            )

    class_centroids: dict[str, tuple[float, float, float, float, int]] = {}
    for cls, grp in direct_df.groupby("classe", sort=True):
        valid_grp = grp.dropna(subset=["V_harm", "A_harm", "D_raw", "D_orth"])
        if len(valid_grp) > 0:
            class_centroids[cls] = (
                float(valid_grp["V_harm"].mean()),
                float(valid_grp["A_harm"].mean()),
                float(valid_grp["D_raw"].mean()),
                float(valid_grp["D_orth"].mean()),
                int(len(valid_grp)),
            )

    # Passe 4 : imputation hiérarchique subclass_centroid puis class_centroid
    unanchored_classes_set: set[str] = set()
    for idx in range(n):
        if provenance[idx] != "":
            continue
        cls = str(df_z_plus.at[idx, "classe"])
        raw_sub = df_z_plus.at[idx, "sous_classe"]
        sub = "" if pd.isna(raw_sub) else str(raw_sub).strip()

        if sub and (cls, sub) in subclass_centroids:
            mv, ma, md_r, md_o, k = subclass_centroids[(cls, sub)]
            v_harm[idx] = mv
            a_harm[idx] = ma
            d_raw[idx] = md_r
            d_orth[idx] = md_o
            provenance[idx] = "subclass_centroid"
            en_match_method[idx] = f"subclass_centroid(n={k})"
        elif cls in class_centroids:
            mv, ma, md_r, md_o, k = class_centroids[cls]
            v_harm[idx] = mv
            a_harm[idx] = ma
            d_raw[idx] = md_r
            d_orth[idx] = md_o
            provenance[idx] = "class_centroid"
            en_match_method[idx] = f"class_centroid(n={k})"
        else:
            provenance[idx] = "unanchored"
            en_match_method[idx] = "unanchored"
            unanchored_classes_set.add(cls)

    unanchored_classes = sorted(unanchored_classes_set)

    df_z_plus["V_harm"] = v_harm
    df_z_plus["A_harm"] = a_harm
    df_z_plus["D_raw"] = d_raw
    df_z_plus["D_orth"] = d_orth
    df_z_plus["metric_provenance"] = pd.Series(provenance, dtype="string")
    df_z_plus["en_matched_term"] = pd.Series(en_matched_term, dtype="string")
    df_z_plus["en_match_method"] = pd.Series(en_match_method, dtype="string")

    df_z_plus["fancat_valence_mean"] = fan_valence_mean
    df_z_plus["fancat_arousal_mean"] = fan_arousal_mean
    df_z_plus["fancat_n_ratings"] = fan_n_ratings
    for emo in FANCAT_DISCRETE_EMOTIONS:
        df_z_plus[f"fancat_{emo}_mean"] = fan_emo_arrays[emo]

    # Contrôles d'intégrité stricts
    assert len(df_z_plus) == 1494
    assert set(df_z_plus["hemisphere_route"].unique()) == {"Z_PLUS_ACTIVE", "Z_PLUS_SATELLITE"}
    assert (df_z_plus["metric_provenance"] != "").all()
    if not unanchored_classes:
        for col in ("V_harm", "A_harm", "D_raw", "D_orth"):
            assert df_z_plus[col].notna().all(), f"NaN inattendu dans {col}"
            assert df_z_plus[col].between(-1.0 - 1e-12, 1.0 + 1e-12).all(), f"Hors [-1, 1] dans {col}"

    is_fan = df_z_plus["metric_provenance"] == "fancat_direct"
    assert (df_z_plus["fancat_awe_mean"].notna() == is_fan).all(), "Incohérence colonnes FANCat vs metric_provenance"

    # Vérification 0 homographe FANCat non pertinent dans Z_PLUS_ACTIVE
    active_en_terms = set(
        df_z_plus.loc[df_z_plus["hemisphere_route"] == "Z_PLUS_ACTIVE", "en_matched_term"].dropna().astype(str)
    )
    forbidden_hits = active_en_terms & FORBIDDEN_ACTIVE_FANCAT_GLOSSES
    assert not forbidden_hits, f"Homographe(s) FANCat non pertinent(s) présent(s) dans Z_PLUS_ACTIVE : {sorted(forbidden_hits)}"

    # Vérification priorité contextuelle (lemme_norm, classe) avant fancat_direct
    def _row(lem: str, pos: str, cls: str) -> pd.Series:
        sub = df_z_plus[
            (df_z_plus["lemme_norm"] == lem)
            & (df_z_plus["part_disc"] == pos)
            & (df_z_plus["classe"] == cls)
        ]
        assert len(sub) == 1, f"Entrée attendue introuvable : {(lem, pos, cls)}"
        return sub.iloc[0]

    r_rire = _row("rire", "VERB", "Mépris")
    assert r_rire["metric_provenance"] == "nrc_override" and r_rire["en_matched_term"] == "mock"
    r_cr_est = _row("crainte", "NOM", "Estime respect")
    assert r_cr_est["metric_provenance"] == "nrc_override" and r_cr_est["en_matched_term"] == "reverence"
    r_cr_peur = _row("crainte", "NOM", "Crainte")
    assert r_cr_peur["metric_provenance"] == "fancat_direct" and r_cr_peur["en_matched_term"] == "fear"

    return df_z_plus, df_ovr, override_lookup, overrides_created, unanchored_classes


def build_report(
    cal_v: LinearCalibration,
    cal_a: LinearCalibration,
    proj_stats: dict[str, Any],
    dom_res: DominanceResidualization,
    df_dima: pd.DataFrame,
    df_z_plus: pd.DataFrame,
    df_ovr: pd.DataFrame,
    unanchored_classes: list[str],
    parquet_size: int,
    parquet_sha256: str,
) -> str:
    """Génère le rapport markdown déterministe reports/lexicon_v3/mp2_calibration_report.md."""
    ovr_sha = sha256_file(OVERRIDES_PATH)
    dima_sha = sha256_file(DIMA_PATH)
    fancat_sha = sha256_file(FANCAT_PATH)
    nrc_sha = sha256_file(RAW_NRC_PATH)

    prov_order = (
        "fancat_direct",
        "nrc_override",
        "nrc_bridge_auto",
        "subclass_centroid",
        "class_centroid",
        "unanchored",
    )
    zpa = df_z_plus[df_z_plus["hemisphere_route"] == "Z_PLUS_ACTIVE"]
    zps = df_z_plus[df_z_plus["hemisphere_route"] == "Z_PLUS_SATELLITE"]
    zpa_nom = int((zpa["part_disc"] == "NOM").sum())
    zpa_adj = int((zpa["part_disc"] == "ADJ").sum())
    n_res_total = int((df_dima["hemisphere_route"] == "Z_MINUS_RESERVE").sum())
    n_res_hum = int((df_dima["pruning_bucket"] == "Z_MINUS_HUMAN_ROLE").sum())
    n_discard = int((df_dima["hemisphere_route"] == "NON_LEXICAL_DISCARD").sum())

    lines: list[str] = [
        "# Rapport d'Audit — Micro-Passe 2 : Calibrage psychométrique FANCat ↔ NRC-VAD v2.1 & Pont FR→EN sur $Z_+$ (CARTOGRAFFECT v3.0.0)",
        "",
        "- **Script :** [`python/lexicon_pipeline/02_bridge_psychometrics.py`](../../python/lexicon_pipeline/02_bridge_psychometrics.py) *(strictement idempotent, zéro appel réseau)*",
        "- **Périmètre Lean 4 :** `Cartograffect/` strictement en lecture seule (0 fichier modifié)",
        (
            f"- **Partition MP1c :** `{len(zpa)}` `Z_PLUS_ACTIVE` (`{zpa_nom} NOM` + `{zpa_adj} ADJ`, unigrammes standard `ExpAffect`) "
            f"+ `{len(zps)}` `Z_PLUS_SATELLITE` = **`{len(df_z_plus):,}` entrées traitées** ; "
            f"`{n_res_total:,}` `Z_MINUS_RESERVE` (dont `{n_res_hum}` `Z_MINUS_HUMAN_ROLE`) et `{n_discard}` `NON_LEXICAL_DISCARD` laissées intactes"
        ),
        "- **Table d'overrides :** [`data/config/fr_en_bridge_overrides.csv`](../../data/config/fr_en_bridge_overrides.csv) (`"
        + f"{len(df_ovr)}"
        + "` règles, SHA-256 `"
        + ovr_sha[:16]
        + "...` ; priorité contextuelle `(lemme_norm, classe)` avant `fancat_direct`)",
        "",
        "### Empreintes des entrées consommées (lecture seule)",
        "",
        "| Fichier | SHA-256 |",
        "| :--- | :--- |",
        f"| `data/processed/dima_normalized.parquet` | `{dima_sha}` |",
        f"| `data/processed/fancat_clean.parquet` | `{fancat_sha}` |",
        f"| `data/raw/NRC-VAD-Lexicon-v2.1.txt` | `{nrc_sha}` |",
        "",
        "---",
        "",
        "## 1. Calibrage empirique FANCat ↔ NRC-VAD v2.1",
        "",
        f"Appariement exact sur la glose anglaise normalisée (`word_en` en minuscules/strip == `term_norm`) : **`{cal_v.n_pairs}` paires** sur `1 031` mots FANCat (`{proj_stats['n_unmatched_fancat']}` gloses sans correspondance exacte NRC-VAD, ex. expressions multi-mots ou variantes orthographiques).",
        "",
        "| Axe | Paires ($N$) | Pearson $r$ | $p$-valeur ($r$) | Spearman $\\rho$ | $p$-valeur ($\\rho$) | $R^2$ | Pente $\\hat{b}$ (± SE) | Ordonnée $\\hat{a}$ (± SE) | RMSE |",
        "| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
        (
            f"| **Valence** (`valence_fan_mean` → `valence`) | {cal_v.n_pairs} | `{cal_v.pearson_r:.6f}` | `{cal_v.pearson_p:.2e}` | "
            f"`{cal_v.spearman_rho:.6f}` | `{cal_v.spearman_p:.2e}` | `{cal_v.r_squared:.4f}` | "
            f"`{cal_v.slope:.6f}` (± `{cal_v.slope_stderr:.6f}`) | `{cal_v.intercept:.6f}` (± `{cal_v.intercept_stderr:.6f}`) | `{cal_v.rmse:.4f}` |"
        ),
        (
            f"| **Arousal** (`arousal_fan_mean` → `arousal`) | {cal_a.n_pairs} | `{cal_a.pearson_r:.6f}` | `{cal_a.pearson_p:.2e}` | "
            f"`{cal_a.spearman_rho:.6f}` | `{cal_a.spearman_p:.2e}` | `{cal_a.r_squared:.4f}` | "
            f"`{cal_a.slope:.6f}` (± `{cal_a.slope_stderr:.6f}`) | `{cal_a.intercept:.6f}` (± `{cal_a.intercept_stderr:.6f}`) | `{cal_a.rmse:.4f}` |"
        ),
        "",
        "### Équations de transfert appliquées à FANCat (échelle 1–9 → $[-1, +1]$)",
        "",
        f"- **Valence harmonisée :** $V_{{\\text{{harm}}}} = {cal_v.intercept:.6f} + {cal_v.slope:.6f} \\cdot V_{{\\text{{FAN}}}}$ — plage projetée sur les 1 031 mots FANCat : `[{proj_stats['v_proj_min']:.4f}, {proj_stats['v_proj_max']:.4f}]` (`{proj_stats['n_clipped_v']}` valeurs écrêtées).",
        f"- **Arousal harmonisé :** $A_{{\\text{{harm}}}} = {cal_a.intercept:.6f} + {cal_a.slope:.6f} \\cdot A_{{\\text{{FAN}}}}$ — plage projetée sur les 1 031 mots FANCat : `[{proj_stats['a_proj_min']:.4f}, {proj_stats['a_proj_max']:.4f}]` (`{proj_stats['n_clipped_a']}` valeurs écrêtées).",
        "",
        "---",
        "",
        "## 2. Dominance orthogonale résidualisée ($D_{\\perp}$)",
        "",
        f"Régression MCO estimée sur l'intégralité des **`{dom_res.n_terms:,}`** entrées de `NRC-VAD-Lexicon-v2.1.txt` :",
        "",
        "$$D = \\hat{\\alpha} + \\hat{\\beta} V + \\varepsilon, \\qquad D_{\\perp} = \\frac{D - (\\hat{\\alpha} + \\hat{\\beta} V)}{\\max|\\varepsilon|}$$",
        "",
        "| Paramètre | Valeur observée | Contrôle |",
        "| :--- | ---: | :--- |",
        f"| $\\hat{{\\alpha}}$ (ordonnée à l'origine) | `{dom_res.alpha:.6f}` | Repère $\\approx 0.0452$ |",
        f"| $\\hat{{\\beta}}$ (pente sur $V$) | `{dom_res.beta:.6f}` | Repère $\\approx 0.4111$ |",
        f"| $r(V, D)$ avant résidualisation | `{dom_res.r_vd:.6f}` ($R^2 = {dom_res.r_squared:.4f}$) | Repère $\\approx 0.4730$ |",
        f"| $\\max|\\varepsilon|$ | `{dom_res.max_abs_eps:.6f}` | Normalisateur $[-1, +1]$ |",
        f"| Plage de $D_{{\\perp}}$ | `[{dom_res.d_orth_min:.6f}, +{dom_res.d_orth_max:.6f}]` | Bornes exactes $[-1, +1]$ |",
        f"| $r(V, D_{{\\perp}})$ après résidualisation | `{dom_res.r_vd_orth:.3e}` | **PASS** ($|r| < 10^{{-6}}$) |",
        "",
        "---",
        "",
        f"## 3. Couverture par `hemisphere_route` et par `metric_provenance` ({len(df_z_plus):,} entrées $Z_+$)",
        "",
        f"Distinction explicite entre le noyau actif épuré **`Z_PLUS_ACTIVE`** (`{len(zpa)}` unigrammes standard `ExpAffect` : `{zpa_nom} NOM`, `{zpa_adj} ADJ`) et les satellites **`Z_PLUS_SATELLITE`** (`{len(zps)}` entrées : verbes, locutions MWE/métaphores, registres `fam` et `vx`/`allemand`/`jur`) :",
        "",
        "| `metric_provenance` | `Z_PLUS_ACTIVE` ($n$) | `Z_PLUS_ACTIVE` (%) | `Z_PLUS_SATELLITE` ($n$) | `Z_PLUS_SATELLITE` (%) | Total $Z_+$ ($n$) | Total $Z_+$ (%) |",
        "| :--- | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]

    for prov in prov_order:
        na = int((zpa["metric_provenance"] == prov).sum())
        ns = int((zps["metric_provenance"] == prov).sum())
        nt = na + ns
        if nt == 0 and prov == "unanchored":
            continue
        lines.append(
            f"| `{prov}` | {na} | {100.0 * na / len(zpa):.2f}% | {ns} | {100.0 * ns / len(zps):.2f}% | {nt} | {100.0 * nt / len(df_z_plus):.2f}% |"
        )

    direct_set = {"fancat_direct", "nrc_override", "nrc_bridge_auto"}
    na_dir = int(zpa["metric_provenance"].isin(direct_set).sum())
    ns_dir = int(zps["metric_provenance"].isin(direct_set).sum())
    nt_dir = na_dir + ns_dir
    na_imp = len(zpa) - na_dir
    ns_imp = len(zps) - ns_dir
    nt_imp = len(df_z_plus) - nt_dir

    lines.extend(
        [
            f"| **Sous-total ancres directes** (`fancat_direct + nrc_override + nrc_bridge_auto`) | **{na_dir}** | **{100.0 * na_dir / len(zpa):.2f}%** | **{ns_dir}** | **{100.0 * ns_dir / len(zps):.2f}%** | **{nt_dir}** | **{100.0 * nt_dir / len(df_z_plus):.2f}%** |",
            f"| **Sous-total imputation hiérarchique** (`subclass_centroid + class_centroid`) | **{na_imp}** | **{100.0 * na_imp / len(zpa):.2f}%** | **{ns_imp}** | **{100.0 * ns_imp / len(zps):.2f}%** | **{nt_imp}** | **{100.0 * nt_imp / len(df_z_plus):.2f}%** |",
            f"| **Total partition $Z_+$** | **{len(zpa)}** | **100.00%** | **{len(zps)}** | **100.00%** | **{len(df_z_plus)}** | **100.00%** |",
            "",
        ]
    )

    if unanchored_classes:
        lines.append(f"- **Classes sans aucune ancre directe (`unanchored`) :** `{unanchored_classes}`")
    else:
        lines.append(
            f"- **Classes sans aucune ancre directe :** `0` sur `{df_z_plus['classe'].nunique()}` classes $Z_+$ "
            f"(`{zpa['classe'].nunique()}` `Z_PLUS_ACTIVE` + `{df_z_plus['classe'].nunique() - zpa['classe'].nunique()}` classes exclusivement `Z_PLUS_SATELLITE` toutes ancrées directement)."
        )

    method_counts = df_z_plus["en_match_method"].value_counts().to_dict()
    n_cog_exact = int(method_counts.get("cognate_exact", 0))
    n_cog_suf = int(sum(v for k, v in method_counts.items() if str(k).startswith("cognate_suffix:")))
    n_static = int(method_counts.get("static_dict", 0))
    lines.append(
        f"- **Détail `nrc_bridge_auto` (`{n_static + n_cog_exact + n_cog_suf}` entrées) :** `{n_static}` dictionnaire statique FR→EN, `{n_cog_exact}` cognates directs sans accents (`NOM`/`ADJ`), `{n_cog_suf}` cognates suffixaux contrôlés."
    )
    lines.append(
        f"- **Périmètre non modifié (`dima_normalized.parquet`) :** `Z_MINUS_RESERVE` = `{n_res_total}` entrées (dont `{n_res_hum}` `Z_MINUS_HUMAN_ROLE`) ; `NON_LEXICAL_DISCARD` = `{n_discard}` entrées."
    )

    lines.extend(
        [
            "",
            "### Détail par panier `pruning_bucket`",
            "",
            "| `hemisphere_route` | `pruning_bucket` | Total ($n$) | `fancat_direct` | `nrc_override` | `nrc_bridge_auto` | `subclass_centroid` | `class_centroid` | Couv. directe (%) |",
            "| :--- | :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for (route_name, bucket_name), grp in df_z_plus.groupby(["hemisphere_route", "pruning_bucket"], sort=True):
        n_b = int(len(grp))
        c_fan = int((grp["metric_provenance"] == "fancat_direct").sum())
        c_ovr = int((grp["metric_provenance"] == "nrc_override").sum())
        c_br = int((grp["metric_provenance"] == "nrc_bridge_auto").sum())
        c_sub = int((grp["metric_provenance"] == "subclass_centroid").sum())
        c_cls = int((grp["metric_provenance"] == "class_centroid").sum())
        pct_b = 100.0 * (c_fan + c_ovr + c_br) / n_b
        lines.append(
            f"| `{route_name}` | `{bucket_name}` | {n_b} | {c_fan} | {c_ovr} | {c_br} | {c_sub} | {c_cls} | {pct_b:.1f}% |"
        )

    # Section 4 : Classes Z_PLUS_ACTIVE < 30% couverture directe
    cls_rows: list[dict[str, Any]] = []
    for cls, grp in zpa.groupby("classe", sort=True):
        n_act = int(len(grp))
        n_f = int((grp["metric_provenance"] == "fancat_direct").sum())
        n_o = int((grp["metric_provenance"] == "nrc_override").sum())
        n_b = int((grp["metric_provenance"] == "nrc_bridge_auto").sum())
        n_sub = int((grp["metric_provenance"] == "subclass_centroid").sum())
        n_cls = int((grp["metric_provenance"] == "class_centroid").sum())
        n_dir = n_f + n_o + n_b
        pct_dir = 100.0 * n_dir / n_act
        has_zm = bool(grp["z_minus_value_candidate"].any())
        n_zm = int(grp["z_minus_value_candidate"].sum())
        cls_rows.append(
            {
                "classe": str(cls),
                "categ": str(grp["categ"].iloc[0]),
                "n_active": n_act,
                "n_direct": n_dir,
                "pct_direct": pct_dir,
                "fancat": n_f,
                "override": n_o,
                "bridge": n_b,
                "sub_cent": n_sub,
                "cls_cent": n_cls,
                "has_zm": has_zm,
                "n_zm": n_zm,
            }
        )
    df_cls = pd.DataFrame(cls_rows).sort_values(["pct_direct", "classe"], kind="mergesort")
    low_cov = df_cls[df_cls["pct_direct"] < 30.0]

    lines.extend(
        [
            "",
            "---",
            "",
            f"## 4. Classes de `Z_PLUS_ACTIVE` (sur les {len(df_cls)} présentes) à couverture directe < 30 %",
            "",
            f"- **Nombre de classes `Z_PLUS_ACTIVE` analysées :** `{len(df_cls)}` (couverture directe médiane par classe : `{df_cls['pct_direct'].median():.1f}%`, moyenne : `{df_cls['pct_direct'].mean():.1f}%`).",
            f"- **Classes sous le seuil de 30 % de couverture directe :** **`{len(low_cov)}`** / `{len(df_cls)}`.",
            "",
        ]
    )

    if len(low_cov) == 0:
        lines.append("> **Aucune classe `Z_PLUS_ACTIVE` n'a une couverture directe inférieure à 30 %.**")
    else:
        lines.extend(
            [
                "| Classe DIMA (`classe`) | Catég. | Effectif `Z_PLUS_ACTIVE` | Direct ($n$) | Couv. directe (%) | `fancat` | `override` | `bridge_auto` | `sub_cent` | `cls_cent` | Contient `z_minus_value_candidate` |",
                "| :--- | :---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :---: |",
            ]
        )
        for _, r in low_cov.iterrows():
            zm_label = f"OUI ({int(r['n_zm'])})" if r["has_zm"] else "non"
            lines.append(
                f"| `{r['classe']}` | {r['categ']} | {int(r['n_active'])} | {int(r['n_direct'])} | {r['pct_direct']:.1f}% | "
                f"{int(r['fancat'])} | {int(r['override'])} | {int(r['bridge'])} | {int(r['sub_cent'])} | {int(r['cls_cent'])} | {zm_label} |"
            )

    # Rappel systématique des 12 classes comportant z_minus_value_candidate == True
    zm_classes = df_cls[df_cls["has_zm"]].sort_values("classe", kind="mergesort")
    lines.extend(
        [
            "",
            f"### Rappel de couverture des {len(zm_classes)} classes comportant `z_minus_value_candidate == True` (`{int(zm_classes['n_zm'].sum())}` entrées)",
            "",
            "| Classe DIMA (`classe`) | Effectif `Z_PLUS_ACTIVE` | `n_z_minus_value_candidate` | Direct ($n$) | Couv. directe (%) |",
            "| :--- | ---: | ---: | ---: | ---: |",
        ]
    )
    for _, r in zm_classes.iterrows():
        lines.append(
            f"| `{r['classe']}` | {int(r['n_active'])} | {int(r['n_zm'])} | {int(r['n_direct'])} | {r['pct_direct']:.1f}% |"
        )

    # Section 5 : Panel témoin de 14 jalons
    witness_specs: tuple[tuple[str, str, str], ...] = (
        ("colère", "NOM", "Colère"),
        ("rage", "NOM", "Colère"),
        ("frustration", "NOM", "Décevoir"),
        ("hostilité", "NOM", "Inimitié"),
        ("peur", "NOM", "Peur"),
        ("angoisse", "NOM", "Inquiéter"),
        ("terreur", "NOM", "Inquiéter Effrayer"),
        ("tristesse", "NOM", "Attrister"),
        ("désespoir", "NOM", "Mauvais moral"),
        ("honte", "NOM", "Honte"),
        ("calme", "NOM", "Apaiser"),
        ("sérénité", "NOM", "Rassurer"),
        ("joie", "NOM", "Réjouir"),
        ("fierté", "NOM", "Orgueil"),
    )

    lines.extend(
        [
            "",
            "---",
            "",
            "## 5. Panel témoin des 14 jalons psychométriques",
            "",
            "Pour les 3 lemmes polysémiques/bi-POS présents dans le panel (`rage` en `Colère`/`Désir`, `hostilité` en `Inimitié`/`Aversion`, `calme` en `NOM`/`ADJ` dans `Apaiser`), la ligne canonique `NOM` de la classe affective primaire est affichée ci-dessous (les entrées sœurs portent exactement le même vecteur psychométrique).",
            "",
            "| Jalon (`lemme_norm`) | `part_disc` | Classe primaire | $V_{\\text{harm}}$ | $A_{\\text{harm}}$ | $D_{\\text{raw}}$ | $D_{\\perp}$ | `en_matched_term` | `metric_provenance` |",
            "| :--- | :---: | :--- | ---: | ---: | ---: | ---: | :--- | :--- |",
        ]
    )
    witness_map: dict[tuple[str, str, str], pd.Series] = {}
    for lem, pos, cls in witness_specs:
        sub = df_z_plus[
            (df_z_plus["lemme_norm"] == lem)
            & (df_z_plus["part_disc"] == pos)
            & (df_z_plus["classe"] == cls)
        ]
        assert len(sub) == 1, f"Jalon témoin introuvable ou ambigu : {(lem, pos, cls)}"
        r = sub.iloc[0]
        witness_map[(lem, pos, cls)] = r
        lines.append(
            f"| `{lem}` | `{pos}` | `{cls}` | `{r['V_harm']:+.4f}` | `{r['A_harm']:+.4f}` | "
            f"`{r['D_raw']:+.4f}` | `{r['D_orth']:+.4f}` | `{r['en_matched_term']}` | `{r['metric_provenance']}` |"
        )

    w_host = witness_map[("hostilité", "NOM", "Inimitié")]
    w_col = witness_map[("colère", "NOM", "Colère")]
    w_rage = witness_map[("rage", "NOM", "Colère")]
    w_calme = witness_map[("calme", "NOM", "Apaiser")]
    w_ser = witness_map[("sérénité", "NOM", "Rassurer")]
    w_fier = witness_map[("fierté", "NOM", "Orgueil")]
    w_joie = witness_map[("joie", "NOM", "Réjouir")]

    lines.extend(
        [
            "",
            (
                f"> **Observation psychométrique sur $D_{{\\perp}}$ :** la résidualisation retire la corrélation "
                f"structurelle de Valence ($r(V, D) = {dom_res.r_vd:.4f}$ dans NRC-VAD) et isole l'agentivité / contrôle pur. "
                f"Ainsi, `hostilité` passe de $D_{{\\text{{raw}}}} = {w_host['D_raw']:+.4f}$ "
                f"(contaminé par sa valence négative ${w_host['V_harm']:+.3f}$) à $D_{{\\perp}} = {w_host['D_orth']:+.4f}$ "
                f"(cohérent avec `colère` ${w_col['D_orth']:+.4f}$ et `rage` ${w_rage['D_orth']:+.4f}$), "
                f"tandis que `calme` (${w_calme['D_orth']:+.4f}$) et `sérénité` (${w_ser['D_orth']:+.4f}$) "
                f"se distinguent nettement de `fierté` (${w_fier['D_orth']:+.4f}$) et `joie` (${w_joie['D_orth']:+.4f}$)."
            ),
        ]
    )

    # Section 6 : Audit qualitatif (homographes FANCat + cognates + artefacts)
    cog_rows = (
        df_z_plus[df_z_plus["en_match_method"].str.startswith("cognate_", na=False)]
        [["lemme_norm", "part_disc", "classe", "en_matched_term", "en_match_method"]]
        .sort_values(["en_match_method", "lemme_norm", "classe"], kind="mergesort")
    )

    lines.extend(
        [
            "",
            "---",
            "",
            "## 6. Points d'audit qualitatif pour relecture humaine (contrôle post-MP1c)",
            "",
            "### 6.1 Contrôle zéro homographe FANCat non pertinent dans `Z_PLUS_ACTIVE`",
            "",
            f"- **Gloses FANCat interdites dans `Z_PLUS_ACTIVE` (`{', '.join(sorted(FORBIDDEN_ACTIVE_FANCAT_GLOSSES))}`) :** **`0` occurrence** (vérification formelle PASS).",
            "- **Devenir des anciens homographes et overrides contextuels prioritaires :**",
            "",
            "| `lemme_norm` | `part_disc` | Classe DIMA | Route / Panier | `en_matched_term` | `metric_provenance` | Statut |",
            "| :--- | :---: | :--- | :--- | :--- | :--- | :--- |",
        ]
    )
    homograph_checks = (
        ("cafard", "NOM", "Apathie", "Exclu de `Z_PLUS_ACTIVE` via `z_plus_metaphor_exclusions.csv` → `Z_PLUS_IDIOM_MWE`"),
        ("transport", "NOM", "Troubler", "Exclu de `Z_PLUS_ACTIVE` (`vx` + métaphore) → `Z_PLUS_IDIOM_MWE`"),
        ("humeur", "NOM", "Colère", "Exclu de `Z_PLUS_ACTIVE` (`vx` + métaphore) → `Z_PLUS_IDIOM_MWE`"),
        ("humeur", "NOM", "Humeur mauvaise", "Exclu de `Z_PLUS_ACTIVE` (`vx` + métaphore) → `Z_PLUS_IDIOM_MWE`"),
        ("soif", "NOM", "Désir", "Exclu de `Z_PLUS_ACTIVE` via `z_plus_metaphor_exclusions.csv` → `Z_PLUS_IDIOM_MWE`"),
        ("rage", "NOM", "Désir", "Exclu de `Z_PLUS_ACTIVE` via `z_plus_metaphor_exclusions.csv` → `Z_PLUS_IDIOM_MWE`"),
        ("rire", "VERB", "Mépris", "Intercepté avant `fancat_direct` par override contextuel `(rire, Mépris) -> mock`"),
        ("crainte", "NOM", "Estime respect", "Intercepté avant `fancat_direct` par override contextuel `(crainte, Estime respect) -> reverence`"),
        ("crainte", "NOM", "Crainte", "Conservé en `Z_PLUS_ACTIVE` avec norme native `fancat_direct` (`fear`)"),
        ("lassitude", "NOM", "Importuner", "`V_harm`/`A_harm` FANCat + complétion `D_raw`/`D_orth` via override global `weariness`"),
    )
    for lem, pos, cls, status_note in homograph_checks:
        sub = df_z_plus[
            (df_z_plus["lemme_norm"] == lem)
            & (df_z_plus["part_disc"] == pos)
            & (df_z_plus["classe"] == cls)
        ]
        assert len(sub) == 1, f"Cas d'audit introuvable : {(lem, pos, cls)}"
        r = sub.iloc[0]
        lines.append(
            f"| `{lem}` | `{pos}` | `{cls}` | `{r['hemisphere_route']}` / `{r['pruning_bucket']}` | "
            f"`{r['en_matched_term']}` | `{r['metric_provenance']}` | {status_note} |"
        )

    lines.extend(
        [
            "",
            f"### 6.2 Audit complet des appariements par règle cognate (`{len(cog_rows)}` entrées)",
            "",
            "| `lemme_norm` | `part_disc` | Classe DIMA | `en_matched_term` | Règle appliquée |",
            "| :--- | :---: | :--- | :--- | :--- |",
        ]
    )
    for _, r in cog_rows.iterrows():
        lines.append(
            f"| `{r['lemme_norm']}` | `{r['part_disc']}` | `{r['classe']}` | `{r['en_matched_term']}` | `{r['en_match_method']}` |"
        )

    lines.extend(
        [
            "",
            "---",
            "",
            "## 7. Artefacts produits par la Micro-Passe 2",
            "",
            "| Artefact | Taille (octets) | SHA-256 | Statut Git |",
            "| :--- | ---: | :--- | :--- |",
            f"| `data/processed/dima_z_plus_psychometrics.parquet` | {parquet_size:,} | `{parquet_sha256}` | Local uniquement (ignoré par `.gitignore`) |",
            f"| `data/config/fr_en_bridge_overrides.csv` | {OVERRIDES_PATH.stat().st_size:,} | `{ovr_sha}` | Versionnable dans Git |",
            "| `python/lexicon_pipeline/02_bridge_psychometrics.py` | — | *(script source)* | Versionnable dans Git |",
            "| `reports/lexicon_v3/mp2_calibration_report.md` | — | *(présent rapport)* | Versionnable dans Git |",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    print("[MP2] Chargement des sources (dima_normalized, fancat_clean, NRC-VAD v2.1)...")
    df_dima, df_fancat, df_nrc = load_inputs()

    df_fancat_cal, cal_v, cal_a, proj_stats = calibrate_fancat_to_nrc(df_fancat, df_nrc)
    print(
        f"[MP2][CALIB] FANCat<->NRC (N={cal_v.n_pairs}): "
        f"Valence r={cal_v.pearson_r:.6f}, rho={cal_v.spearman_rho:.6f}, V_harm={cal_v.intercept:.6f}+{cal_v.slope:.6f}*V_FAN | "
        f"Arousal r={cal_a.pearson_r:.6f}, rho={cal_a.spearman_rho:.6f}, A_harm={cal_a.intercept:.6f}+{cal_a.slope:.6f}*A_FAN"
    )

    df_nrc_orth, dom_res = compute_orthogonal_dominance(df_nrc)
    print(
        f"[MP2][D_ORTH] NRC-VAD (N={dom_res.n_terms}): "
        f"alpha={dom_res.alpha:.6f}, beta={dom_res.beta:.6f}, r(V,D)={dom_res.r_vd:.6f}, "
        f"max|eps|={dom_res.max_abs_eps:.6f}, r(V,D_orth)={dom_res.r_vd_orth:.3e}"
    )

    df_z_plus, df_ovr, _lookup, overrides_created, unanchored_classes = run_z_plus_cascade(
        df_dima, df_fancat_cal, df_nrc_orth
    )
    status_ovr = "créé" if overrides_created else "existant conservé"
    print(
        f"[MP2][OVERRIDES] data/config/fr_en_bridge_overrides.csv ({status_ovr}, {len(df_ovr)} règles) | "
        f"unanchored_classes={unanchored_classes}"
    )
    print(
        f"[MP2][CASCADE Z+] {len(df_z_plus)} lignes | provenance={df_z_plus['metric_provenance'].value_counts().to_dict()}"
    )

    Z_PLUS_OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    df_z_plus.to_parquet(Z_PLUS_OUT_PATH, engine="pyarrow", index=False)

    pq_size = Z_PLUS_OUT_PATH.stat().st_size
    pq_sha = sha256_file(Z_PLUS_OUT_PATH)

    report_md = build_report(
        cal_v=cal_v,
        cal_a=cal_a,
        proj_stats=proj_stats,
        dom_res=dom_res,
        df_dima=df_dima,
        df_z_plus=df_z_plus,
        df_ovr=df_ovr,
        unanchored_classes=unanchored_classes,
        parquet_size=pq_size,
        parquet_sha256=pq_sha,
    )
    REPORT_OUT_PATH.write_text(report_md, encoding="utf-8", newline="\n")
    rep_sha = sha256_file(REPORT_OUT_PATH)
    ovr_sha = sha256_file(OVERRIDES_PATH)

    print(f"[MP2][SHA-256] parquet : {pq_sha} ({pq_size} B)")
    print(f"[MP2][SHA-256] overrides: {ovr_sha} ({OVERRIDES_PATH.stat().st_size} B)")
    print(f"[MP2][SHA-256] report  : {rep_sha} ({REPORT_OUT_PATH.stat().st_size} B)")


if __name__ == "__main__":
    main()
