import os
import sys
import time
import argparse
import pandas as pd

# Chargement sécurisé des variables d'environnement depuis .env
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    if os.path.exists(".env"):
        with open(".env", "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    os.environ[k.strip()] = v.strip().strip('"').strip("'")

from google import genai
from google.genai import types
from cartograffect_core import NON_CANONICAL_PROTO_MAP

MODEL_ID = "gemini-3.8-flash"
BATCH_SIZE = 150
INPUT_FILE = "nrc_candidates_filtered.tsv"
REF_FILE = "ref_176_cartograffect.tsv"
OUTPUT_FILE = "nrc_llm_classified.tsv"

def load_reference_labels(ref_path):
    df_ref = pd.read_csv(ref_path, sep="\t", encoding="utf-8")
    return df_ref["label_fr"].tolist()

def build_system_instruction(proto_labels):
    labels_formatted = ", ".join(proto_labels)
    instruction = f"""Tu es un expert mondial en psycholinguistique computationnelle et en modélisation affective différentielle.
Ta mission est d'évaluer des termes lexicaux issus du NRC-VAD (avec leurs coordonnées de Valence, Arousal, Dominance) et de déterminer rigoureusement s'il s'agit d'affects humains, de les classifier selon la théorie géométrique CARTOGRAFFECT et de les arrimer au prototype français le plus proche.

Architecture des Strates Z (profondeur cognitive et temporelle) de CARTOGRAFFECT (Z=0 à Z=7) :
- Z=0 : Veille (origine structurale, équilibre basal, éveil neutre).
- Z=1 : Surprise (rupture homéostatique, saillance perceptive pure, réorientation immédiate sans valence fixée).
- Z=2 : Affects primaires et prototypes fondamentaux (8 positions : Joie, Tristesse, Peur, Courage, Colère, Calme, Désir, Dégoût).
- Z=3 : Émotions réactives (16 positions : réponses immédiates, ex: Enthousiasme, Ennui, Panique, Soulagement, etc.).
- Z=4 : États émotionnels relationnels et sentiments réflexifs (24 positions : affects avec soi ou autrui, ex: Fierté, Honte, Admiration, Mépris, Amour, etc.).
- Z=5 : Dispositions, orientations et traits affectifs durables (32 positions : attitudes stables, humeurs, ex: Confiance, Méfiance, Optimisme, Patience, etc.).
- Z=6 : Identités affectives (40 positions : styles affectifs intégrés à la personnalité, ex: Allégresse, Angoisse, Sérénité profonde, etc.).
- Z=7 : Sentiments transcendantaux (48 positions : états limites d'absorption existentielle, ex: Plénitude absolue, Épiphanie, Sérénité extatique, etc.).

Liste exhaustive des 176 prototypes français admissibles (proto_fr_suggere) :
{labels_formatted}

Règles de classification :
1. `statut` :
   - 0 : Le terme N'EST PAS un affect, une émotion, un sentiment, une humeur ou une disposition affective (ex: objet physique concret, action motrice externe, concept purement technique ou descriptif non émotionnel).
   - 1 : Le terme désigne un état affectif pur, une émotion, un ressenti expérientiel ou un sentiment immédiat/réflexif.
   - 2 : Le terme désigne une disposition, attitude, orientation relationnelle ou trait à forte composante affective.
2. Si statut = 0 :
   - Renvoie EXACTEMENT : `nrc_id|0|0|-|-`
3. Si statut = 1 ou 2 :
   - `Z_cible` : entier de 0 à 7 correspondant à la profondeur cognitive/temporelle la plus adaptée.
   - `proto_fr_suggere` : DOIT être STRICTEMENT un des 176 prototypes français listés ci-dessus (respecter exactement l'orthographe et les accents).
   - `traduction_fr` : traduction française précise, naturelle et contextuelle du terme anglais.

Format de sortie OBLIGATOIRE :
Pour CHAQUE ligne d'entrée `nrc_id|term|V|A|D`, produis EXACTEMENT UNE ligne de sortie au format :
`nrc_id|statut|Z_cible|proto_fr_suggere|traduction_fr`

ATTENTION :
- Ne répète JAMAIS le mot anglais 'term' ni les valeurs VAD dans ta réponse. Le deuxième champ DOIT être le chiffre statut (0, 1 ou 2).
- Aucun texte avant ou après, pas de balises markdown ```, uniquement les lignes demandées séparées par des barres verticales |.
"""
    return instruction

def parse_llm_line(line, proto_labels_set):
    """
    Parse de manière robuste une ligne renvoyée par le LLM.
    Prend en compte les éventuelles répétitions du terme anglais ou décalages de colonnes.
    """
    line = line.strip().strip("`").strip()
    if not line or "|" not in line:
        return None
    parts = [p.strip() for p in line.split("|")]
    if not parts or not parts[0].isdigit():
        return None
    
    nrc_id = int(parts[0])
    statut = None
    z_cible = None
    proto = "-"
    trad = "-"

    # Cas 1 : Format standard 5 colonnes [id, statut, z, proto, trad]
    if len(parts) == 5 and parts[1] in ("0", "1", "2") and parts[2].isdigit():
        statut = parts[1]
        z_cible = parts[2]
        proto = parts[3]
        trad = parts[4]
    # Cas 2 : Format 6 colonnes avec répétition du terme anglais [id, term, statut, z, proto, trad]
    elif len(parts) >= 6 and parts[2] in ("0", "1", "2") and parts[3].isdigit():
        statut = parts[2]
        z_cible = parts[3]
        proto = parts[4]
        trad = parts[5] if len(parts) > 5 else "-"
    # Cas 3 : Format étendu (avec VAD) : recherche de la séquence [statut, z]
    else:
        for idx in range(1, len(parts) - 1):
            if parts[idx] in ("0", "1", "2") and parts[idx + 1].isdigit() and 0 <= int(parts[idx + 1]) <= 7:
                statut = parts[idx]
                z_cible = parts[idx + 1]
                proto = parts[idx + 2] if len(parts) > idx + 2 else "-"
                trad = parts[idx + 3] if len(parts) > idx + 3 else "-"
                break

    if statut is None or z_cible is None:
        return None

    if statut == "0":
        z_cible = "0"
        proto = "-"
        trad = "-"
    else:
        # Nettoyage si le prototype comporte des annotations ou un synonyme non-canonique
        if proto not in proto_labels_set:
            proto_lower = proto.strip().lower()
            proto_lower = NON_CANONICAL_PROTO_MAP.get(proto_lower, proto_lower)
            for p in proto_labels_set:
                if p.lower() == proto_lower:
                    proto = p
                    break

    return (nrc_id, statut, z_cible, proto, trad)

def process_batch(client, model_id, system_instruction, batch_rows):
    prompt_lines = [f"{r['nrc_id']}|{r['term']}|{r['valence']:.3f}|{r['arousal']:.3f}|{r['dominance']:.3f}" for r in batch_rows]
    user_prompt = "\n".join(prompt_lines)

    response = client.models.generate_content(
        model=model_id,
        contents=user_prompt,
        config=types.GenerateContentConfig(
            system_instruction=system_instruction,
            temperature=0.0
        )
    )
    return response.text

def normalize_existing_output(output_file, proto_labels_set):
    """
    Lit l'historique et extrait uniquement les enregistrements valides et sains.
    Élimine les décalages de colonnes et les lignes corrompues.
    """
    valid_records = {}
    if not os.path.exists(output_file):
        return valid_records

    with open(output_file, "r", encoding="utf-8") as f:
        header = f.readline()
        for line in f:
            parts = line.strip().split("\t")
            if len(parts) < 2 and "|" in line:
                parts = line.strip().split("|")
            parsed = parse_llm_line("|".join(parts), proto_labels_set)
            if parsed:
                nrc_id, statut, z, proto, trad = parsed
                # Si affect (statut 1 ou 2), il doit posséder une traduction et un proto valide
                if statut in ("1", "2") and (trad == "-" or trad == "" or proto == "-"):
                    continue
                valid_records[nrc_id] = (nrc_id, statut, z, proto, trad)

    return valid_records

def save_clean_output(output_file, records_dict):
    """Sauvegarde propre ordonnée par nrc_id croissant."""
    with open(output_file, "w", encoding="utf-8", newline="") as f:
        f.write("nrc_id\tstatut\tZ_cible\tproto_fr_suggere\ttraduction_fr\n")
        for n_id in sorted(records_dict.keys()):
            r = records_dict[n_id]
            f.write(f"{r[0]}\t{r[1]}\t{r[2]}\t{r[3]}\t{r[4]}\n")

def main():
    parser = argparse.ArgumentParser(description="Classification sémantique NRC-VAD via Gemini")
    parser.add_argument("--test", action="store_true", help="Traite un seul lot de 150 mots et affiche la sortie")
    args = parser.parse_args()

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("Erreur : la variable d'environnement GEMINI_API_KEY n'est pas définie.", file=sys.stderr)
        print("Définissez-la dans un fichier .env ou via votre environnement système.", file=sys.stderr)
        sys.exit(1)

    client = genai.Client(api_key=api_key)

    if not os.path.exists(INPUT_FILE):
        print(f"Erreur : fichier {INPUT_FILE} introuvable.", file=sys.stderr)
        sys.exit(1)
    if not os.path.exists(REF_FILE):
        print(f"Erreur : fichier {REF_FILE} introuvable.", file=sys.stderr)
        sys.exit(1)

    proto_labels = load_reference_labels(REF_FILE)
    proto_labels_set = set(proto_labels)
    system_instruction = build_system_instruction(proto_labels)

    # Récupération et normalisation de l'historique
    existing_records = normalize_existing_output(OUTPUT_FILE, proto_labels_set)
    print(f"Historique validé et sain : {len(existing_records)} identifiants conformes.")

    df_input = pd.read_csv(INPUT_FILE, sep="\t", encoding="utf-8")
    processed_ids = set(existing_records.keys())
    df_to_process = df_input[~df_input["nrc_id"].isin(processed_ids)].copy()

    print(f"Nombre total de termes restants à classifier/réparer : {len(df_to_process)} / {len(df_input)}")

    if len(df_to_process) == 0:
        print("Tous les termes ont déjà été classifiés et validés avec succès.")
        save_clean_output(OUTPUT_FILE, existing_records)
        print(f"Fichier {OUTPUT_FILE} réécrit de manière propre et triée.")
        return

    records = df_to_process.to_dict(orient="records")

    if args.test:
        test_batch = records[:BATCH_SIZE]
        print(f"--- Mode TEST : exécution sur un lot de {len(test_batch)} termes ---")
        raw_output = process_batch(client, MODEL_ID, system_instruction, test_batch)
        print("\n--- Sortie brute du modèle (premières lignes) ---")
        lines = [line.strip() for line in raw_output.strip().split("\n") if line.strip()]
        for l in lines[:20]:
            print(l)
        
        parsed_batch = {}
        for l in lines:
            p = parse_llm_line(l, proto_labels_set)
            if p:
                parsed_batch[p[0]] = p
        print(f"\nTermes valides parsés sur le test : {len(parsed_batch)} / {len(test_batch)}")
        return

    # Boucle complète par lots
    total_batches = (len(records) + BATCH_SIZE - 1) // BATCH_SIZE
    print(f"Démarrage du traitement : {total_batches} lots de {BATCH_SIZE} termes.")

    for b_idx in range(total_batches):
        batch = records[b_idx * BATCH_SIZE : (b_idx + 1) * BATCH_SIZE]
        print(f"Traitement lot {b_idx + 1}/{total_batches} (IDs {batch[0]['nrc_id']} à {batch[-1]['nrc_id']})...", end="", flush=True)

        success = False
        attempts = 0
        while not success and attempts < 5:
            attempts += 1
            try:
                raw_output = process_batch(client, MODEL_ID, system_instruction, batch)
                lines = [line.strip() for line in raw_output.strip().split("\n") if line.strip()]
                
                parsed_count = 0
                for l in lines:
                    parsed = parse_llm_line(l, proto_labels_set)
                    if parsed:
                        existing_records[parsed[0]] = parsed
                        parsed_count += 1
                
                # Sauvegarde incrémentale propre après chaque lot réussi
                save_clean_output(OUTPUT_FILE, existing_records)
                print(f" OK ({parsed_count}/{len(batch)} parsés)")
                success = True
            except Exception as e:
                print(f" Erreur (tentative {attempts}/5) : {e}")
                time.sleep(3 * attempts)

        if not success:
            print(f"Échec critique sur le lot {b_idx + 1}. Arrêt pour reprise ultérieure.", file=sys.stderr)
            break

    save_clean_output(OUTPUT_FILE, existing_records)
    print(f"Traitement terminé. Total entrées classifiées et validées dans {OUTPUT_FILE} : {len(existing_records)}")

if __name__ == "__main__":
    main()
