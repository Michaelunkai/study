# tests/test_integration.py
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from matching.normalizer import QueryNormalizer
from matching.scorer import ConfidenceScorer
from matching.game_detector import GameDetector
from ranking.ranker import Ranker
from providers.base import SearchResult

def test_elden_ring_scenarios():
    config = {
        "elden ring": ["elden ring", "elden ring shadow of the erdtree"],
    }
    n = QueryNormalizer(config)
    s = ConfidenceScorer(n)
    d = GameDetector()

    test_cases = [
        ("Elden.RING.v1.12.3-RUNE", True, 60),
        ("ELDEN RING Shadow of the Erdtree-RUNE", True, 50),
        ("Elden Ring (2022) v1.12.3 PC GAME", True, 50),
        ("Elden.Ring.2022.1080p.WEB-DL.x264-GalaxyRG", False, 30),
        ("Grand Theft Auto V-PLAZA", True, 0),
    ]

    all_pass = True
    for filename, expect_game, min_score in test_cases:
        is_game = d.is_game(filename)
        score = s.score("elden ring", filename)
        game_ok = is_game == expect_game
        score_ok = score >= min_score
        status = "PASS" if (game_ok and score_ok) else "FAIL"
        if status == "FAIL":
            all_pass = False
        print(f"  [{status}] {filename}: game={is_game}(expect {expect_game}), score={score}(need >= {min_score})")
    return all_pass

def test_gta_scenarios():
    config = {
        "gta v": ["gta 5", "grand theft auto v", "grand theft auto 5"],
        "gta 5": ["gta v", "grand theft auto 5", "grand theft auto v"],
    }
    n = QueryNormalizer(config)
    s = ConfidenceScorer(n)

    test_cases = [
        ("GTA.V.v1.0.2802.0-RUNE", 70),
        ("Grand Theft Auto V v1.0.2802.0-RUNE", 55),
        ("GTA 5 v1.0.2802.0-RUNE", 70),
        ("GTA San Andreas-RELOADED", 25),
        ("GTA Trilogy-PLAZA", 25),
    ]

    all_pass = True
    for filename, min_score in test_cases:
        score = s.score("gta v", filename)
        status = "PASS" if score >= min_score else "FAIL"
        if status == "FAIL":
            all_pass = False
        print(f"  [{status}] {filename}: score={score} (need >= {min_score})")
    return all_pass

def test_deduplication():
    from ranking.deduplicator import Deduplicator
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

    print("Elden Ring scenarios:")
    r1 = test_elden_ring_scenarios()

    print("\nGTA scenarios:")
    r2 = test_gta_scenarios()

    print("\nDeduplication:")
    r3 = test_deduplication()

    print("\nAlias expansion:")
    r4 = test_alias_expansion()

    all_ok = r1 and r2 and r3 and r4
    print(f"\n{'='*40}")
    print(f"Result: {'ALL PASSED' if all_ok else 'SOME FAILED'}")
    sys.exit(0 if all_ok else 1)
