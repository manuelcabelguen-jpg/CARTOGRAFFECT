#!/usr/bin/env python3
"""
Suite de tests adversariaux pour `scripts/check_consistency.py` et
`scripts/sync_metadata.py` (bibliothèque standard Python 3.10+ uniquement).
"""

from __future__ import annotations

import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parent.parent
CHECK_SCRIPT = REPO_ROOT / "scripts" / "check_consistency.py"
SYNC_SCRIPT = REPO_ROOT / "scripts" / "sync_metadata.py"
EXPORT_SCRIPT = REPO_ROOT / "scripts" / "export_site_payload.py"

# Sous-ensemble complet de fichiers légers (< 256 KiB) + fichiers obligatoires
# permettant de reconstruire un dépôt temporaire fidèle et rapide (< 0.3s/test).
REQUIRED_COPY_PATHS = (
    "VERSION",
    "README.md",
    "CITATION.cff",
    ".zenodo.json",
    "manifest.json",
    "NOTICE",
    "CHANGELOG.md",
    ".gitattributes",
    "Cartograffect.lean",
    "docs/01-Article_Cartograffect.md",
    "docs/CONVERGENCE_MATRIX.md",
    "extensions/lexicon/EPISTEMIC_STATUS.md",
    "extensions/in_silico/EPISTEMIC_STATUS.md",
    "extensions/in_silico/pyproject.toml",
    "extensions/in_silico/data/lexicon_176.json",
    "scripts/check_consistency.py",
    "scripts/sync_metadata.py",
    "scripts/export_site_payload.py",
)

REQUIRED_COPY_DIRS = (
    "Cartograffect",
    "rocq/theories",
    "agda/src",
    "dafny/src",
    "smt/theories",
    "tla/specs",
)

FORMAL_SOURCE_SUFFIXES = frozenset({".lean", ".v", ".agda", ".dfy", ".smt2", ".tla", ".cfg"})


def _run_script(script: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(script), *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )


def _copy_if_file(src_root: Path, dst_root: Path, rel: str) -> None:
    src = src_root / rel
    if not src.is_file():
        return
    dst = dst_root / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def _make_temp_repo(tmpdir: Path) -> Path:
    for rel in REQUIRED_COPY_PATHS:
        _copy_if_file(REPO_ROOT, tmpdir, rel)

    for rel_dir in REQUIRED_COPY_DIRS:
        src_dir = REPO_ROOT / rel_dir
        if src_dir.is_dir():
            for path in src_dir.rglob("*"):
                if path.is_file() and path.suffix in FORMAL_SOURCE_SUFFIXES:
                    _copy_if_file(REPO_ROOT, tmpdir, path.relative_to(REPO_ROOT).as_posix())

    results_dir = REPO_ROOT / "extensions/in_silico/results"
    if results_dir.is_dir():
        for path in results_dir.rglob("*.json"):
            _copy_if_file(REPO_ROOT, tmpdir, path.relative_to(REPO_ROOT).as_posix())

    subprocess.run(["git", "init", "-q", str(tmpdir)], check=True)
    subprocess.run(
        ["git", "-C", str(tmpdir), "-c", "core.autocrlf=false", "-c", "core.safecrlf=false", "add", "-A"],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return tmpdir


class TestCheckConsistencyGuardrails(unittest.TestCase):
    def _assert_check_fails_on_category(self, repo: Path, expected_category: str) -> None:
        proc = _run_script(CHECK_SCRIPT, "--strict", "--json", "--root", str(repo))
        self.assertEqual(
            proc.returncode,
            1,
            f"Échec attendu (code 1) mais code={proc.returncode}.\nSTDOUT:\n{proc.stdout}\nSTDERR:\n{proc.stderr}",
        )
        report = json.loads(proc.stdout)
        self.assertEqual(report["status"], "FAIL")
        by_key = {cat["key"]: cat for cat in report["categories"]}
        self.assertIn(expected_category, by_key)
        self.assertFalse(
            by_key[expected_category]["passed"],
            f"La catégorie '{expected_category}' aurait dû échouer : {by_key[expected_category]}",
        )

    def test_real_repository_passes_strict(self) -> None:
        proc = _run_script(CHECK_SCRIPT, "--strict", "--json", "--root", str(REPO_ROOT))
        self.assertEqual(proc.returncode, 0, f"STDOUT:\n{proc.stdout}\nSTDERR:\n{proc.stderr}")
        report = json.loads(proc.stdout)
        self.assertEqual(report["status"], "PASS")
        self.assertEqual(report["summary"]["categories_passed"], 7)
        self.assertEqual(report["summary"]["total_errors"], 0)

    def test_isolated_baseline_copy_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = _make_temp_repo(Path(tmp))
            proc = _run_script(CHECK_SCRIPT, "--strict", "--json", "--root", str(repo))
            self.assertEqual(proc.returncode, 0, f"STDOUT:\n{proc.stdout}\nSTDERR:\n{proc.stderr}")
            report = json.loads(proc.stdout)
            self.assertEqual(report["status"], "PASS")

    def test_fault_version_desync_zenodo(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = _make_temp_repo(Path(tmp))
            zpath = repo / ".zenodo.json"
            data = json.loads(zpath.read_text(encoding="utf-8"))
            data["version"] = "2.0.2"
            zpath.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            self._assert_check_fails_on_category(repo, "version_parity")

    def test_fault_zenodo_composite_license_and(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = _make_temp_repo(Path(tmp))
            zpath = repo / ".zenodo.json"
            data = json.loads(zpath.read_text(encoding="utf-8"))
            data["license"] = "AGPL-3.0-or-later AND CC-BY-NC-SA-4.0"
            zpath.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            self._assert_check_fails_on_category(repo, "zenodo_cff_spdx")

    def test_fault_lexicon176_sha256_tamper(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = _make_temp_repo(Path(tmp))
            lex_path = repo / "Cartograffect/Lexicon176.lean"
            raw = lex_path.read_bytes()
            lex_path.write_bytes(raw + b"\n")
            self._assert_check_fails_on_category(repo, "strate0_integrity")

    def test_fault_uncommented_sorry_in_lean(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = _make_temp_repo(Path(tmp))
            core_path = repo / "Cartograffect/CoreAffect.lean"
            text = core_path.read_text(encoding="utf-8")
            core_path.write_text(
                text + "\ntheorem injected_gap : True := by sorry\n",
                encoding="utf-8",
            )
            self._assert_check_fails_on_category(repo, "strate0_integrity")

    def test_commented_sorry_is_ignored(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = _make_temp_repo(Path(tmp))
            core_path = repo / "Cartograffect/CoreAffect.lean"
            text = core_path.read_text(encoding="utf-8")
            core_path.write_text(
                text
                + "\n-- sorry Admitted postulate {:axiom} AXIOM\n"
                + "/- outer /- nested sorry admit -/ outer -/\n",
                encoding="utf-8",
            )
            proc = _run_script(CHECK_SCRIPT, "--strict", "--json", "--root", str(repo))
            self.assertEqual(proc.returncode, 0, f"STDOUT:\n{proc.stdout}\nSTDERR:\n{proc.stderr}")

    def test_fault_user_path_leak_in_tracked_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = _make_temp_repo(Path(tmp))
            leak_file = repo / "docs/LEAK_TEST.md"
            leak_value = "C:\\" + "Users\\" + ("dr" + "cab") + "\\Desktop\\secret.txt\n"
            leak_file.write_text(leak_value, encoding="utf-8")
            subprocess.run(
                ["git", "-C", str(repo), "-c", "core.autocrlf=false", "-c", "core.safecrlf=false", "add", "docs/LEAK_TEST.md"],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            self._assert_check_fails_on_category(repo, "zero_leak_zenodo_hygiene")

    def test_fault_a4_sanctuaire_violation(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = _make_temp_repo(Path(tmp))
            art_path = repo / "docs/01-Article_Cartograffect.md"
            text = art_path.read_text(encoding="utf-8")
            marker = "## Disponibilité des données"
            injected = text.replace(marker, f"Valeur interdite PXP_BIC = 1.0000.\n\n{marker}", 1)
            art_path.write_text(injected, encoding="utf-8")
            self._assert_check_fails_on_category(repo, "epistemic_compartmentalization")

    def test_fault_results_json_windows_path(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = _make_temp_repo(Path(tmp))
            res_path = repo / "extensions/in_silico/results/exp01_statistics.json"
            data = json.loads(res_path.read_text(encoding="utf-8"))
            data["figure_path"] = "D:\\Artifacts\\fig1.png"
            res_path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            self._assert_check_fails_on_category(repo, "tracked_results_json")

    def test_sync_metadata_check_and_apply_roundtrip(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = _make_temp_repo(Path(tmp))
            (repo / "VERSION").write_text("2.0.2\n", encoding="utf-8")

            check_before = _run_script(SYNC_SCRIPT, "--check", "--root", str(repo))
            self.assertEqual(check_before.returncode, 1)
            self.assertIn("DESYNC DETECTED", check_before.stdout)
            self.assertIn("--- a/.zenodo.json", check_before.stdout)

            apply_proc = _run_script(SYNC_SCRIPT, "--apply", "--root", str(repo))
            self.assertEqual(apply_proc.returncode, 0, apply_proc.stdout + apply_proc.stderr)

            check_after = _run_script(SYNC_SCRIPT, "--check", "--root", str(repo))
            self.assertEqual(check_after.returncode, 0, check_after.stdout + check_after.stderr)
            self.assertIn("SYNC OK", check_after.stdout)

    def test_export_site_payload_determinism_and_check(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            out_a = Path(tmp) / "a.json"
            out_b = Path(tmp) / "b.json"

            p1 = _run_script(EXPORT_SCRIPT, "--root", str(REPO_ROOT), "--output", str(out_a))
            self.assertEqual(p1.returncode, 0, p1.stdout + p1.stderr)
            p2 = _run_script(EXPORT_SCRIPT, "--root", str(REPO_ROOT), "--output", str(out_b))
            self.assertEqual(p2.returncode, 0, p2.stdout + p2.stderr)

            bytes_a = out_a.read_bytes()
            bytes_b = out_b.read_bytes()
            self.assertEqual(bytes_a, bytes_b)

            chk = _run_script(EXPORT_SCRIPT, "--check", "--root", str(REPO_ROOT), "--output", str(out_a))
            self.assertEqual(chk.returncode, 0, chk.stdout + chk.stderr)
            self.assertIn("PAYLOAD CHECK OK", chk.stdout)

            payload = json.loads(bytes_a.decode("utf-8"))
            self.assertEqual(payload["schema_version"], "1.0")
            self.assertEqual(payload["release"]["version"], "2.0.1")
            self.assertEqual(payload["release"]["tag"], "v2.0.1")
            self.assertEqual(payload["release"]["date"], "2026-11-21")
            self.assertIn("non mathématicien formel", payload["ai_disclosure"]["verification_and_audit_status"])
            self.assertIn("ligne par ligne", payload["ai_disclosure"]["verification_and_audit_status"])
            self.assertEqual(payload["identifiers"]["cipo_registration"], "1233199")
            self.assertEqual(payload["strate_0_core"]["theorems_verified"], 113)
            self.assertEqual(payload["strate_0_core"]["sorry_count"], 0)
            self.assertEqual(len(payload["strate_0_core"]["provers"]), 6)
            self.assertEqual(payload["strate_0_core"]["lean_modules_count"], 9)
            self.assertEqual(payload["strate_0_core"]["states_count"], 176)
            self.assertEqual(payload["strate_0_core"]["predictions_count"], 5)
            self.assertEqual(payload["licenses"]["spdx_expression"], "AGPL-3.0-or-later AND CC-BY-NC-SA-4.0")

    def test_fault_site_payload_manifest_mismatch(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = _make_temp_repo(Path(tmp))
            mpath = repo / "manifest.json"
            data = json.loads(mpath.read_text(encoding="utf-8"))
            data["strate_0_core"]["theorems_verified"] = 68
            mpath.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

            exp_fail = _run_script(EXPORT_SCRIPT, "--check", "--root", str(repo))
            self.assertEqual(exp_fail.returncode, 1)
            self._assert_check_fails_on_category(repo, "site_payload_contract")


if __name__ == "__main__":
    unittest.main()
