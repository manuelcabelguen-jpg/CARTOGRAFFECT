"""
03b_affect_audit_gemini.py
Audit sémantique strict des termes retenus (statut 1 ou 2) par 03_classify_batches_gemini.py.

Objectif : ne conserver que les termes réellement AFFECTIFS (émotion, sentiment, humeur,
état affectif ressenti, disposition affective) et fournir pour chacun une traduction
française de référence.

Sortie : nrc_affect_audit.tsv
    nrc_id  affectif  categorie  traduction_fr
    - affectif = 1 (conservé) ou 0 (exclu)
    - categorie ∈ CATEGORIES_KEEP ∪ CATEGORIES_REJECT
"""

import os
import sys
import time
import argparse
import pandas as pd

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

MODEL_ID = os.environ.get("GEMINI_MODEL_ID", "gemini-2.5-flash")
BATCH_SIZE = 150
CANDIDATES_FILE = "nrc_candidates_filtered.tsv"
LLM_FILE = "nrc_llm_classified.tsv"
OUTPUT_FILE = "nrc_affect_audit.tsv"

CATEGORIES_KEEP = {"EMOTION", "SENTIMENT", "HUMEUR", "ETAT_AFFECTIF", "DISPOSITION_AFFECTIVE", "INDUCTION_AFFECTIVE"}
CATEGORIES_REJECT = {"TRAIT_COGNITIF", "QUALITE_MORALE_SOCIALE", "ETAT_PHYSIOLOGIQUE",
                     "QUALITE_OBJET_SITUATION", "ACTION_COMPORTEMENT", "AUTRE"}

SYSTEM_INSTRUCTION = """Tu es un expert en psychologie des émotions et en lexicologie affective franco-anglaise.
On te soumet des termes anglais (issus du lexique NRC-VAD) déjà présélectionnés comme potentiellement affectifs.
Ta mission : décider de manière STRICTE si chaque terme relève du domaine AFFECTIF (émotions, sentiments, humeurs,
ressentis), puis donner sa meilleure traduction française.

CONSERVER (affectif = 1) uniquement si le sens principal du terme désigne ou qualifie directement un vécu affectif :
- EMOTION : émotion ressentie (fear, joy, anger, terrified, disgust, surprise...).
- SENTIMENT : sentiment durable ou relationnel (love, hatred, contempt, pride, shame, gratitude, envy...).
- HUMEUR : humeur ou tonalité affective diffuse (gloom, cheerfulness, melancholy, irritability...).
- ETAT_AFFECTIF : état affectif vécu (relief, distress, serenity, boredom, loneliness, despair...).
- DISPOSITION_AFFECTIVE : tendance stable à éprouver un affect (anxious, irritable, affectionate, coldhearted, fearful...).
- INDUCTION_AFFECTIVE : verbe ou adjectif dont le sens central est de provoquer ou d'exprimer un affect précis
  (terrify, humiliate, cherish, despise, appalling, heartbreaking...).

EXCLURE (affectif = 0) si le sens principal n'est pas un vécu affectif :
- TRAIT_COGNITIF : capacité ou style intellectuel (smart, meticulous, sage, dogmatic, exploratory...).
- QUALITE_MORALE_SOCIALE : qualité morale, civique ou sociale sans composante ressentie centrale
  (civility, decency, formal, cooperative, reliability, sovereignty, individualism, refined...).
- ETAT_PHYSIOLOGIQUE : état corporel (starving, ravenous, suffocation, weakened...).
- QUALITE_OBJET_SITUATION : propriété d'un objet, d'un lieu ou d'une situation (snazzy, noxious, title, reward,
  unlimited, insurmountable, prisonlike, squalor...).
- ACTION_COMPORTEMENT : action ou comportement observable sans affect spécifique (rush, stymie, rise, activated...).
- AUTRE : tout autre cas non affectif.

En cas de doute réel, privilégie l'exclusion (affectif = 0).

Traduction française : un mot ou une locution française courante, précise et naturelle, de même catégorie
grammaticale que l'anglais (nom -> nom, adjectif -> adjectif masculin singulier, verbe -> infinitif),
dans le sens affectif du terme lorsqu'il est conservé. Pas de guillemets, pas de parenthèses, pas de barre verticale.

Format de sortie OBLIGATOIRE : pour CHAQUE ligne d'entrée `nrc_id|term|traduction_initiale`, produis EXACTEMENT
une ligne : `nrc_id|affectif|categorie|traduction_fr`
Aucun texte avant ou après, pas de balises markdown.
"""


def load_input():
    df_cand = pd.read_csv(CANDIDATES_FILE, sep="\t", encoding="utf-8")
    df_llm = pd.read_csv(LLM_FILE, sep="\t", encoding="utf-8", on_bad_lines="skip")
    df_llm["nrc_id"] = pd.to_numeric(df_llm["nrc_id"], errors="coerce")
    df_llm = df_llm.dropna(subset=["nrc_id"]).copy()
    df_llm["nrc_id"] = df_llm["nrc_id"].astype(int)
    df_llm = df_llm.drop_duplicates(subset=["nrc_id"], keep="last")
    df_llm = df_llm[df_llm["statut"].astype(str).str.strip().isin(["1", "2"])]
    df = pd.merge(df_cand[["nrc_id", "term"]], df_llm[["nrc_id", "traduction_fr"]], on="nrc_id", how="inner")
    return df.sort_values("nrc_id").reset_index(drop=True)


def parse_line(line, valid_ids):
    line = line.strip().strip("`").strip()
    parts = [p.strip() for p in line.split("|")]
    if len(parts) < 4 or not parts[0].isdigit():
        return None
    nrc_id = int(parts[0])
    if nrc_id not in valid_ids:
        return None
    # Tolérance à la répétition éventuelle du terme anglais
    if parts[1] not in ("0", "1") and len(parts) >= 5 and parts[2] in ("0", "1"):
        parts = [parts[0]] + parts[2:]
    affectif, categorie, trad = parts[1], parts[2].upper(), parts[3]
    if affectif not in ("0", "1") or not trad or trad == "-":
        return None
    if categorie not in CATEGORIES_KEEP | CATEGORIES_REJECT:
        categorie = "AUTRE" if affectif == "0" else "ETAT_AFFECTIF"
    # Cohérence affectif / catégorie
    if affectif == "1" and categorie in CATEGORIES_REJECT:
        affectif = "0"
    if affectif == "0" and categorie in CATEGORIES_KEEP:
        categorie = "AUTRE"
    return nrc_id, affectif, categorie, trad.replace("\t", " ")


def load_existing():
    if not os.path.exists(OUTPUT_FILE):
        return {}
    df = pd.read_csv(OUTPUT_FILE, sep="\t", encoding="utf-8", dtype=str)
    return {int(r.nrc_id): (int(r.nrc_id), r.affectif, r.categorie, r.traduction_fr) for r in df.itertuples()}


def save(records):
    with open(OUTPUT_FILE, "w", encoding="utf-8", newline="") as f:
        f.write("nrc_id\taffectif\tcategorie\ttraduction_fr\n")
        for k in sorted(records):
            r = records[k]
            f.write(f"{r[0]}\t{r[1]}\t{r[2]}\t{r[3]}\n")


def process_batch(client, batch):
    prompt = "\n".join(f"{r['nrc_id']}|{r['term']}|{r['traduction_fr']}" for r in batch)
    resp = client.models.generate_content(
        model=MODEL_ID,
        contents=prompt,
        config=types.GenerateContentConfig(system_instruction=SYSTEM_INSTRUCTION, temperature=0.0),
    )
    return resp.text or ""


def main():
    parser = argparse.ArgumentParser(description="Audit affectif strict + traduction FR via Gemini")
    parser.add_argument("--test", action="store_true", help="Traite un seul lot et affiche la sortie")
    args = parser.parse_args()

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("Erreur : GEMINI_API_KEY non définie (.env).", file=sys.stderr)
        sys.exit(1)
    client = genai.Client(api_key=api_key)

    df = load_input()
    records = load_existing()
    todo = df[~df["nrc_id"].isin(records.keys())].to_dict(orient="records")
    print(f"Termes à auditer : {len(todo)} / {len(df)} (déjà audités : {len(records)})")

    if args.test:
        batch = todo[:BATCH_SIZE]
        raw = process_batch(client, batch)
        ids = {r["nrc_id"] for r in batch}
        parsed = [p for p in (parse_line(l, ids) for l in raw.splitlines()) if p]
        terms = {r["nrc_id"]: r["term"] for r in batch}
        for p in parsed[:40]:
            print(terms[p[0]], "->", p[1:])
        print(f"Parsés : {len(parsed)} / {len(batch)}")
        return

    # Plusieurs passes pour récupérer les identifiants manquants d'un lot
    for passe in range(1, 4):
        todo = df[~df["nrc_id"].isin(records.keys())].to_dict(orient="records")
        if not todo:
            break
        n_batches = (len(todo) + BATCH_SIZE - 1) // BATCH_SIZE
        print(f"Passe {passe} : {len(todo)} termes, {n_batches} lots")
        for b in range(n_batches):
            batch = todo[b * BATCH_SIZE:(b + 1) * BATCH_SIZE]
            ids = {r["nrc_id"] for r in batch}
            for attempt in range(1, 6):
                try:
                    raw = process_batch(client, batch)
                    n = 0
                    for l in raw.splitlines():
                        p = parse_line(l, ids)
                        if p:
                            records[p[0]] = p
                            n += 1
                    save(records)
                    print(f"  lot {b + 1}/{n_batches} : {n}/{len(batch)} parsés", flush=True)
                    break
                except Exception as e:
                    print(f"  lot {b + 1} erreur (tentative {attempt}/5) : {e}", flush=True)
                    time.sleep(3 * attempt)

    save(records)
    missing = len(df) - len(records)
    kept = sum(1 for r in records.values() if r[1] == "1")
    print(f"Audit terminé : {len(records)} audités, {kept} affectifs conservés, "
          f"{len(records) - kept} exclus, {missing} non audités.")
    if missing:
        sys.exit(2)


if __name__ == "__main__":
    main()

