# tests/test_integration.py
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from matching.normalizer import QueryNormalizer
from matching.scorer import ConfidenceScorer
from matching.game_detector import GameDetector
from ranking.ranker import Ranker
from ranking.deduplicator import Deduplicator
from providers.base import SearchResult

def test_hades_2_must_not_match_movie():
    n = QueryNormalizer({})
    s = ConfidenceScorer(n)
    test_cases = [
        ("Escape.Plan.2.Hades.2018.DVDRip.400MB", "hades 2", False),
        ("Escape Plan 2 Hades 2018 720p BluRay x264", "hades 2", False),
        ("Hades.II.v1.0-RUNE", "hades 2", True),
        ("Hades 2 (v1.131346 + Bonus OST, MULTi15) [FitGirl Repack]", "hades 2", True),
    ]
    all_pass = True
    for filename, query, should_match in test_cases:
        score = s.score(query, filename)
        matched = score >= 50
        status = "PASS" if matched == should_match else "FAIL"
        if status == "FAIL":
            all_pass = False
        print(f"  [{status}] '{filename}' vs '{query}': score={score}, match={matched}, expected={should_match}")
    return all_pass

def test_elden_ring_always_found():
    n = QueryNormalizer({"elden ring": ["elden ring shadow of the erdtree"]})
    s = ConfidenceScorer(n)
    d = GameDetector()

    game_cases = [
        "Elden.RING.v1.16.RUNE",
        "ELDEN RING Shadow of the Erdtree-RUNE",
        "Elden Ring (2022) v1.16 PC GAME",
        "Elden.Ring.Deluxe.Edition-FLT",
        "ELDEN RING v1.12.3-FitGirl Repack",
    ]

    all_pass = True
    for filename in game_cases:
        score = s.score("elden ring", filename)
        is_game = d.is_game(filename)
        ok = score >= 50 or is_game
        status = "PASS" if ok else "FAIL"
        if status == "FAIL":
            all_pass = False
        print(f"  [{status}] '{filename}': score={score}, game={is_game}")

    not_game_cases = [
        "Elden.Ring.2022.1080p.WEB-DL.x264-GalaxyRG",
        "Elden.Ring.2022.720p.BluRay.x264",
    ]
    for filename in not_game_cases:
        score = s.score("elden ring", filename)
        is_game = d.is_game(filename)
        ok = score < 50
        status = "PASS" if ok else "FAIL"
        if status == "FAIL":
            all_pass = False
        print(f"  [{status}] '{filename}' (should NOT match): score={score}, game={is_game}")

    return all_pass

def test_gta_v_matches_gta_5():
    config = {
        "gta v": ["gta 5", "grand theft auto v", "grand theft auto 5"],
        "gta 5": ["gta v", "grand theft auto 5", "grand theft auto v"],
    }
    n = QueryNormalizer(config)
    s = ConfidenceScorer(n)

    should_match = [
        ("GTA.V.v1.0.2802.0-RUNE", "gta v"),
        ("Grand Theft Auto V v1.0.2802.0-RUNE", "gta v"),
        ("GTA 5 v1.0.2802.0-RUNE", "gta v"),
        ("Grand.Theft.Auto.V-PLAZA", "gta v"),
    ]

    should_not_match = [
        ("GTA San Andreas-RELOADED", "gta v"),
        ("GTA Trilogy-PLAZA", "gta v"),
    ]

    all_pass = True
    for filename, query in should_match:
        score = s.score(query, filename)
        ok = score >= 50
        status = "PASS" if ok else "FAIL"
        if status == "FAIL":
            all_pass = False
        print(f"  [{status}] '{filename}' vs '{query}': score={score} (need >= 50)")

    for filename, query in should_not_match:
        score = s.score(query, filename)
        ok = score < 40
        status = "PASS" if ok else "FAIL"
        if status == "FAIL":
            all_pass = False
        print(f"  [{status}] '{filename}' vs '{query}': score={score} (should be < 40)")

    return all_pass

def test_deduplication():
    d = Deduplicator()
    results = [
        SearchResult("Game", "magnet:?xt=urn:btih:abc123", 100, 10, 10.0, "source1", "abc123"),
        SearchResult("Game", "magnet:?xt=urn:btih:abc123", 200, 20, 10.0, "source2", "abc123"),
        SearchResult("Game", "magnet:?xt=urn:btih:def456", 150, 15, 10.0, "source3", "def456"),
    ]
    deduped = d.deduplicate(results)
    ok = len(deduped) == 2
    if ok:
        for r in deduped:
            if r.info_hash == "abc123" and r.seeders != 200:
                ok = False
    status = "PASS" if ok else "FAIL"
    print(f"  [{status}] Dedup: {len(deduped)} unique from 3 input (expected 2)")
    return ok

def test_alias_expansion():
    import yaml
    config_path = os.path.join(os.path.dirname(__file__), '..', 'config.yaml')
    if not os.path.exists(config_path):
        print("  [SKIP] config.yaml not found")
        return True
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)
    aliases = config.get('aliases', {})
    n = QueryNormalizer(aliases)

    tests = [
        ("GTA V", ["gta 5", "grand theft auto v"]),
        ("Elden Ring", ["elden ring shadow of the erdtree"]),
        ("Baldurs Gate", ["baldurs gate 3", "bg3"]),
    ]

    all_pass = True
    for query, expected_in_expansions in tests:
        expansions = n.expand(query)
        for expected in expected_in_expansions:
            if expected not in expansions:
                print(f"  [FAIL] '{query}' expansion missing '{expected}'")
                all_pass = False
            else:
                print(f"  [PASS] '{query}' -> contains '{expected}'")
    return all_pass

if __name__ == "__main__":
    print("=== Integration Tests ===\n")

    print("CRITICAL: Hades 2 must NOT match movie:")
    r0 = test_hades_2_must_not_match_movie()

    print("\nElden Ring scenarios:")
    r1 = test_elden_ring_always_found()

    print("\nGTA V scenarios:")
    r2 = test_gta_v_matches_gta_5()

    print("\nDeduplication:")
    r3 = test_deduplication()

    print("\nAlias expansion:")
    r4 = test_alias_expansion()

    all_ok = r0 and r1 and r2 and r3 and r4
    print(f"\n{'='*40}")
    print(f"Result: {'ALL PASSED' if all_ok else 'SOME FAILED'}")
    sys.exit(0 if all_ok else 1)
