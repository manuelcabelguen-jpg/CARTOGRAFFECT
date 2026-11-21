import re
import csv
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
CANONICAL_LEXICON176_LEAN = os.path.join(REPO_ROOT, "Cartograffect", "Lexicon176.lean")
OUT_REF176_TSV = os.path.join(SCRIPT_DIR, "ref_176_cartograffect.tsv")


def main():
    os.chdir(SCRIPT_DIR)
    lean_path = CANONICAL_LEXICON176_LEAN if os.path.exists(CANONICAL_LEXICON176_LEAN) else os.path.join(SCRIPT_DIR, "Lexicon176.lean")
    with open(lean_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Pattern: ⟨"Label", ⟨X, Y, Z⟩⟩
    pattern = re.compile(r'⟨"([^"]+)",\s*⟨(-?\d+),\s*(-?\d+),\s*(\d+)⟩⟩')
    matches = pattern.findall(content)

    print(f"Trouvé {len(matches)} entrées dans {os.path.relpath(lean_path, REPO_ROOT)}")

    entries = []
    coord_to_label = {}
    for match in matches:
        label, x_str, y_str, z_str = match
        x, y, z = int(x_str), int(y_str), int(z_str)
        # Canonical Strate 0 origin (0, 0, 0) is "Point de Veille" (legacy alias "Veille" normalized on read)
        if (x, y, z) == (0, 0, 0) and label == "Veille":
            label = "Point de Veille"
        coord_to_label[(x, y, z)] = label
        entries.append((label, x, y, z))

    print(f"Nombre de coordonnées uniques : {len(coord_to_label)}")

    rows = []
    for idx, (label, x, y, z) in enumerate(entries, 1):
        r_l1 = abs(x) + abs(y)

        if x == 0 and y == 0:
            type_geom = "Centre"
        elif x == 0 or y == 0:
            type_geom = "Axiale"
        elif abs(x) == abs(y):
            type_geom = "Diagonale"
        else:
            type_geom = "Laterale"

        if x == 0 and y == 0:
            groupe_geom = "OPERATEUR_CENTRAL"
        elif abs(x) == abs(y):
            if x > 0 and y > 0:
                groupe_geom = "DESIR"
            elif x < 0 and y < 0:
                groupe_geom = "DEGOUT"
            elif x < 0 and y > 0:
                groupe_geom = "COLERE"
            elif x > 0 and y < 0:
                groupe_geom = "CALME"
            else:
                raise ValueError(f"Diagonale non classée : {label} ({x}, {y}, {z})")
        elif abs(y) > abs(x):
            if y > 0:
                groupe_geom = "JOIE"
            elif y < 0:
                groupe_geom = "TRISTESSE"
            else:
                raise ValueError(f"Y dominant nul : {label}")
        elif abs(x) > abs(y):
            if x < 0:
                groupe_geom = "PEUR"
            elif x > 0:
                groupe_geom = "COURAGE"
            else:
                raise ValueError(f"X dominant nul : {label}")
        else:
            raise ValueError(f"Cas imprévu : {label} ({x}, {y}, {z})")

        if type_geom == "Centre":
            antag_coord = (0, 0, z)
        elif type_geom in ("Axiale", "Diagonale"):
            antag_coord = (-x, -y, z)
        elif type_geom == "Laterale":
            if x * y > 0:
                antag_coord = (-y, -x, z)
            elif x * y < 0:
                antag_coord = (y, x, z)
            else:
                raise ValueError(f"Latérale avec coord nulle : {label} ({x}, {y}, {z})")
        else:
            raise ValueError(f"Type géométrique inconnu : {type_geom}")

        if antag_coord not in coord_to_label:
            raise ValueError(f"Antagoniste {antag_coord} introuvable pour {label} ({x}, {y}, {z})")

        antag_label = coord_to_label[antag_coord]

        rows.append({
            "id_176": idx,
            "label_fr": label,
            "X": x,
            "Y": y,
            "Z": z,
            "rayon_L1": r_l1,
            "type_geom": type_geom,
            "groupe_geom": groupe_geom,
            "antagoniste_label": antag_label
        })

    expected_counts = {
        "JOIE": 36, "TRISTESSE": 36, "COURAGE": 36, "PEUR": 36,
        "DESIR": 6, "DEGOUT": 6, "COLERE": 6, "CALME": 6,
        "OPERATEUR_CENTRAL": 8,
    }
    counts = {}
    for r in rows:
        counts[r["groupe_geom"]] = counts.get(r["groupe_geom"], 0) + 1
    print("Effectifs par groupe_geom : " + ", ".join(f"{g}: {counts.get(g, 0)}" for g in expected_counts))
    if counts != expected_counts or len(rows) != 176:
        raise ValueError(f"Symétrie des groupes rompue : {counts} (attendu {expected_counts})")

    fieldnames = ["id_176", "label_fr", "X", "Y", "Z", "rayon_L1", "type_geom", "groupe_geom", "antagoniste_label"]
    with open(OUT_REF176_TSV, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)

    print(f"Fichier ref_176_cartograffect.tsv généré avec succès avec {len(rows)} lignes (Z=0 : '{rows[0]['label_fr']}').")


if __name__ == "__main__":
    main()
