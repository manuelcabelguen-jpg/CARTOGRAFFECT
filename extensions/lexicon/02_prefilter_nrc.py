import sys
import subprocess
import os

# 1. Vérification et installation des dépendances si nécessaire
try:
    import pandas as pd
    import nltk
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pandas", "nltk"])
    import pandas as pd
    import nltk

# Téléchargement des corpus WordNet uniquement s'ils ne sont pas déjà installés localement
for _pkg in ("wordnet", "omw-1.4"):
    try:
        nltk.data.find(f"corpora/{_pkg}.zip")
    except LookupError:
        try:
            nltk.data.find(f"corpora/{_pkg}")
        except LookupError:
            nltk.download(_pkg, quiet=True)

from nltk.corpus import wordnet as wn

def main():
    nrc_file = "NRC-VAD-Lexicon-v2.1.txt"
    if not os.path.exists(nrc_file):
        print(f"Erreur : fichier {nrc_file} introuvable.")
        sys.exit(1)

    # 2. Chargement du fichier NRC-VAD avec pandas
    df = pd.read_csv(nrc_file, sep="\t")
    initial_count = len(df)
    print(f"Nombre initial de lignes : {initial_count}")

    # Renommage des colonnes si besoin (normalisation de la casse)
    df.columns = [c.strip().lower() for c in df.columns]

    # Vérification et normalisation sur [-1.0, +1.0] si les valeurs sont sur [0, 1]
    for col in ["valence", "arousal", "dominance"]:
        min_val = df[col].min()
        max_val = df[col].max()
        if min_val >= 0.0 and max_val <= 1.0:
            df[col] = 2.0 * df[col] - 1.0
            print(f"Normalisation appliquée à {col} : [0, 1] -> [-1, 1]")
        else:
            print(f"Plage déjà normalisée pour {col} : [{min_val}, {max_val}]")

    # Domaines WordNet
    PHYSICAL_DOMAINS = {
        "noun.artifact", "noun.object", "noun.animal", "noun.plant",
        "noun.food", "noun.location", "noun.substance", "noun.body", "noun.quantity"
    }

    PSYCH_DOMAINS = {
        "noun.feeling", "noun.state", "noun.attribute", "noun.cognition",
        "noun.motive", "adj.all", "verb.emotion"
    }

    filtered_rows = []

    for _, row in df.iterrows():
        term = str(row["term"])

        # a) Rejeter les locutions de plus de 2 mots
        words = term.strip().split()
        if len(words) > 2:
            continue

        # Récupération des synsets
        synsets = wn.synsets(term.replace(" ", "_"))
        if not synsets and len(words) == 1:
            # Essai avec le terme brut
            synsets = wn.synsets(term)

        if not synsets:
            continue

        lexnames = [s.lexname() for s in synsets]

        # b) Rejeter tous les termes dont les synsets désignent uniquement des objets physiques
        if all(lx in PHYSICAL_DOMAINS for lx in lexnames):
            continue

        # c) Conserver uniquement les termes ayant au moins un synset dans les domaines psychologiques/affectifs
        if not any(lx in PSYCH_DOMAINS for lx in lexnames):
            continue

        # d) Dont le premier synset n'est pas un artefact physique concret
        if lexnames[0] in PHYSICAL_DOMAINS:
            continue

        v = round(float(row["valence"]), 4)
        a = round(float(row["arousal"]), 4)
        d = round(float(row["dominance"]), 4)
        l1_vad = round(abs(v) + abs(a) + abs(d), 4)

        filtered_rows.append({
            "term": term,
            "valence": v,
            "arousal": a,
            "dominance": d,
            "L1_vad": l1_vad
        })

    # Construction du dataframe final et ajout de nrc_id
    res_df = pd.DataFrame(filtered_rows)
    res_df.insert(0, "nrc_id", range(1, len(res_df) + 1))

    output_file = "nrc_candidates_filtered.tsv"
    res_df.to_csv(output_file, sep="\t", index=False)

    final_count = len(res_df)
    print(f"Nombre de candidats retenus : {final_count}")
    print(f"Fichier sauvegardé dans : {output_file}")

if __name__ == "__main__":
    main()

